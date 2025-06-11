import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/schema.dart';

abstract interface class Filterable<S extends FirestoreSchema, T> {
  /// Filter the query using a strongly-typed filter builder
  /// Returns a Filterable that can be further modified
  Filterable<S, T> where(
    FirestoreFilter<T> Function(RootFilterBuilder<T> builder) filterBuilder,
  );
}

