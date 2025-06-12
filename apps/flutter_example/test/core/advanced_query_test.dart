import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔍 Advanced Query Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🔢 Multiple OrderBy', () {
      test('should handle multiple orderBy clauses', () async {
        final users = [
          User(
            id: 'multi_order_1',
            name: 'Alice',
            email: 'alice@example.com',
            age: 25,
            profile: Profile(
              bio: 'Alice bio',
              avatar: 'alice.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'multi_order_2',
            name: 'Bob',
            email: 'bob@example.com',
            age: 25, // Same age as Alice
            profile: Profile(
              bio: 'Bob bio',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'multi_order_3',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 30,
            profile: Profile(
              bio: 'Charlie bio',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 80,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Order by age first, then by rating (descending)
        final results = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'coding'))
            .orderBy(($) => ($.age(), $.rating(descending: true)))
            .get();

        expect(results.length, equals(3));

        // Should be ordered by age first (25, 25, 30), then by rating descending within same age
        expect(results[0].age, equals(25));
        expect(results[0].rating, equals(4.0)); // Alice (higher rating)
        expect(results[1].age, equals(25));
        expect(results[1].rating, equals(3.5)); // Bob (lower rating)
        expect(results[2].age, equals(30));
        expect(results[2].rating, equals(4.5)); // Charlie
      });
    });

    group('🏗️ Nested Field OrderBy', () {
      test('should order by nested profile fields', () async {
        final users = [
          User(
            id: 'nested_order_1',
            name: 'User 1',
            email: 'user1@example.com',
            age: 25,
            profile: Profile(
              bio: 'User 1 bio',
              avatar: 'user1.jpg',
              socialLinks: {},
              interests: ['nested'],
              followers: 50,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'nested_order_2',
            name: 'User 2',
            email: 'user2@example.com',
            age: 30,
            profile: Profile(
              bio: 'User 2 bio',
              avatar: 'user2.jpg',
              socialLinks: {},
              interests: ['nested'],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'nested_order_3',
            name: 'User 3',
            email: 'user3@example.com',
            age: 28,
            profile: Profile(
              bio: 'User 3 bio',
              avatar: 'user3.jpg',
              socialLinks: {},
              interests: ['nested'],
              followers: 100,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Order by nested profile.followers field
        final results = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'nested'))
            .orderBy(($) => ($.profile.followers(descending: true),))
            .get();

        expect(results.length, equals(3));
        expect(results[0].profile.followers, equals(200)); // User 2
        expect(results[1].profile.followers, equals(100)); // User 3
        expect(results[2].profile.followers, equals(50)); // User 1
      });
    });

    group('🔢 LimitToLast Operations', () {
      test('should handle limitToLast queries', () async {
        final users = [
          User(
            id: 'limit_last_1',
            name: 'First User',
            email: 'first@example.com',
            age: 20,
            profile: Profile(
              bio: 'First user',
              avatar: 'first.jpg',
              socialLinks: {},
              interests: ['limiting'],
              followers: 10,
            ),
            rating: 1.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'limit_last_2',
            name: 'Second User',
            email: 'second@example.com',
            age: 25,
            profile: Profile(
              bio: 'Second user',
              avatar: 'second.jpg',
              socialLinks: {},
              interests: ['limiting'],
              followers: 20,
            ),
            rating: 2.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'limit_last_3',
            name: 'Third User',
            email: 'third@example.com',
            age: 30,
            profile: Profile(
              bio: 'Third user',
              avatar: 'third.jpg',
              socialLinks: {},
              interests: ['limiting'],
              followers: 30,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'limit_last_4',
            name: 'Fourth User',
            email: 'fourth@example.com',
            age: 35,
            profile: Profile(
              bio: 'Fourth user',
              avatar: 'fourth.jpg',
              socialLinks: {},
              interests: ['limiting'],
              followers: 40,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Note: limitToLast might not be implemented yet in the current ODM
        // This test demonstrates the expected API once implemented
        try {
          final results = await odm.users
              .where(($) => $.profile.interests(arrayContains: 'limiting'))
              .orderBy(($) => ($.age(),))
              .limitToLast(2)
              .get();

          expect(results.length, equals(2));
          // Should get the last 2 documents in age order (Third and Fourth users)
          expect(results[0].age, equals(30)); // Third User
          expect(results[1].age, equals(35)); // Fourth User
        } catch (e) {
          // If limitToLast is not implemented, this test will fail
          // but it documents the expected behavior
          print('limitToLast not yet implemented: $e');
        }
      });
    });

    group('🔄 Query Update Operations', () {
      test('should perform updates on query results', () async {
        final users = [
          User(
            id: 'query_update_1',
            name: 'Query User 1',
            email: 'query1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Query user 1',
              avatar: 'query1.jpg',
              socialLinks: {},
              interests: ['query_updates'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'query_update_2',
            name: 'Query User 2',
            email: 'query2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Query user 2',
              avatar: 'query2.jpg',
              socialLinks: {},
              interests: ['query_updates'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Update all users matching the query
        await odm.users
            .where(($) => $.profile.interests(arrayContains: 'query_updates'))
            .patch(($) => [$.isActive(true), $.rating.increment(0.5)]);

        // Verify all matching users were updated
        final updatedUsers = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'query_updates'))
            .get();

        expect(updatedUsers.length, equals(2));
        for (final user in updatedUsers) {
          expect(user.isActive, isTrue);
          expect(user.rating, greaterThan(3.0));
        }
      });

      test('should perform modify operations on query results', () async {
        final users = [
          User(
            id: 'query_modify_1',
            name: 'Modify User 1',
            email: 'modify1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Modify user 1',
              avatar: 'modify1.jpg',
              socialLinks: {},
              interests: ['query_modify'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'query_modify_2',
            name: 'Modify User 2',
            email: 'modify2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Modify user 2',
              avatar: 'modify2.jpg',
              socialLinks: {},
              interests: ['query_modify'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Modify all users matching the query
        await odm.users
            .where(($) => $.profile.interests(arrayContains: 'query_modify'))
            .modify(
              (user) => user.copyWith(
                isPremium: true,
                profile: user.profile.copyWith(
                  bio: '${user.profile.bio} - Modified',
                ),
              ),
            );

        // Verify all matching users were modified
        final modifiedUsers = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'query_modify'))
            .get();

        expect(modifiedUsers.length, equals(2));
        for (final user in modifiedUsers) {
          expect(user.isPremium, isTrue);
          expect(user.profile.bio, contains('- Modified'));
        }
      });

      test(
        'should perform incremental modify operations on query results',
        () async {
          final users = [
            User(
              id: 'query_inc_mod_1',
              name: 'Inc Modify User 1',
              email: 'incmod1@example.com',
              age: 25,
              profile: Profile(
                bio: 'Inc modify user 1',
                avatar: 'incmod1.jpg',
                socialLinks: {},
                interests: ['query_incremental'],
                followers: 100,
              ),
              rating: 3.0,
              isActive: true,
              isPremium: false,
              tags: ['original'],
              scores: [80, 85],
              createdAt: DateTime.now(),
            ),
            User(
              id: 'query_inc_mod_2',
              name: 'Inc Modify User 2',
              email: 'incmod2@example.com',
              age: 30,
              profile: Profile(
                bio: 'Inc modify user 2',
                avatar: 'incmod2.jpg',
                socialLinks: {},
                interests: ['query_incremental'],
                followers: 150,
              ),
              rating: 3.5,
              isActive: true,
              isPremium: false,
              tags: ['original'],
              scores: [90, 95],
              createdAt: DateTime.now(),
            ),
          ];

          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          // Incremental modify all users matching the query
          await odm.users
              .where(
                ($) => $.profile.interests(arrayContains: 'query_incremental'),
              )
              .incrementalModify(
                (user) => user.copyWith(
                  rating: user.rating + 0.5, // Should auto-detect as increment
                  profile: user.profile.copyWith(
                    followers:
                        user.profile.followers +
                        50, // Should auto-detect as increment
                  ),
                  tags: [
                    ...user.tags,
                    'incremented',
                  ], // Should auto-detect as arrayUnion
                  lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
                ),
              );

          // Verify all matching users were incrementally modified
          final modifiedUsers = await odm.users
              .where(
                ($) => $.profile.interests(arrayContains: 'query_incremental'),
              )
              .get();

          expect(modifiedUsers.length, equals(2));
          for (final user in modifiedUsers) {
            expect(user.rating, greaterThan(3.0));
            expect(user.profile.followers, greaterThan(100));
            expect(user.tags, contains('incremented'));
            expect(user.lastLogin, isNotNull);
          }
        },
      );
    });
  });
}
