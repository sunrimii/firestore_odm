import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:cloud_firestore_platform_interface/src/field_path_type.dart';
import 'package:firestore_odm/firestore_odm.dart';

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
class FirestoreFilter<T> {
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

/// Represents an order by field with direction
class OrderByField<T> {
  final dynamic field;
  final bool descending;

  const OrderByField(this.field, {this.descending = false});
}

/// Base filter builder class
/// Extended by generated FilterBuilder classes that provide type-safe filtering methods
class FilterSelector<T> {
  /// Field prefix for nested object filtering
  final String prefix;

  /// Create a FilterSelector with optional field prefix for nested objects
  FilterSelector({this.prefix = ''});

  /// Helper to get field path with prefix
  String getFieldPath(String fieldName) {
    return prefix.isEmpty ? fieldName : '$prefix.$fieldName';
  }

  /// Create string field filter
  FirestoreFilter<R> stringFilter<R>(
    dynamic fieldName, {
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
    final fieldPath = fieldName is String ? getFieldPath(fieldName) : fieldName;
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

  /// Create numeric field filter
  FirestoreFilter<R> numericFilter<R, N extends num>(
    String fieldName, {
    N? isEqualTo,
    N? isNotEqualTo,
    N? isLessThan,
    N? isLessThanOrEqualTo,
    N? isGreaterThan,
    N? isGreaterThanOrEqualTo,
    List<N>? whereIn,
    List<N>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = getFieldPath(fieldName);
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

  /// Create boolean field filter
  FirestoreFilter<R> boolFilter<R>(
    String fieldName, {
    bool? isEqualTo,
    bool? isNotEqualTo,
    List<bool>? whereIn,
    List<bool>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = getFieldPath(fieldName);
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

  /// Create DateTime field filter
  FirestoreFilter<R> dateTimeFilter<R>(
    String fieldName, {
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
    final fieldPath = getFieldPath(fieldName);
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

  /// Create array field filter
  FirestoreFilter<R> arrayFilter<R, E>(
    String fieldName, {
    List<E>? isEqualTo,
    List<E>? isNotEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<List<E>>? whereIn,
    List<List<E>>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = getFieldPath(fieldName);
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

/// Root filter builder with all filtering logic
/// Extended by generated FilterBuilder classes for type-safe operations
class RootFilterSelector<T> extends FilterSelector<T> {
  RootFilterSelector({super.prefix});

  /// Create OR filter with type safety (supports up to 30 filters)
  FirestoreFilter<T> or(
    FirestoreFilter<T> filter1,
    FirestoreFilter<T> filter2, [
    FirestoreFilter<T>? filter3,
    FirestoreFilter<T>? filter4,
    FirestoreFilter<T>? filter5,
    FirestoreFilter<T>? filter6,
    FirestoreFilter<T>? filter7,
    FirestoreFilter<T>? filter8,
    FirestoreFilter<T>? filter9,
    FirestoreFilter<T>? filter10,
    FirestoreFilter<T>? filter11,
    FirestoreFilter<T>? filter12,
    FirestoreFilter<T>? filter13,
    FirestoreFilter<T>? filter14,
    FirestoreFilter<T>? filter15,
    FirestoreFilter<T>? filter16,
    FirestoreFilter<T>? filter17,
    FirestoreFilter<T>? filter18,
    FirestoreFilter<T>? filter19,
    FirestoreFilter<T>? filter20,
    FirestoreFilter<T>? filter21,
    FirestoreFilter<T>? filter22,
    FirestoreFilter<T>? filter23,
    FirestoreFilter<T>? filter24,
    FirestoreFilter<T>? filter25,
    FirestoreFilter<T>? filter26,
    FirestoreFilter<T>? filter27,
    FirestoreFilter<T>? filter28,
    FirestoreFilter<T>? filter29,
    FirestoreFilter<T>? filter30,
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
    return FirestoreFilter<T>.or(allFilters);
  }

  /// Create AND filter with type safety (supports up to 30 filters)
  FirestoreFilter<T> and(
    FirestoreFilter<T> filter1,
    FirestoreFilter<T> filter2, [
    FirestoreFilter<T>? filter3,
    FirestoreFilter<T>? filter4,
    FirestoreFilter<T>? filter5,
    FirestoreFilter<T>? filter6,
    FirestoreFilter<T>? filter7,
    FirestoreFilter<T>? filter8,
    FirestoreFilter<T>? filter9,
    FirestoreFilter<T>? filter10,
    FirestoreFilter<T>? filter11,
    FirestoreFilter<T>? filter12,
    FirestoreFilter<T>? filter13,
    FirestoreFilter<T>? filter14,
    FirestoreFilter<T>? filter15,
    FirestoreFilter<T>? filter16,
    FirestoreFilter<T>? filter17,
    FirestoreFilter<T>? filter18,
    FirestoreFilter<T>? filter19,
    FirestoreFilter<T>? filter20,
    FirestoreFilter<T>? filter21,
    FirestoreFilter<T>? filter22,
    FirestoreFilter<T>? filter23,
    FirestoreFilter<T>? filter24,
    FirestoreFilter<T>? filter25,
    FirestoreFilter<T>? filter26,
    FirestoreFilter<T>? filter27,
    FirestoreFilter<T>? filter28,
    FirestoreFilter<T>? filter29,
    FirestoreFilter<T>? filter30,
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
    return FirestoreFilter<T>.and(allFilters);
  }
}

/// Base order by builder class
/// Extended by generated OrderByBuilder classes that provide type-safe ordering methods
class OrderBySelector<T> {
  /// Field prefix for nested object ordering
  final String prefix;

  /// Create an OrderByBuilder with optional field prefix for nested objects
  OrderBySelector({this.prefix = ''});
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

/// Base update builder class
/// Extended by generated UpdateBuilder classes that provide type-safe update methods
class UpdateBuilder<T> {
  /// Field prefix for nested object updates
  final String prefix;

  /// Create an UpdateBuilder with optional field prefix for nested objects
  UpdateBuilder({this.prefix = ''});

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

/// Generic field builder
class FieldBuilder<T> {
  final String fieldPath;
  FieldBuilder(this.fieldPath);

  /// Set field value
  UpdateOperation call(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// List field builder
class ListFieldBuilder<T> extends FieldBuilder<List<T>> {
  ListFieldBuilder(super.fieldPath);

  /// Add element to array
  UpdateOperation add(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayAdd, value);
  }

  /// Remove element from array
  UpdateOperation remove(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.arrayRemove, value);
  }
}

/// Numeric field builder
class NumericFieldBuilder<T extends num> extends FieldBuilder<T> {
  NumericFieldBuilder(super.fieldPath);

  /// Increment field value
  UpdateOperation increment(T value) {
    return UpdateOperation(fieldPath, UpdateOperationType.increment, value);
  }
}

/// DateTime field builder
class DateTimeFieldBuilder extends FieldBuilder<DateTime> {
  DateTimeFieldBuilder(super.fieldPath);

  /// Set field to server timestamp
  UpdateOperation serverTimestamp() {
    return UpdateOperation(
      fieldPath,
      UpdateOperationType.serverTimestamp,
      null,
    );
  }
}

/// Universal filter creation helper - eliminates need for repetitive generated code
class FilterFactory {
  /// Create string field filter with all operators
  static FirestoreFilter stringFilter(
    String fieldName,
    String prefix, {
    String? isEqualTo,
    String? isNotEqualTo,
    List<String>? whereIn,
    List<String>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

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

  /// Create boolean field filter
  static FirestoreFilter boolFilter(
    String fieldName,
    String prefix, {
    bool? isEqualTo,
    bool? isNotEqualTo,
    List<bool>? whereIn,
    List<bool>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

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

  /// Create comparable field filter (int, double, DateTime)
  static FirestoreFilter comparableFilter<T>(
    String fieldName,
    String prefix, {
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    List<T>? whereIn,
    List<T>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

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

  /// Create list field filter
  static FirestoreFilter listFilter<T>(
    String fieldName,
    String prefix, {
    List<T>? isEqualTo,
    List<T>? isNotEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<List<T>>? whereIn,
    List<List<T>>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

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

/// Universal AND/OR filter creation - eliminates repetitive 30-parameter methods
class LogicalFilterFactory {
  /// Create OR filter from variable number of filters
  static FirestoreFilter orFilters(List<FirestoreFilter> filters) {
    if (filters.length < 2) {
      throw ArgumentError('OR operation requires at least 2 filters');
    }
    return FirestoreFilter.or(filters);
  }

  /// Create AND filter from variable number of filters
  static FirestoreFilter andFilters(List<FirestoreFilter> filters) {
    if (filters.length < 2) {
      throw ArgumentError('AND operation requires at least 2 filters');
    }
    return FirestoreFilter.and(filters);
  }

  /// Helper to collect optional filters into list
  static List<FirestoreFilter> collectFilters(
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
    return allFilters;
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

  dynamic get value => fieldName ?? documentId;

  @override
  String toString() => fieldName ?? documentId.toString();
}

class OrderByHelper {
  /// Create OrderByField with prefix
  static OrderByField<T> createOrderByField<T>(
    String fieldName, {
    String prefix = '',
    bool descending = false,
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';
    return OrderByField<T>(fieldPath, descending: descending);
  }

  /// Create OrderByField with prefix
  static OrderByField<T> createOrderByDocumentId<T>({bool descending = false}) {
    return OrderByField<T>(FieldPathType.documentId, descending: descending);
  }

  static OrderBySelector<T> createOrderBySelector<T>(
    String fieldName, {
    String prefix = '',
  }) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';
    return OrderBySelector<T>(prefix: fieldPath);
  }
}

/// Extension for Update operations
extension UpdateBuilderExtensions on UpdateBuilder {
  /// Get field path with prefix
  String getFieldPath(String fieldName) {
    return prefix.isEmpty ? fieldName : '$prefix.$fieldName';
  }
}

/// Callable filter instances - significantly reduce generated code
/// Base callable filter class
abstract class CallableFilter<T, V> {
  final String fieldName;
  final String prefix;

  const CallableFilter(this.fieldName, this.prefix);

  dynamic get fieldPath => prefix.isEmpty ? fieldName : '$prefix.$fieldName';
}

/// String field callable filter
class StringFieldFilter<T> extends CallableFilter<T, String> {
  const StringFieldFilter(super.fieldName, super.prefix);

  FirestoreFilter<T> call({
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
class NumericFieldFilter<T, N extends num> extends CallableFilter<T, N> {
  const NumericFieldFilter(super.fieldName, super.prefix);

  FirestoreFilter<T> call({
    N? isEqualTo,
    N? isNotEqualTo,
    N? isLessThan,
    N? isLessThanOrEqualTo,
    N? isGreaterThan,
    N? isGreaterThanOrEqualTo,
    List<N>? whereIn,
    List<N>? whereNotIn,
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
class BoolFieldFilter<T> extends CallableFilter<T, bool> {
  const BoolFieldFilter(super.fieldName, super.prefix);

  FirestoreFilter<T> call({
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
class DateTimeFieldFilter<T> extends CallableFilter<T, DateTime> {
  const DateTimeFieldFilter(super.fieldName, super.prefix);

  FirestoreFilter<T> call({
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
class ArrayFieldFilter<T, E> extends CallableFilter<T, List<E>> {
  const ArrayFieldFilter(super.fieldName, super.prefix);

  FirestoreFilter<T> call({
    List<E>? isEqualTo,
    List<E>? isNotEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<List<E>>? whereIn,
    List<List<E>>? whereNotIn,
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

/// Document ID callable filter (special case)
class DocumentIdFieldFilter<T> extends CallableFilter<T, String> {
  const DocumentIdFieldFilter(super.fieldName, super.prefix);

  @override
  get fieldPath => FieldPathType.documentId;

  FirestoreFilter<T> call({
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

/// Callable update instances - reduce generated update code
/// Base callable update class
abstract class CallableUpdate<T> {
  final String fieldName;
  final String prefix;
  
  const CallableUpdate(this.fieldName, this.prefix);
  
  String get fieldPath => prefix.isEmpty ? fieldName : '$prefix.$fieldName';
}

/// Boolean field callable updater
class BoolFieldUpdate<T> extends CallableUpdate<T> {
  const BoolFieldUpdate(super.fieldName, super.prefix);
  
  /// Set boolean value
  UpdateOperation call(bool value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// String field callable updater
class StringFieldUpdate<T> extends CallableUpdate<T> {
  const StringFieldUpdate(super.fieldName, super.prefix);
  
  /// Set string value
  UpdateOperation call(String value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// Numeric field callable updater
class NumericFieldUpdate<T, N extends num> extends CallableUpdate<T> {
  const NumericFieldUpdate(super.fieldName, super.prefix);
  
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
  const ListFieldUpdate(super.fieldName, super.prefix);
  
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
  const DateTimeFieldUpdate(super.fieldName, super.prefix);
  
  /// Set DateTime value
  UpdateOperation call(DateTime value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
  
  /// Set field to server timestamp
  UpdateOperation serverTimestamp() {
    return UpdateOperation(fieldPath, UpdateOperationType.serverTimestamp, null);
  }
}

/// Generic field callable updater (fallback)
class GenericFieldUpdate<T, V> extends CallableUpdate<T> {
  const GenericFieldUpdate(super.fieldName, super.prefix);
  
  /// Set value
  UpdateOperation call(V value) {
    return UpdateOperation(fieldPath, UpdateOperationType.set, value);
  }
}

/// Callable order by instances - reduce generated order by code
/// Base callable order by class
abstract class CallableOrderBy<T> {
  final String fieldName;
  final String prefix;
  
  const CallableOrderBy(this.fieldName, this.prefix);
  
  String get fieldPath => prefix.isEmpty ? fieldName : '$prefix.$fieldName';
}

/// Generic field callable order by
class FieldOrderBy<T> extends CallableOrderBy<T> {
  const FieldOrderBy(super.fieldName, super.prefix);
  
  /// Create order by field
  OrderByField<T> call({bool descending = false}) {
    return OrderByHelper.createOrderByField<T>(
      fieldName,
      prefix: prefix,
      descending: descending,
    );
  }
}

/// Document ID callable order by
class DocumentIdOrderBy<T> extends CallableOrderBy<T> {
  const DocumentIdOrderBy(super.fieldName, super.prefix);
  
  /// Create order by document ID
  OrderByField<T> call({bool descending = false}) {
    return OrderByHelper.createOrderByDocumentId<T>(descending: descending);
  }
}
