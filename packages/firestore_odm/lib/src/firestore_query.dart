import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_collection.dart';
import 'interfaces/query_operations.dart';
import 'interfaces/update_operations.dart';
import 'interfaces/pagination_operations.dart';
import 'services/query_operations_service.dart';
import 'services/update_operations_service.dart';
import 'services/subscription_service.dart';
import 'schema.dart';
import 'count_query.dart' show FirestoreCountQuery;
import 'tuple_aggregate.dart';
import 'pagination.dart' as pg;
import 'order_by_selector.dart' as obs;

/// Abstract base class for type-safe Firestore queries
class FirestoreQuery<S extends FirestoreSchema, T, O extends Object?>
    implements QueryOperations<T>, UpdateOperations<T>, PaginationOperations<T, O> {
  final FirestoreCollection<S, T> collection;

  /// The underlying Firestore query
  final Query<Map<String, dynamic>> query;

  /// OrderBy configuration for pagination
  final pg.OrderByConfiguration _orderByConfig;
  
  /// Store the original orderBy builder function for smart value extraction
  final O Function(obs.OrderByFieldSelector<T>)? _orderByBuilder;

  /// Service for handling query operations
  late final QueryOperationsService<T> _queryService;

  /// Service for handling update operations
  late final UpdateOperationsService<T> _updateService;

  /// Service for handling real-time subscriptions
  late final QuerySubscriptionService<T> _subscriptionService;

  /// Creates a new FirestoreQuery instance
  FirestoreQuery(this.collection, this.query, [pg.OrderByConfiguration? orderByConfig, this._orderByBuilder])
    : _orderByConfig = orderByConfig ?? const pg.OrderByConfiguration([]) {
    _queryService = QueryOperationsService<T>(
      query: query,
      converter: collection.converter,
      documentIdField: collection.documentIdField,
    );
    _updateService = UpdateOperationsService<T>(
      converter: collection.converter,
      documentIdField: collection.documentIdField,
    );
    _subscriptionService = QuerySubscriptionService<T>(
      query: query,
      converter: collection.converter,
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
  FirestoreQuery<S, T, O> limit(int limit) {
    return FirestoreQuery<S, T, O>(collection, _queryService.applyLimit(limit), _orderByConfig);
  }

  /// Limits the number of results returned from the end
  ///
  /// // limitation: Requires orderBy() to be called first for predictable results
  /// // limitation: Returns results in reverse order of the orderBy clause
  /// // limitation: Cannot be combined with limit() in the same query
  /// // limitation: May have performance implications for large datasets
  @override
  FirestoreQuery<S, T, O> limitToLast(int limit) {
    return FirestoreQuery<S, T, O>(
      collection,
      _queryService.applyLimitToLast(limit),
      _orderByConfig,
    );
  }

  /// Executes the query and returns the results
  @override
  Future<List<T>> get() async {
    return await _queryService.executeQuery();
  }

  @override
  FirestoreQuery<S, T, O> where(
    FirestoreFilter<T> Function(RootFilterBuilder<T> builder) filterBuilder,
  ) {
    final builder = RootFilterBuilder<T>();
    final builtFilter = filterBuilder(builder);
    final newQuery = applyFilterToQuery(query, builtFilter);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  @override
  FirestoreQuery<S, T, R> orderBy<R extends Record>(
    R Function(obs.OrderByFieldSelector<T> selector) orderBuilder,
  ) {
    final selector = obs.OrderByFieldSelector<T>();
    final tupleSpec = orderBuilder(selector);
    
    // Build the actual Firestore query from the collected fields
    Query<Map<String, dynamic>> newQuery = query;
    for (final field in selector.fields) {
      newQuery = newQuery.orderBy(field.fieldPath, descending: field.descending);
    }
    
    // Create configuration from the collected fields - convert to pagination format
    final pgFields = selector.fields.map((f) =>
      pg.OrderByFieldInfo(f.fieldPath, f.descending, f.fieldType)
    ).toList();
    final config = pg.OrderByConfiguration(pgFields);
    
    // Store the builder function for smart value extraction
    return FirestoreQuery<S, T, R>(collection, newQuery, config, orderBuilder);
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

  /// Get the count of documents matching this query
  @override
  FirestoreCountQuery count() {
    return FirestoreCountQuery(query);
  }

  /// Perform strongly-typed aggregate operations using records/tuples
  @override
  TupleAggregateQuery<T, R> aggregate<R extends Record>(
    R Function(AggregateFieldSelector<T> selector) builder,
  ) {
    return TupleAggregateQuery<T, R>(query, collection.converter, builder);
  }

  /// Stream of query result changes for real-time updates
  Stream<List<T>> get stream => _subscriptionService.stream;

  /// Whether this query is currently subscribed to real-time updates
  bool get isSubscribing => _subscriptionService.isSubscribing;

  /// Get the current orderBy configuration
  pg.OrderByConfiguration get orderByConfig => _orderByConfig;

  /// Start pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  @override
  FirestoreQuery<S, T, O> startAt(O cursorValues) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use startAt without orderBy. Call orderBy() first.');
    }
    final valuesList = _extractValuesFromTuple(cursorValues);
    final newQuery = query.startAt(valuesList);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  /// Start pagination after the given cursor values
  /// The cursor values must match the orderBy tuple type O
  @override
  FirestoreQuery<S, T, O> startAfter(O cursorValues) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use startAfter without orderBy. Call orderBy() first.');
    }
    final valuesList = _extractValuesFromTuple(cursorValues);
    final newQuery = query.startAfter(valuesList);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  /// End pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  @override
  FirestoreQuery<S, T, O> endAt(O cursorValues) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use endAt without orderBy. Call orderBy() first.');
    }
    final valuesList = _extractValuesFromTuple(cursorValues);
    final newQuery = query.endAt(valuesList);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  /// End pagination before the given cursor values
  /// The cursor values must match the orderBy tuple type O
  @override
  FirestoreQuery<S, T, O> endBefore(O cursorValues) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use endBefore without orderBy. Call orderBy() first.');
    }
    final valuesList = _extractValuesFromTuple(cursorValues);
    final newQuery = query.endBefore(valuesList);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  /// Start pagination at the given object
  /// Automatically extracts cursor values using the SAME builder function as orderBy
  @override
  FirestoreQuery<S, T, O> startAtObject(T object) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use startAtObject without orderBy. Call orderBy() first.');
    }
    final values = _extractValuesWithBuilder(object);
    return _startAtFromList(values);
  }

  /// Start pagination after the given object
  /// Automatically extracts cursor values using the SAME builder function as orderBy
  @override
  FirestoreQuery<S, T, O> startAfterObject(T object) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use startAfterObject without orderBy. Call orderBy() first.');
    }
    final values = _extractValuesWithBuilder(object);
    return _startAfterFromList(values);
  }

  /// End pagination at the given object
  /// Automatically extracts cursor values using the SAME builder function as orderBy
  @override
  FirestoreQuery<S, T, O> endAtObject(T object) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use endAtObject without orderBy. Call orderBy() first.');
    }
    final values = _extractValuesWithBuilder(object);
    return _endAtFromList(values);
  }

  /// End pagination before the given object
  /// Automatically extracts cursor values using the SAME builder function as orderBy
  @override
  FirestoreQuery<S, T, O> endBeforeObject(T object) {
    if (_orderByConfig.isEmpty) {
      throw ArgumentError('Cannot use endBeforeObject without orderBy. Call orderBy() first.');
    }
    final values = _extractValuesWithBuilder(object);
    return _endBeforeFromList(values);
  }

  /// Smart value extraction using the SAME builder function as orderBy
  /// This ensures perfect consistency and type safety
  List<dynamic> _extractValuesWithBuilder(T object) {
    if (_orderByBuilder == null) {
      // Fallback to old extraction method if builder not available
      final cursor = pg.PaginationCursor.fromObject(object, _orderByConfig.fields, collection.converter.toMap);
      return cursor.values;
    }
    
    // Convert object to Map for extraction
    final objectMap = collection.converter.toMap(object);
    
    // Create extraction-mode selector with the same object
    final extractionSelector = obs.OrderByFieldSelector<T>(
      isExtractionMode: true,
      sourceObject: objectMap,
    );
    
    // Reuse the SAME builder function to extract values!
    // This guarantees perfect consistency with orderBy
    _orderByBuilder!(extractionSelector);
    
    return extractionSelector.extractedValues;
  }

  /// Helper method to extract values from tuple/record type O
  List<dynamic> _extractValuesFromTuple(O cursorValues) {
    // Handle different tuple types
    if (cursorValues is Record) {
      // For Record types, we need to extract the values
      // Extract tuple values using modern switch expression pattern
      final values = switch (cursorValues) {
        (var a,) => [a],
        (var a, var b) => [a, b],
        (var a, var b, var c) => [a, b, c],
        (var a, var b, var c, var d) => [a, b, c, d],
        (var a, var b, var c, var d, var e) => [a, b, c, d, e],
        (var a, var b, var c, var d, var e, var f) => [a, b, c, d, e, f],
        (var a, var b, var c, var d, var e, var f, var g) => [a, b, c, d, e, f, g],
        (var a, var b, var c, var d, var e, var f, var g, var h) => [a, b, c, d, e, f, g, h],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i) => [a, b, c, d, e, f, g, h, i],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j) => [a, b, c, d, e, f, g, h, i, j],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k) => [a, b, c, d, e, f, g, h, i, j, k],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l) => [a, b, c, d, e, f, g, h, i, j, k, l],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m) => [a, b, c, d, e, f, g, h, i, j, k, l, m],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var aa) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, aa],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var aa, var bb) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, aa, bb],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var aa, var bb, var cc) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, aa, bb, cc],
        (var a, var b, var c, var d, var e, var f, var g, var h, var i, var j, var k, var l, var m, var n, var o, var p, var q, var r, var s, var t, var u, var v, var w, var x, var y, var z, var aa, var bb, var cc, var dd) => [a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, aa, bb, cc, dd],
        _ => <dynamic>[],
      };
      
      return values;
    } else if (cursorValues is List) {
      // If it's already a list, return it
      return cursorValues;
    } else {
      // Single value
      return [cursorValues];
    }
  }

  /// Helper methods for object-based pagination that work with List<dynamic>
  FirestoreQuery<S, T, O> _startAtFromList(List<dynamic> cursorValues) {
    final newQuery = query.startAt(cursorValues);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  FirestoreQuery<S, T, O> _startAfterFromList(List<dynamic> cursorValues) {
    final newQuery = query.startAfter(cursorValues);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  FirestoreQuery<S, T, O> _endAtFromList(List<dynamic> cursorValues) {
    final newQuery = query.endAt(cursorValues);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
  }

  FirestoreQuery<S, T, O> _endBeforeFromList(List<dynamic> cursorValues) {
    final newQuery = query.endBefore(cursorValues);
    return FirestoreQuery<S, T, O>(collection, newQuery, _orderByConfig);
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
