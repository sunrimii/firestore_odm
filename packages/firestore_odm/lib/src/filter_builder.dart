import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/types.dart';

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
}

/// Base filter builder class using Node-based architecture
class FilterSelector<T> extends Node {
  /// Create a FilterSelector with optional name and parent for nested objects
  FilterSelector({super.name, super.parent});
}

class RootFilterSelector<T> extends FilterSelector<T> {
  RootFilterSelector();

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

/// Represents a single update operation
sealed class UpdateOperation {
  final String field;

  const UpdateOperation(this.field);

  @override
  String toString() => 'UpdateOperation($field)';
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
    return SetOperation<T>($path, convertedValue);
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

/// Callable filter instances using Node-based architecture
/// Base callable filter class
abstract class CallableFilter extends Node {
  CallableFilter({super.name, super.parent});

  dynamic get fieldPath => $path;
}

/// String field callable filter
class StringFieldFilter extends CallableFilter {
  StringFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    String? isEqualTo,
    String? isNotEqualTo,
    String? isLessThan,
    String? isLessThanOrEqualTo,
    String? isGreaterThan,
    String? isGreaterThanOrEqualTo,
    List<String>? whereIn,
    List<String>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThan,
        value: isLessThan,
      );
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      );
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThan,
        value: isGreaterThan,
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Numeric field callable filter
class NumericFieldFilter extends CallableFilter {
  NumericFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    num? isEqualTo,
    num? isNotEqualTo,
    num? isLessThan,
    num? isLessThanOrEqualTo,
    num? isGreaterThan,
    num? isGreaterThanOrEqualTo,
    List<num>? whereIn,
    List<num>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThan,
        value: isLessThan,
      );
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      );
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThan,
        value: isGreaterThan,
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Boolean field callable filter
class BoolFieldFilter extends CallableFilter {
  BoolFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    bool? isEqualTo,
    bool? isNotEqualTo,
    List<bool>? whereIn,
    List<bool>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// DateTime field callable filter
class DateTimeFieldFilter extends CallableFilter {
  DateTimeFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    DateTime? isEqualTo,
    DateTime? isNotEqualTo,
    DateTime? isLessThan,
    DateTime? isLessThanOrEqualTo,
    DateTime? isGreaterThan,
    DateTime? isGreaterThanOrEqualTo,
    List<DateTime>? whereIn,
    List<DateTime>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThan,
        value: isLessThan,
      );
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      );
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThan,
        value: isGreaterThan,
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Array field callable filter
class ArrayFieldFilter extends CallableFilter {
  ArrayFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    List? isEqualTo,
    List? isNotEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<List>? whereIn,
    List<List>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (arrayContains != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.arrayContains,
        value: arrayContains,
      );
    }
    if (arrayContainsAny != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.arrayContainsAny,
        value: arrayContainsAny,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Map field callable filter with key access support
class MapFieldFilter extends CallableFilter {
  MapFieldFilter({super.name, super.parent});

  /// Filter the entire map
  FirestoreFilter call({Map? isEqualTo, Map? isNotEqualTo, bool? isNull}) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }

    throw ArgumentError('At least one filter condition must be provided');
  }

  /// Access a specific key in the map for filtering
  /// Usage: $.profile.socialLinks.key("github")(isEqualTo: "username")
  MapKeyFieldFilter key(dynamic mapKey) {
    return MapKeyFieldFilter(name: mapKey.toString(), parent: this);
  }
}

/// Filter for individual map keys
class MapKeyFieldFilter extends CallableFilter {
  MapKeyFieldFilter({super.name, super.parent});

  FirestoreFilter call({
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    List? whereIn,
    List? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThan,
        value: isLessThan,
      );
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      );
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThan,
        value: isGreaterThan,
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }

    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Document ID callable filter (special case)
class DocumentIdFieldFilter extends CallableFilter {
  DocumentIdFieldFilter({super.name, super.parent});

  @override
  get fieldPath => FieldPathType.documentId.toFirestore();

  FirestoreFilter call({
    String? isEqualTo,
    String? isNotEqualTo,
    String? isLessThan,
    String? isLessThanOrEqualTo,
    String? isGreaterThan,
    String? isGreaterThanOrEqualTo,
    List<String>? whereIn,
    List<String>? whereNotIn,
    bool? isNull,
  }) {
    if (isEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isEqualTo,
        value: isEqualTo,
      );
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isNotEqualTo,
        value: isNotEqualTo,
      );
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThan,
        value: isLessThan,
      );
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      );
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThan,
        value: isGreaterThan,
      );
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereIn,
        value: whereIn,
      );
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: FilterOperator.whereNotIn,
        value: whereNotIn,
      );
    }
    if (isNull != null) {
      return FirestoreFilter.field(
        field: fieldPath,
        operator: isNull
            ? FilterOperator.isEqualTo
            : FilterOperator.isNotEqualTo,
        value: null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Numeric field callable updater
class NumericFieldUpdate<T extends num?> extends PatchBuilder<T> {
  const NumericFieldUpdate({required super.name, super.parent, required super.converter});

  /// Increment field value
  UpdateOperation increment(T value) {
    return IncrementOperation(
      $path,
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
    return ArrayAddAllOperation($path, [_elementConverter.toJson(value)]);
  }

  /// Add multiple elements to array
  UpdateOperation addAll(Iterable<E> values) {
    return ArrayAddAllOperation(
      $path,
      values.map(_elementConverter.toJson).toList(),
    );
  }

  /// Remove element from array
  UpdateOperation remove(E value) {
    return ArrayRemoveAllOperation($path, [_elementConverter.toJson(value)]);
  }

  /// Remove multiple elements from array
  UpdateOperation removeAll(Iterable<E> values) {
    return ArrayRemoveAllOperation(
      $path,
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
    return ServerTimestampOperation($path);
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
    return IncrementOperation($path, milliseconds);
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

  /// Set a single key-value pair (like map[key] = value)
  /// Usage: $.settings['theme'] = 'dark' → $.settings.set('theme', 'dark')
  UpdateOperation set(K key, V value) {
    final convertedKey = _keyConverter.toJson(key);
    final keyPath = '${$path}.$convertedKey';
    return SetOperation<V>(keyPath, _valueConverter.toJson(value));
  }

  /// Remove a single key (like map.remove(key))
  /// Usage: $.settings.remove('oldSetting')
  UpdateOperation remove(K key) {
    final convertedKey = _keyConverter.toJson(key);
    final keyPath = '${$path}.$convertedKey';
    return DeleteOperation(keyPath);
  }

  /// Add multiple key-value pairs (like map.addAll(other))
  /// Usage: $.settings.addAll({'theme': 'dark', 'language': 'en'})
  UpdateOperation addAll(Map<K, V> entries) {
    final entriesMap = entries.map(
      (key, value) => MapEntry(
        '${$path}.${_keyConverter.toJson(key)}',
        _valueConverter.toJson(value),
      ),
    );
    return MapPutAllOperation($path, entriesMap);
  }

  /// Add multiple entries from MapEntry iterable (more flexible)
  /// Usage: $.settings.addEntries([MapEntry('theme', 'dark'), MapEntry('lang', 'en')])
  UpdateOperation addEntries(Iterable<MapEntry<K, V>> entries) {
    final entriesMap = Map.fromEntries(
      entries.map(
        (entry) => MapEntry(
          '${$path}.${_keyConverter.toJson(entry.key)}',
          _valueConverter.toJson(entry.value),
        ),
      ),
    );
    return MapPutAllOperation($path, entriesMap);
  }

  /// Remove multiple keys at once
  /// Usage: $.settings.removeWhere(['oldSetting1', 'oldSetting2'])
  UpdateOperation removeWhere(Iterable<K> keys) {
    final keysList = keys.map((key) => _keyConverter.toJson(key)).toList();
    return MapRemoveAllOperation($path, keysList);
  }

  /// Clear all entries (like map.clear())
  /// Usage: $.settings.clear()
  UpdateOperation clear() {
    return SetOperation<Map<String, dynamic>>($path, {});
  }

  // ===== Convenience Methods =====

  /// Set multiple keys to the same value
  /// Usage: $.permissions.setAll(['read', 'write'], true)
  UpdateOperation setAll(Iterable<K> keys, V value) {
    final entriesMap = Map.fromIterables(
      keys.map((key) => '${$path}.${_keyConverter.toJson(key)}'),
      Iterable.generate(keys.length, (_) => _valueConverter.toJson(value)),
    );
    return MapPutAllOperation($path, entriesMap);
  }
}
