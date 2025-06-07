import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
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
