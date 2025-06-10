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
  QueryOperations<T> limit(int limit);

  /// Limit the number of results returned from the end
  QueryOperations<T> limitToLast(int limit);
}
