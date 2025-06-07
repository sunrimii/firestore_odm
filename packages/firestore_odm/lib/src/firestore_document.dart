import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collection.dart';

/// Exception thrown when a document is not found
class FirestoreDocumentNotFoundException implements Exception {
  final String documentId;

  const FirestoreDocumentNotFoundException(this.documentId);

  @override
  String toString() => 'Document with ID "$documentId" not found';
}

/// A wrapper around Firestore DocumentReference with type safety and caching
class FirestoreDocument<T> {
  /// The collection this document belongs to
  final FirestoreCollection<T> collection;

  /// The document ID
  final String id;

  /// Cached document data
  Map<String, dynamic>? _cache;

  /// Computes the difference between old and new data for efficient updates
  static Map<String, dynamic> _diff(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final result = <String, dynamic>{};

    // Find removed fields
    for (final key in oldData.keys) {
      if (!newData.containsKey(key)) {
        result[key] = FieldValue.delete();
      }
    }

    // Find added or changed fields
    for (final entry in newData.entries) {
      final key = entry.key;
      final newValue = entry.value;

      if (!oldData.containsKey(key) || oldData[key] != newValue) {
        result[key] = newValue;
      }
    }

    return result;
  }

  /// Analyzes changes and converts them to atomic operations where possible
  static Map<String, dynamic> _diffWithAtomicOperations(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final result = <String, dynamic>{};

    // Find removed fields
    for (final key in oldData.keys) {
      if (!newData.containsKey(key)) {
        result[key] = FieldValue.delete();
      }
    }

    // Find added or changed fields with atomic operation detection
    for (final entry in newData.entries) {
      final key = entry.key;
      final newValue = entry.value;
      final oldValue = oldData[key];

      if (!oldData.containsKey(key)) {
        // New field
        result[key] = newValue;
      } else if (oldValue != newValue) {
        // Changed field - try to detect atomic operations
        final atomicOp = _detectAtomicOperation(oldValue, newValue);
        result[key] = atomicOp ?? newValue;
      }
    }

    return result;
  }

  /// Detects if a change can be represented as an atomic operation
  static dynamic _detectAtomicOperation(dynamic oldValue, dynamic newValue) {
    // Numeric increment detection
    if (oldValue is num && newValue is num) {
      final diff = newValue - oldValue;
      if (diff != 0) {
        return FieldValue.increment(diff);
      }
    }

    // Array operations detection
    if (oldValue is List && newValue is List) {
      final oldSet = Set.from(oldValue);
      final newSet = Set.from(newValue);

      final added = newSet.difference(oldSet).toList();
      final removed = oldSet.difference(newSet).toList();

      // If only additions, use arrayUnion
      if (removed.isEmpty && added.isNotEmpty) {
        return FieldValue.arrayUnion(added);
      }

      // If only removals, use arrayRemove
      if (added.isEmpty && removed.isNotEmpty) {
        return FieldValue.arrayRemove(removed);
      }

      // For mixed operations, fall back to direct assignment
    }

    // No atomic operation detected
    return null;
  }

  /// Stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// Whether this document is currently subscribed to real-time updates
  bool get isSubscribing => _subscription != null;

  /// Stream controller for broadcasting document changes
  final StreamController<T?> _controller = StreamController.broadcast();

  /// Stream of document changes
  Stream<T?> get changes => _controller.stream;

  /// The underlying Firestore document reference
  DocumentReference<Map<String, dynamic>> get ref => collection.ref.doc(id);

  /// Creates a new FirestoreDocument instance
  FirestoreDocument(this.collection, this.id) {
    _controller.onListen = () {
      log('listening to data changes');
      _subscription = ref.snapshots().skip(1).listen((event) {
        log('data changed: ${event.data()}');
        _cache = event.data();
        _controller.add(_fromJson(_cache));
      });
    };
    _controller.onCancel = () {
      log('cancelling data changes');
      _subscription?.cancel();
      _subscription = null;
    };
  }

  /// Converts JSON data to model instance, adding the document ID
  T? _fromJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    data['id'] = id;
    return collection.fromJson(data);
  }

  /// Checks if the document exists in Firestore
  Future<bool> exists() async {
    return await get() != null;
  }

  /// Gets the document data
  /// Uses transactions when available, otherwise fetches from cache or Firestore
  Future<T?> get() async {
    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('getting with transaction');
      final value = await transaction.get(ref);
      _cache = value.data();
      return _fromJson(_cache);
    } else {
      // if we are not subscribing, we need to pull the data
      if (!isSubscribing) {
        log('pulling data');
        final value = await ref.get();
        _cache = value.data();
      }
      return _fromJson(_cache);
    }
  }

  /// Gets the document or creates it with the provided factory function
  Future<T> getOrCreate(T Function() create) async {
    final value = await get();
    if (value != null) return value;
    await set(create());
    return create();
  }

  /// Sets the document data
  /// Uses transactions when available for atomic operations
  Future<void> set(T state) async {
    final transaction = Zone.current[#transaction] as Transaction?;
    final data = collection.toJson(state);
    final serializedData = _deepSerialize(data);
    if (transaction != null) {
      log('setting with transaction: $serializedData');
      transaction.set(ref, serializedData);
      Zone.current[#onSuccess](() {
        _cache = serializedData;
      });
    } else {
      log('setting without transaction: $serializedData');
      await ref.set(serializedData);
      _cache = serializedData;
    }
  }

  /// Recursively serializes nested objects to ensure compatibility with fake_cloud_firestore
  Map<String, dynamic> _deepSerialize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result[key] = null;
      } else if (value is Map<String, dynamic>) {
        result[key] = _deepSerialize(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _deepSerialize(item);
          } else if (item.runtimeType.toString().contains('Impl')) {
            // This is a Freezed object, serialize it
            return _deepSerialize(
                (item as dynamic).toJson() as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else if (value.runtimeType.toString().contains('Impl')) {
        // This is a Freezed object, serialize it
        result[key] =
            _deepSerialize((value as dynamic).toJson() as Map<String, dynamic>);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// RxDB-style incremental modify with automatic atomic operations
  /// Automatically detects and uses Firestore atomic operations where possible
  Future<void> incrementalModify(T Function(T docData) modifier) async {
    final oldState = await get();
    if (oldState == null) {
      throw FirestoreDocumentNotFoundException(id);
    }

    final newState = modifier(oldState);
    final oldData = collection.toJson(oldState);
    final newData = collection.toJson(newState);
    final updateData = _diffWithAtomicOperations(oldData, newData);

    if (updateData.isEmpty) return; // No changes

    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('incrementalModify with transaction: $updateData');
      transaction.update(ref, updateData);
      Zone.current[#onSuccess](() {
        _cache = newData;
      });
    } else {
      log('incrementalModify without transaction: $updateData');
      await ref.update(updateData);
      _cache = newData;
    }
  }

  /// RxDB-style modify without atomic operations
  /// Only computes differences and updates changed fields
  Future<void> modify(T Function(T docData) modifier) async {
    final oldState = await get();
    if (oldState == null) {
      throw FirestoreDocumentNotFoundException(id);
    }

    final newState = modifier(oldState);
    final oldData = collection.toJson(oldState);
    final newData = collection.toJson(newState);
    final updateData = _diff(oldData, newData);

    if (updateData.isEmpty) return; // No changes

    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('modify with transaction: $updateData');
      transaction.set(ref, updateData, SetOptions(merge: true));
      Zone.current[#onSuccess](() {
        _cache = newData;
      });
    } else {
      log('modify without transaction: $updateData');
      await ref.set(updateData, SetOptions(merge: true));
      _cache = newData;
    }
  }

  /// Updates specific fields using a Map (similar to Firestore's update)
  Future<void> updateFields(Map<String, dynamic> fields) async {
    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('updateFields with transaction: $fields');
      transaction.update(ref, fields);
      Zone.current[#onSuccess](() {
        // Update cache by merging fields
        _cache = {...?_cache, ...fields};
      });
    } else {
      log('updateFields without transaction: $fields');
      await ref.update(fields);
      // Update cache by merging fields
      _cache = {...?_cache, ...fields};
    }
  }

  /// Deletes the document
  Future<void> delete() async {
    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('deleting with transaction');
      transaction.delete(ref);
      Zone.current[#onSuccess](() {
        _cache = null;
      });
    } else {
      log('deleting without transaction');
      await ref.delete();
      _cache = null;
    }
  }

  /// Disposes of resources when the document is no longer needed
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
