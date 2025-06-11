import 'package:firestore_odm/src/orderby.dart';

typedef OrderByBuilder<T, O extends Record> =
    O Function(OrderByFieldSelector<T> selector);

abstract interface class Orderable<T> {
  /// Order results by specified fields, enabling pagination
  /// Returns an OrderedQuery that supports strongly-typed pagination
  dynamic orderBy<O extends Record>(OrderByBuilder<T, O> orderBuilder);
}
