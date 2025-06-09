import '../filter_builder.dart';

/// Interface defining query operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class QueryOperations<T> {
  /// Execute the query and return the results
  Future<List<T>> get();
  
  /// Limit the number of results returned
  QueryOperations<T> limit(int limit);
  
  /// Limit the number of results returned from the end
  QueryOperations<T> limitToLast(int limit);
}