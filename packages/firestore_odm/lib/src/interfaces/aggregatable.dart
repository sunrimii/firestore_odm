import 'package:firestore_odm/src/count_query.dart' show FirestoreCountQuery;
import 'package:firestore_odm/src/schema.dart';

// abstract interface class Aggregatable<S extends FirestoreSchema, T> {
//   /// Perform strongly-typed aggregate operations using records/tuples
//   ///
//   /// Example:
//   /// ```dart
//   /// final result = await users.aggregate(($) => (
//   ///   averageAge: $.age.average(),
//   ///   count: $.count(),
//   ///   totalFollowers: $.profile.followers.sum(),
//   /// )).get();
//   ///
//   /// print('Average age: ${result.averageAge}'); // double
//   /// print('Count: ${result.count}'); // int
//   /// print('Total followers: ${result.totalFollowers}'); // num
//   /// ```
//   TupleAggregateQuery<T, R> aggregate<R extends Record>(
//     R Function(AggregateFieldSelector<T> selector) builder,
//   );

//   /// Get the count of documents matching this query
//   /// Returns a query that can be executed with .get() or watched with .snapshots() 
//   FirestoreCountQuery count();
// }
