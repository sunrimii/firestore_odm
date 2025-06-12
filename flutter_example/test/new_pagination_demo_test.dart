import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('New Strongly-Typed Pagination Tuple Syntax', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('demonstrates new tuple syntax for single field orderBy', () {
      // NEW SYNTAX: Single field orderBy with tuple
      final ageQuery = odm.users
          .orderBy(($) => ($.age(),)) // ✅ (int,) tuple - strongly typed!
          .limit(10);

      expect(ageQuery, isNotNull);

      // Strongly-typed pagination with tuple cursor
      final paginatedQuery = ageQuery
          .startAt((25,)) // ✅ (int,) tuple cursor
          .endBefore((65,)); // ✅ (int,) tuple cursor

      expect(paginatedQuery, isNotNull);
    });

    test('demonstrates new tuple syntax for multiple field orderBy', () {
      // NEW SYNTAX: Multiple fields in single tuple
      final multiQuery = odm.users
          .orderBy(
            ($) => (
              $.age(), // int
              $.rating(descending: true), // double (descending)
            ),
          )
          .limit(10);

      expect(multiQuery, isNotNull);

      // Strongly-typed pagination with (int, double) tuple cursor
      final paginatedQuery = multiQuery
          .startAt((25, 4.5)) // ✅ (int, double) tuple cursor
          .endBefore((65, 2.0)); // ✅ (int, double) tuple cursor

      expect(paginatedQuery, isNotNull);
    });

    test(
      'demonstrates object-based pagination with automatic cursor extraction',
      () {
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
            .orderBy(($) => ($.age(),)) // (int,) tuple
            .startAtObject(sampleUser); // Should extract age (30) automatically

        expect(singleQuery, isNotNull);

        // Multi-field object-based pagination
        final multiQuery = odm.users
            .orderBy(($) => ($.age(), $.rating(descending: true))) // (int, double) tuple
            .startAtObject(sampleUser) // Should extract (30, 4.3) automatically
            .endBeforeObject(
              sampleUser,
            ); // Should extract (30, 4.3) automatically

        expect(multiQuery, isNotNull);
      },
    );

    test('demonstrates type safety - compilation should catch type mismatches', () {
      // This demonstrates the type safety - the following would cause compile errors:

      final query = odm.users.orderBy(
        ($) => ($.age(), $.rating()),
      ); // (int, double) tuple expected

      expect(query, isNotNull);

      // ❌ These should cause compile-time errors (uncomment to test):
      // query.startAt((25, 'invalid'));     // Wrong types - expecting (int, double)
      // query.startAt((25,));               // Wrong arity - expecting (int, double)
      // query.startAt((25, 4.5, 'extra')); // Wrong arity - expecting (int, double)
    });

    test('demonstrates new syntax with descending order', () {
      // NEW SYNTAX: Descending order with boolean parameter
      final query = odm.users
          .orderBy(
            ($) => (
              $.rating(descending: true), // double, descending
              $.age(descending: false), // int, ascending
            ),
          )
          .limit(10);

      expect(query, isNotNull);

      // Tuple pagination
      final paginatedQuery = query
          .startAfter((4.5, 30)) // ✅ (double, int) tuple
          .endAt((2.0, 60)); // ✅ (double, int) tuple

      expect(paginatedQuery, isNotNull);
    });
  });
}
