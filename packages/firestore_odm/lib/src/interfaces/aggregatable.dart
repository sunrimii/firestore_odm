import 'package:firestore_odm/src/aggregate.dart';

/// An interface for performing aggregate operations on a Firestore collection.
///
/// [S] is the FirestoreSchema associated with the collection.
/// [T] is the type of the model in the collection.
abstract interface class Aggregatable<T> {
  /// Performs strongly-typed aggregate operations on the collection.
  ///
  /// This method allows you to define complex aggregation queries using a builder
  /// function that provides access to fields of type [T] for aggregation. The
  /// results are returned as a record/tuple [R], providing type-safe access
  /// to the aggregated values.
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
  ///
  /// [builder]: A function that constructs the aggregate query using a [AggregateFieldRoot].
  /// Returns an [AggregateQuery] that, when executed (e.g., with `.get()`), will
  /// yield the aggregated results.
  AggregateQuery<T, R, AggregateFieldRoot> aggregate<R extends Record>(
    R Function(AggregateFieldRoot builder) handler,
  );

  /// Gets the count of documents matching the current query.
  ///
  /// This method returns an [AggregateCountQuery] which can be executed
  /// using `.get()` to retrieve the count or watched with `.snapshots()`
  /// for real-time updates to the count.
  ///
  /// Returns an [AggregateCountQuery] representing the count operation.
  AggregateCountQuery count();
}
