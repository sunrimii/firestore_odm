import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🎯 Clean Map Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('Core operations - set, remove (Dart Map style)', () async {
      final user = ImmutableUser(
        id: 'core_operations_test',
        name: 'Core Operations Test User',
        email: 'core@operations.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test core operations with clean API
      await odm.immutableUsers(user.id).patch((update) => [
        // Set single values (like map[key] = value)
        update.settings.set('theme', 'dark'),
        update.settings.set('notifications', 'enabled'),
        // Remove single values (like map.remove(key))
        update.settings.remove('language'),
      ]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['notifications'], equals('enabled'));
      expect(result.settings.containsKey('language'), isFalse);

      print('✅ Core operations work correctly');
      print('   - set() for setting single values');
      print('   - remove() for removing single keys');
    });

    test('Bulk operations - addAll, removeWhere, clear', () async {
      final user = ImmutableUser(
        id: 'bulk_operations_test',
        name: 'Bulk Operations Test User',
        email: 'bulk@operations.test',
        age: 25,
        tags: ['test'].toIList(),
        scores: [95].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
          'oldSetting1': 'value1',
          'oldSetting2': 'value2',
        }.toIMap(),
        categories: {'tester'}.toISet(),
        rating: 4.0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test bulk operations
      await odm.immutableUsers(user.id).patch((update) => [
        // Add multiple entries at once (like map.addAll(other))
        update.settings.addAll({
          'notifications': 'enabled',
          'autoSave': 'true',
          'version': '2.0',
        }),
        // Remove multiple keys at once
        update.settings.removeWhere(['oldSetting1', 'oldSetting2']),
      ]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      
      // Check added entries
      expect(result!.settings['notifications'], equals('enabled'));
      expect(result.settings['autoSave'], equals('true'));
      expect(result.settings['version'], equals('2.0'));
      
      // Check removed entries
      expect(result.settings.containsKey('oldSetting1'), isFalse);
      expect(result.settings.containsKey('oldSetting2'), isFalse);
      
      // Check preserved entries
      expect(result.settings['theme'], equals('light'));
      expect(result.settings['language'], equals('en'));

      print('✅ Bulk operations work correctly');
      print('   - addAll() for adding multiple entries');
      print('   - removeWhere() for removing multiple keys');
    });

    test('Convenience operations - setAll', () async {
      final user = ImmutableUser(
        id: 'convenience_operations_test',
        name: 'Convenience Operations Test User',
        email: 'convenience@operations.test',
        age: 28,
        tags: ['test'].toIList(),
        scores: [85].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
          'notifications': 'disabled',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test convenience operations
      await odm.immutableUsers(user.id).patch(($) => [
        // $ individual entries
        $.settings.set('theme', 'dark'),
        $.settings.set('language', 'zh'),
        $.settings.set('newFeature', 'enabled'),
        // Set multiple keys to same value
        $.settings.setAll(['feature1', 'feature2'], 'enabled'),
        // Add multiple entries using Map
        $.settings.addAll({
          'advanced': 'true',
          'beta': 'enabled',
        }),
        // Add multiple entries using MapEntry iterable (more flexible)
        $.settings.addEntries([
          MapEntry('flexible1', 'value1'),
          MapEntry('flexible2', 'value2'),
        ]),
      ]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      
      // Check updated entries
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['language'], equals('zh'));
      expect(result.settings['newFeature'], equals('enabled'));
      
      // Check setAll entries
      expect(result.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));
      
      // Check addAll entries
      expect(result.settings['advanced'], equals('true'));
      expect(result.settings['beta'], equals('enabled'));
      
      // Check addEntries entries
      expect(result.settings['flexible1'], equals('value1'));
      expect(result.settings['flexible2'], equals('value2'));
      
      // Check preserved entries
      expect(result.settings['notifications'], equals('disabled'));

      print('✅ Convenience operations work correctly');
      print('   - set() for individual updates');
      print('   - setAll() for setting multiple keys to same value');
      print('   - addAll() for adding multiple entries from Map');
      print('   - addEntries() for adding from MapEntry iterable');
    });

    test('Mixed operations with arrays', () async {
      final user = ImmutableUser(
        id: 'mixed_operations_test',
        name: 'Mixed Operations Test User',
        email: 'mixed@operations.test',
        age: 35,
        tags: ['flutter', 'dart'].toIList(),
        scores: [92, 88].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
        }.toIMap(),
        categories: {'developer', 'architect'}.toISet(),
        rating: 4.7,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test mixing map and array operations
      await odm.immutableUsers(user.id).patch((update) => [
        // Map operations
        update.settings.set('notifications', 'enabled'),
        update.settings.addAll({
          'version': '3.0',
          'beta': 'enabled',
        }),
        update.settings.setAll(['feature1', 'feature2'], 'enabled'),
        
        // Array operations (still work alongside map operations)
        update.tags.add('firestore'),
        update.scores.add(95),
      ]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      
      // Check map operations
      expect(result!.settings['notifications'], equals('enabled'));
      expect(result.settings['version'], equals('3.0'));
      expect(result.settings['beta'], equals('enabled'));
      expect(result.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));
      
      // Check preserved map entries
      expect(result.settings['theme'], equals('light'));
      expect(result.settings['language'], equals('en'));
      
      // Check array operations still work
      expect(result.tags.contains('firestore'), isTrue);
      expect(result.scores.contains(95), isTrue);

      print('✅ Mixed operations work correctly');
      print('   - Map operations work alongside array operations');
      print('   - Clean, consistent API across all operations');
    });

    test('Edge cases and backward compatibility', () async {
      final user = ImmutableUser(
        id: 'edge_cases_test',
        name: 'Edge Cases Test User',
        email: 'edge@cases.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {
          'existing': 'value',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test edge cases and backward compatibility
      await odm.immutableUsers(user.id).patch((update) => [
        // Empty operations should be safe
        update.settings.addAll({}),
        update.settings.removeWhere([]),
        update.settings.setAll([], 'value'),
        
        // Operations on non-existent keys should be safe
        update.settings.remove('nonexistent'),
        update.settings.removeWhere(['nonexistent1', 'nonexistent2']),
        
        // Setting empty string values
        update.settings.set('emptyValue', ''),
        
        // Backward compatibility - deprecated methods should still work
        update.settings.setKey('backwardCompat', 'works'),
        update.settings.removeKey('nonexistent'),
      ]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      
      // Check that existing data is preserved
      expect(result!.settings['existing'], equals('value'));
      
      // Check empty value was set
      expect(result.settings.containsKey('emptyValue'), isTrue);
      expect(result.settings['emptyValue'], equals(''));
      
      // Check backward compatibility
      expect(result.settings['backwardCompat'], equals('works'));

      print('✅ Edge cases handled correctly');
      print('   - Empty operations are safe');
      print('   - Operations on non-existent keys are safe');
      print('   - Backward compatibility maintained');
    });
  });
}