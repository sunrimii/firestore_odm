import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/insertable.dart';
import 'package:firestore_odm/src/interfaces/updatable.dart';
import 'package:firestore_odm/src/interfaces/upsertable.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<S extends FirestoreSchema, T>
    implements
        Insertable<T>,
        Updatable<T>,
        Upsertable<T>,
        Query<S, T, Null, Null> {
  @override
  FirestoreCollection<S, T> get collection => this;

  /// The underlying Firestore collection reference
  @override
  final firestore.CollectionReference<Map<String, dynamic>> query;

  /// Model converter for data transformation
  final ModelConverter<T> converter;

  String get documentIdField => 'id';

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({required this.query, required this.converter});

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  FirestoreDocument<S, T> call(String id) => FirestoreDocument(this, query.doc(id));

  /// Upsert a document using the id field as document ID
  Future<void> upsert(T value) => 
      CollectionHandler.upsert(query, value, converter.toJson, documentIdField);

  /// Insert a new document using the id field as document ID
  /// If ID is empty string, server will generate a unique ID
  /// Fails if document already exists (when ID is specified)
  Future<void> insert(T value) =>
      CollectionHandler.insert(query, value, converter.toJson, documentIdField);

  /// Update an existing document using the id field as document ID
  /// Fails if document doesn't exist
  @override
  Future<void> update(T value) =>
      CollectionHandler.update(query, value, converter.toJson, documentIdField);

  @override
  Future<List<T>> get() =>
      CollectionHandler.get<T>(query, converter.fromJson, documentIdField);

  @override
  Stream<List<T>> get stream =>
      QueryHandler.stream(query, converter.fromJson, documentIdField);
}
