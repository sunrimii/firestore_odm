import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔧 New OrderedQuery Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🎯 OrderedQuery Additional Filtering', () {
      test(
        'should allow additional where() filtering on OrderedQuery',
        () async {
          // Create test users with different criteria
          final users = [
            User(
              id: 'ordered_filter_1',
              name: 'Alice',
              email: 'alice@example.com',
              age: 25,
              profile: Profile(
                bio: 'Alice bio',
                avatar: 'alice.jpg',
                socialLinks: {},
                interests: ['coding'],
                followers: 500,
              ),
              rating: 4.5,
              isActive: true,
              isPremium: false,
              createdAt: DateTime.now(),
            ),
            User(
              id: 'ordered_filter_2',
              name: 'Bob',
              email: 'bob@example.com',
              age: 30,
              profile: Profile(
                bio: 'Bob bio',
                avatar: 'bob.jpg',
                socialLinks: {},
                interests: ['design'],
                followers: 1000,
              ),
              rating: 3.8,
              isActive: false, // Inactive
              isPremium: true,
              createdAt: DateTime.now(),
            ),
            User(
              id: 'ordered_filter_3',
              name: 'Charlie',
              email: 'charlie@example.com',
              age: 35,
              profile: Profile(
                bio: 'Charlie bio',
                avatar: 'charlie.jpg',
                socialLinks: {},
                interests: ['management'],
                followers: 1500,
              ),
              rating: 4.9,
              isActive: true,
              isPremium: true,
              createdAt: DateTime.now(),
            ),
          ];

          // Insert all users
          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          // ✅ NEW: Use OrderedQuery with additional where() filtering
          final results = await odm.users
              .orderBy(
                ($) => ($.profile.followers(descending: true),),
              ) // Order by followers descending
              .where(
                ($) => $.isActive(isEqualTo: true),
              ) // ✅ NEW: Additional filtering
              .get();

          expect(
            results.length,
            equals(2),
          ); // Only Alice and Charlie (active users)
          expect(
            results.first.name,
            equals('Charlie'),
          ); // Highest followers among active
          expect(
            results.last.name,
            equals('Alice'),
          ); // Lower followers among active

          print('✅ OrderedQuery.where() - Additional filtering works');
        },
      );

      test('should chain multiple where() calls on OrderedQuery', () async {
        // Create test users
        final users = [
          User(
            id: 'chain_1',
            name: 'Premium Active',
            email: 'premium@example.com',
            age: 28,
            profile: Profile(
              bio: 'Premium active user',
              avatar: 'premium.jpg',
              socialLinks: {},
              interests: ['premium'],
              followers: 2000,
            ),
            rating: 4.8,
            isActive: true,
            isPremium: true, // Matches all criteria
            createdAt: DateTime.now(),
          ),
          User(
            id: 'chain_2',
            name: 'Premium Inactive',
            email: 'inactive@example.com',
            age: 32,
            profile: Profile(
              bio: 'Premium inactive user',
              avatar: 'inactive.jpg',
              socialLinks: {},
              interests: ['premium'],
              followers: 1500,
            ),
            rating: 4.2,
            isActive: false, // Will be filtered out
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'chain_3',
            name: 'Regular Active',
            email: 'regular@example.com',
            age: 26,
            profile: Profile(
              bio: 'Regular active user',
              avatar: 'regular.jpg',
              socialLinks: {},
              interests: ['regular'],
              followers: 800,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false, // Will be filtered out
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Chain multiple where() calls on OrderedQuery
        final results = await odm.users
            .orderBy(($) => ($.rating(descending: true),)) // Order by rating descending
            .where(
              ($) => $.isActive(isEqualTo: true),
            ) // First filter: active only
            .where(
              ($) => $.isPremium(isEqualTo: true),
            ) // ✅ NEW: Second filter: premium only
            .get();

        expect(results.length, equals(1)); // Only Premium Active user
        expect(results.first.name, equals('Premium Active'));

        print('✅ OrderedQuery multiple where() chains work');
      });
    });

    group('🔄 OrderedQuery Bulk Operations', () {
      test('should perform bulk patch operations on OrderedQuery', () async {
        // Create test users
        final users = [
          User(
            id: 'bulk_patch_1',
            name: 'User 1',
            email: 'user1@example.com',
            age: 25,
            profile: Profile(
              bio: 'User 1 bio',
              avatar: 'user1.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false, // Will be updated
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_patch_2',
            name: 'User 2',
            email: 'user2@example.com',
            age: 30,
            profile: Profile(
              bio: 'User 2 bio',
              avatar: 'user2.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false, // Will be updated
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Bulk patch on OrderedQuery
        await odm.users
            .orderBy(($) => ($.age(),)) // Order by age
            .patch(
              ($) => [
                $.isPremium(true), // Upgrade all to premium
                $.profile.followers.increment(50), // Add 50 followers to each
              ],
            );

        // Verify updates
        final updatedUsers = await odm.users.get();
        expect(updatedUsers.length, equals(2));

        for (final user in updatedUsers) {
          expect(user.isPremium, isTrue);
          expect(
            user.profile.followers,
            greaterThanOrEqualTo(150),
          ); // 100+50 or 150+50
        }

        print('✅ OrderedQuery.patch() - Bulk patch operations work');
      });

      test('should perform bulk modify operations on OrderedQuery', () async {
        // Create test users
        final users = [
          User(
            id: 'bulk_modify_1',
            name: 'Modify User 1',
            email: 'modify1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Original bio 1',
              avatar: 'modify1.jpg',
              socialLinks: {},
              interests: ['modify'],
              followers: 200,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_modify_2',
            name: 'Modify User 2',
            email: 'modify2@example.com',
            age: 35,
            profile: Profile(
              bio: 'Original bio 2',
              avatar: 'modify2.jpg',
              socialLinks: {},
              interests: ['modify'],
              followers: 300,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Bulk modify on OrderedQuery
        await odm.users
            .orderBy(($) => ($.rating(),)) // Order by rating
            .modify(
              (user) => user.copyWith(
                isPremium: true,
                profile: user.profile.copyWith(
                  bio: '${user.profile.bio} - Modified!',
                ),
              ),
            );

        // Verify updates
        final modifiedUsers = await odm.users.get();
        expect(modifiedUsers.length, equals(2));

        for (final user in modifiedUsers) {
          expect(user.isPremium, isTrue);
          expect(user.profile.bio, contains('Modified!'));
        }

        print('✅ OrderedQuery.modify() - Bulk modify operations work');
      });

      test('should perform bulk incrementalModify on OrderedQuery', () async {
        // Create test users
        final users = [
          User(
            id: 'incremental_1',
            name: 'Inc User 1',
            email: 'inc1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Inc bio 1',
              avatar: 'inc1.jpg',
              socialLinks: {},
              interests: ['increment'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'incremental_2',
            name: 'Inc User 2',
            email: 'inc2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Inc bio 2',
              avatar: 'inc2.jpg',
              socialLinks: {},
              interests: ['increment'],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Bulk incrementalModify on OrderedQuery
        await odm.users
            .orderBy(($) => ($.name(),)) // Order by name
            .incrementalModify(
              (user) => user.copyWith(
                age:
                    user.age +
                    5, // Should auto-convert to FieldValue.increment(5)
                profile: user.profile.copyWith(
                  followers:
                      user.profile.followers + 100, // Auto-increment followers
                ),
              ),
            );

        // Verify atomic updates worked
        final incrementedUsers = await odm.users.get();
        expect(incrementedUsers.length, equals(2));

        for (final user in incrementedUsers) {
          expect(user.age, greaterThanOrEqualTo(30)); // 25+5 or 30+5
          expect(
            user.profile.followers,
            greaterThanOrEqualTo(200),
          ); // 100+100 or 200+100
        }

        print('✅ OrderedQuery.incrementalModify() - Atomic operations work');
      });
    });

    group('📊 OrderedQuery Aggregate Operations', () {
      test('should perform aggregate operations on OrderedQuery', () async {
        // Create test users for aggregation
        final users = [
          User(
            id: 'agg_1',
            name: 'Agg User 1',
            email: 'agg1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Agg user 1',
              avatar: 'agg1.jpg',
              socialLinks: {},
              interests: ['aggregation'],
              followers: 500,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'agg_2',
            name: 'Agg User 2',
            email: 'agg2@example.com',
            age: 35,
            profile: Profile(
              bio: 'Agg user 2',
              avatar: 'agg2.jpg',
              socialLinks: {},
              interests: ['aggregation'],
              followers: 1000,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'agg_3',
            name: 'Agg User 3',
            email: 'agg3@example.com',
            age: 30,
            profile: Profile(
              bio: 'Agg user 3',
              avatar: 'agg3.jpg',
              socialLinks: {},
              interests: ['aggregation'],
              followers: 750,
            ),
            rating: 3.8,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Aggregate operations on OrderedQuery
        final aggregateResult = await odm.users
            .orderBy(($) => ($.rating(descending: true),)) // Order by rating descending
            .aggregate(
              ($) => (
                count: $.count(),
                avgAge: $.age.average(),
                totalFollowers: $.profile.followers.sum(),
                maxRating: $.rating.sum(), // Sum for max effect
              ),
            )
            .get();

        expect(aggregateResult.count, equals(3));
        expect(aggregateResult.avgAge, equals(30.0)); // (25+35+30)/3
        expect(aggregateResult.totalFollowers, equals(2250)); // 500+1000+750
        expect(aggregateResult.maxRating, equals(12.3)); // 4.0+4.5+3.8

        print('✅ OrderedQuery.aggregate() - Complex aggregations work');
      });

      test('should perform count operations on OrderedQuery', () async {
        // Create test users
        final users = List.generate(
          5,
          (i) => User(
            id: 'count_$i',
            name: 'Count User $i',
            email: 'count$i@example.com',
            age: 20 + i,
            profile: Profile(
              bio: 'Count user $i',
              avatar: 'count$i.jpg',
              socialLinks: {},
              interests: ['counting'],
              followers: 100 * (i + 1),
            ),
            rating: 3.0 + (i * 0.2),
            isActive: i % 2 == 0, // Even indices are active
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        );

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Count with OrderedQuery
        final countResult = await odm.users
            .orderBy(($) => ($.age(),)) // Order by age
            .where(($) => $.isActive(isEqualTo: true)) // Filter active users
            .count()
            .get();

        expect(countResult, equals(3)); // Users 0, 2, 4 are active

        print('✅ OrderedQuery.count() - Filtered counting works');
      });
    });
  });
}
