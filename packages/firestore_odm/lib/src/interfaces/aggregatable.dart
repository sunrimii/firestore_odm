import 'package:firestore_odm/src/aggregate.dart';
import 'package:firestore_odm/src/schema.dart';

typedef AggregateBuilder<T, R> = R Function(AggregateFieldSelector<T> selector);

abstract interface class Aggregatable<S extends FirestoreSchema, T> {
  /// Perform strongly-typed aggregate operations using records/tuples
  ///
  /// Example:
  /// ```dart
  /// final result = await users.aggregate(($) => (
  ///   averageAge: $.age.average(),
  ///   count: $.count(),
  ///   totalFollowers: $.profile.followers.sum(),
  /// )).get();
  ///
  /// print('Average age: ${result.averageAge}'); // double
  /// print('Count: ${result.count}'); // int
  /// print('Total followers: ${result.totalFollowers}'); // num
  /// ```
  AggregateQuery<S, T, R> aggregate<R extends Record>(
    AggregateBuilder<T, R> builder,
  );

  /// Get the count of documents matching this query
  /// Returns a query that can be executed with .get() or watched with .snapshots()
  AggregateCountQuery count();
}
