abstract interface class Limitable {
  /// Limit the number of results returned
  ///
  /// // limitation: limit must be a positive integer
  /// // limitation: Cannot be combined with limitToLast() in the same query
  /// // limitation: May affect query performance for very large result sets
  dynamic limit(int limit);

  /// Limit the number of results returned from the end
  ///
  /// // limitation: Requires orderBy() to be called first for predictable results
  /// // limitation: Returns results in reverse order of the orderBy clause
  /// // limitation: Cannot be combined with limit() in the same query
  /// // limitation: May have performance implications for large datasets
  dynamic limitToLast(int limit);
}
