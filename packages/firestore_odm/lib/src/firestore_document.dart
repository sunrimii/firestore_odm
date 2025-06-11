import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'services/update_operations_service.dart';
import 'filter_builder.dart';
import 'schema.dart';

/// A wrapper around Firestore DocumentReference with type safety and caching
/// Uses Interface + Composition architecture with services handling operations
class FirestoreDocument<S extends FirestoreSchema, T>
    implements Streamable<T?> {
  /// The collection this document belongs to (nullable for fromRef constructor)
  final ModelConverter<T> converter;

  final String documentIdField;

  /// The document ID
  final DocumentReference<Map<String, dynamic>> ref;


  /// Creates a new FirestoreDocument instance from a collection and document ID
  FirestoreDocument(this.ref, this.converter, this.documentIdField);

  /// Stream of document snapshots
  Stream<T?> get stream => DocumentHandler.streamDocument<T>(
    ref,
    converter.fromJson,
    documentIdField,
  );

  /// Checks if the document exists
  Future<bool> exists() => DocumentHandler.exists(ref);

  /// Gets the document data
  Future<T?> get() => DocumentHandler.get(
    ref,
    converter.fromJson,
    documentIdField,
  );

  /// Sets the document data
  Future<void> update(T state) => DocumentHandler.update(
    ref,
    state,
    converter.toJson,
    documentIdField,
  );

  /// Incremental modify a document using diff-based updates (with automatic atomic operations)
  Future<void> incrementalModify(T Function(T docData) modifier) =>
      DocumentHandler.incrementalModify(
        ref,
        modifier,
        converter,
        documentIdField,
      );

  /// Modify a document using diff-based updates
  Future<void> modify(T Function(T docData) modifier) => DocumentHandler.modify(
    ref,
    modifier,
    converter,
    documentIdField,
  );

  /// Delete this document
  Future<void> delete() => DocumentHandler.delete(ref);

  Future<void> patch(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) => DocumentHandler.patch(ref, updateBuilder);
}
