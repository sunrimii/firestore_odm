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
import 'package:firestore_odm/src/types.dart';
import 'package:firestore_odm/src/interfaces/paginatable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/pagination.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';
import 'package:firestore_odm/src/utils.dart';

class OrderByField<T> extends Node {
  OrderByField({super.name, super.parent, this.type});
  final FieldPathType? type;

  T call({bool descending = false}) {
    switch ($root) {
      case RootOrderByFieldSelector selector:
        // Call the addField method on the root selector
        selector._fields.add(
          OrderByFieldInfo(type?.toFirestore() ?? $path, descending),
        );
      case RootOrderByFieldExtractor extractor:
        // Extract the value from the source object using the field path
        final value = resolveJsonWithParts(extractor.data, $parts);
        // Add the extracted value to the list
        extractor.extractedValues.add(value);
      default:
        throw StateError('Invalid root type for OrderByField: ${$root}');
    }
    return defaultValue<T>();
  }
}

class OrderByFieldSelector<T> extends Node {
  /// Create a field selector with optional prefix for nested fields
  /// If parentFields is provided, nested selectors will share the same field collection
  OrderByFieldSelector({super.name, super.parent});
}

class RootOrderByFieldSelector<T> extends OrderByFieldSelector<T> {
  RootOrderByFieldSelector();

  final List<OrderByFieldInfo> _fields = [];
}

class RootOrderByFieldExtractor<T> extends OrderByFieldSelector<T> {
  RootOrderByFieldExtractor(this.data);
  final Map<String, dynamic> data;
  final List<dynamic> extractedValues = [];
}

/// Information about an orderBy field for pagination
class OrderByFieldInfo {
  final dynamic fieldPath; // Can be String or FieldPath
  final bool descending;

  const OrderByFieldInfo(this.fieldPath, this.descending);

  @override
  String toString() => 'OrderByFieldInfo($fieldPath, desc: $descending)';
}

typedef OrderByBuilderFunction<T, O extends Record> =
    O Function(OrderByFieldSelector<T> selector);

/// Container for orderBy configuration used in pagination
class OrderByConfiguration<T, O extends Record> {
  final List<OrderByFieldInfo> fields;
  final OrderByBuilderFunction<T, O> builder;

  const OrderByConfiguration(this.fields, this.builder);

  @override
  String toString() => 'OrderByConfiguration(${fields.join(', ')})';
}

abstract class QueryOrderbyHandler {
  static OrderByConfiguration<T, O> buildOrderBy<T, O extends Record>(
    O Function(OrderByFieldSelector<T> selector) orderBuilder,
    String documentIdFieldName,
  ) {
    final selector = RootOrderByFieldSelector<T>();

    // Call the order builder to populate the selector
    orderBuilder(selector);

    final pgFields = selector._fields
        .map((f) => OrderByFieldInfo(f.fieldPath, f.descending))
        .toList();
    return OrderByConfiguration(pgFields, orderBuilder);
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

class OrderedQuery<S extends FirestoreSchema, T, O extends Record>
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

  final OrderByConfiguration<T, O> _orderByConfig;

  const OrderedQuery(
    firestore.Query<Map<String, dynamic>> _query,
    FirestoreConverter<T, Map<String, dynamic>> converter,
    String _documentIdField,
    OrderByConfiguration<T, O> orderByConfig,
  ) : _query = _query,
      _converter = converter,
      _documentIdField = _documentIdField,
      _orderByConfig = orderByConfig;

  @override
  Future<List<T>> get() =>
      QueryHandler.get(_query, _converter.fromJson, _documentIdField);

  @override
  Stream<List<T>?> get stream =>
      QueryHandler.stream(_query, _converter.fromJson, _documentIdField);

  @override
  OrderedQuery<S, T, O> limit(int limit) {
    final newQuery = QueryLimitHandler.applyLimit(_query, limit);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> limitToLast(int limit) {
    final newQuery = QueryLimitHandler.applyLimitToLast(_query, limit);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> endAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndAt(_query, cursors);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> endAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object,
      _converter.toJson,
      _orderByConfig.builder,
      _documentIdField,
    );
    final newQuery = QueryPaginationHandler.applyEndAt(_query, values);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> endBefore(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, cursors);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> endBeforeObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object,
      _converter.toJson,
      _orderByConfig.builder,
      _documentIdField,
    );
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, values);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> startAfter(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, cursors);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> startAfterObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object,
      _converter.toJson,
      _orderByConfig.builder,
      _documentIdField,
    );
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, values);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> startAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAt(_query, cursors);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> startAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object,
      _converter.toJson,
      _orderByConfig.builder,
      _documentIdField,
    );
    final newQuery = QueryPaginationHandler.applyStartAt(_query, values);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
    );
  }

  @override
  OrderedQuery<S, T, O> where(
    FirestoreFilter Function(RootFilterSelector<T> builder) filterBuilder,
  ) {
    final filter = QueryFilterHandler.buildFilter(filterBuilder);
    final newQuery = QueryFilterHandler.applyFilter(_query, filter);
    return OrderedQuery<S, T, O>(
      newQuery,
      _converter,
      _documentIdField,
      _orderByConfig,
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
