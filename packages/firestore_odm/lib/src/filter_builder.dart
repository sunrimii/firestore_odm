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
