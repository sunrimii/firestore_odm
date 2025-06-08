import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_document.dart';
import 'firestore_query.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<T> extends FirestoreQuery<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Cache for document instances
  final Map<String, FirestoreDocument<T>> _cache = {};

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({
    required this.ref,
    required T Function(Map<String, dynamic> data, [String? documentId]) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
  }) : super(ref, fromJson, toJson);

  @override
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query) {
    return _FirestoreQueryImpl<T>(query, fromJson, toJson);
  }

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  FirestoreDocument<T> call(String id) {
    return _cache.putIfAbsent(id, () => FirestoreDocument(this, id));
  }
}

/// Internal implementation of FirestoreQuery for queries derived from collections
class _FirestoreQueryImpl<T> extends FirestoreQuery<T> {
  _FirestoreQueryImpl(Query<Map<String, dynamic>> query,
      T Function(Map<String, dynamic> data, [String? documentId]) fromJson,
      Map<String, dynamic> Function(T value) toJson)
      : super(query, fromJson, toJson);

  @override
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query) {
    return _FirestoreQueryImpl<T>(query, fromJson, toJson);
  }
}
