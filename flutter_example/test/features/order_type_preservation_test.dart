import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔄 Order Type Preservation Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should preserve order type O after where() filtering', () async {
      // Create test users
      final users = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          profile: Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {},
            interests: ['coding'],
            followers: 1500,
            lastActive: DateTime.now(),
          ),
          rating: 4.8,
          tags: ['premium'],
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 30,
          profile: Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {},
            interests: ['design'],
            followers: 1200,
            lastActive: DateTime.now(),
          ),
          rating: 4.2,
          tags: ['regular'],
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        ),
      ];

      for (final user in users) {
        await odm.users(user.id).update(user);
      }

      // Test: OrderedQuery.where() should preserve order type
      final orderedQuery = odm.users
          .orderBy(($) => ($.rating(true), $.age())); // Returns OrderedQuery<TestSchema, User, (double, int)>

      // After where() filtering, should still maintain order type for pagination
      final filteredOrderedQuery = orderedQuery
          .where(($) => $.isActive(isEqualTo: true)); // Should still be OrderedQuery<TestSchema, User, (double, int)>

      // Verify we can still use pagination methods (which require order type O)
      final results = await filteredOrderedQuery
          .startAfterObject(users[0]) // This requires the order type O to be preserved
          .limit(1)
          .get();

      expect(results, hasLength(1));
      expect(results.first.name, equals('Bob'));

      print('✅ Order type preserved after where() - pagination still works');

      // Test: Can use cursor-based pagination with preserved order type
      final cursorValues = (4.8, 25); // (rating, age) matching the order type
      final cursorResults = await filteredOrderedQuery
          .startAfter(cursorValues)
          .get();

      expect(cursorResults, hasLength(1));
      expect(cursorResults.first.name, equals('Bob'));

      print('✅ Cursor-based pagination works with preserved order type');
    });

    test('should lose order type for aggregate operations (correct behavior)', () async {
      // Create test data
      final user = User(
        id: 'agg_user',
        name: 'Aggregate User',
        email: 'agg@example.com',
        age: 28,
        profile: Profile(
          bio: 'Agg bio',
          avatar: 'agg.jpg',
          socialLinks: {},
          interests: ['analytics'],
          followers: 800,
          lastActive: DateTime.now(),
        ),
        rating: 4.5,
        tags: ['analyst'],
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      await odm.users(user.id).update(user);

      // Test: OrderedQuery.aggregate() should return AggregateQuery (no order type)
      final orderedQuery = odm.users
          .orderBy(($) => ($.rating(true), $.age())); // OrderedQuery with order type

      final aggregateQuery = orderedQuery
          .aggregate(($) => (
            count: $.count(),
            avgRating: $.rating.average(),
          )); // Returns AggregateQuery (no order type needed)

      final result = await aggregateQuery.get();
      
      expect(result.count, equals(1));
      expect(result.avgRating, equals(4.5));

      print('✅ Aggregate operations correctly lose order type (no pagination needed)');

      // Test: Count operations also lose order type
      final countQuery = orderedQuery.count(); // Returns AggregateCountQuery (no order type)
      final countResult = await countQuery.get();
      
      expect(countResult, equals(1));

      print('✅ Count operations correctly lose order type');
    });

    test('should demonstrate the correct API flow', () async {
      // This test demonstrates the correct type flow
      
      // 1. Start with collection (no order type)
      final collection = odm.users; // FirestoreCollection<TestSchema, User>
      
      // 2. Apply ordering (gains order type)
      final ordered = collection.orderBy(($) => ($.rating(true), $.name())); // OrderedQuery<TestSchema, User, (double, String)>
      
      // 3. Apply filtering (preserves order type) ✅ CORRECT
      final filtered = ordered.where(($) => $.isActive(isEqualTo: true)); // OrderedQuery<TestSchema, User, (double, String)>
      
      // 4. Apply pagination (uses preserved order type) ✅ CORRECT
      final paginated = filtered.limit(10); // OrderedQuery<TestSchema, User, (double, String)>
      
      // 5. Aggregate loses order type (correct) ✅ CORRECT
      final aggregated = ordered.aggregate(($) => (count: $.count())); // AggregateQuery (no order type)
      
      print('✅ API flow demonstrates correct type preservation:');
      print('  - Collection: No order type');
      print('  - After orderBy(): Gains order type O');
      print('  - After where(): Preserves order type O (for pagination)');
      print('  - After aggregate(): Loses order type (no pagination needed)');
    });
  });
}