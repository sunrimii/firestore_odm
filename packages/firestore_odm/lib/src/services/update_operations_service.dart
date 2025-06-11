import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_odm.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/utils.dart';

class FirestoreDocumentNotFoundException implements Exception {
  final String documentId;
  FirestoreDocumentNotFoundException(this.documentId);
  @override
  String toString() =>
      'FirestoreDocumentNotFoundException: Document with ID "$documentId" not found';
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

Map<String, dynamic> processUpdateData(Map<String, dynamic> data) {
  return _replaceServerTimestamps(data);
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

Transaction? getTransactionFromZone() {
  return Zone.current[#transaction] as Transaction?;
}

class UpdateService {
  static Future<bool> exists<T>(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final transaction = getTransactionFromZone();
    if (transaction != null) {
      final snapshot = await transaction.get(ref);
      return snapshot.exists;
    } else {
      final snapshot = await ref.get();
      return snapshot.exists;
    }
  }

  static Stream<T?> streamDocument<T>(DocumentReference<Map<String, dynamic>> ref, JsonDeserializer<T> fromJson, String documentIdField) {
    return lazyBroadcast(
      () => ref.snapshots().map(
        (snapshot) => snapshot.exists
          ? processDocumentSnapshot(snapshot, fromJson, documentIdField)
          : null,
      ),
    );
  }


  static Future<T?> get<T>(
    DocumentReference<Map<String, dynamic>> ref,
    JsonDeserializer<T> deserializer,
    String documentIdField,
  ) async {
    final transaction = getTransactionFromZone();
    if (transaction != null) {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return null;
      return fromFirestoreData(
        deserializer,
        snapshot.data()!,
        documentIdField,
        snapshot.id,
      );
    } else {
      final snapshot = await ref.get();
      if (!snapshot.exists) return null;
      return fromFirestoreData(
        deserializer,
        snapshot.data()!,
        documentIdField,
        snapshot.id,
      );
    }
  }

  static Future<void> _update<T>(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> updateData,
  ) async {
    final transaction = getTransactionFromZone();
    final processedUpdateData = serializeForFirestore(updateData);
    if (transaction != null) {
      transaction.update(ref, processedUpdateData);
    } else {
      await ref.update(processedUpdateData);
    }
  }

  static Future<void> delete(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final transaction = getTransactionFromZone();
    if (transaction != null) {
      transaction.delete(ref);
    } else {
      await ref.delete();
    }
  }

  static Future<void> update<T>(
    DocumentReference<Map<String, dynamic>> ref,
    T data,
    JsonSerializer<T> serializer,
    String? documentIdField,
    ) async {
    final dataMap = toFirestoreData(
      serializer,
      data,
      documentIdField: documentIdField,
    );
    final processedData = serializeForFirestore(dataMap);
    
    final transaction = getTransactionFromZone();
    if (transaction != null) {
      transaction.set(ref, processedData);
    } else {
      await ref.set(processedData);
    }
  }

  static Future<void> patch<T>(
    DocumentReference<Map<String, dynamic>> ref,
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) async {
    final builder = UpdateBuilder<T>();
    final operations = updateBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    if (!updateMap.isNotEmpty) {
      return; // No updates to apply
    }
    await _update(ref, updateMap);
  }

  static Future<void> _modify<T>(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    ModelConverter<T> converter,
    String documentIdField,
    Map<String, dynamic> Function(
      Map<String, dynamic> oldData,
      Map<String, dynamic> newData,
    )
    computeDiff,
  ) async {
    final transaction = getTransactionFromZone();
    
    if (transaction != null) {
      // In transaction: do all reads first, then defer writes
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw FirestoreDocumentNotFoundException(ref.id);
      }
      
      final currentData = fromFirestoreData(
        converter.fromJson,
        snapshot.data()!,
        documentIdField,
        snapshot.id,
      );
      
      final newData = modifier(currentData);
      final oldDataMap = converter.toJson(currentData);
      final newDataMap = converter.toJson(newData);
      final updateData = computeDiff(oldDataMap, newDataMap);

      if (updateData.isNotEmpty) {
        transaction.update(ref, serializeForFirestore(updateData));
      }
    } else {
      // Not in transaction: normal operation
      final currentData = await get(ref, converter.fromJson, documentIdField);
      if (currentData == null) {
        throw FirestoreDocumentNotFoundException(ref.id);
      }
      final newData = modifier(currentData);
      final oldDataMap = converter.toJson(currentData);
      final newDataMap = converter.toJson(newData);
      final updateData = computeDiff(oldDataMap, newDataMap);

      if (updateData.isNotEmpty) {
        await _update(ref, updateData);
      }
    }
  }

  static Future<void> modify<T>(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    ModelConverter<T> converter,
    String documentIdField,
  ) async {
    return _modify(ref, modifier, converter, documentIdField, computeDiff);
  }

  static Future<void> incrementalModify<T>(
    DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    ModelConverter<T> converter,
    String documentIdField,
  ) async {
    return _modify(
      ref,
      modifier,
      converter,
      documentIdField,
      computeDiffWithAtomicOperations,
    );
  }



}



abstract class CollectionHandler {
  static Future<List<T>> get<T>(
    CollectionReference<Map<String, dynamic>> ref,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return ref.get().then(
      (snapshot) => processQuerySnapshot<T>(
        snapshot,
        fromJson,
        documentIdField,
      ),
    );
  }

  static Future<void> insert<T>(
    CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    // First extract the document ID without validation
    final (data, documentId) = processObject(toJson, value, documentIdField: documentIdField);

    // If ID is empty string, let Firestore generate a unique ID
    if (documentId.isEmpty) {
      await ref.add(data);
      return;
    }

    // Check if document already exists
    final docRef = ref.doc(documentId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      throw StateError(
        'Document with ID \'$documentId\' already exists. Use upsert() to update existing documents.',
      );
    }

    await docRef.set(data);
  }

  static Future<void> update<T>(
    CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    final (data, documentId) = processObject(toJson, value, documentIdField: documentIdField);

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be empty for update operation',
      );
    }

    // Check if document exists
    final docRef = ref.doc(documentId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw StateError('Document with ID \'$documentId\' does not exist');
    }

    await docRef.set(data);
  }


  static Future<void> upsert<T>(
    CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    final (data, documentId) = processObject(toJson, value, documentIdField: documentIdField);

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be empty for upsert operation',
      );
    }

    // Use set with merge option to upsert
    await ref.doc(documentId).set(data, SetOptions(merge: true));
  }
}

abstract class QueryHandler {
  static Future<List<T>> get<T>(
    Query<Map<String, dynamic>> query,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return query.get().then(
      (snapshot) => processQuerySnapshot<T>(
        snapshot,
        fromJson,
        documentIdField,
      ),
    );
  }
  
  static Stream<List<T>> stream<T>(
    Query<Map<String, dynamic>> query,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return lazyBroadcast(
      () => query.snapshots().map(
        (snapshot) => processQuerySnapshot(
          snapshot,
          fromJson,
          documentIdField,
        ),
      ),
    );
  }

  
  static Future<void> update(
    Query query,
    Map<String, dynamic> updateData,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();
    final processedUpdateData = processUpdateData(updateData);
    final serializedUpdateData = serializeForFirestore(processedUpdateData);

    for (final docSnapshot in snapshot.docs) {
      batch.update(docSnapshot.reference, serializedUpdateData);
    }

    await batch.commit();
  }

  static Future<void> modify<T>(
    Query<Map<String, dynamic>> query,
    String documentIdField,
    ModelConverter<T> converter,
    T Function(T) modifier,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      final data = docSnapshot.data();
      final doc = fromFirestoreData(
        converter.fromJson,
        data,
        documentIdField,
        docSnapshot.id,
      );
      final newDoc = modifier(doc);
      final oldData = converter.toJson(doc);
      final newData = converter.toJson(newDoc);
      final updateData = computeDiff(oldData, newData);

      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData = serializeForFirestore(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }

    await batch.commit();
  }

  static Future<void> incrementalModify<T>(
    Query<Map<String, dynamic>> query,
    String documentIdField,
    ModelConverter<T> converter,
    T Function(T) modifier,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      final data = docSnapshot.data();
      final doc = fromFirestoreData(
        converter.fromJson,
        data,
        documentIdField,
        docSnapshot.id,
      );
      final newDoc = modifier(doc);
      final oldData = converter.toJson(doc);
      final newData = converter.toJson(newDoc);
      final updateData = computeDiffWithAtomicOperations(oldData, newData);

      if (updateData.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateData);
        final serializedUpdateData = serializeForFirestore(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }

    await batch.commit();
  }

  static Future<void> patch<T>(
    Query<Map<String, dynamic>> query,
    String documentIdField,
    ModelConverter<T> converter,
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      final builder = UpdateBuilder<T>();
      final operations = updateBuilder(builder);
      final updateMap = UpdateBuilder.operationsToMap(operations);

      if (updateMap.isNotEmpty) {
        final processedUpdateData = processUpdateData(updateMap);
        final serializedUpdateData = serializeForFirestore(processedUpdateData);
        batch.update(docSnapshot.reference, serializedUpdateData);
      }
    }
    await batch.commit();
  }


  static Future<void> delete(Query query) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      batch.delete(docSnapshot.reference);
    }

    await batch.commit();
  }
}