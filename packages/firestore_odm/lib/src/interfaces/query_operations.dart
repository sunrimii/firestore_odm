import 'package:firestore_odm/src/firestore_query.dart';

import '../filter_builder.dart';

/// Interface defining query operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class QueryOperations<T> {
  QueryOperations<T> where(
    FirestoreFilter<T> Function(RootFilterBuilder<T> builder) filterBuilder,
  );

  QueryOperations<T> orderBy(
    OrderByField<T> Function(OrderByBuilder<T> order) orderBuilder,
  );

  /// Execute the query and return the results
  Future<List<T>> get();

  /// Limit the number of results returned
  ///
  /// // limitation: limit must be a positive integer
  /// // limitation: Cannot be combined with limitToLast() in the same query
  /// // limitation: May affect query performance for very large result sets
  QueryOperations<T> limit(int limit);

  /// Limit the number of results returned from the end
  ///
  /// // limitation: Requires orderBy() to be called first for predictable results
  /// // limitation: Returns results in reverse order of the orderBy clause
  /// // limitation: Cannot be combined with limit() in the same query
  /// // limitation: May have performance implications for large datasets
  QueryOperations<T> limitToLast(int limit);
}
