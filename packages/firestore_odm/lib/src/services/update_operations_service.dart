import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class that encapsulates all update operations logic
/// Extracted from UpdateOperationsMixin to follow composition over inheritance
class UpdateOperationsService<T> {
  /// Special timestamp that should be replaced with server timestamp
  final DateTime specialTimestamp;
  
  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;
  
  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data, [String? documentId]) fromJson;

  /// Creates a new UpdateOperationsService instance
  const UpdateOperationsService({
    required this.specialTimestamp,
    required this.toJson,
    required this.fromJson,
  });

  /// Process data for updates, replacing special timestamps with server timestamps
  Map<String, dynamic> processUpdateData(Map<String, dynamic> data) {
    return _replaceSpecialTimestamps(data, specialTimestamp);
  }

  /// Recursively replace special timestamps with FieldValue.serverTimestamp()
  Map<String, dynamic> _replaceSpecialTimestamps(Map<String, dynamic> data, DateTime specialTimestamp) {
    final result = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is DateTime && value == specialTimestamp) {
        result[key] = FieldValue.serverTimestamp();
      } else if (value is Map<String, dynamic>) {
        result[key] = _replaceSpecialTimestamps(value, specialTimestamp);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _replaceSpecialTimestamps(item, specialTimestamp);
          } else if (item is DateTime && item == specialTimestamp) {
            return FieldValue.serverTimestamp();
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Compute the difference between old and new data for efficient updates
  Map<String, dynamic> computeDiff(
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
  Map<String, dynamic> computeDiffWithAtomicOperations(
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
        if (atomicOp != null) {
          result[key] = atomicOp;
        } else if (oldValue is Map && newValue is Map) {
          // Handle nested objects - check if it's an empty map (deletion scenario)
          if (newValue.isEmpty && oldValue.isNotEmpty) {
            // Empty map means we want to clear all nested fields
            result[key] = newValue; // Set to empty map
          } else {
            // For other nested changes, use the new value
            result[key] = newValue;
          }
        } else {
          result[key] = newValue;
        }
      }
    }

    return result;
  }

  /// Detects if a change can be represented as an atomic operation
  dynamic _detectAtomicOperation(dynamic oldValue, dynamic newValue) {
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

      // For mixed operations or when trying to add duplicates, fall back to direct assignment
      // Note: arrayUnion naturally handles duplicates by not adding them again
    }

    // No atomic operation detected
    return null;
  }

  /// Recursively serializes nested objects to ensure compatibility with fake_cloud_firestore
  Map<String, dynamic> deepSerialize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result[key] = null;
      } else if (value is Map<String, dynamic>) {
        result[key] = deepSerialize(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return deepSerialize(item);
          } else if (_isFreezedObject(item)) {
            // This is a Freezed object, serialize it
            return deepSerialize(
                (item as dynamic).toJson() as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else if (_isFreezedObject(value)) {
        // This is a Freezed object, serialize it
        result[key] =
            deepSerialize((value as dynamic).toJson() as Map<String, dynamic>);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Check if an object is a Freezed-generated object
  bool _isFreezedObject(dynamic obj) {
    if (obj == null) return false;
    final typeName = obj.runtimeType.toString();
    // Check for Freezed patterns: ends with 'Impl' or contains '$'
    return typeName.contains('Impl') ||
           typeName.contains('\$') ||
           (obj is Object && obj.toString().startsWith('_\$'));
  }

  /// Execute update operations on a document reference
  Future<void> executeUpdate(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> updateData,
    {Transaction? transaction}
  ) async {
    final processedUpdateData = processUpdateData(updateData);
    final serializedUpdateData = deepSerialize(processedUpdateData);
    
    if (transaction != null) {
      log('executeUpdate with transaction: $serializedUpdateData');
      transaction.update(ref, serializedUpdateData);
    } else {
      log('executeUpdate without transaction: $serializedUpdateData');
      await ref.update(serializedUpdateData);
    }
  }

  /// Execute modify operation with diff detection
  Future<void> executeModify(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    T currentData,
    {Transaction? transaction}
  ) async {
    final newData = modifier(currentData);
    final oldDataMap = toJson(currentData);
    final newDataMap = toJson(newData);
    final updateData = computeDiff(oldDataMap, newDataMap);

    if (updateData.isEmpty) return; // No changes

    await executeUpdate(ref, updateData, transaction: transaction);
  }

  /// Execute incremental modify operation with atomic operations
  Future<void> executeIncrementalModify(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    T currentData,
    {Transaction? transaction}
  ) async {
    final newData = modifier(currentData);
    final oldDataMap = toJson(currentData);
    final newDataMap = toJson(newData);
    final updateData = computeDiffWithAtomicOperations(oldDataMap, newDataMap);

    if (updateData.isEmpty) return; // No changes

    await executeUpdate(ref, updateData, transaction: transaction);
  }

  /// Execute bulk update operations on a query
  Future<void> executeBulkUpdate(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> updateData,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();
    final processedUpdateData = processUpdateData(updateData);
    final serializedUpdateData = deepSerialize(processedUpdateData);
    
    for (final docSnapshot in snapshot.docs) {
      batch.update(docSnapshot.reference, serializedUpdateData);
    }
    
    await batch.commit();
  }

  /// Execute bulk modify operations on a query
  Future<void> executeBulkModify(
    Query<Map<String, dynamic>> query,
    T Function(T) modifier,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();
    
    for (final docSnapshot in snapshot.docs) {
      final doc = fromJson(docSnapshot.data(), docSnapshot.id);
      final newDoc = modifier(doc);
      final oldData = toJson(doc);
      final newData = toJson(newDoc);
      final updateData = computeDiff(oldData, newData);
      
      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData = deepSerialize(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }
    
    await batch.commit();
  }

  /// Execute bulk incremental modify operations on a query
  Future<void> executeBulkIncrementalModify(
    Query<Map<String, dynamic>> query,
    T Function(T) modifier,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();
    
    for (final docSnapshot in snapshot.docs) {
      final doc = fromJson(docSnapshot.data(), docSnapshot.id);
      final newDoc = modifier(doc);
      final oldData = toJson(doc);
      final newData = toJson(newDoc);
      final updateData = computeDiffWithAtomicOperations(oldData, newData);
      
      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData = deepSerialize(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }
    
    await batch.commit();
  }
}