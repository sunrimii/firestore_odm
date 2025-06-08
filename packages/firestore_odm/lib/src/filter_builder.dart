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
    final updates = <String, dynamic>{};
    
    for (final op in operations) {
      switch (op.type) {
        case UpdateOperationType.set:
          updates[op.field] = op.value;
          break;
        case UpdateOperationType.increment:
          updates[op.field] = FieldValue.increment(op.value);
          break;
        case UpdateOperationType.arrayAdd:
          updates[op.field] = FieldValue.arrayUnion([op.value]);
          break;
        case UpdateOperationType.arrayRemove:
          updates[op.field] = FieldValue.arrayRemove([op.value]);
          break;
        case UpdateOperationType.delete:
          updates[op.field] = FieldValue.delete();
          break;
        case UpdateOperationType.serverTimestamp:
          updates[op.field] = FieldValue.serverTimestamp();
          break;
        case UpdateOperationType.objectMerge:
          if (op.value is Map<String, dynamic>) {
            for (final entry in (op.value as Map<String, dynamic>).entries) {
              final nestedField = op.field.isEmpty ? entry.key : '${op.field}.${entry.key}';
              updates[nestedField] = entry.value;
            }
          }
          break;
      }
    }
    
    return updates;
  }
}
