import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_collection.dart';
import 'package:meta/meta.dart';
import 'interfaces/query_operations.dart';
import 'interfaces/update_operations.dart';
import 'services/query_operations_service.dart';
import 'services/update_operations_service.dart';
import 'schema.dart';

/// Abstract base class for type-safe Firestore queries
class FirestoreQuery<S extends FirestoreSchema, T> implements QueryOperations<T>, UpdateOperations<T> {
  final FirestoreCollection<S, T> collection;

  /// The underlying Firestore query
  final Query<Map<String, dynamic>> query;

  /// Service for handling query operations
  late final QueryOperationsService<T> _queryService;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  /// Creates a new FirestoreQuery instance
  FirestoreQuery(this.collection, this.query) {
    _queryService = QueryOperationsService<T>(
      query: query,
      fromJson: (data) => collection.fromJson(data),
      documentIdField: collection.documentIdField,
    );
    _updateService = UpdateOperationsService<T>(
      toJson: (value) => collection.toJson(value),
      fromJson: (data) => collection.fromJson(data),
      documentIdField: collection.documentIdField,
    );
  }

  /// Bulk modify all documents that match this query using diff-based updates
  @override
  Future<void> modify(T Function(T docData) modifier) async {
    await _updateService.executeBulkModify(query, modifier);
  }

  /// Bulk incremental modify all documents that match this query with automatic atomic operations
  @override
  Future<void> incrementalModify(T Function(T docData) modifier) async {
    await _updateService.executeBulkIncrementalModify(query, modifier);
  }

  /// Limits the number of results returned
  ///
  /// // limitation: limit must be a positive integer
  /// // limitation: Cannot be combined with limitToLast() in the same query
  /// // limitation: May affect query performance for very large result sets
  @override
  QueryOperations<T> limit(int limit) {
    return FirestoreQuery<S, T>(collection, _queryService.applyLimit(limit));
  }

  /// Limits the number of results returned from the end
  ///
  /// // limitation: Requires orderBy() to be called first for predictable results
  /// // limitation: Returns results in reverse order of the orderBy clause
  /// // limitation: Cannot be combined with limit() in the same query
  /// // limitation: May have performance implications for large datasets
  @override
  QueryOperations<T> limitToLast(int limit) {
    return FirestoreQuery<S, T>(collection, _queryService.applyLimitToLast(limit));
  }

  /// Executes the query and returns the results
  @override
  Future<List<T>> get() async {
    return await _queryService.executeQuery();
  }

  @override
  QueryOperations<T> where(
    FirestoreFilter<T> Function(RootFilterBuilder<T> builder) filterBuilder,
  ) {
    final builder = RootFilterBuilder<T>();
    final builtFilter = filterBuilder(builder);
    final newQuery = applyFilterToQuery(query, builtFilter);
    return FirestoreQuery<S, T>(collection, newQuery);
  }

  @override
  QueryOperations<T> orderBy(
    OrderByField<T> Function(OrderByBuilder<T> order) orderBuilder,
  ) {
    final builder = OrderByBuilder<T>();
    final orderByField = orderBuilder(builder);
    final newQuery = _queryService.applyOrderBy(orderByField);
    return FirestoreQuery<S, T>(collection, newQuery);
  }

  @override
  Future<void> update(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  ) {
    final builder = UpdateBuilder<T>();
    final operations = updateBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    return _updateService.executeBulkUpdate(query, updateMap);
  }
}

/// Applies a filter to the given Firestore query
Query<Map<String, dynamic>> applyFilterToQuery(
  Query<Map<String, dynamic>> query,
  FirestoreFilter filter,
) {
  if (filter.type == FilterType.field) {
    final field = filter.field!;
    final operator = filter.operator!;
    final value = filter.value;

    switch (operator) {
      case FilterOperator.isEqualTo:
        return query.where(field, isEqualTo: value);
      case FilterOperator.isNotEqualTo:
        return query.where(field, isNotEqualTo: value);
      case FilterOperator.isLessThan:
        return query.where(field, isLessThan: value);
      case FilterOperator.isLessThanOrEqualTo:
        return query.where(field, isLessThanOrEqualTo: value);
      case FilterOperator.isGreaterThan:
        return query.where(field, isGreaterThan: value);
      case FilterOperator.isGreaterThanOrEqualTo:
        return query.where(field, isGreaterThanOrEqualTo: value);
      case FilterOperator.arrayContains:
        return query.where(field, arrayContains: value);
      case FilterOperator.arrayContainsAny:
        return query.where(field, arrayContainsAny: value);
      case FilterOperator.whereIn:
        return query.where(field, whereIn: value);
      case FilterOperator.whereNotIn:
        return query.where(field, whereNotIn: value);
    }
  } else if (filter.type == FilterType.and) {
    Query<Map<String, dynamic>> newQuery = query;
    for (var subFilter in filter.filters!) {
      newQuery = applyFilterToQuery(newQuery, subFilter);
    }
    return newQuery;
  } else if (filter.type == FilterType.or) {
    // Use Firestore's Filter.or() for proper OR logic
    final filters = filter.filters!
        .map((f) => _buildFirestoreFilter(f))
        .toList();
    if (filters.isEmpty)
      throw ArgumentError('OR filter must have at least one condition');
    if (filters.length == 1) return query.where(filters.first);
    return query.where(_buildOrFilter(filters));
  }
  throw ArgumentError('Unsupported filter type: ${filter.type}');
}

/// Build a Firestore Filter from our FirestoreFilter
Filter _buildFirestoreFilter(FirestoreFilter filter) {
  switch (filter.type) {
    case FilterType.field:
      return _buildFieldFilter(filter);
    case FilterType.and:
      final filters = filter.filters!.map(_buildFirestoreFilter).toList();
      if (filters.isEmpty)
        throw ArgumentError('AND filter must have at least one condition');
      if (filters.length == 1) return filters.first;
      return _buildAndFilter(filters);
    case FilterType.or:
      final filters = filter.filters!.map(_buildFirestoreFilter).toList();
      if (filters.isEmpty)
        throw ArgumentError('OR filter must have at least one condition');
      if (filters.length == 1) return filters.first;
      return _buildOrFilter(filters);
  }
}

/// Build a single field Filter
Filter _buildFieldFilter(FirestoreFilter filter) {
  switch (filter.operator!) {
    case FilterOperator.isEqualTo:
      return Filter(filter.field!, isEqualTo: filter.value);
    case FilterOperator.isNotEqualTo:
      return Filter(filter.field!, isNotEqualTo: filter.value);
    case FilterOperator.isLessThan:
      return Filter(filter.field!, isLessThan: filter.value);
    case FilterOperator.isLessThanOrEqualTo:
      return Filter(filter.field!, isLessThanOrEqualTo: filter.value);
    case FilterOperator.isGreaterThan:
      return Filter(filter.field!, isGreaterThan: filter.value);
    case FilterOperator.isGreaterThanOrEqualTo:
      return Filter(filter.field!, isGreaterThanOrEqualTo: filter.value);
    case FilterOperator.arrayContains:
      return Filter(filter.field!, arrayContains: filter.value);
    case FilterOperator.arrayContainsAny:
      return Filter(filter.field!, arrayContainsAny: filter.value);
    case FilterOperator.whereIn:
      return Filter(filter.field!, whereIn: filter.value);
    case FilterOperator.whereNotIn:
      return Filter(filter.field!, whereNotIn: filter.value);
  }
}

/// Build Filter.or() with the correct API signature
Filter _buildOrFilter(List<Filter> filters) {
  if (filters.length < 2)
    throw ArgumentError('OR filter needs at least 2 filters');

  // Use the specific API signature for Filter.or()
  return Filter.or(
    filters[0],
    filters[1],
    filters.length > 2 ? filters[2] : null,
    filters.length > 3 ? filters[3] : null,
    filters.length > 4 ? filters[4] : null,
    filters.length > 5 ? filters[5] : null,
    filters.length > 6 ? filters[6] : null,
    filters.length > 7 ? filters[7] : null,
    filters.length > 8 ? filters[8] : null,
    filters.length > 9 ? filters[9] : null,
    filters.length > 10 ? filters[10] : null,
    filters.length > 11 ? filters[11] : null,
    filters.length > 12 ? filters[12] : null,
    filters.length > 13 ? filters[13] : null,
    filters.length > 14 ? filters[14] : null,
    filters.length > 15 ? filters[15] : null,
    filters.length > 16 ? filters[16] : null,
    filters.length > 17 ? filters[17] : null,
    filters.length > 18 ? filters[18] : null,
    filters.length > 19 ? filters[19] : null,
    filters.length > 20 ? filters[20] : null,
    filters.length > 21 ? filters[21] : null,
    filters.length > 22 ? filters[22] : null,
    filters.length > 23 ? filters[23] : null,
    filters.length > 24 ? filters[24] : null,
    filters.length > 25 ? filters[25] : null,
    filters.length > 26 ? filters[26] : null,
    filters.length > 27 ? filters[27] : null,
    filters.length > 28 ? filters[28] : null,
    filters.length > 29 ? filters[29] : null,
  );
}

/// Build Filter.and() with the correct API signature
Filter _buildAndFilter(List<Filter> filters) {
  if (filters.length < 2)
    throw ArgumentError('AND filter needs at least 2 filters');

  // Use the specific API signature for Filter.and()
  return Filter.and(
    filters[0],
    filters[1],
    filters.length > 2 ? filters[2] : null,
    filters.length > 3 ? filters[3] : null,
    filters.length > 4 ? filters[4] : null,
    filters.length > 5 ? filters[5] : null,
    filters.length > 6 ? filters[6] : null,
    filters.length > 7 ? filters[7] : null,
    filters.length > 8 ? filters[8] : null,
    filters.length > 9 ? filters[9] : null,
    filters.length > 10 ? filters[10] : null,
    filters.length > 11 ? filters[11] : null,
    filters.length > 12 ? filters[12] : null,
    filters.length > 13 ? filters[13] : null,
    filters.length > 14 ? filters[14] : null,
    filters.length > 15 ? filters[15] : null,
    filters.length > 16 ? filters[16] : null,
    filters.length > 17 ? filters[17] : null,
    filters.length > 18 ? filters[18] : null,
    filters.length > 19 ? filters[19] : null,
    filters.length > 20 ? filters[20] : null,
    filters.length > 21 ? filters[21] : null,
    filters.length > 22 ? filters[22] : null,
    filters.length > 23 ? filters[23] : null,
    filters.length > 24 ? filters[24] : null,
    filters.length > 25 ? filters[25] : null,
    filters.length > 26 ? filters[26] : null,
    filters.length > 27 ? filters[27] : null,
    filters.length > 28 ? filters[28] : null,
    filters.length > 29 ? filters[29] : null,
  );
}
