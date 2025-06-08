import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:meta/meta.dart';

/// Filter types
enum FilterType {
  field,
  and,
  or,
}

/// Universal filter class that can represent any filter type
class FirestoreFilter {
  final FilterType type;
  
  // For field filters
  final String? field;
  final String? operator;
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
    required String field,
    required String operator,
    required dynamic value,
  }) : this._(
          type: FilterType.field,
          field: field,
          operator: operator,
          value: value,
        );

  /// Create an AND filter
  const FirestoreFilter.and(List<FirestoreFilter> filters)
      : this._(
          type: FilterType.and,
          filters: filters,
        );

  /// Create an OR filter
  const FirestoreFilter.or(List<FirestoreFilter> filters)
      : this._(
          type: FilterType.or,
          filters: filters,
        );

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
class OrderByField {
  final String field;
  final bool descending;
  
  const OrderByField(this.field, {this.descending = false});
}

/// Base filter builder class
/// Extended by generated FilterBuilder classes that provide type-safe filtering methods
abstract class FilterBuilder {
  /// Field prefix for nested object filtering
  final String prefix;
  
  /// Create a FilterBuilder with optional field prefix for nested objects
  FilterBuilder({this.prefix = ''});
}

/// Root filter builder with all filtering logic
/// Extended by generated FilterBuilder classes for type-safe operations
abstract class RootFilterBuilder<T extends FirestoreFilter> extends FilterBuilder {
  RootFilterBuilder({super.prefix});

  /// Helper to get field path with prefix
  String getFieldPath(String fieldName) {
    return prefix.isEmpty ? fieldName : '$prefix.$fieldName';
  }

  /// Abstract method to wrap FirestoreFilter - implemented by generated classes
  T wrapFilter(FirestoreFilter coreFilter);

  /// Create OR filter with type safety (supports up to 30 filters)
  T or(
    T filter1,
    T filter2, [
    T? filter3,
    T? filter4,
    T? filter5,
    T? filter6,
    T? filter7,
    T? filter8,
    T? filter9,
    T? filter10,
    T? filter11,
    T? filter12,
    T? filter13,
    T? filter14,
    T? filter15,
    T? filter16,
    T? filter17,
    T? filter18,
    T? filter19,
    T? filter20,
    T? filter21,
    T? filter22,
    T? filter23,
    T? filter24,
    T? filter25,
    T? filter26,
    T? filter27,
    T? filter28,
    T? filter29,
    T? filter30,
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
    return wrapFilter(FirestoreFilter.or(allFilters));
  }

  /// Create AND filter with type safety (supports up to 30 filters)
  T and(
    T filter1,
    T filter2, [
    T? filter3,
    T? filter4,
    T? filter5,
    T? filter6,
    T? filter7,
    T? filter8,
    T? filter9,
    T? filter10,
    T? filter11,
    T? filter12,
    T? filter13,
    T? filter14,
    T? filter15,
    T? filter16,
    T? filter17,
    T? filter18,
    T? filter19,
    T? filter20,
    T? filter21,
    T? filter22,
    T? filter23,
    T? filter24,
    T? filter25,
    T? filter26,
    T? filter27,
    T? filter28,
    T? filter29,
    T? filter30,
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
    return wrapFilter(FirestoreFilter.and(allFilters));
  }

  /// Create string field filter
  T stringFilter(
    String fieldName, {
    String? isEqualTo,
    String? isNotEqualTo,
    List<String>? whereIn,
    List<String>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = getFieldPath(fieldName);
    if (isEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo));
    }
    if (isNotEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo));
    }
    if (whereIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn));
    }
    if (whereNotIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn));
    }
    if (isNull != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  /// Create numeric field filter
  T numericFilter<N extends num>(
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
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo));
    }
    if (isNotEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo));
    }
    if (isLessThan != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '<', value: isLessThan));
    }
    if (isLessThanOrEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '<=', value: isLessThanOrEqualTo));
    }
    if (isGreaterThan != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '>', value: isGreaterThan));
    }
    if (isGreaterThanOrEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '>=', value: isGreaterThanOrEqualTo));
    }
    if (whereIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn));
    }
    if (whereNotIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn));
    }
    if (isNull != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  /// Create boolean field filter
  T boolFilter(
    String fieldName, {
    bool? isEqualTo,
    bool? isNotEqualTo,
    List<bool>? whereIn,
    List<bool>? whereNotIn,
    bool? isNull,
  }) {
    final fieldPath = getFieldPath(fieldName);
    if (isEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo));
    }
    if (isNotEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo));
    }
    if (whereIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn));
    }
    if (whereNotIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn));
    }
    if (isNull != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  /// Create DateTime field filter
  T dateTimeFilter(
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
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo));
    }
    if (isNotEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo));
    }
    if (isLessThan != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '<', value: isLessThan));
    }
    if (isLessThanOrEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '<=', value: isLessThanOrEqualTo));
    }
    if (isGreaterThan != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '>', value: isGreaterThan));
    }
    if (isGreaterThanOrEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '>=', value: isGreaterThanOrEqualTo));
    }
    if (whereIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn));
    }
    if (whereNotIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn));
    }
    if (isNull != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  /// Create array field filter
  T arrayFilter<E>(
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
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo));
    }
    if (isNotEqualTo != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo));
    }
    if (arrayContains != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'array-contains', value: arrayContains));
    }
    if (arrayContainsAny != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'array-contains-any', value: arrayContainsAny));
    }
    if (whereIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn));
    }
    if (whereNotIn != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn));
    }
    if (isNull != null) {
      return wrapFilter(FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Base order by builder class
/// Extended by generated OrderByBuilder classes that provide type-safe ordering methods
abstract class OrderByBuilder {
  /// Field prefix for nested object ordering
  final String prefix;
  
  /// Create an OrderByBuilder with optional field prefix for nested objects
  OrderByBuilder({this.prefix = ''});
}

/// Update operation types
enum UpdateOperationType {
  set,           // Direct field assignment
  increment,     // Numeric increment/decrement
  arrayAdd,      // Array add operation
  arrayRemove,   // Array remove operation
  delete,        // Delete field
  serverTimestamp, // Server timestamp
  objectMerge,   // Object merge update
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
abstract class UpdateBuilder {
  /// Field prefix for nested object updates
  final String prefix;
  
  /// Create an UpdateBuilder with optional field prefix for nested objects
  UpdateBuilder({this.prefix = ''});
  
  /// Convert operations to Firestore update map
  static Map<String, dynamic> operationsToMap(List<UpdateOperation> operations) {
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
    final fieldsWithBothOps =
        arrayAdds.keys.toSet().intersection(arrayRemoves.keys.toSet());
    if (fieldsWithBothOps.isNotEmpty) {
      throw ArgumentError(
          'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update. Fields: $fieldsWithBothOps');
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
        fieldPath, UpdateOperationType.serverTimestamp, null);
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
      return FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo);
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo);
    }
    if (whereIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn);
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn);
    }
    if (isNull != null) {
      return FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null);
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
      return FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo);
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo);
    }
    if (whereIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn);
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn);
    }
    if (isNull != null) {
      return FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null);
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
      return FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo);
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo);
    }
    if (isLessThan != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '<', value: isLessThan);
    }
    if (isLessThanOrEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '<=', value: isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '>', value: isGreaterThan);
    }
    if (isGreaterThanOrEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '>=', value: isGreaterThanOrEqualTo);
    }
    if (whereIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn);
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn);
    }
    if (isNull != null) {
      return FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null);
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
      return FirestoreFilter.field(field: fieldPath, operator: '==', value: isEqualTo);
    }
    if (isNotEqualTo != null) {
      return FirestoreFilter.field(field: fieldPath, operator: '!=', value: isNotEqualTo);
    }
    if (arrayContains != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'array-contains', value: arrayContains);
    }
    if (arrayContainsAny != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'array-contains-any', value: arrayContainsAny);
    }
    if (whereIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'in', value: whereIn);
    }
    if (whereNotIn != null) {
      return FirestoreFilter.field(field: fieldPath, operator: 'not-in', value: whereNotIn);
    }
    if (isNull != null) {
      return FirestoreFilter.field(field: fieldPath, operator: isNull ? '==' : '!=', value: null);
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

/// Extension for OrderBy operations
extension OrderByBuilderExtensions on OrderByBuilder {
  /// Generate OrderBy field method
  OrderByField orderByField(String fieldName, {bool descending = false}) {
    final fieldPath = prefix.isEmpty ? fieldName : '$prefix.$fieldName';
    return OrderByField(fieldPath, descending: descending);
  }
}

/// Extension for Update operations
extension UpdateBuilderExtensions on UpdateBuilder {
  /// Get field path with prefix
  String getFieldPath(String fieldName) {
    return prefix.isEmpty ? fieldName : '$prefix.$fieldName';
  }
}
