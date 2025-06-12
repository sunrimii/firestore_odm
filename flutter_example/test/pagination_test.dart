import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('Strongly-Typed Pagination System Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('single field orderBy with strongly-typed int pagination', () {
      // Order by age field (int) - pagination should accept int cursor values
      final query = odm.users
          .orderBy(
            ($) => ($.age(),),
          ) // NEW: Tuple syntax FirestoreQuery<TestSchema, User, (int,)>
          .startAt((25,)) // ✓ Should accept (int,) tuple cursor value
          .endBefore((65,)); // ✓ Should accept (int,) tuple cursor value

      expect(query, isNotNull);

      // Test other pagination methods with int cursors
      final query2 = odm.users
          .orderBy(($) => ($.age(),)) // NEW: Tuple syntax
          .startAfter((30,)) // ✓ (int,) tuple cursor
          .endAt((60,)); // ✓ (int,) tuple cursor

      expect(query2, isNotNull);
    });

    test('multiple field orderBy with strongly-typed tuple pagination', () {
      // Order by age (int) + name (String) - pagination should accept (int, String) tuple
      final query = odm.users
          .orderBy(
            ($) => ($.age(), $.name()),
          ) // NEW: Tuple syntax FirestoreQuery<TestSchema, User, (int, String)>
          .startAt((25, 'Alice')) // ✓ Should accept (int, String) tuple
          .endBefore((65, 'Zoe')); // ✓ Should accept (int, String) tuple

      expect(query, isNotNull);

      // Test other pagination methods with tuple cursors
      final query2 = odm.users
          .orderBy(($) => ($.age(), $.name())) // NEW: Tuple syntax
          .startAfter((30, 'John')) // ✓ (int, String) tuple
          .endAt((60, 'Smith')); // ✓ (int, String) tuple

      expect(query2, isNotNull);
    });

    test(
      'complex multi-field orderBy with strongly-typed triple tuple pagination',
      () {
        // Order by rating (double) + age (int) + name (String)
        final query = odm.users
            .orderBy(
              ($) => ($.rating(descending: true), $.age(), $.name()),
            ) // NEW: Tuple syntax (double, int, String)
            .startAfter((4.5, 30, 'John')) // ✓ (double, int, String) tuple
            .endAt((2.0, 60, 'Zoe')); // ✓ (double, int, String) tuple

        expect(query, isNotNull);
      },
    );

    test('string field orderBy with strongly-typed String pagination', () {
      // Order by name field (String) - pagination should accept String cursor values
      final query = odm.users
          .orderBy(($) => ($.name(),)) // NEW: Tuple syntax (String,)
          .startAt(('Alice',)) // ✓ Should accept (String,) tuple cursor
          .endBefore(('Zoe',)); // ✓ Should accept (String,) tuple cursor

      expect(query, isNotNull);
    });

    test('double field orderBy with strongly-typed double pagination', () {
      // Order by rating field (double) - pagination should accept double cursor values
      final query = odm.users
          .orderBy(($) => ($.rating(descending: true),)) // NEW: Tuple syntax (double,)
          .startAt((4.5,)) // ✓ Should accept (double,) tuple cursor
          .endBefore((2.0,)); // ✓ Should accept (double,) tuple cursor

      expect(query, isNotNull);
    });

    test('DateTime field orderBy with strongly-typed DateTime pagination', () {
      // Order by createdAt field (DateTime) - pagination should accept DateTime cursor values
      final timestamp1 = DateTime(2023, 1, 1);
      final timestamp2 = DateTime(2024, 1, 1);

      final query = odm.users
          .orderBy(($) => ($.createdAt(),)) // NEW: Tuple syntax (DateTime,)
          .startAt((timestamp1,)) // ✓ Should accept (DateTime,) tuple cursor
          .endBefore((timestamp2,)); // ✓ Should accept (DateTime,) tuple cursor

      expect(query, isNotNull);
    });

    test('nested field orderBy with strongly-typed int pagination', () {
      // Order by nested profile.followers field (int) - pagination should accept int cursor
      final query = odm.users
          .orderBy(
            ($) => ($.profile.followers(descending: true),),
          ) // NEW: Tuple syntax (int,) - nested field!
          .startAt((
            1000,
          )) // ✓ Should accept (int,) tuple cursor for followers field
          .endBefore((10,)); // ✓ Should accept (int,) tuple cursor

      expect(query, isNotNull);
    });

    test('object-based pagination with automatic cursor extraction', () {
      // Create sample user for object-based pagination testing
      final sampleUser = User(
        id: 'sample_id',
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
        tags: ['developer'],
        scores: [95, 88],
        profile: Profile(
          bio: 'Developer',
          followers: 1500,
          avatar: 'https://example.com/avatar.jpg',
          socialLinks: {'twitter': '@johndoe'},
          interests: ['coding', 'music'],
        ),
        rating: 4.3,
        isActive: true,
        isPremium: false,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Single field object-based pagination
      final singleQuery = odm.users
          .orderBy(($) => ($.age(),)) // NEW: Tuple syntax (int,)
          .startAtObject(sampleUser); // Should extract age (30) automatically

      expect(singleQuery, isNotNull);

      // Multi-field object-based pagination
      final multiQuery = odm.users
          .orderBy(
            ($) => ($.age(), $.name()),
          ) // NEW: Tuple syntax (int, String)
          .startAfterObject(
            sampleUser,
          ); // Should extract (30, 'John Doe') automatically

      expect(multiQuery, isNotNull);

      // Triple field object-based pagination
      final tripleQuery = odm.users
          .orderBy(
            ($) => ($.rating(descending: true), $.age(), $.name()),
          ) // NEW: Tuple syntax (double, int, String)
          .endBeforeObject(
            sampleUser,
          ); // Should extract (4.3, 30, 'John Doe') automatically

      expect(tripleQuery, isNotNull);
    });

    test('real-world leaderboard pagination with strongly-typed cursors', () {
      // Leaderboard pagination with strongly-typed cursors
      final leaderboard = odm.users
          .where((filter) => filter.isActive(isEqualTo: true))
          .orderBy(
            ($) => ($.rating(descending: true), $.id()),
          ) // NEW: Tuple syntax (double, String)
          .limit(10)
          .startAfter((
            4.2,
            'user_xyz',
          )); // ✓ (double, String) tuple matches orderBy types

      expect(leaderboard, isNotNull);

      // Get next page after getting results
      final nextPage = leaderboard.startAfter((
        3.8,
        'user_abc',
      )); // ✓ Continue with another (double, String) tuple

      expect(nextPage, isNotNull);
    });

    test('chronological pagination with DateTime cursors', () {
      // Chronological pagination with DateTime cursors
      final recentPosts = odm.users
          .orderBy(($) => ($.createdAt(descending: true),)) // NEW: Tuple syntax (DateTime,)
          .limit(20)
          .startAfter((
            DateTime(2023, 12, 1),
          )); // ✓ (DateTime,) tuple matches orderBy type

      expect(recentPosts, isNotNull);

      // Get older posts
      final olderPosts = recentPosts.startAfter((
        DateTime(2023, 6, 1),
      )); // ✓ Continue with another (DateTime,) tuple

      expect(olderPosts, isNotNull);
    });

    test('search results with multi-field strongly-typed pagination', () {
      // Search users and paginate results with multiple fields
      final searchResults = odm.users
          .where((filter) => filter.tags(arrayContains: 'developer'))
          .orderBy(
            ($) => ($.rating(descending: true), $.id()),
          ) // NEW: Tuple syntax (double, String)
          .limit(15)
          .startAfter((3.8, 'user_xyz')); // ✓ (double, String) tuple

      expect(searchResults, isNotNull);
    });

    test('document ID ordering with strongly-typed String pagination', () {
      final query = odm.users
          .orderBy(($) => ($.id(),)) // NEW: Tuple syntax (String,)
          .startAt(('user123',)) // ✓ (String,) tuple cursor for document ID
          .limit(20);

      expect(query, isNotNull);
    });

    test(
      'complex 4-field orderBy with strongly-typed quad tuple pagination',
      () {
        // Order by 4 fields to test larger tuple types
        final query = odm.users
            .orderBy(
              ($) => ($.rating(descending: true), $.age(), $.name(), $.id()),
            ) // NEW: Tuple syntax (double, int, String, String)
            .startAfter((
              4.5,
              30,
              'John',
              'user123',
            )) // ✓ (double, int, String, String) tuple
            .endAt((
              2.0,
              60,
              'Zoe',
              'user999',
            )); // ✓ (double, int, String, String) tuple

        expect(query, isNotNull);
      },
    );

    test('demonstrates type evolution through orderBy chain', () {
      final users = odm.users;

      // Start: FirestoreCollection<TestSchema, User> - no orderBy, no generic type O
      expect(users, isNotNull);

      // Add orderBy with tuple: FirestoreQuery<TestSchema, User, (int,)>
      final ageQuery = users.orderBy(($) => ($.age(),));
      expect(ageQuery, isNotNull);

      // Test single field pagination
      final singleFieldQuery = ageQuery.startAt((25,)); // (int,) tuple cursor
      expect(singleFieldQuery, isNotNull);

      // Add multi-field orderBy: FirestoreQuery<TestSchema, User, (int, String)>
      final multiQuery = users.orderBy(($) => ($.age(), $.name()));
      expect(multiQuery, isNotNull);

      // Test tuple pagination
      final tupleQuery = multiQuery.startAt((
        25,
        'Alice',
      )); // (int, String) tuple cursor
      expect(tupleQuery, isNotNull);

      // Add triple field orderBy: FirestoreQuery<TestSchema, User, (int, String, double)>
      final tripleQuery = users.orderBy(($) => ($.age(), $.name(), $.rating()));
      expect(tripleQuery, isNotNull);

      // Test triple tuple pagination
      final tripleFieldQuery = tripleQuery.startAt((
        25,
        'Alice',
        4.5,
      )); // (int, String, double) tuple
      expect(tripleFieldQuery, isNotNull);

      // Each orderBy call updates the generic type parameter O
      // enabling strongly-typed pagination cursors
    });

    test('error handling - pagination only works with ordered queries', () {
      // Base collection has no orderBy, so pagination methods are not available
      final users = odm.users;

      // FirestoreCollection doesn't have pagination methods - they only exist on FirestoreQuery
      expect(users, isNotNull);

      // Only ordered queries can use pagination
      final orderedQuery = users.orderBy(($) => ($.age(),));
      final paginatedQuery = orderedQuery.startAt((25,));
      expect(paginatedQuery, isNotNull);
    });
  });
}
