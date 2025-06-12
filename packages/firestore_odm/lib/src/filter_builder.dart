import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/types.dart';
import 'package:firestore_odm/src/utils.dart';

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

/// Update operation types
enum UpdateOperationType {
  set, // Direct field assignment
  increment, // Numeric increment/decrement
  arrayAdd, // Array add operation
  arrayRemove, // Array remove operation
  delete, // Delete field
  serverTimestamp, // Server timestamp
  objectMerge, // Object merge update
}

/// Represents a single update operation
class UpdateOperation {
  final String field;
  final UpdateOperationType type;
  final dynamic value;

  const UpdateOperation(this.field, this.type, this.value);

  @override
  String toString() => 'UpdateOperation($field, $type, $value)';
}

/// Base update builder class using Node-based architecture
class UpdateBuilder<T> extends Node {
  /// Create an UpdateBuilder with optional name and parent for nested objects
  UpdateBuilder({super.name, super.parent});

  /// Convert operations to Firestore update map
  static Map<String, dynamic> operationsToMap(
    List<UpdateOperation> operations,
  ) {
    final Map<String, dynamic> updateMap = {};
    final Map<String, List<dynamic>> arrayAdds = {};
    final Map<String, List<dynamic>> arrayRemoves = {};
    final Map<String, num> increments = {};

    for (final operation in operations) {
      switch (operation.type) {
        case UpdateOperationType.set:
          updateMap[operation.field] = operation.value;
          break;
        case UpdateOperationType.increment:
          increments[operation.field] =
              (increments[operation.field] ?? 0) + (operation.value as num);
          break;
        case UpdateOperationType.arrayAdd:
          arrayAdds.putIfAbsent(operation.field, () => []).add(operation.value);
          break;
        case UpdateOperationType.arrayRemove:
          arrayRemoves
              .putIfAbsent(operation.field, () => [])
              .add(operation.value);
          break;
        case UpdateOperationType.delete:
          updateMap[operation.field] = FieldValue.delete();
          break;
        case UpdateOperationType.serverTimestamp:
          updateMap[operation.field] = FieldValue.serverTimestamp();
          break;
        case UpdateOperationType.objectMerge:
          // For object merge, flatten the nested fields
          final data = operation.value as Map<String, dynamic>;
          for (final entry in data.entries) {
            final fieldPath = operation.field.isEmpty
                ? entry.key
                : '${operation.field}.${entry.key}';
            updateMap[fieldPath] = entry.value;
          }
          break;
      }
    }

    // Handle fields with both add and remove operations by executing them sequentially
    final fieldsWithBothOps = arrayAdds.keys.toSet().intersection(
      arrayRemoves.keys.toSet(),
    );
    if (fieldsWithBothOps.isNotEmpty) {
      throw ArgumentError(
        'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update. Fields: $fieldsWithBothOps',
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
  FirestoreFilter call({
    Map? isEqualTo,
    Map? isNotEqualTo,
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

/// Callable update instances using Node-based architecture
/// Base callable update class
abstract class CallableUpdate<T> extends Node {
  CallableUpdate({super.name, super.parent});

  String get fieldPath => $path;
}

/// Boolean field callable updater
class BoolFieldUpdate<T> extends CallableUpdate<T> {
  BoolFieldUpdate({super.name, super.parent});

  /// Set boolean value
  UpdateOperation call(bool value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// String field callable updater
class StringFieldUpdate<T> extends CallableUpdate<T> {
  StringFieldUpdate({super.name, super.parent});

  /// Set string value
  UpdateOperation call(String value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// Numeric field callable updater
class NumericFieldUpdate<T, N extends num> extends CallableUpdate<T> {
  NumericFieldUpdate({super.name, super.parent});

  /// Set numeric value
  UpdateOperation call(N value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Increment field value
  UpdateOperation increment(N value) {
    return UpdateOperation(fieldPath, UpdateOperationType.increment, value);
  }
}

/// List field callable updater
class ListFieldUpdate<T, E> extends CallableUpdate<T> {
  ListFieldUpdate({super.name, super.parent});

  /// Set list value
  UpdateOperation call(List<E> value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Add element to array
  UpdateOperation add(E value) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayAdd, value);
  }

  /// Remove element from array
  UpdateOperation remove(E value) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayRemove, value);
  }
}

/// DateTime field callable updater
class DateTimeFieldUpdate<T> extends CallableUpdate<T> {
  DateTimeFieldUpdate({super.name, super.parent});

  /// Set DateTime value
  UpdateOperation call(DateTime value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Set field to server timestamp
  UpdateOperation serverTimestamp() {
    return UpdateOperation(
      fieldPath,
      UpdateOperationType.serverTimestamp,
      null,
    );
  }
}

/// Generic field callable updater (fallback)
class GenericFieldUpdate<T, V> extends CallableUpdate<T> {
  GenericFieldUpdate({super.name, super.parent});

  /// Set value
  UpdateOperation call(V value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// Map field callable updater
class MapFieldUpdate<T, K, V> extends CallableUpdate<T> {
  MapFieldUpdate({super.name, super.parent});

  /// Set entire map value
  UpdateOperation call(Map<K, V> value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }

  /// Set a specific key in the map
  /// Usage: $.profile.socialLinks.setKey("github", "username")
  UpdateOperation setKey(K key, V value) {
    final keyPath = '$fieldPath.$key';
    return UpdateOperation(keyPath, UpdateOperationType.set, value);
  }

  /// Remove a specific key from the map
  /// Usage: $.profile.socialLinks.removeKey("github")
  UpdateOperation removeKey(K key) {
    final keyPath = '$fieldPath.$key';
    return UpdateOperation(keyPath, UpdateOperationType.delete, null);
  }
}
