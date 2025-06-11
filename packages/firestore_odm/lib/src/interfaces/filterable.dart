import 'package:firestore_odm/src/filter_builder.dart';

typedef FilterBuilder<T> = FirestoreFilter<T> Function(
  RootFilterSelector<T> selector,
);
abstract interface class Filterable<T> {
  /// Filter the query using a strongly-typed filter builder
  /// Returns a Filterable that can be further modified
  Filterable<T> where(
    FilterBuilder<T> filterBuilder,
  );
}

