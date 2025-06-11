import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔍 Core Query Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🎯 Basic Filtering', () {
      test('should filter by equality', () async {
        final users = [
          User(
            id: 'active_user',
            name: 'Active User',
            email: 'active@example.com',
            age: 25,
            profile: Profile(
              bio: 'Active user bio',
              avatar: 'active.jpg',
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
            id: 'inactive_user',
            name: 'Inactive User',
            email: 'inactive@example.com',
            age: 30,
            profile: Profile(
              bio: 'Inactive user bio',
              avatar: 'inactive.jpg',
              socialLinks: {},
              interests: ['reading'],
              followers: 50,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final activeUsers =
            await odm.users.where(($) => $.isActive(isEqualTo: true)).get();

        expect(activeUsers.length, equals(1));
        expect(activeUsers.first.name, equals('Active User'));
      });

      test('should filter by not equal', () async {
        final users = [
          User(
            id: 'premium_user',
            name: 'Premium User',
            email: 'premium@example.com',
            age: 28,
            profile: Profile(
              bio: 'Premium user',
              avatar: 'premium.jpg',
              socialLinks: {},
              interests: ['premium'],
              followers: 200,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'regular_user',
            name: 'Regular User',
            email: 'regular@example.com',
            age: 26,
            profile: Profile(
              bio: 'Regular user',
              avatar: 'regular.jpg',
              socialLinks: {},
              interests: ['regular'],
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

        final nonPremiumUsers =
            await odm.users.where(($) => $.isPremium(isNotEqualTo: true)).get();

        expect(nonPremiumUsers.length, equals(1));
        expect(nonPremiumUsers.first.name, equals('Regular User'));
      });

      test('should filter by numerical comparisons', () async {
        final users = List.generate(
            5,
            (index) => User(
                  id: 'age_user_$index',
                  name: 'User $index',
                  email: 'user$index@example.com',
                  age: 20 + index * 5, // 20, 25, 30, 35, 40
                  profile: Profile(
                    bio: 'User $index bio',
                    avatar: 'user$index.jpg',
                    socialLinks: {},
                    interests: ['age_test'],
                    followers: 50 + index * 25,
                  ),
                  rating: 2.0 + index * 0.5, // 2.0, 2.5, 3.0, 3.5, 4.0
                  isActive: true,
                  isPremium: index >= 3,
                  createdAt: DateTime.now(),
                ));

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Test greater than
        final olderUsers =
            await odm.users.where(($) => $.age(isGreaterThan: 25)).get();
        expect(olderUsers.length, equals(3)); // ages 30, 35, 40

        // Test less than or equal
        final youngerUsers =
            await odm.users.where(($) => $.age(isLessThanOrEqualTo: 30)).get();
        expect(youngerUsers.length, equals(3)); // ages 20, 25, 30

        // Test rating greater than or equal
        final highRatedUsers = await odm.users
            .where(($) => $.rating(isGreaterThanOrEqualTo: 3.0))
            .get();
        expect(highRatedUsers.length, equals(3)); // ratings 3.0, 3.5, 4.0
      });
    });

    group('📋 Array and List Operations', () {
      test('should filter by array contains', () async {
        final users = [
          User(
            id: 'coder_user',
            name: 'Coder User',
            email: 'coder@example.com',
            age: 28,
            profile: Profile(
              bio: 'Software developer',
              avatar: 'coder.jpg',
              socialLinks: {},
              interests: ['coding', 'javascript', 'dart'],
              followers: 150,
            ),
            rating: 4.2,
            isActive: true,
            isPremium: false,
            tags: ['developer', 'flutter'],
            createdAt: DateTime.now(),
          ),
          User(
            id: 'designer_user',
            name: 'Designer User',
            email: 'designer@example.com',
            age: 26,
            profile: Profile(
              bio: 'UI/UX Designer',
              avatar: 'designer.jpg',
              socialLinks: {},
              interests: ['design', 'ui', 'ux'],
              followers: 120,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            tags: ['designer', 'creative'],
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final codingUsers = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'coding'))
            .get();

        expect(codingUsers.length, equals(1));
        expect(codingUsers.first.name, equals('Coder User'));

        final flutterDevelopers = await odm.users
            .where(($) => $.tags(arrayContains: 'flutter'))
            .get();

        expect(flutterDevelopers.length, equals(1));
        expect(flutterDevelopers.first.id, equals('coder_user'));
      });

      test('should filter by array contains any', () async {
        final users = [
          User(
            id: 'multi_interest_user',
            name: 'Multi Interest User',
            email: 'multi@example.com',
            age: 30,
            profile: Profile(
              bio: 'Multiple interests',
              avatar: 'multi.jpg',
              socialLinks: {},
              interests: ['coding', 'music', 'sports'],
              followers: 200,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            tags: ['versatile', 'active'],
            createdAt: DateTime.now(),
          ),
          User(
            id: 'single_interest_user',
            name: 'Single Interest User',
            email: 'single@example.com',
            age: 24,
            profile: Profile(
              bio: 'Focused person',
              avatar: 'single.jpg',
              socialLinks: {},
              interests: ['reading'],
              followers: 80,
            ),
            rating: 3.8,
            isActive: true,
            isPremium: false,
            tags: ['focused'],
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final activeUsers = await odm.users
            .where(($) => $.profile
                .interests(arrayContainsAny: ['sports', 'music', 'gaming']))
            .get();

        expect(activeUsers.length, equals(1));
        expect(activeUsers.first.name, equals('Multi Interest User'));

        final taggedUsers = await odm.users
            .where(($) =>
                $.tags(arrayContainsAny: ['versatile', 'focused', 'unknown']))
            .get();

        expect(taggedUsers.length, equals(2)); // Both users have matching tags
      });
    });

    group('📊 Nested Field Queries', () {
      test('should query nested profile fields', () async {
        final users = [
          User(
            id: 'popular_user',
            name: 'Popular User',
            email: 'popular@example.com',
            age: 29,
            profile: Profile(
              bio: 'Very popular user',
              avatar: 'popular.jpg',
              socialLinks: {},
              interests: ['popularity'],
              followers: 1000,
            ),
            rating: 4.8,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'starting_user',
            name: 'Starting User',
            email: 'starting@example.com',
            age: 22,
            profile: Profile(
              bio: 'Just starting out',
              avatar: 'starting.jpg',
              socialLinks: {},
              interests: ['learning'],
              followers: 50,
            ),
            rating: 3.2,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final popularUsers = await odm.users
            .where(($) => $.profile.followers(isGreaterThan: 500))
            .get();

        expect(popularUsers.length, equals(1));
        expect(popularUsers.first.name, equals('Popular User'));

        final bioContainsUsers = await odm.users
            .where(($) => $.profile.bio(isEqualTo: 'Very popular user'))
            .get();

        expect(bioContainsUsers.length, equals(1));
        expect(bioContainsUsers.first.id, equals('popular_user'));
      });
    });

    group('🔗 Logical Operators', () {
      test('should combine filters with AND', () async {
        final users = List.generate(
            4,
            (index) => User(
                  id: 'combo_user_$index',
                  name: 'Combo User $index',
                  email: 'combo$index@example.com',
                  age: 25 + index * 5, // 25, 30, 35, 40
                  profile: Profile(
                    bio: 'Combo user $index',
                    avatar: 'combo$index.jpg',
                    socialLinks: {},
                    interests: ['combo'],
                    followers: 100 + index * 50,
                  ),
                  rating: 3.0 + index * 0.3, // 3.0, 3.3, 3.6, 3.9
                  isActive: index % 2 == 0, // true, false, true, false
                  isPremium: index >= 2, // false, false, true, true
                  createdAt: DateTime.now(),
                ));

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final complexFilter = await odm.users
            .where(($) => $.and(
                  $.age(isGreaterThan: 25),
                  $.isActive(isEqualTo: true),
                  $.rating(isGreaterThan: 3.5),
                ))
            .get();

        expect(complexFilter.length,
            equals(1)); // Only combo_user_2 matches all conditions
        expect(complexFilter.first.id, equals('combo_user_2'));
      });

      test('should combine filters with OR', () async {
        final users = [
          User(
            id: 'high_rating_user',
            name: 'High Rating User',
            email: 'highrating@example.com',
            age: 25,
            profile: Profile(
              bio: 'High rating user',
              avatar: 'highrating.jpg',
              socialLinks: {},
              interests: ['excellence'],
              followers: 100,
            ),
            rating: 4.8,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'premium_user',
            name: 'Premium User',
            email: 'premium@example.com',
            age: 30,
            profile: Profile(
              bio: 'Premium subscriber',
              avatar: 'premium.jpg',
              socialLinks: {},
              interests: ['premium'],
              followers: 200,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'regular_user',
            name: 'Regular User',
            email: 'regular@example.com',
            age: 28,
            profile: Profile(
              bio: 'Regular user',
              avatar: 'regular.jpg',
              socialLinks: {},
              interests: ['regular'],
              followers: 80,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final orFilter = await odm.users
            .where(($) => $.or(
                  $.rating(isGreaterThan: 4.5),
                  $.isPremium(isEqualTo: true),
                ))
            .get();

        expect(orFilter.length, equals(2)); // High rating user and premium user
        final resultIds = orFilter.map((u) => u.id).toSet();
        expect(resultIds, contains('high_rating_user'));
        expect(resultIds, contains('premium_user'));
      });

      test('should combine AND and OR operators', () async {
        final users = List.generate(
            6,
            (index) => User(
                  id: 'mixed_user_$index',
                  name: 'Mixed User $index',
                  email: 'mixed$index@example.com',
                  age: 20 + index * 3, // 20, 23, 26, 29, 32, 35
                  profile: Profile(
                    bio: 'Mixed user $index',
                    avatar: 'mixed$index.jpg',
                    socialLinks: {},
                    interests: ['mixed'],
                    followers: 50 + index * 30,
                  ),
                  rating: 2.5 + index * 0.3, // 2.5, 2.8, 3.1, 3.4, 3.7, 4.0
                  isActive:
                      index % 2 == 1, // false, true, false, true, false, true
                  isPremium:
                      index >= 4, // false, false, false, false, true, true
                  createdAt: DateTime.now(),
                ));

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final mixedFilter = await odm.users
            .where(($) => $.and(
                  $.age(isGreaterThan: 25),
                  $.or(
                    $.isPremium(isEqualTo: true),
                    $.rating(isGreaterThan: 3.5),
                  ),
                ))
            .get();

        // Should match users with age > 25 AND (isPremium = true OR rating > 3.5)
        expect(mixedFilter.length, greaterThan(0));
        for (final user in mixedFilter) {
          expect(user.age, greaterThan(25));
          expect(user.isPremium || user.rating > 3.5, isTrue);
        }
      });
    });

    group('📊 Ordering and Limiting', () {
      test('should order results', () async {
        final users = [
          User(
            id: 'z_user',
            name: 'Z User',
            email: 'z@example.com',
            age: 30,
            profile: Profile(
              bio: 'Z user',
              avatar: 'z.jpg',
              socialLinks: {},
              interests: ['sorting'],
              followers: 100,
            ),
            rating: 2.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'a_user',
            name: 'A User',
            email: 'a@example.com',
            age: 25,
            profile: Profile(
              bio: 'A user',
              avatar: 'a.jpg',
              socialLinks: {},
              interests: ['sorting'],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'm_user',
            name: 'M User',
            email: 'm@example.com',
            age: 35,
            profile: Profile(
              bio: 'M user',
              avatar: 'm.jpg',
              socialLinks: {},
              interests: ['sorting'],
              followers: 150,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final orderedByName = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'sorting'))
            .orderBy(($) => ($.name(),))
            .get();

        expect(orderedByName.length, equals(3));
        expect(orderedByName[0].name, equals('A User'));
        expect(orderedByName[1].name, equals('M User'));
        expect(orderedByName[2].name, equals('Z User'));

        final orderedByRatingDesc = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'sorting'))
            .orderBy(($) => ($.rating(true),))
            .get();

        expect(orderedByRatingDesc.length, equals(3));
        expect(orderedByRatingDesc[0].rating, equals(4.0));
        expect(orderedByRatingDesc[1].rating, equals(3.0));
        expect(orderedByRatingDesc[2].rating, equals(2.0));
      });

      test('should limit results', () async {
        final users = List.generate(
            10,
            (index) => User(
                  id: 'limit_user_$index',
                  name: 'Limit User $index',
                  email: 'limit$index@example.com',
                  age: 20 + index,
                  profile: Profile(
                    bio: 'Limit user $index',
                    avatar: 'limit$index.jpg',
                    socialLinks: {},
                    interests: ['limiting'],
                    followers: index * 10,
                  ),
                  rating: 1.0 + index * 0.3,
                  isActive: true,
                  isPremium: false,
                  createdAt: DateTime.now(),
                ));

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        final limitedResults = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'limiting'))
            .limit(5)
            .get();

        expect(limitedResults.length, equals(5));

        final limitedAndOrdered = await odm.users
            .where(($) => $.profile.interests(arrayContains: 'limiting'))
            .orderBy(($) => ($.age(true),))
            .limit(3)
            .get();

        expect(limitedAndOrdered.length, equals(3));
        // Should be the 3 oldest users
        expect(limitedAndOrdered[0].age, greaterThan(limitedAndOrdered[1].age));
        expect(limitedAndOrdered[1].age, greaterThan(limitedAndOrdered[2].age));
      });
    });
  });
}
