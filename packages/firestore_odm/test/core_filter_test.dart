import 'package:test/test.dart';

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
    if (isEqualTo != null) {
      _fields.add(field);
      _values.add(isEqualTo);
      _operators.add('==');
    }
    if (isNotEqualTo != null) {
      _fields.add(field);
      _values.add(isNotEqualTo);
      _operators.add('!=');
    }
    if (isLessThan != null) {
      _fields.add(field);
      _values.add(isLessThan);
      _operators.add('<');
    }
    if (isLessThanOrEqualTo != null) {
      _fields.add(field);
      _values.add(isLessThanOrEqualTo);
      _operators.add('<=');
    }
    if (isGreaterThan != null) {
      _fields.add(field);
      _values.add(isGreaterThan);
      _operators.add('>');
    }
    if (isGreaterThanOrEqualTo != null) {
      _fields.add(field);
      _values.add(isGreaterThanOrEqualTo);
      _operators.add('>=');
    }
    if (arrayContains != null) {
      _fields.add(field);
      _values.add(arrayContains);
      _operators.add('array-contains');
    }
    if (arrayContainsAny != null) {
      _fields.add(field);
      _values.add(arrayContainsAny);
      _operators.add('array-contains-any');
    }
    if (whereIn != null) {
      _fields.add(field);
      _values.add(whereIn);
      _operators.add('in');
    }
    if (whereNotIn != null) {
      _fields.add(field);
      _values.add(whereNotIn);
      _operators.add('not-in');
    }
    if (isNull != null) {
      _fields.add(field);
      _values.add(null);
      _operators.add(isNull ? '==' : '!=');
    }
    if (contains != null) {
      // For text search, we'll use >= and < with the text + '\uf8ff'
      _fields.add(field);
      _values.add(contains);
      _operators.add('>=');
      _fields.add(field);
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
}

// Test implementation of FilterBuilder
class TestFilterBuilder extends FilterBuilder {
  // This class inherits all the functionality from FilterBuilder
  // and can be used for testing without needing generated code
}

void main() {
  group('Core Filter Tests', () {
    test('FirestoreFilter field creation should work', () {
      // Test basic field filter creation
      final filter = FirestoreFilter.field(
        field: 'age',
        operator: '>',
        value: 18,
      );

      expect(filter.type, FilterType.field);
      expect(filter.field, 'age');
      expect(filter.operator, '>');
      expect(filter.value, 18);
      print('✅ Field filter creation test passed!');
    });

    test('FirestoreFilter AND creation should work', () {
      // Test AND filter creation
      final filter1 = FirestoreFilter.field(
        field: 'age',
        operator: '>',
        value: 18,
      );
      
      final filter2 = FirestoreFilter.field(
        field: 'isActive',
        operator: '==',
        value: true,
      );

      final andFilter = FirestoreFilter.and([filter1, filter2]);

      expect(andFilter.type, FilterType.and);
      expect(andFilter.filters, isNotNull);
      expect(andFilter.filters!.length, 2);
      print('✅ AND filter creation test passed!');
    });

    test('FirestoreFilter OR creation should work', () {
      // Test OR filter creation
      final filter1 = FirestoreFilter.field(
        field: 'isPremium',
        operator: '==',
        value: true,
      );
      
      final filter2 = FirestoreFilter.field(
        field: 'age',
        operator: '>',
        value: 30,
      );

      final orFilter = FirestoreFilter.or([filter1, filter2]);

      expect(orFilter.type, FilterType.or);
      expect(orFilter.filters, isNotNull);
      expect(orFilter.filters!.length, 2);
      print('✅ OR filter creation test passed!');
    });

    test('FilterBuilder addCondition should work', () {
      // Test FilterBuilder functionality
      final builder = TestFilterBuilder();
      
      builder.addCondition('age', isGreaterThan: 18);
      builder.addCondition('isActive', isEqualTo: true);
      
      final filter = builder.build();
      
      expect(filter.type, FilterType.and);
      expect(filter.filters, isNotNull);
      expect(filter.filters!.length, 2);
      print('✅ FilterBuilder addCondition test passed!');
    });

    test('Complex nested filters should work', () {
      // Test complex nested filter structure
      final ageFilter = FirestoreFilter.field(
        field: 'age',
        operator: '>',
        value: 18,
      );
      
      final premiumFilter = FirestoreFilter.field(
        field: 'isPremium',
        operator: '==',
        value: true,
      );
      
      final activeFilter = FirestoreFilter.field(
        field: 'isActive',
        operator: '==',
        value: true,
      );
      
      // (age > 18 AND isPremium) OR isActive
      final andFilter = FirestoreFilter.and([ageFilter, premiumFilter]);
      final complexFilter = FirestoreFilter.or([andFilter, activeFilter]);
      
      expect(complexFilter.type, FilterType.or);
      expect(complexFilter.filters!.length, 2);
      expect(complexFilter.filters![0].type, FilterType.and);
      expect(complexFilter.filters![1].type, FilterType.field);
      print('✅ Complex nested filters test passed!');
    });

    test('FilterBuilder different operators should work', () {
      final builder = TestFilterBuilder();
      
      // Test different operators
      builder.addCondition('age', isGreaterThan: 18);
      builder.addCondition('rating', isLessThanOrEqualTo: 5.0);
      builder.addCondition('name', isNotEqualTo: 'test');
      builder.addCondition('email', isNull: false);
      
      final filter = builder.build();
      
      expect(filter.type, FilterType.and);
      expect(filter.filters!.length, 4);
      
      // Check individual filters
      final filters = filter.filters!;
      expect(filters[0].operator, '>');
      expect(filters[1].operator, '<=');
      expect(filters[2].operator, '!=');
      expect(filters[3].operator, '!='); // isNull: false becomes != null
      
      print('✅ FilterBuilder different operators test passed!');
    });

    test('FilterBuilder array operations should work', () {
      final builder = TestFilterBuilder();
      
      builder.addCondition('tags', arrayContains: 'flutter');
      builder.addCondition('categories', arrayContainsAny: ['tech', 'mobile']);
      builder.addCondition('status', whereIn: ['active', 'pending']);
      builder.addCondition('type', whereNotIn: ['deleted', 'archived']);
      
      final filter = builder.build();
      
      expect(filter.type, FilterType.and);
      expect(filter.filters!.length, 4);
      
      final filters = filter.filters!;
      expect(filters[0].operator, 'array-contains');
      expect(filters[1].operator, 'array-contains-any');
      expect(filters[2].operator, 'in');
      expect(filters[3].operator, 'not-in');
      
      print('✅ FilterBuilder array operations test passed!');
    });

    test('FilterBuilder text search should work', () {
      final builder = TestFilterBuilder();
      
      builder.addCondition('title', contains: 'flutter');
      
      final filter = builder.build();
      
      expect(filter.type, FilterType.and);
      expect(filter.filters!.length, 2); // contains creates two conditions
      
      final filters = filter.filters!;
      expect(filters[0].operator, '>=');
      expect(filters[0].value, 'flutter');
      expect(filters[1].operator, '<');
      expect(filters[1].value, 'flutter\uf8ff');
      
      print('✅ FilterBuilder text search test passed!');
    });

    test('Nested filter design should work', () {
      // Test the new nested filter design that we want to implement
      // This simulates: filter.and(
      //   filter.age(isGreaterThan: 18),
      //   filter.profile.followers(isGreaterThan: 100),
      //   filter.profile.socialLinks.github(isNotEqualTo: null),
      //   filter.profile.socialLinks.contact.address.city(isEqualTo: "Hong Kong"),
      // )
      
      final ageFilter = FirestoreFilter.field(
        field: 'age',
        operator: '>',
        value: 18,
      );
      
      final followersFilter = FirestoreFilter.field(
        field: 'profile.followers',
        operator: '>',
        value: 100,
      );
      
      final githubFilter = FirestoreFilter.field(
        field: 'profile.socialLinks.github',
        operator: '!=',
        value: null,
      );
      
      final cityFilter = FirestoreFilter.field(
        field: 'profile.socialLinks.contact.address.city',
        operator: '==',
        value: 'Hong Kong',
      );
      
      final complexAndFilter = FirestoreFilter.and([
        ageFilter,
        followersFilter,
        githubFilter,
        cityFilter,
      ]);
      
      expect(complexAndFilter.type, FilterType.and);
      expect(complexAndFilter.filters!.length, 4);
      
      // Verify each filter
      final filters = complexAndFilter.filters!;
      expect(filters[0].field, 'age');
      expect(filters[0].operator, '>');
      expect(filters[0].value, 18);
      
      expect(filters[1].field, 'profile.followers');
      expect(filters[1].operator, '>');
      expect(filters[1].value, 100);
      
      expect(filters[2].field, 'profile.socialLinks.github');
      expect(filters[2].operator, '!=');
      expect(filters[2].value, null);
      
      expect(filters[3].field, 'profile.socialLinks.contact.address.city');
      expect(filters[3].operator, '==');
      expect(filters[3].value, 'Hong Kong');
      
      print('✅ Nested filter design test passed!');
    });
  });
}