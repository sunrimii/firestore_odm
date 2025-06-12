import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🚀 Fast Immutable Collections Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should create and retrieve user with IList tags', () async {
      // Create user with IList tags
      final user = ImmutableUser(
        id: 'immutable_user_1',
        name: 'Alice Immutable',
        email: 'alice@immutable.com',
        age: 28,
        tags: ['flutter', 'dart', 'immutable'].toIList(),
        scores: [95, 88, 92].toIList(),
        settings: {'theme': 'dark', 'language': 'en'}.toIMap(),
        categories: {'developer', 'flutter-expert'}.toISet(),
        rating: 4.8,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await odm.immutableUsers(user.id).update(user);

      // Retrieve and verify
      final retrieved = await odm.immutableUsers(user.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Alice Immutable'));
      expect(retrieved.tags.length, equals(3));
      expect(retrieved.tags.contains('flutter'), isTrue);
      expect(retrieved.tags.contains('dart'), isTrue);
      expect(retrieved.tags.contains('immutable'), isTrue);

      print('✅ IList tags: ${retrieved.tags}');
    });

    test('should handle IList scores operations', () async {
      final user = ImmutableUser(
        id: 'immutable_user_2',
        name: 'Bob Scores',
        email: 'bob@scores.com',
        age: 32,
        tags: ['testing'].toIList(),
        scores: [85, 90, 78, 95, 88].toIList(),
        settings: {'notifications': 'enabled'}.toIMap(),
        categories: {'tester', 'qa'}.toISet(),
        rating: 4.2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      final retrieved = await odm.immutableUsers(user.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.scores.length, equals(5));
      expect(retrieved.scores.first, equals(85));
      expect(retrieved.scores.last, equals(88));

      // Test IList immutability - these should work without modifying original
      final highScores = retrieved.scores.where((score) => score >= 90);
      expect(highScores.length, equals(2)); // 90 and 95

      print('✅ IList scores: ${retrieved.scores}');
      print('✅ High scores: ${highScores.toList()}');
    });

    test('should handle IMap settings operations', () async {
      final user = ImmutableUser(
        id: 'immutable_user_3',
        name: 'Charlie Settings',
        email: 'charlie@settings.com',
        age: 35,
        tags: ['configuration'].toIList(),
        scores: [100].toIList(),
        settings: {
          'theme': 'light',
          'language': 'zh',
          'timezone': 'Asia/Hong_Kong',
          'notifications': 'disabled',
        }.toIMap(),
        categories: {'admin', 'config-master'}.toISet(),
        rating: 5.0,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      final retrieved = await odm.immutableUsers(user.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.settings.length, equals(4));
      expect(retrieved.settings['theme'], equals('light'));
      expect(retrieved.settings['language'], equals('zh'));
      expect(retrieved.settings['timezone'], equals('Asia/Hong_Kong'));
      expect(retrieved.settings.containsKey('notifications'), isTrue);

      print('✅ IMap settings: ${retrieved.settings}');
    });

    test('should handle ISet categories operations', () async {
      final user = ImmutableUser(
        id: 'immutable_user_4',
        name: 'Diana Categories',
        email: 'diana@categories.com',
        age: 29,
        tags: ['categorization'].toIList(),
        scores: [92, 87].toIList(),
        settings: {'view': 'grid'}.toIMap(),
        categories: {
          'developer',
          'designer',
          'product-manager',
          'team-lead',
          'flutter-expert',
        }.toISet(),
        rating: 4.6,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      final retrieved = await odm.immutableUsers(user.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.categories.length, equals(5));
      expect(retrieved.categories.contains('developer'), isTrue);
      expect(retrieved.categories.contains('designer'), isTrue);
      expect(retrieved.categories.contains('flutter-expert'), isTrue);

      // Test ISet operations
      final techCategories = retrieved.categories.where(
        (cat) => cat.contains('developer') || cat.contains('flutter'),
      );
      expect(techCategories.length, equals(2));

      print('✅ ISet categories: ${retrieved.categories}');
      print('✅ Tech categories: ${techCategories.toList()}');
    });

    test('should demonstrate fast immutable collections benefits', () async {
      // Create user with immutable collections
      final user = ImmutableUser(
        id: 'benefits_user',
        name: 'Benefits Demo',
        email: 'benefits@test.com',
        age: 30,
        tags: ['immutable', 'fast', 'collections'].toIList(),
        scores: [90, 85, 95].toIList(),
        settings: {'performance': 'high', 'memory': 'efficient'}.toIMap(),
        categories: {'performance', 'memory', 'immutable'}.toISet(),
        rating: 4.8,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);
      final retrieved = await odm.immutableUsers(user.id).get();

      expect(retrieved, isNotNull);

      // Test immutability - operations return new collections without modifying original
      final originalTags = retrieved!.tags;
      final newTags = originalTags.add('new-tag');

      expect(originalTags.length, equals(3));
      expect(newTags.length, equals(4));
      expect(originalTags.contains('new-tag'), isFalse);
      expect(newTags.contains('new-tag'), isTrue);

      // Test efficient operations
      final filteredScores = retrieved.scores.where((score) => score > 85);
      expect(filteredScores.length, equals(2));

      // Test map operations
      final updatedSettings = retrieved.settings.add('cache', 'enabled');
      expect(retrieved.settings.length, equals(2));
      expect(updatedSettings.length, equals(3));

      print(
        '✅ Immutability preserved: original tags length = ${originalTags.length}',
      );
      print('✅ New collection created: new tags length = ${newTags.length}');
      print('✅ Efficient filtering: ${filteredScores.length} high scores');
      print(
        '✅ Map operations: ${updatedSettings.length} settings after update',
      );
    });
  });
}
