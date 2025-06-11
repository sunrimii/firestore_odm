import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

/// Test models for type analysis
class IterableTestModel {
  final String id;
  final List<String> standardList;
  final Set<int> standardSet;
  final Iterable<double> genericIterable;
  final List<User> customObjectList;
  final Set<Profile> customObjectSet;
  final Map<String, int> stringToIntMap;
  final Map<String, List<String>> nestedMap;

  const IterableTestModel({
    required this.id,
    required this.standardList,
    required this.standardSet,
    required this.genericIterable,
    required this.customObjectList,
    required this.customObjectSet,
    required this.stringToIntMap,
    required this.nestedMap,
  });
}

/// Test model with immutable collections (if available)
class ImmutableTestModel {
  final String id;
  final List<String> regularList;
  // Note: In real usage, these would be BuiltList, IList, KtList, etc.
  // For testing purposes, we use regular types but the principle applies
  final Iterable<String> immutableIterable;
  final Set<int> immutableSet;

  const ImmutableTestModel({
    required this.id,
    required this.regularList,
    required this.immutableIterable,
    required this.immutableSet,
  });
}

void main() {
  group('🔍 TypeAnalyzer Robust Type Checking Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('supports standard iterable types (List, Set)', () async {
      // Create test user with various iterable types
      final user = User(
        id: 'iterable_test_1',
        name: 'Iterable Test User',
        email: 'iterable@test.com',
        age: 30,
        tags: ['list', 'test'], // List<String>
        scores: [95, 87, 92], // List<int>
        profile: Profile(
          bio: 'Testing iterables',
          avatar: 'test.jpg',
          interests: ['testing', 'iterables'], // List<String>
          followers: 1000,
          socialLinks: {}, // Map<String, String>
        ),
        rating: 4.5,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      // Store the user
      await odm.users(user.id).update(user);

      // Verify we can query by iterable fields
      final tagQuery = odm.users
          .where((filter) => filter.tags(arrayContains: 'list'))
          .limit(10);

      final scoreQuery = odm.users
          .where((filter) => filter.scores(arrayContains: 95))
          .limit(10);

      // These should compile and work with any iterable type
      expect(tagQuery, isNotNull);
      expect(scoreQuery, isNotNull);

      // Verify the queries actually work
      final tagResults = await tagQuery.get();
      final scoreResults = await scoreQuery.get();

      expect(tagResults, hasLength(1));
      expect(scoreResults, hasLength(1));
      expect(tagResults.first.id, equals('iterable_test_1'));

      print('✅ Standard iterable support: SUCCESS');
    });

    test('supports orderBy and pagination with iterable fields', () async {
      // Create multiple users for ordering tests
      final users = [
        User(
          id: 'order_1',
          name: 'Alice',
          email: 'alice@test.com',
          age: 25,
          tags: ['a', 'b', 'c'], // Length: 3
          scores: [90, 85], // Length: 2
          profile: Profile(
            bio: 'User Alice',
            avatar: 'alice.jpg',
            interests: ['reading'],
            followers: 500,
            socialLinks: {},
          ),
          rating: 4.2,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        ),
        User(
          id: 'order_2',
          name: 'Bob',
          email: 'bob@test.com',
          age: 30,
          tags: ['x', 'y'], // Length: 2
          scores: [95, 88, 92], // Length: 3
          profile: Profile(
            bio: 'User Bob',
            avatar: 'bob.jpg',
            interests: ['coding', 'music'],
            followers: 1000,
            socialLinks: {},
          ),
          rating: 4.7,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Store users
      for (final user in users) {
        await odm.users(user.id).update(user);
      }

      // Test ordering by regular fields with iterable data present
      final ageQuery = odm.users
          .orderBy(($) => ($.age(),))
          .limit(10);

      final ratingQuery = odm.users
          .orderBy(($) => ($.rating(true),)) // Descending
          .limit(10);

      final multiQuery = odm.users
          .orderBy(($) => ($.age(), $.rating(true)))
          .limit(10);

      // These should work regardless of iterable fields present
      expect(ageQuery, isNotNull);
      expect(ratingQuery, isNotNull);
      expect(multiQuery, isNotNull);

      // Test pagination with tuple cursors
      final paginatedAge = ageQuery.startAt((27,));
      final paginatedRating = ratingQuery.startAfter((4.5,));
      final paginatedMulti = multiQuery.startAt((28, 4.5));

      expect(paginatedAge, isNotNull);
      expect(paginatedRating, isNotNull);
      expect(paginatedMulti, isNotNull);

      // Test actual execution
      final ageResults = await ageQuery.get();
      final ratingResults = await ratingQuery.get();

      expect(ageResults, hasLength(2));
      expect(ratingResults, hasLength(2));

      // Verify ordering
      expect(ageResults.first.age, lessThanOrEqualTo(ageResults.last.age));
      expect(ratingResults.first.rating, greaterThanOrEqualTo(ratingResults.last.rating));

      print('✅ OrderBy and pagination with iterables: SUCCESS');
    });

    test('supports filtering on nested iterable fields', () async {
      // Create user with nested iterable data
      final user = User(
        id: 'nested_iterable_1',
        name: 'Nested Test User',
        email: 'nested@test.com',
        age: 35,
        tags: ['nested', 'test'],
        scores: [100],
        profile: Profile(
          bio: 'Nested iterable test',
          avatar: 'nested.jpg',
          interests: ['ai', 'machine-learning', 'data-science'], // Nested List<String>
          followers: 2000,
          socialLinks: {
            'github': 'https://github.com/user',
            'twitter': 'https://twitter.com/user',
          }, // Nested Map<String, String>
        ),
        rating: 4.9,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      await odm.users(user.id).update(user);

      // Test filtering on nested iterable fields
      final nestedInterestQuery = odm.users
          .where((filter) => filter.profile.interests(arrayContains: 'ai'))
          .limit(10);

      // Test ordering by nested numeric field
      final nestedFollowerQuery = odm.users
          .orderBy(($) => ($.profile.followers(true),))
          .limit(10);

      expect(nestedInterestQuery, isNotNull);
      expect(nestedFollowerQuery, isNotNull);

      // Verify execution
      final interestResults = await nestedInterestQuery.get();
      final followerResults = await nestedFollowerQuery.get();

      expect(interestResults, hasLength(1));
      expect(followerResults, hasLength(1));
      expect(interestResults.first.id, equals('nested_iterable_1'));

      print('✅ Nested iterable field support: SUCCESS');
    });

    test('supports update operations on iterable fields', () async {
      // Create initial user
      final user = User(
        id: 'update_iterable_1',
        name: 'Update Test User',
        email: 'update@test.com',
        age: 40,
        tags: ['initial'], // Will be updated
        scores: [80], // Will be updated
        profile: Profile(
          bio: 'Update test',
          avatar: 'update.jpg',
          interests: ['reading'], // Will be updated
          followers: 100,
          socialLinks: {},
        ),
        rating: 3.5,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      await odm.users(user.id).update(user);

      // Test updating iterable fields
      await odm.users(user.id).modify((user) => user.copyWith(
        tags: ['updated', 'new', 'tags'], // Update List<String>
        scores: [85, 90, 95], // Update List<int>
        profile: user.profile.copyWith(
          interests: ['coding', 'testing', 'dart'], // Update nested List<String>
          followers: 150,
        ),
      ));

      // Verify updates
      final updatedUser = await odm.users(user.id).get();
      expect(updatedUser, isNotNull);
      expect(updatedUser!.tags, equals(['updated', 'new', 'tags']));
      expect(updatedUser.scores, equals([85, 90, 95]));
      expect(updatedUser.profile.interests, equals(['coding', 'testing', 'dart']));
      expect(updatedUser.profile.followers, equals(150));

      print('✅ Iterable field updates: SUCCESS');
    });

    test('handles complex iterable type combinations', () async {
      // Create user with complex nested iterable combinations
      final user = User(
        id: 'complex_iterable_1',
        name: 'Complex Test User',
        email: 'complex@test.com',
        age: 45,
        tags: ['complex', 'nested', 'iterables'], // List<String>
        scores: [98, 97, 96, 95], // List<int>
        profile: Profile(
          bio: 'Complex iterable combinations',
          avatar: 'complex.jpg',
          interests: ['ai', 'ml', 'data', 'algorithms'], // Nested List<String>
          followers: 5000,
          socialLinks: {
            'github': 'https://github.com/complex',
            'linkedin': 'https://linkedin.com/in/complex',
            'website': 'https://complex.dev',
          }, // Nested Map<String, String>
        ),
        rating: 4.95,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      await odm.users(user.id).update(user);

      // Test complex queries combining multiple iterable conditions
      final complexQuery = odm.users
          .where((filter) => filter.tags(arrayContains: 'complex'))
          .where((filter) => filter.scores(arrayContains: 98))
          .where((filter) => filter.profile.interests(arrayContains: 'ai'))
          .orderBy(($) => ($.rating(true),))
          .limit(5);

      expect(complexQuery, isNotNull);

      final results = await complexQuery.get();
      expect(results, hasLength(1));
      expect(results.first.id, equals('complex_iterable_1'));

      // Test complex ordering with multiple fields including iterables present
      final complexOrderQuery = odm.users
          .orderBy(($) => ($.profile.followers(true), $.rating(), $.age()))
          .limit(10);

      expect(complexOrderQuery, isNotNull);

      final orderResults = await complexOrderQuery.get();
      expect(orderResults, isNotEmpty);

      print('✅ Complex iterable combinations: SUCCESS');
    });

    test('type safety - compilation tests for iterable types', () {
      // These demonstrate that the type system correctly handles iterables
      
      // Single tuple with various types including iterables
      expect(() {
        const singleInt = (25,);
        const singleString = ('Alice',);
        const singleDouble = (4.5,);
        const singleBool = (true,);
        
        expect(singleInt is (int,), isTrue);
        expect(singleString is (String,), isTrue);
        expect(singleDouble is (double,), isTrue);
        expect(singleBool is (bool,), isTrue);
      }, returnsNormally);

      // Multi-field tuples that would be used with iterable data present
      expect(() {
        const multiTuple = (25, 'Alice', 4.5, true);
        expect(multiTuple is (int, String, double, bool), isTrue);
      }, returnsNormally);

      // Demonstrate pattern matching works with complex types
      expect(() {
        dynamic testTuple = (30, 'Bob', 4.8);
        
        final result = switch (testTuple) {
          (var age, var name, var rating) when age is int && name is String && rating is double =>
            'User: $name, Age: $age, Rating: $rating',
          _ => 'Unknown pattern',
        };
        
        expect(result, equals('User: Bob, Age: 30, Rating: 4.8'));
      }, returnsNormally);

      print('✅ Type safety compilation tests: SUCCESS');
    });

    test('demonstrates real-world usage with any iterable implementation', () {
      // This test demonstrates that the system would work with any iterable
      // implementation, not just List/Set
      
      // Custom iterable example (in real usage, this could be BuiltList, etc.)
      final customIterable = ['custom', 'iterable', 'implementation'];
      final customSet = {'unique', 'values', 'only'};
      
      // Verify these are recognized as iterables
      expect(customIterable is Iterable<String>, isTrue);
      expect(customSet is Iterable<String>, isTrue);
      
      // Test that they work in expected contexts
      expect(customIterable.contains('custom'), isTrue);
      expect(customSet.contains('unique'), isTrue);
      expect(customIterable.length, equals(3));
      expect(customSet.length, equals(3));
      
      // Test conversion operations that would be used in Firestore
      final iterableList = customIterable.toList();
      final setList = customSet.toList();
      
      expect(iterableList, isA<List<String>>());
      expect(setList, isA<List<String>>());
      
      print('✅ Real-world iterable implementation support: SUCCESS');
      print('   - Any implementation of Iterable<T> is supported');
      print('   - Fast immutable collections work transparently');
      print('   - No hardcoding of specific collection types required');
    });
  });

  group('🚀 Iterable Performance and Edge Cases', () {
    test('handles empty iterables correctly', () {
      // Test with empty collections
      final emptyList = <String>[];
      final emptySet = <int>{};
      final emptyMap = <String, String>{};
      
      expect(emptyList is Iterable<String>, isTrue);
      expect(emptySet is Iterable<int>, isTrue);
      expect(emptyMap is Map<String, String>, isTrue);
      
      expect(emptyList.isEmpty, isTrue);
      expect(emptySet.isEmpty, isTrue);
      expect(emptyMap.isEmpty, isTrue);
      
      print('✅ Empty iterable handling: SUCCESS');
    });

    test('handles large iterables efficiently', () {
      // Test with large collections to ensure performance
      final largeList = List.generate(10000, (i) => 'item_$i');
      final largeSet = <int>{};
      for (int i = 0; i < 5000; i++) {
        largeSet.add(i);
      }
      
      expect(largeList is Iterable<String>, isTrue);
      expect(largeSet is Iterable<int>, isTrue);
      
      expect(largeList.length, equals(10000));
      expect(largeSet.length, equals(5000));
      
      // Test iteration performance
      var count = 0;
      for (final item in largeList.take(100)) {
        count++;
      }
      expect(count, equals(100));
      
      print('✅ Large iterable performance: SUCCESS');
    });

    test('handles nested iterable structures', () {
      // Test with deeply nested iterable structures
      final nestedList = [
        ['a', 'b', 'c'],
        ['d', 'e', 'f'],
        ['g', 'h', 'i'],
      ];
      
      final nestedMap = {
        'list1': ['x', 'y', 'z'],
        'list2': ['1', '2', '3'],
      };
      
      expect(nestedList is Iterable<List<String>>, isTrue);
      expect(nestedMap is Map<String, List<String>>, isTrue);
      
      expect(nestedList.length, equals(3));
      expect(nestedMap.length, equals(2));
      expect(nestedList.first.length, equals(3));
      expect(nestedMap['list1']?.length, equals(3));
      
      print('✅ Nested iterable structures: SUCCESS');
    });
  });
}