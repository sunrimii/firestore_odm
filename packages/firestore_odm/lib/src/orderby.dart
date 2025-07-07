import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/aggregate.dart';
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/interfaces/aggregatable.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/filterable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/limitable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/types.dart';
import 'package:firestore_odm/src/interfaces/paginatable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/pagination.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';
import 'package:firestore_odm/src/utils.dart';

typedef OrderByBuilderFunc<OB extends OrderByFieldNode> =
    OB Function({
      required OrderByContext context,
      String name,
      OrderByFieldNode? parent,
    });

class OrderByFieldNode extends Node {
  final OrderByContext $context;

  /// Creates a new OrderByFieldNode with the given context
  const OrderByFieldNode({
    super.name,
    super.parent,
    required OrderByContext context,
  }) : $context = context;
}

class OrderByField<T> extends OrderByFieldNode {
  OrderByField({super.name, super.parent, this.type, required super.context});
  final FieldPathType? type;

  T call({bool descending = false}) {
    $context.resolver($parts, descending);
    return defaultValue<T>();
  }
}

/// Base class for orderBy field selectors
abstract class OrderByContext {
  void resolver(List<String> parts, bool descending);
}

class OrderByBuilderContext extends OrderByContext {
  OrderByBuilderContext();

  final List<OrderByFieldInfo> fields = [];

  @override
  void resolver(List<String> parts, bool descending) {
    /// Add the field to the list of orderBy fields
    fields.add(OrderByFieldInfo(parts.join('.'), descending));
  }
}

class OrderByExtractorContext extends OrderByContext {
  OrderByExtractorContext({required this.data});
  final Map<String, dynamic> data;
  final List<dynamic> extractedValues = [];

  @override
  void resolver(List<String> parts, bool descending) {
    final value = resolveJsonWithParts(data, parts);
    extractedValues.add(value);
  }
}

/// Information about an orderBy field for pagination
class OrderByFieldInfo {
  final dynamic fieldPath; // Can be String or FieldPath
  final bool descending;

  const OrderByFieldInfo(this.fieldPath, this.descending);

  @override
  String toString() => 'OrderByFieldInfo($fieldPath, desc: $descending)';
}

/// Container for orderBy configuration used in pagination
class OrderByConfiguration<O extends Record, OB extends OrderByFieldNode> {
  final List<OrderByFieldInfo> fields;
  final O Function(OB selector) builder;

  const OrderByConfiguration(this.fields, this.builder);

  @override
  String toString() => 'OrderByConfiguration(${fields.join(', ')})';
}

abstract class QueryOrderbyHandler {
  static OrderByConfiguration<O, OB>
  buildOrderBy<T, O extends Record, OB extends OrderByFieldNode>({
    required O Function(OB selector) orderByFunc,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required String documentIdFieldName,
  }) {
    final context = OrderByBuilderContext();
    final builder = orderByBuilderFunc(context);

    // Call the order builder to populate the selector
    orderByFunc(builder);

    return OrderByConfiguration<O, OB>(context.fields, orderByFunc);
  }

  static firestore.Query<Map<String, dynamic>> applyOrderBy<
    T,
    O extends Record
  >(firestore.Query<Map<String, dynamic>> query, OrderByConfiguration config) {
    // Build the actual Firestore query from the collected fields
    firestore.Query<Map<String, dynamic>> newQuery = query;
    for (final field in config.fields) {
      newQuery = newQuery.orderBy(
        field.fieldPath,
        descending: field.descending,
      );
    }

    return newQuery;
  }
}

class OrderedQuery<
  S extends FirestoreSchema,
  T,
  O extends Record,
  OB extends OrderByFieldNode
>
    implements
        Gettable<List<T>>,
        Streamable<List<T>>,
        Paginatable<T, O>,
        Limitable,
        Filterable<T>,
        Patchable<T>,
        Modifiable<T>,
        Aggregatable<S, T>,
        Deletable {
  final FirestoreConverter<T, Map<String, dynamic>> _converter;

  final String _documentIdField;

  /// The underlying Firestore query
  final firestore.Query<Map<String, dynamic>> _query;

  final OrderByConfiguration<O, OB> _orderByConfig;

  final OB Function(OrderByContext context) _orderByBuilderFunc;

  const OrderedQuery({
    required firestore.Query<Map<String, dynamic>> query,
    required FirestoreConverter<T, Map<String, dynamic>> converter,
    required String documentIdField,
    required OrderByConfiguration<O, OB> orderByConfig,
    required OB Function(OrderByContext context) orderByBuilderFunc,
  }) : _orderByBuilderFunc = orderByBuilderFunc,
       _query = query,
       _converter = converter,
       _documentIdField = documentIdField,
       _orderByConfig = orderByConfig;

  @override
  Future<List<T>> get() =>
      QueryHandler.get(_query, _converter.fromJson, _documentIdField);

  @override
  Stream<List<T>?> get stream =>
      QueryHandler.stream(_query, _converter.fromJson, _documentIdField);

  @override
  OrderedQuery<S, T, O, OB> limit(int limit) {
    final newQuery = QueryLimitHandler.applyLimit(_query, limit);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> limitToLast(int limit) {
    final newQuery = QueryLimitHandler.applyLimitToLast(_query, limit);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> endAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndAt(_query, cursors);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> endAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _converter.toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyEndAt(_query, values);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> endBefore(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, cursors);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> endBeforeObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _converter.toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, values);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> startAfter(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, cursors);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> startAfterObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _converter.toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, values);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> startAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAt(_query, cursors);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> startAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _converter.toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyStartAt(_query, values);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, OB> where(
    FirestoreFilter Function(RootFilterSelector<T> builder) filterBuilder,
  ) {
    final filter = QueryFilterHandler.buildFilter(filterBuilder);
    final newQuery = QueryFilterHandler.applyFilter(_query, filter);
    return OrderedQuery<S, T, O, OB>(
      query: newQuery,
      converter: _converter,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
  }

  @override
  Future<void> patch(
    List<UpdateOperation> Function(PatchBuilder<T> patchBuilder) patches,
  ) {
    final builder = PatchBuilder<T>(converter: _converter);
    final operations = patches(builder);
    return QueryHandler.patch(_query, operations);
  }

  /// Modify multiple documents in this ordered query using diff-based updates.
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
  /// // Update top users with atomic operations (default)
  /// await db.users
  ///   .orderBy(($) => $.score(descending: true))
  ///   .limit(10)
  ///   .modify((user) => user.copyWith(
  ///     bonus: user.bonus + 100, // Auto-detects -> FieldValue.increment(100)
  ///   ));
  /// ```
  @override
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true}) =>
      QueryHandler.modify(
        _query,
        _documentIdField,
        _converter.toJson,
        _converter.fromJson,
        modifier,
        atomic: atomic,
      );

  @override
  AggregateQuery<S, T, R> aggregate<R extends Record>(
    R Function(RootAggregateFieldSelector<T> selector) builder,
  ) {
    final config = QueryAggregatableHandler.buildAggregate(builder);
    final newQuery = QueryAggregatableHandler.applyAggregate(
      _query,
      config.operations,
    );
    return AggregateQuery(
      newQuery,
      _converter.toJson,
      _converter.fromJson,
      _documentIdField,
      config,
    );
  }

  @override
  AggregateCountQuery count() {
    final newQuery = QueryAggregatableHandler.applyCount(_query);
    return AggregateCountQuery(newQuery);
  }

  @override
  Future<void> delete() => QueryHandler.delete(_query);
}
