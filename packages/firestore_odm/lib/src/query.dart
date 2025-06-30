import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/aggregate.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/interfaces/aggregatable.dart';
import 'package:firestore_odm/src/interfaces/filterable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/limitable.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/orderable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/orderby.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';

class Query<S extends FirestoreSchema, T>
    implements
        Gettable<List<T>>,
        Streamable<List<T>>,
        Filterable<T>,
        Orderable<T>,
        Patchable<T>,
        Modifiable<T>,
        Aggregatable<S, T>,
        Limitable,
        Deletable {
          
  final FirestoreConverter<T, Map<String, dynamic>> _converter;
  final String _documentIdField;

  /// The underlying Firestore query
  final firestore.Query<Map<String, dynamic>> _query;

  const Query(this._query, this._converter, this._documentIdField);

  @override
  Future<List<T>> get() =>
      QueryHandler.get(_query, _converter.fromJson, _documentIdField);

  @override
  Stream<List<T>> get stream =>
      QueryHandler.stream(_query, _converter.fromJson, _documentIdField);

  @override
  Query<S, T> where(
    FirestoreFilter Function(RootFilterSelector<T> builder) filterBuilder,
  ) {
    final filter = QueryFilterHandler.buildFilter(filterBuilder);
    final newQuery = QueryFilterHandler.applyFilter(_query, filter);
    // Handle different types of query objects
    return Query<S, T>(newQuery, _converter, _documentIdField);
  }

  @override
  OrderedQuery<S, T, O> orderBy<O extends Record>(
    OrderByBuilder<T, O> orderBuilder,
  ) {
    final config = QueryOrderbyHandler.buildOrderBy(
      orderBuilder,
      _documentIdField,
    );
    final newQuery = QueryOrderbyHandler.applyOrderBy(_query, config);
    return OrderedQuery(newQuery, _converter, _documentIdField, config);
  }

  @override
  Query<S, T> limit(int limit) {
    final newQuery = QueryLimitHandler.applyLimit(_query, limit);
    return Query<S, T>(newQuery, _converter, _documentIdField);
  }

  @override
  Query<S, T> limitToLast(int limit) {
    final newQuery = QueryLimitHandler.applyLimitToLast(_query, limit);

    return Query<S, T>(newQuery, _converter, _documentIdField);
  }

  @override
  Future<void> patch(
    List<UpdateOperation> Function(PatchBuilder<T> patchBuilder) patches,
  ) {
    final builder = PatchBuilder<T>(converter: _converter);
    final operations = patches(builder);
    return QueryHandler.patch(_query, operations);
  }

  /// Modify multiple documents using diff-based updates.
  ///
  /// This method performs a read operation followed by batch update operations.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// **Important Notes:**
  /// - **Performance**: This method has an additional read operation, making it slower than [patch]
  /// - **Concurrency**: Firestore uses last-write-wins semantics. This read-modify-write
  ///   operation is NOT transactional and may be subject to race conditions
  /// - **Transactions**: For transactional updates, use transactions instead
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// **Example:**
  /// ```dart
  /// // Update all premium users with atomic operations (default)
  /// await db.users
  ///   .where(($) => $.isPremium(isEqualTo: true))
  ///   .modify((user) => user.copyWith(points: user.points + 100));
  ///
  /// // Update without atomic operations
  /// await db.users
  ///   .where(($) => $.status(isEqualTo: 'inactive'))
  ///   .modify((user) => user.copyWith(status: 'archived'), atomic: false);
  /// ```
  @override
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true}) =>
      QueryHandler.modify(_query, _documentIdField, _converter.toJson, _converter.fromJson, modifier, atomic: atomic);


  @override
  AggregateQuery<S, T, R> aggregate<R extends Record>(
    R Function(RootAggregateFieldSelector<T> selector) builder,
  ) {
    final config = QueryAggregatableHandler.buildAggregate(builder);
    final newQuery = QueryAggregatableHandler.applyAggregate(
      _query,
      config.operations,
    );
    return AggregateQuery(newQuery, _converter.toJson, _converter.fromJson, _documentIdField, config);
  }

  @override
  AggregateCountQuery count() {
    final newQuery = QueryAggregatableHandler.applyCount(_query);
    return AggregateCountQuery(newQuery);
  }

  @override
  Future<void> delete() => QueryHandler.delete(_query);
}
