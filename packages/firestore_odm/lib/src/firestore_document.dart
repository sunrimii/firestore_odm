import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'firestore_collection.dart';
import 'services/update_operations_service.dart';
import 'filter_builder.dart';
import 'schema.dart';

/// A wrapper around Firestore DocumentReference with type safety and caching
/// Uses Interface + Composition architecture with services handling operations
class FirestoreDocument<S extends FirestoreSchema, T>
    implements Streamable<T?> {
  /// The collection this document belongs to (nullable for fromRef constructor)
  final FirestoreCollection<S, T> collection;

  /// The document ID
  final DocumentReference<Map<String, dynamic>> ref;


  /// Creates a new FirestoreDocument instance from a collection and document ID
  FirestoreDocument(this.collection, this.ref);

  /// Stream of document snapshots
  Stream<T?> get stream => UpdateService.streamDocument<T>(
    ref,
    collection.converter.fromJson,
    collection.documentIdField,
  );

  /// Checks if the document exists
  Future<bool> exists() => UpdateService.exists(ref);

  /// Gets the document data
  Future<T?> get() => UpdateService.get(
    ref,
    collection.converter.fromJson,
    collection.documentIdField,
  );

  /// Sets the document data
  Future<void> update(T state) => UpdateService.update(
    ref,
    state,
    collection.converter.toJson,
    collection.documentIdField,
  );

  /// Incremental modify a document using diff-based updates (with automatic atomic operations)
  Future<void> incrementalModify(T Function(T docData) modifier) =>
      UpdateService.incrementalModify(
        ref,
        modifier,
        collection.converter,
        collection.documentIdField,
      );

  /// Modify a document using diff-based updates
  Future<void> modify(T Function(T docData) modifier) => UpdateService.modify(
    ref,
    modifier,
    collection.converter,
    collection.documentIdField,
  );

  /// Delete this document
  Future<void> delete() => UpdateService.delete(ref);

  Future<void> patch(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) => UpdateService.patch(ref, updateBuilder);
}
