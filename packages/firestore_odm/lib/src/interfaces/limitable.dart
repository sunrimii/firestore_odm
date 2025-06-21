/// An interface for limiting the number of documents returned by a query.
abstract interface class Limitable {
  /// Limits the number of documents to be returned by the query.
  ///
  /// The [limit] must be a positive integer. This method specifies the maximum
  /// number of documents that will be retrieved from the beginning of the result set.
  ///
  /// Limitations:
  /// - [limit] must be a positive integer.
  /// - Cannot be combined with [limitToLast] within the same query.
  /// - May affect query performance for very large result sets, especially
  ///   when combined with complex ordering.
  ///
  /// [limit]: The maximum number of documents to return.
  /// Returns a dynamic type representing the query with the applied limit.
  dynamic limit(int limit);

  /// Limits the number of documents to be returned by the query, counting from the end.
  ///
  /// This method works in conjunction with `orderBy()` and specifies the maximum
  /// number of documents that will be retrieved from the end of the query's result set.
  ///
  /// Limitations:
  /// - Requires `orderBy()` to be called first for predictable results.
  /// - Returns results in reverse order of the `orderBy` clause.
  /// - Cannot be combined with [limit] within the same query.
  /// - May have performance implications for large datasets, as it often requires
  ///   reading all documents and then selecting the last ones.
  ///
  /// [limit]: The maximum number of documents to return from the end.
  /// Returns a dynamic type representing the query with the applied `limitToLast`.
  dynamic limitToLast(int limit);
}
