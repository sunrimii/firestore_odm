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

/// Base filter builder class
abstract class FilterBuilder {
  final List<String> _fields = [];
  final List<dynamic> _values = [];
  final List<String> _operators = [];
  final String prefix;
  
  /// Create a FilterBuilder with optional field prefix for nested objects
  FilterBuilder({this.prefix = ''});
  
  
  /// Add a field filter condition
 void addCondition(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
    String? contains,
  }) {
     final fullField = prefix.isEmpty ? field : '$prefix$field';
     
     if (isEqualTo != null) {
       _fields.add(fullField);
       _values.add(isEqualTo);
       _operators.add('==');
     }
     if (isNotEqualTo != null) {
       _fields.add(fullField);
       _values.add(isNotEqualTo);
       _operators.add('!=');
     }
     if (isLessThan != null) {
       _fields.add(fullField);
       _values.add(isLessThan);
       _operators.add('<');
     }
     if (isLessThanOrEqualTo != null) {
       _fields.add(fullField);
       _values.add(isLessThanOrEqualTo);
       _operators.add('<=');
     }
     if (isGreaterThan != null) {
       _fields.add(fullField);
       _values.add(isGreaterThan);
       _operators.add('>');
     }
     if (isGreaterThanOrEqualTo != null) {
       _fields.add(fullField);
       _values.add(isGreaterThanOrEqualTo);
       _operators.add('>=');
     }
     if (arrayContains != null) {
       _fields.add(fullField);
       _values.add(arrayContains);
       _operators.add('array-contains');
     }
     if (arrayContainsAny != null) {
       _fields.add(fullField);
       _values.add(arrayContainsAny);
       _operators.add('array-contains-any');
     }
     if (whereIn != null) {
       _fields.add(fullField);
       _values.add(whereIn);
       _operators.add('in');
     }
     if (whereNotIn != null) {
       _fields.add(fullField);
       _values.add(whereNotIn);
       _operators.add('not-in');
     }
     if (isNull != null) {
       _fields.add(fullField);
       _values.add(null);
       _operators.add(isNull ? '==' : '!=');
     }
     if (contains != null) {
       // For text search, we'll use >= and < with the text + '\uf8ff'
       _fields.add(fullField);
       _values.add(contains);
       _operators.add('>=');
       _fields.add(fullField);
       _values.add(contains + '\uf8ff');
       _operators.add('<');
     }
   }

  /// Build a FirestoreFilter from the current builder state
  FirestoreFilter build() {
    if (_fields.length == 1) {
      return FirestoreFilter.field(
        field: _fields[0],
        operator: _operators[0],
        value: _values[0],
      );
    } else if (_fields.length > 1) {
      // Multiple conditions are combined with AND by default
      final filters = <FirestoreFilter>[];
      for (int i = 0; i < _fields.length; i++) {
        filters.add(FirestoreFilter.field(
          field: _fields[i],
          operator: _operators[i],
          value: _values[i],
        ));
      }
      return FirestoreFilter.and(filters);
    } else {
      throw StateError('No conditions added to filter builder');
    }
  }

  /// Apply filters to a Firestore query
  firestore.Query<Map<String, dynamic>> applyToQuery(firestore.Query<Map<String, dynamic>> query) {
    firestore.Query<Map<String, dynamic>> result = query;

    // Apply regular field filters
    for (int i = 0; i < _fields.length; i++) {
      final field = _fields[i];
      final operator = _operators[i];
      final value = _values[i];

      switch (operator) {
        case '==':
          result = result.where(field, isEqualTo: value);
          break;
        case '!=':
          result = result.where(field, isNotEqualTo: value);
          break;
        case '<':
          result = result.where(field, isLessThan: value);
          break;
        case '<=':
          result = result.where(field, isLessThanOrEqualTo: value);
          break;
        case '>':
          result = result.where(field, isGreaterThan: value);
          break;
        case '>=':
          result = result.where(field, isGreaterThanOrEqualTo: value);
          break;
        case 'array-contains':
          result = result.where(field, arrayContains: value);
          break;
        case 'array-contains-any':
          result = result.where(field, arrayContainsAny: value);
          break;
        case 'in':
          result = result.where(field, whereIn: value);
          break;
        case 'not-in':
          result = result.where(field, whereNotIn: value);
          break;
      }
    }

    return result;
  }

}


