import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_document.dart';
import 'firestore_query.dart';
import 'services/query_operations_service.dart';
import 'services/update_operations_service.dart';
import 'filter_builder.dart';
import 'interfaces/query_operations.dart';
import 'interfaces/update_operations.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<T> implements QueryOperations<T>, UpdateOperations<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data, [String? documentId]) fromJson;

  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;

  /// Special timestamp that should be replaced with server timestamp
  final DateTime specialTimestamp;

  /// Cache for document instances
  final Map<String, FirestoreDocument<T>> _cache = {};

  /// Service for handling query operations
  late final QueryOperationsService<T> _queryService;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({
    required this.ref,
    required this.fromJson,
    required this.toJson,
    DateTime? specialTimestamp,
  }) : specialTimestamp = specialTimestamp ?? DateTime.utc(1900, 1, 1, 0, 0, 10) {
    _queryService = QueryOperationsService<T>(
      query: ref,
      fromJson: fromJson,
    );
    _updateService = UpdateOperationsService<T>(
      specialTimestamp: this.specialTimestamp,
      toJson: toJson,
      fromJson: fromJson,
    );
  }

  /// Create a new query instance
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query) {
    return FirestoreQuery<T>(query, fromJson, toJson, specialTimestamp);
  }

  /// Executes the query and returns the results
  @override
  Future<List<T>> get() async {
    return await _queryService.executeQuery();
  }

  /// Limits the number of results returned
  @override
  FirestoreQuery<T> limit(int limit) {
    return newInstance(_queryService.applyLimit(limit));
  }

  /// Limits the number of results returned from the end
  @override
  FirestoreQuery<T> limitToLast(int limit) {
    return newInstance(_queryService.applyLimitToLast(limit));
  }


  /// Bulk modify all documents that match this collection using diff-based updates
  @override
  Future<void> modify(T Function(T docData) modifier) async {
    await _updateService.executeBulkModify(ref, modifier);
  }

  /// Bulk incremental modify all documents that match this collection with automatic atomic operations
  @override
  Future<void> incrementalModify(T Function(T docData) modifier) async {
    await _updateService.executeBulkIncrementalModify(ref, modifier);
  }

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  FirestoreDocument<T> call(String id) {
    return _cache.putIfAbsent(id, () => FirestoreDocument(this, id));
  }
}
