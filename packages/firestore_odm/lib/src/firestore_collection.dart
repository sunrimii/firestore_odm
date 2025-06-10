import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/data_processor.dart';
import 'firestore_document.dart';
import 'firestore_query.dart';
import 'services/query_operations_service.dart';
import 'services/update_operations_service.dart';
import 'services/subscription_service.dart';
import 'filter_builder.dart';
import 'interfaces/query_operations.dart';
import 'interfaces/update_operations.dart';
import 'interfaces/collection_operations.dart';
import 'schema.dart';
import 'count_query.dart' show FirestoreCountQuery;
import 'tuple_aggregate.dart';
import 'model_converter.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<S extends FirestoreSchema, T>
    implements
        QueryOperations<T>,
        UpdateOperations<T>,
        CollectionOperations<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Model converter for data transformation
  final ModelConverter<T> converter;

  /// Cache for document instances
  final Map<String, FirestoreDocument<S, T>> _cache = {};

  /// Service for handling query operations
  late final QueryOperationsService<T> _queryService;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  /// Service for handling real-time subscriptions
  late final QuerySubscriptionService<T> _subscriptionService;

  String get documentIdField => 'id';

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({required this.ref, required this.converter}) {
    _queryService = QueryOperationsService<T>(
      query: ref,
      converter: converter,
      documentIdField: documentIdField,
    );
    _updateService = UpdateOperationsService<T>(
      converter: converter,
      documentIdField: documentIdField,
    );
    _subscriptionService = QuerySubscriptionService<T>(
      query: ref,
      converter: converter,
    );
  }

  /// Helper getter for fromJson (for backwards compatibility)
  T Function(Map<String, dynamic>) get fromJson => converter.fromJson;

  /// Helper getter for toJson (for backwards compatibility)
  Map<String, dynamic> Function(T) get toJson => converter.toJson;

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

  /// Insert a new document using the id field as document ID
  /// If ID is empty string, server will generate a unique ID
  /// Fails if document already exists (when ID is specified)
  Future<void> insert(T value) async {
    // First extract the document ID without validation
    final mapData = toJson(value);
    final documentId = DocumentIdHandler.extractDocumentId(
      mapData,
      documentIdField,
    );

    if (documentId == null) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be null for insert operation',
      );
    }

    // If ID is empty string, let Firestore generate a unique ID
    if (documentId.isEmpty) {
      final processedData = DocumentIdHandler.removeDocumentIdField(
        mapData,
        documentIdField,
      );
      final serializedData = FirestoreDataProcessor.serializeForFirestore(
        processedData,
      );
      await ref.add(serializedData);
      return;
    }

    // For non-empty IDs, use the normal validation path
    final (
      json,
      validatedDocumentId,
    ) = FirestoreDataProcessor.toJsonAndDocumentId(
      toJson,
      value,
      documentIdField: documentIdField,
    );

    // Check if document already exists
    final docRef = ref.doc(validatedDocumentId!);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      throw StateError(
        'Document with ID \'$validatedDocumentId\' already exists. Use upsert() to update existing documents.',
      );
    }

    await docRef.set(json);
  }

  /// Update an existing document using the id field as document ID
  /// Fails if document doesn't exist
  Future<void> updateDocument(T value) async {
    final (json, documentId) = FirestoreDataProcessor.toJsonAndDocumentId(
      toJson,
      value,
      documentIdField: documentIdField,
    );

    if (documentId == null) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be null for update operation',
      );
    }

    // Check if document exists
    final docRef = ref.doc(documentId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw StateError(
        'Document with ID \'$documentId\' does not exist. Use insert() or upsert() to create new documents.',
      );
    }

    await docRef.set(json);
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

  /// Get the count of documents in this collection
  @override
  FirestoreCountQuery count() {
    return FirestoreCountQuery(ref);
  }

  /// Perform strongly-typed aggregate operations using records/tuples
  @override
  TupleAggregateQuery<T, R> aggregate<R extends Record>(
    R Function(AggregateFieldSelector<T> selector) builder,
  ) {
    return TupleAggregateQuery<T, R>(ref, converter, builder);
  }

  /// Stream of collection changes for real-time updates
  Stream<List<T>> get stream => _subscriptionService.stream;
}
