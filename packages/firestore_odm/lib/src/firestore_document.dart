import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/data_processor.dart';
import 'firestore_collection.dart';
import 'services/update_operations_service.dart';
import 'services/subscription_service.dart';
import 'interfaces/document_operations.dart';
import 'filter_builder.dart';

/// Exception thrown when a document is not found
class FirestoreDocumentNotFoundException implements Exception {
  final String documentId;
  FirestoreDocumentNotFoundException(this.documentId);
  @override
  String toString() => 'FirestoreDocumentNotFoundException: Document with ID "$documentId" not found';
}

/// A wrapper around Firestore DocumentReference with type safety and caching
/// Uses Interface + Composition architecture with services handling operations
class FirestoreDocument<T> implements DocumentOperations<T> {
  /// The collection this document belongs to
  final FirestoreCollection<T> collection;
  
  /// The document ID
  final String id;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  /// Service for handling subscriptions
  late final SubscriptionService<T> _subscriptionService;

  /// Cached document data
  Map<String, dynamic>? _cache;

  /// Creates a new FirestoreDocument instance
  FirestoreDocument(this.collection, this.id) {
    _updateService = UpdateOperationsService<T>(
      specialTimestamp: collection.specialTimestamp,
      toJson: collection.toJson,
      fromJson: collection.fromJson,
      documentIdField: collection.documentIdField,
    );
    _subscriptionService = SubscriptionService<T>(
      documentRef: ref,

      fromJson: collection.fromJson,
      documentIdField: collection.documentIdField,
    );
  }

  /// The underlying Firestore document reference
  DocumentReference<Map<String, dynamic>> get ref => collection.ref.doc(id);

  /// Stream of document changes
  @override
  Stream<T?> get changes => _subscriptionService.changes;

  /// Whether we are currently subscribing to changes
  @override
  bool get isSubscribing => _subscriptionService.isSubscribing;

  /// Helper function to convert raw data to model instance
  T _fromJson(Map<String, dynamic> data) {
    final processedData = FirestoreDataProcessor.processFirestoreData(
      data,
      documentIdField: collection.documentIdField,
      documentId: id,
    );
    return collection.fromJson(processedData);
  }

  /// Checks if the document exists
  @override
  Future<bool> exists() async {
    try {
      final doc = await ref.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Gets the document data
  @override
  Future<T?> get() async {
    log('getting document $id');
    if (_cache != null) {
      return _fromJson(_cache!);
    } else {
      // if we are not subscribing, we need to pull the data
      if (!isSubscribing) {
        log('pulling data');
        final value = await ref.get();
        _cache = value.data();
      }
      if (_cache == null) {
        return null; // Document doesn't exist
      }
      return _fromJson(_cache!);
    }
  }

  /// Gets the document or creates it with the provided factory function
  @override
  Future<T> getOrCreate(T Function() create) async {
    final value = await get();
    if (value != null) return value;
    final newData = create();
    await set(newData);
    return newData;
  }

  /// Sets the document data
  @override
  Future<void> set(T state) async {
    final data = FirestoreDataProcessor.toJson(collection.toJson, state,
        documentIdField: collection.documentIdField, documentId: id);
    await ref.set(data);
    _cache = data;
  }


  /// Incremental modify a document using diff-based updates (with automatic atomic operations)
  @override
  Future<void> incrementalModify(T Function(T docData) modifier) async {
    final oldState = await get();
    if (oldState == null) {
      throw FirestoreDocumentNotFoundException(id);
    }

    // Execute the incremental modify operation
    await _updateService.executeIncrementalModify(ref, modifier, oldState);

    // Update cache
    final newState = modifier(oldState);
    _cache = FirestoreDataProcessor.toJson(collection.toJson, newState,
        documentIdField: collection.documentIdField, documentId: id);
  }

  /// Modify a document using diff-based updates
  @override
  Future<void> modify(T Function(T docData) modifier) async {
    final oldState = await get();
    if (oldState == null) {
      throw FirestoreDocumentNotFoundException(id);
    }

    // Execute the modify operation
    await _updateService.executeModify(ref, modifier, oldState);

    // Update cache
    final newState = modifier(oldState);
    _cache = FirestoreDataProcessor.toJson(collection.toJson, newState,
        documentIdField: collection.documentIdField, documentId: id);
  }

  /// Internal helper for Firestore field updates using map
  /// Called by the update() and modify() methods
  Future<void> _updateFields(Map<String, dynamic> fields) async {
    // Execute the update
    await _updateService.executeUpdate(ref, fields);

    // Clear cache to force fresh fetch on next get()
    // We can't predict the final values of FieldValue operations like serverTimestamp()
    _cache = null;
  }

  /// Delete this document
  @override
  Future<void> delete() async {
    await ref.delete();
    _cache = null;
  }

  /// Internal method for executing update operations
  /// Called by generated extensions with converted operations
  Future<void> _executeUpdate(List<UpdateOperation> operations) async {
    final updateMap = UpdateBuilder.operationsToMap(operations);
    if (updateMap.isNotEmpty) {
      await _updateFields(updateMap);
    }
  }
  
  Future<void> update(
      List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
          updateBuilder) async {
    final builder = UpdateBuilder<T>();
    final operations = updateBuilder(builder);
    await _executeUpdate(operations);
  }

  /// Dispose subscriptions when document is no longer needed
  void dispose() {
    _subscriptionService.dispose();
  }
}
