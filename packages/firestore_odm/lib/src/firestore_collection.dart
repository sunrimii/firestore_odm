import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/data_processor.dart';
import 'package:firestore_odm/src/firestore_odm.dart';
import 'firestore_document.dart';
import 'firestore_query.dart';
import 'services/query_operations_service.dart';
import 'services/update_operations_service.dart';
import 'filter_builder.dart';
import 'interfaces/query_operations.dart';
import 'interfaces/update_operations.dart';
import 'schema.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<S extends FirestoreSchema, T>
    implements QueryOperations<T>, UpdateOperations<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data) fromJson;

  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;

  /// Cache for document instances
  final Map<String, FirestoreDocument<S, T>> _cache = {};

  /// Service for handling query operations
  late final QueryOperationsService<T> _queryService;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  String get documentIdField => 'id';

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({
    required this.ref,
    required this.fromJson,
    required this.toJson,
  }) {
    _queryService = QueryOperationsService<T>(
      query: ref,
      fromJson: fromJson,
      documentIdField: documentIdField,
    );
    _updateService = UpdateOperationsService<T>(
      toJson: toJson,
      fromJson: fromJson,
      documentIdField: documentIdField,
    );
  }

  /// Executes the query and returns the results
  @override
  Future<List<T>> get() async {
    return await _queryService.executeQuery();
  }

  /// Limits the number of results returned
  @override
  QueryOperations<T> limit(int limit) {
    return FirestoreQuery<S, T>(this, _queryService.applyLimit(limit));
  }

  /// Limits the number of results returned from the end
  @override
  QueryOperations<T> limitToLast(int limit) {
    return FirestoreQuery<S, T>(this, _queryService.applyLimitToLast(limit));
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
  FirestoreDocument<S, T> call(String id) {
    return _cache.putIfAbsent(id, () => FirestoreDocument(this, id));
  }

  @override
  FirestoreQuery<S, T> where(
    FirestoreFilter<T> Function(RootFilterBuilder<T> builder) filterBuilder,
  ) {
    final builder = RootFilterBuilder<T>();
    final builtFilter = filterBuilder(builder);
    final newQuery = applyFilterToQuery(ref, builtFilter);
    return FirestoreQuery<S, T>(this, newQuery);
  }

  @override
  FirestoreQuery<S, T> orderBy(
    OrderByField<T> Function(OrderByBuilder<T> order) orderBuilder,
  ) {
    final builder = OrderByBuilder<T>();
    final orderByField = orderBuilder(builder);
    final newQuery = _queryService.applyOrderBy(orderByField);
    return FirestoreQuery<S, T>(this, newQuery);
  }

  /// Upsert a document using the id field as document ID
  Future<void> upsert(T value) async {
    final (json, documentId) = FirestoreDataProcessor.toJsonAndDocumentId(
      toJson,
      value,
      documentIdField: documentIdField,
    );
    await ref.doc(documentId!).set(json, SetOptions(merge: true));
  }

  @override
  Future<void> update(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) {
    final builder = UpdateBuilder<T>();
    final operations = updateBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    return _updateService.executeBulkUpdate(ref, updateMap);
  }
}
