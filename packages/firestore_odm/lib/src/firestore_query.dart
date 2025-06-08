import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:meta/meta.dart';

/// Abstract base class for type-safe Firestore queries
abstract class FirestoreQuery<T> {
  /// The underlying Firestore query
  @protected
  final Query<Map<String, dynamic>> query;

  /// Get the underlying query for extensions
  Query<Map<String, dynamic>> get underlyingQuery => query;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data) fromJson;

  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;

  /// Creates a new FirestoreQuery instance
  FirestoreQuery(this.query, this.fromJson, this.toJson);

  /// Limits the number of results returned
  FirestoreQuery<T> limit(int limit) {
    return newInstance(query.limit(limit));
  }

  /// Limits the number of results returned from the end
  FirestoreQuery<T> limitToLast(int limit) {
    return newInstance(query.limitToLast(limit));
  }

  /// Executes the query and returns the results
  Future<List<T>> get() async {
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add document ID to the data
      return fromJson(data);
    }).toList();
  }

  /// Creates a new instance of the query with the given Firestore query
  @protected
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query);
}

/// Applies a filter to the given Firestore query
Query<Map<String, dynamic>> applyFilterToQuery(Query<Map<String, dynamic>> query, FirestoreFilter filter) {
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
    final filters = filter.filters!.map((f) => _buildFirestoreFilter(f)).toList();
    if (filters.isEmpty) throw ArgumentError('OR filter must have at least one condition');
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
      if (filters.isEmpty) throw ArgumentError('AND filter must have at least one condition');
      if (filters.length == 1) return filters.first;
      return _buildAndFilter(filters);
    case FilterType.or:
      final filters = filter.filters!.map(_buildFirestoreFilter).toList();
      if (filters.isEmpty) throw ArgumentError('OR filter must have at least one condition');
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
  if (filters.length < 2) throw ArgumentError('OR filter needs at least 2 filters');
  
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
  if (filters.length < 2) throw ArgumentError('AND filter needs at least 2 filters');
  
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