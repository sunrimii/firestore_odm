import 'package:test/test.dart';
import '../lib/src/filter_builder.dart';

void main() {
  group('FilterBuilder Tests', () {
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
  });
}

// Test implementation of FilterBuilder
class TestFilterBuilder extends FilterBuilder {
  // This class inherits all the functionality from FilterBuilder
  // and can be used for testing without needing generated code
}