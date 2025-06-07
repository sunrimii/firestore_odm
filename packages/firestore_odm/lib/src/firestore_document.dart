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
    if (transaction != null) {
      log('setting with transaction: $data');
      transaction.set(ref, data);
      Zone.current[#onSuccess](() {
        _cache = data;
      });
    } else {
      log('setting without transaction: $data');
      await ref.set(data);
      _cache = data;
    }
  }

  /// Updates the document using a callback function
  /// Computes the difference for efficient partial updates
  Future<void> update(T Function(T state) cb) async {
    final oldState = await get();
    if (oldState == null) {
      throw FirestoreDocumentNotFoundException(id);
    }
    final newState = cb(oldState);
    final newData = collection.toJson(newState);
    final data = _diff(_cache ?? {}, newData);

    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('updating with transaction: $data');
      transaction.set(ref, data, SetOptions(merge: true));
      Zone.current[#onSuccess](() {
        _cache = newData;
      });
    } else {
      log('updating without transaction: $data');
      await ref.set(data, SetOptions(merge: true));
      _cache = newData;
    }
  }

  /// Disposes of resources when the document is no longer needed
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
