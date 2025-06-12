import 'package:firestore_odm/src/filter_builder.dart';

typedef FilterBuilder<T> =
    FirestoreFilter Function(RootFilterSelector<T> selector);

abstract interface class Filterable<T> {
  /// Filter the query using a strongly-typed filter builder
  /// Returns a query that can be further modified
  dynamic where(FilterBuilder<T> filterBuilder);
}
