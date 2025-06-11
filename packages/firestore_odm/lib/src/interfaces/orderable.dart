import 'package:firestore_odm/src/query.dart';
import 'package:firestore_odm/src/schema.dart';

abstract interface class Orderable<S extends FirestoreSchema, T> {
  /// Order results by specified fields, enabling pagination
  /// Returns an OrderedQuery that supports strongly-typed pagination
  dynamic orderBy<O extends Record>(
    O Function(OrderByFieldSelector<T> selector) orderBuilder,
  );
}
