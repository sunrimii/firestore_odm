import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_document.dart';
import 'firestore_query.dart';
import 'update_operations_mixin.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<T> extends FirestoreQuery<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Cache for document instances
  final Map<String, FirestoreDocument<T>> _cache = {};

  /// Special timestamp that should be replaced with server timestamp
  final DateTime _specialTimestamp;
  
  @override
  DateTime get specialTimestamp => _specialTimestamp;

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({
    required this.ref,
    required T Function(Map<String, dynamic> data, [String? documentId]) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
    DateTime? specialTimestamp,
  }) : _specialTimestamp = specialTimestamp ?? DateTime.utc(1900, 1, 1, 0, 0, 10),
       super(ref, fromJson, toJson);

  @override
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query) {
    return _FirestoreQueryImpl<T>(query, fromJson, toJson, _specialTimestamp);
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
  final DateTime _specialTimestamp;

  _FirestoreQueryImpl(Query<Map<String, dynamic>> query,
      T Function(Map<String, dynamic> data, [String? documentId]) fromJson,
      Map<String, dynamic> Function(T value) toJson,
      DateTime specialTimestamp)
      : _specialTimestamp = specialTimestamp,
        super(query, fromJson, toJson);

  @override
  DateTime get specialTimestamp => _specialTimestamp;

  @override
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query) {
    return _FirestoreQueryImpl<T>(query, fromJson, toJson, _specialTimestamp);
  }
}
