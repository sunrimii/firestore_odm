import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/data_processor.dart';
import 'package:firestore_odm/src/firestore_odm.dart';

/// Service class that encapsulates all update operations logic
/// Extracted from UpdateOperationsMixin to follow composition over inheritance
class UpdateOperationsService<T> {
  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data) fromJson;

  final String documentIdField;

  /// Creates a new UpdateOperationsService instance
  const UpdateOperationsService({
    required this.toJson,
    required this.fromJson,
    required this.documentIdField,
  });

  /// Process data for updates, replacing special timestamps with server timestamps
  Map<String, dynamic> processUpdateData(Map<String, dynamic> data) {
    return _replaceServerTimestamps(data);
  }

  /// Recursively replace special timestamps with FieldValue.serverTimestamp()
  Map<String, dynamic> _replaceServerTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is DateTime && value == FirestoreODM.serverTimestamp) {
        result[key] = FieldValue.serverTimestamp();
      } else if (value is Map<String, dynamic>) {
        result[key] = _replaceServerTimestamps(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _replaceServerTimestamps(item);
          } else if (item is DateTime && item == FirestoreODM.serverTimestamp) {
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

  /// Execute update operations on a document reference
  Future<void> executeUpdate(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> updateData, {
    Transaction? transaction,
  }) async {
    final processedUpdateData = FirestoreDataProcessor.serializeForFirestore(
      updateData,
    );

    if (transaction != null) {
      log('executeUpdate with transaction: $processedUpdateData');
      transaction.update(ref, processedUpdateData);
    } else {
      log('executeUpdate without transaction: $processedUpdateData');
      await ref.update(processedUpdateData);
    }
  }

  /// Execute modify operation with diff detection
  Future<void> executeModify(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    T currentData, {
    Transaction? transaction,
  }) async {
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
    T currentData, {
    Transaction? transaction,
  }) async {
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
    final serializedUpdateData = FirestoreDataProcessor.serializeForFirestore(
      processedUpdateData,
    );

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
      final data = docSnapshot.data();
      final processedData = FirestoreDataProcessor.processFirestoreData(
        data,
        documentIdField: documentIdField,
        documentId: docSnapshot.id,
      );
      final doc = fromJson(processedData);
      final newDoc = modifier(doc);
      final oldData = toJson(doc);
      final newData = toJson(newDoc);
      final updateData = computeDiff(oldData, newData);

      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData =
            FirestoreDataProcessor.serializeForFirestore(processedUpdateData);
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
      final data = docSnapshot.data();
      final processedData = FirestoreDataProcessor.processFirestoreData(
        data,
        documentIdField: documentIdField,
        documentId: docSnapshot.id,
      );
      final doc = fromJson(processedData);
      final newDoc = modifier(doc);
      final oldData = toJson(doc);
      final newData = toJson(newDoc);
      final updateData = computeDiffWithAtomicOperations(oldData, newData);

      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData =
            FirestoreDataProcessor.serializeForFirestore(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }

    await batch.commit();
  }
}
