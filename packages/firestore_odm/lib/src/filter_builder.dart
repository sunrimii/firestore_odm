import 'package:cloud_firestore/cloud_firestore.dart'
    show FieldPath, FieldValue;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/types.dart';

typedef FilterBuilderFunc<AB extends FilterBuilderNode> =
    AB Function({String name, FilterBuilderNode? parent});

/// Filter types
enum FilterType { field, and, or }

/// Firestore operators
enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// Universal filter class that can represent any filter type
class FirestoreFilter {
  final FilterType type;

  // For field filters
  final Object? field;
  final FilterOperator? operator;
  final dynamic value;

  // For logical filters (AND/OR)
  final List<FirestoreFilter>? filters;

  const FirestoreFilter._({
    required this.type,
    this.field,
    this.operator,
    this.value,
    this.filters,
  });

  /// Default constructor for generated classes
  const FirestoreFilter() : this._(type: FilterType.field);

  /// Create a field filter
  const FirestoreFilter.field({
    required Object field,
    required FilterOperator operator,
    required dynamic value,
  }) : this._(
         type: FilterType.field,
         field: field,
         operator: operator,
         value: value,
       );

  /// Create an AND filter
  const FirestoreFilter.and(List<FirestoreFilter> filters)
    : this._(type: FilterType.and, filters: filters);

  /// Create an OR filter
  const FirestoreFilter.or(List<FirestoreFilter> filters)
    : this._(type: FilterType.or, filters: filters);

  /// Create a filter from another FirestoreFilter (copy constructor)
  FirestoreFilter.fromFilter(FirestoreFilter other)
    : this._(
        type: other.type,
        field: other.field,
        operator: other.operator,
        value: other.value,
        filters: other.filters,
      );

  FirestoreFilter and(FirestoreFilter other) {
    return FirestoreFilter.and([...?filters, other]);
  }

  FirestoreFilter or(FirestoreFilter other) {
    return FirestoreFilter.or([...?filters, other]);
  }
}

/// Base filter builder class using Node-based architecture
class FilterBuilderNode extends Node {
  /// Create a FilterSelector with optional name and parent for nested objects
  const FilterBuilderNode({super.name, super.parent});
}

abstract class FilterBuilderRoot {
  factory FilterBuilderRoot() = _FilterBuilderRootImpl;

  /// Create OR filter with type safety (supports up to 30 filters)
  FirestoreFilter or(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]);

  /// Create AND filter with type safety (supports up to 30 filters)
  FirestoreFilter and(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]);
}

mixin FilterBuilderRootMixin on FilterBuilderNode implements FilterBuilderRoot {
  /// Create OR filter with type safety (supports up to 30 filters)
  FirestoreFilter or(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]) {
    final allFilters = <FirestoreFilter>[filter1, filter2];
    if (filter3 != null) allFilters.add(filter3);
    if (filter4 != null) allFilters.add(filter4);
    if (filter5 != null) allFilters.add(filter5);
    if (filter6 != null) allFilters.add(filter6);
    if (filter7 != null) allFilters.add(filter7);
    if (filter8 != null) allFilters.add(filter8);
    if (filter9 != null) allFilters.add(filter9);
    if (filter10 != null) allFilters.add(filter10);
    if (filter11 != null) allFilters.add(filter11);
    if (filter12 != null) allFilters.add(filter12);
    if (filter13 != null) allFilters.add(filter13);
    if (filter14 != null) allFilters.add(filter14);
    if (filter15 != null) allFilters.add(filter15);
    if (filter16 != null) allFilters.add(filter16);
    if (filter17 != null) allFilters.add(filter17);
    if (filter18 != null) allFilters.add(filter18);
    if (filter19 != null) allFilters.add(filter19);
    if (filter20 != null) allFilters.add(filter20);
    if (filter21 != null) allFilters.add(filter21);
    if (filter22 != null) allFilters.add(filter22);
    if (filter23 != null) allFilters.add(filter23);
    if (filter24 != null) allFilters.add(filter24);
    if (filter25 != null) allFilters.add(filter25);
    if (filter26 != null) allFilters.add(filter26);
    if (filter27 != null) allFilters.add(filter27);
    if (filter28 != null) allFilters.add(filter28);
    if (filter29 != null) allFilters.add(filter29);
    if (filter30 != null) allFilters.add(filter30);
    return FirestoreFilter.or(allFilters);
  }

  /// Create AND filter with type safety (supports up to 30 filters)
  FirestoreFilter and(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]) {
    final allFilters = <FirestoreFilter>[filter1, filter2];
    if (filter3 != null) allFilters.add(filter3);
    if (filter4 != null) allFilters.add(filter4);
    if (filter5 != null) allFilters.add(filter5);
    if (filter6 != null) allFilters.add(filter6);
    if (filter7 != null) allFilters.add(filter7);
    if (filter8 != null) allFilters.add(filter8);
    if (filter9 != null) allFilters.add(filter9);
    if (filter10 != null) allFilters.add(filter10);
    if (filter11 != null) allFilters.add(filter11);
    if (filter12 != null) allFilters.add(filter12);
    if (filter13 != null) allFilters.add(filter13);
    if (filter14 != null) allFilters.add(filter14);
    if (filter15 != null) allFilters.add(filter15);
    if (filter16 != null) allFilters.add(filter16);
    if (filter17 != null) allFilters.add(filter17);
    if (filter18 != null) allFilters.add(filter18);
    if (filter19 != null) allFilters.add(filter19);
    if (filter20 != null) allFilters.add(filter20);
    if (filter21 != null) allFilters.add(filter21);
    if (filter22 != null) allFilters.add(filter22);
    if (filter23 != null) allFilters.add(filter23);
    if (filter24 != null) allFilters.add(filter24);
    if (filter25 != null) allFilters.add(filter25);
    if (filter26 != null) allFilters.add(filter26);
    if (filter27 != null) allFilters.add(filter27);
    if (filter28 != null) allFilters.add(filter28);
    if (filter29 != null) allFilters.add(filter29);
    if (filter30 != null) allFilters.add(filter30);
    return FirestoreFilter.and(allFilters);
  }
}

class _FilterBuilderRootImpl extends FilterBuilderNode
    with FilterBuilderRootMixin {
  const _FilterBuilderRootImpl();
}

/// Represents a single update operation
sealed class UpdateOperation {
  final List<String> fieldPath;

  const UpdateOperation(this.fieldPath);

  /// Convert fieldPath to a string representation for compatibility
  String get field => fieldPath.join('.');

  @override
  String toString() => 'UpdateOperation(${fieldPath.join('.')})';
}

class SetOperation<T> extends UpdateOperation {
  final T value;

  SetOperation(super.field, this.value);

  @override
  String toString() => 'SetOperation($field, $value)';
}

class IncrementOperation<T extends num> extends UpdateOperation {
  final T value;

  IncrementOperation(super.field, this.value);

  @override
  String toString() => 'IncrementOperation($field, $value)';
}

class ArrayAddAllOperation<T> extends UpdateOperation {
  final List<T> values;

  ArrayAddAllOperation(super.field, this.values);

  @override
  String toString() => 'ArrayAddAllOperation($field, $values)';
}

class ArrayRemoveAllOperation<T> extends UpdateOperation {
  final List<T> values;

  ArrayRemoveAllOperation(super.field, this.values);

  @override
  String toString() => 'ArrayRemoveAllOperation($field, $values)';
}

class DeleteOperation extends UpdateOperation {
  DeleteOperation(super.field);

  @override
  String toString() => 'DeleteOperation($field)';
}

class ServerTimestampOperation extends UpdateOperation {
  ServerTimestampOperation(super.field);

  @override
  String toString() => 'ServerTimestampOperation($field)';
}

class ObjectMergeOperation extends UpdateOperation {
  final Map<String, dynamic> data;

  ObjectMergeOperation(super.field, this.data);

  @override
  String toString() => 'ObjectMergeOperation($field, $data)';
}

class MapPutAllOperation<V> extends UpdateOperation {
  final Map<String, V> entries;

  MapPutAllOperation(super.field, this.entries);

  @override
  String toString() => 'MapPutAllOperation($field, $entries)';
}

class MapRemoveAllOperation<K> extends UpdateOperation {
  final List<K> keys;

  MapRemoveAllOperation(super.field, this.keys);

  @override
  String toString() => 'MapRemoveAllOperation($field, $keys)';
}

class MapClearOperation extends UpdateOperation {
  MapClearOperation(super.field);

  @override
  String toString() => 'MapClearOperation($field)';
}

class MapSetOperation<K, V> extends UpdateOperation {
  final Map<K, V> entries;

  MapSetOperation(super.field, this.entries);

  @override
  String toString() => 'MapSetOperation($field, $entries)';
}

/// Convert operations to Firestore update map
Map<String, dynamic> operationsToMap(List<UpdateOperation> operations) {
  final Map<String, dynamic> updateMap = {};
  final Map<String, List<dynamic>> arrayAdds = {};
  final Map<String, List<dynamic>> arrayRemoves = {};
  final Map<String, num> increments = {};

  // Track which fields have set operations to handle precedence
  final Set<String> fieldsWithSetOperations = {};

  // First pass: identify fields with set operations
  for (final operation in operations) {
    if (operation is SetOperation ||
        operation is DeleteOperation ||
        operation is ServerTimestampOperation ||
        operation is ObjectMergeOperation) {
      fieldsWithSetOperations.add(operation.field);
    }
  }

  // Second pass: process operations with precedence rules
  for (final operation in operations) {
    switch (operation) {
      case SetOperation setOp:
        updateMap[setOp.field] = setOp.value;
        break;
      case IncrementOperation incOp:
        // Increment operations are not affected by set operations
        increments[incOp.field] = (increments[incOp.field] ?? 0) + incOp.value;
        break;
      case ArrayAddAllOperation arrayAddAllOp:
        // Skip array operations if field has set operation
        if (!fieldsWithSetOperations.contains(arrayAddAllOp.field)) {
          arrayAdds
              .putIfAbsent(arrayAddAllOp.field, () => [])
              .addAll(arrayAddAllOp.values);
        }
        break;
      case ArrayRemoveAllOperation arrayRemoveAllOp:
        // Skip array operations if field has set operation
        if (!fieldsWithSetOperations.contains(arrayRemoveAllOp.field)) {
          arrayRemoves
              .putIfAbsent(arrayRemoveAllOp.field, () => [])
              .addAll(arrayRemoveAllOp.values);
        }
        break;
      case DeleteOperation deleteOp:
        updateMap[deleteOp.field] = FieldValue.delete();
        break;
      case ServerTimestampOperation serverTimestampOp:
        updateMap[serverTimestampOp.field] = FieldValue.serverTimestamp();
        break;
      case ObjectMergeOperation operation:
        // For object merge, flatten the nested fields
        final data = operation.data;
        for (final entry in data.entries) {
          final fieldPath = operation.field.isEmpty
              ? entry.key
              : '${operation.field}.${entry.key}';
          updateMap[fieldPath] = entry.value;
        }
        break;
      case MapPutAllOperation mapPutAllOp:
        // For map putAll, set multiple nested fields
        final data = mapPutAllOp.entries;
        for (final entry in data.entries) {
          final keyPath = '${mapPutAllOp.field}.${entry.key}';
          updateMap[keyPath] = entry.value;
        }
        break;
      case MapRemoveAllOperation mapRemoveAllOp:
        // For map removeAll, delete multiple nested fields
        final keys = mapRemoveAllOp.keys;
        for (final key in keys) {
          final keyPath = '${operation.field}.$key';
          updateMap[keyPath] = FieldValue.delete();
        }
        break;
      case MapClearOperation mapClearOp:
        // For map clear, delete the entire map field
        updateMap[mapClearOp.field] = FieldValue.delete();
        // Note: Firestore does not support clearing a map field directly,
        // so we delete the field instead.

        // This is a workaround to clear the map field and preserve the structure
        updateMap[mapClearOp.field + '._tmp'] = FieldValue.delete();
        break;

      case MapSetOperation mapSetOp:
        // for map set, delete the existing map field
        updateMap[mapSetOp.field] = FieldValue.delete();

        // For map set, set multiple nested fields
        final data = mapSetOp.entries;
        for (final entry in data.entries) {
          final keyPath = '${mapSetOp.field}.${entry.key}';
          updateMap[keyPath] = entry.value;
        }
        break;
    }
  }

  // Handle fields with both add and remove operations
  // Note: Firestore doesn't support both arrayUnion and arrayRemove on the same field
  // in a single update, but we can combine the operations by computing the net effect
  final fieldsWithBothOps = arrayAdds.keys.toSet().intersection(
    arrayRemoves.keys.toSet(),
  );

  for (final field in fieldsWithBothOps) {
    final toAdd = arrayAdds[field]!;
    final toRemove = arrayRemoves[field]!;

    // Remove items that are both added and removed (they cancel out)
    final netAdd = toAdd.where((item) => !toRemove.contains(item)).toList();
    final netRemove = toRemove.where((item) => !toAdd.contains(item)).toList();

    // Update the maps with net operations
    if (netAdd.isNotEmpty) {
      arrayAdds[field] = netAdd;
    } else {
      arrayAdds.remove(field);
    }

    if (netRemove.isNotEmpty) {
      arrayRemoves[field] = netRemove;
    } else {
      arrayRemoves.remove(field);
    }
  }

  // After computing net operations, check if we still have conflicts
  final remainingConflicts = arrayAdds.keys.toSet().intersection(
    arrayRemoves.keys.toSet(),
  );
  if (remainingConflicts.isNotEmpty) {
    throw ArgumentError(
      'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update. Fields: $remainingConflicts',
    );
  }

  // Apply accumulated increment operations
  for (final entry in increments.entries) {
    updateMap[entry.key] = FieldValue.increment(entry.value);
  }

  // Apply accumulated array operations
  for (final entry in arrayAdds.entries) {
    updateMap[entry.key] = FieldValue.arrayUnion(entry.value);
  }
  for (final entry in arrayRemoves.entries) {
    updateMap[entry.key] = FieldValue.arrayRemove(entry.value);
  }

  print('Generated update map: $updateMap');

  return updateMap;
}

class PatchBuilder<T> extends Node {
  /// Converter function to transform the value before storing in Firestore
  final FirestoreConverter<T, dynamic> _converter;

  /// Create a DefaultUpdateBuilder with optional name, parent and converter
  const PatchBuilder({
    super.name,
    super.parent,
    required FirestoreConverter<T, dynamic> converter,
  }) : _converter = converter;

  UpdateOperation call(T value) {
    // Apply converter if provided, otherwise use the value directly
    final convertedValue = _converter.toJson(value);
    return SetOperation($parts, convertedValue);
  }
}

class FieldNameOrDocumentId {
  final String? fieldName;
  final FieldPathType documentId = FieldPathType.documentId;

  const FieldNameOrDocumentId._({this.fieldName});

  /// Create a FieldNameOrDocumentId with a field name
  const FieldNameOrDocumentId.field(String fieldName)
    : this._(fieldName: fieldName);

  /// Create a FieldNameOrDocumentId for document ID
  const FieldNameOrDocumentId.documentId() : this._();

  bool get isDocumentId => fieldName == null;
  bool get isFieldName => fieldName != null;

  dynamic get value => fieldName ?? documentId.toFirestore();

  @override
  String toString() => fieldName ?? documentId.toFirestore().toString();
}

class NoValue {
  /// Represents a special value indicating no value is provided
  const NoValue();

  @override
  String toString() => 'NoValue';
}

/// Callable filter instances using Node-based architecture
/// Base callable filter class
abstract class CallableFilter extends FilterBuilderNode {
  final FieldPathType? _type;
  const CallableFilter({super.name, super.parent, FieldPathType? type})
    : _type = type;

  FirestoreFilter _process(FilterOperator operator, dynamic value) {
    return FirestoreFilter.field(
      field: _type?.toFirestore() ?? FieldPath($parts),
      operator: operator,
      value: value,
    );
  }
}

class FilterFieldImpl<T> extends CallableFilter implements FilterField<T> {
  FilterFieldImpl({super.name = '', super.parent, super.type});

  FirestoreFilter call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? whereIn,
    Object? whereNotIn,
    Object? isNull,
  }) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    if (isLessThan != null) {
      return _process(FilterOperator.isLessThan, isLessThan);
    }
    if (isLessThanOrEqualTo != null) {
      return _process(FilterOperator.isLessThanOrEqualTo, isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) {
      return _process(FilterOperator.isGreaterThan, isGreaterThan);
    }
    if (isGreaterThanOrEqualTo != null) {
      return _process(
        FilterOperator.isGreaterThanOrEqualTo,
        isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return _process(FilterOperator.whereIn, whereIn);
    }
    if (whereNotIn != null) {
      return _process(FilterOperator.whereNotIn, whereNotIn);
    }
    if (isNull != null) {
      return _process(
        isNull as bool ? FilterOperator.isEqualTo : FilterOperator.isNotEqualTo,
        null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class FilterField<T> implements CallableFilter {
  factory FilterField({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = FilterFieldImpl;

  FirestoreFilter call({
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    List<T>? whereIn,
    List<T>? whereNotIn,
    bool? isNull,
  });
}

class BoolFieldFilterImpl extends CallableFilter implements BoolFieldFilter {
  const BoolFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({Object? isEqualTo, Object? isNotEqualTo}) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class BoolFieldFilter implements CallableFilter {
  factory BoolFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = BoolFieldFilterImpl;

  FirestoreFilter call({bool? isEqualTo, bool? isNotEqualTo});
}

class ArrayFieldFilterImpl<T> extends CallableFilter
    implements ArrayFieldFilter<T> {
  const ArrayFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? arrayContains,
    Object? arrayContainsAny,
  }) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    if (arrayContains != null) {
      return _process(FilterOperator.arrayContains, arrayContains);
    }
    if (arrayContainsAny != null) {
      return _process(FilterOperator.arrayContainsAny, arrayContainsAny);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class ArrayFieldFilter<T> implements CallableFilter {
  factory ArrayFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = ArrayFieldFilterImpl;

  FirestoreFilter call({
    List<T>? isEqualTo,
    List<T>? isNotEqualTo,
    T? arrayContains,
    List<T>? arrayContainsAny,
  });
}

class MapFieldFilterImpl<K, V> extends CallableFilter
    implements MapFieldFilter<K, V> {
  const MapFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({Map<K, V>? isEqualTo, Map<K, V>? isNotEqualTo}) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  FilterField<V> key(K mapKey) {
    return FilterField<V>(name: mapKey.toString(), parent: this);
  }
}

/// Map field callable filter with key access support
abstract class MapFieldFilter<K, V> extends CallableFilter {
  factory MapFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = MapFieldFilterImpl<K, V>;

  FirestoreFilter call({Map<K, V>? isEqualTo, Map<K, V>? isNotEqualTo});

  /// Access a specific key in the map for filtering
  /// Usage: $.profile.socialLinks.key("github")(isEqualTo: "username")
  FilterField<V> key(K mapKey);
}

/// Numeric field callable updater
class NumericFieldUpdate<T extends num?> extends PatchBuilder<T> {
  const NumericFieldUpdate({
    required super.name,
    super.parent,
    required super.converter,
  });

  /// Increment field value
  UpdateOperation increment(T value) {
    return IncrementOperation(
      $parts,
      value as num, // Ensure value is a num
    );
  }
}

/// List field callable updater
class ListFieldUpdate<T, E> extends PatchBuilder<T> {
  const ListFieldUpdate({
    required super.name,
    super.parent,
    required super.converter,
    required FirestoreConverter<E, dynamic> elementConverter,
  }) : _elementConverter = elementConverter;

  final FirestoreConverter<E, dynamic> _elementConverter;

  /// Add element to array
  UpdateOperation add(E value) {
    return ArrayAddAllOperation($parts, [_elementConverter.toJson(value)]);
  }

  /// Add multiple elements to array
  UpdateOperation addAll(Iterable<E> values) {
    return ArrayAddAllOperation(
      $parts,
      values.map(_elementConverter.toJson).toList(),
    );
  }

  /// Remove element from array
  UpdateOperation remove(E value) {
    return ArrayRemoveAllOperation($parts, [_elementConverter.toJson(value)]);
  }

  /// Remove multiple elements from array
  UpdateOperation removeAll(Iterable<E> values) {
    return ArrayRemoveAllOperation(
      $parts,
      values.map(_elementConverter.toJson).toList(),
    );
  }
}

/// DateTime field callable updater
class DateTimeFieldUpdate<T> extends PatchBuilder<T> {
  const DateTimeFieldUpdate({required super.name, super.parent})
    : super(
        converter: null is T
            ? const NullableConverter(DateTimeConverter())
                  as FirestoreConverter<T, dynamic>
            : const DateTimeConverter() as FirestoreConverter<T, dynamic>,
      );

  /// Set field to server timestamp
  UpdateOperation serverTimestamp() {
    return ServerTimestampOperation($parts);
  }
}

/// Duration field callable updater
class DurationFieldUpdate<T extends Duration?> extends PatchBuilder<T> {
  const DurationFieldUpdate({required super.name, super.parent})
    : super(
        converter: null is T
            ? const NullableConverter(DurationConverter())
                  as FirestoreConverter<T, int?>
            : const DurationConverter() as FirestoreConverter<T, int?>,
      );

  /// Increment field value by a Duration
  UpdateOperation increment(Duration value) {
    final int milliseconds = const DurationConverter().toJson(value);
    return IncrementOperation($parts, milliseconds);
  }
}

/// Map field callable updater with clean, consistent Dart Map-like operations
class MapFieldUpdate<T, K, V> extends PatchBuilder<T> {
  const MapFieldUpdate({
    required super.name,
    super.parent,
    required super.converter,
    required FirestoreConverter<K, dynamic> keyConverter,
    required FirestoreConverter<V, dynamic> valueConverter,
  }) : _keyConverter = keyConverter,
       _valueConverter = valueConverter;

  final FirestoreConverter<K, dynamic> _keyConverter;
  final FirestoreConverter<V, dynamic> _valueConverter;

  @override
  UpdateOperation call(T value) {
    return MapSetOperation(
      $parts,
      value is Map<K, V>
          ? value.map(
              (key, val) => MapEntry(
                _keyConverter.toJson(key).toString(),
                _valueConverter.toJson(val),
              ),
            )
          : {},
    );
  }

  /// Set a single key-value pair (like map[key] = value)
  /// Usage: $.settings['theme'] = 'dark' → $.settings.set('theme', 'dark')
  UpdateOperation set(K key, V value) {
    final convertedKey = _keyConverter.toJson(key);
    final keyPath = [...$parts, convertedKey.toString()];
    return SetOperation<V>(keyPath, _valueConverter.toJson(value));
  }

  /// Remove a single key (like map.remove(key))
  /// Usage: $.settings.remove('oldSetting')
  UpdateOperation remove(K key) {
    final convertedKey = _keyConverter.toJson(key);
    final keyPath = [...$parts, convertedKey.toString()];
    return DeleteOperation(keyPath);
  }

  /// Add multiple key-value pairs (like map.addAll(other))
  /// Usage: $.settings.addAll({'theme': 'dark', 'language': 'en'})
  UpdateOperation addAll(Map<K, V> entries) {
    final entriesMap = entries.map(
      (key, value) => MapEntry(
        _keyConverter.toJson(key).toString(),
        _valueConverter.toJson(value),
      ),
    );
    return MapPutAllOperation($parts, entriesMap);
  }

  /// Add multiple entries from MapEntry iterable (more flexible)
  /// Usage: $.settings.addEntries([MapEntry('theme', 'dark'), MapEntry('lang', 'en')])
  UpdateOperation addEntries(Iterable<MapEntry<K, V>> entries) {
    final entriesMap = Map.fromEntries(
      entries.map(
        (entry) => MapEntry(
          _keyConverter.toJson(entry.key).toString(),
          _valueConverter.toJson(entry.value),
        ),
      ),
    );
    return MapPutAllOperation($parts, entriesMap);
  }

  /// Remove multiple keys at once
  /// Usage: $.settings.removeWhere(['oldSetting1', 'oldSetting2'])
  UpdateOperation removeWhere(Iterable<K> keys) {
    final keysList = keys.map((key) => _keyConverter.toJson(key)).toList();
    return MapRemoveAllOperation($parts, keysList);
  }

  /// Clear all entries (like map.clear())
  /// Usage: $.settings.clear()
  UpdateOperation clear() {
    return MapClearOperation($parts);
  }

  // ===== Convenience Methods =====

  /// Set multiple keys to the same value
  /// Usage: $.permissions.setAll(['read', 'write'], true)
  UpdateOperation setAll(Iterable<K> keys, V value) {
    final entriesMap = Map.fromIterables(
      keys.map((key) => _keyConverter.toJson(key).toString()),
      Iterable.generate(keys.length, (_) => _valueConverter.toJson(value)),
    );
    return MapPutAllOperation($parts, entriesMap);
  }
}
