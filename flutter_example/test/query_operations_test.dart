import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/post.dart';

void main() {
  group('Query Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('🔍 Basic Filtering', () {
      test('should filter by top-level fields', () async {
        // Arrange
        final users = [
          User(
            id: 'user1',
            name: 'Alice',
            email: 'alice@example.com',
            age: 25,
            profile: Profile(
              bio: 'Developer',
              avatar: 'alice.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user2',
            name: 'Bob',
            email: 'bob@example.com',
            age: 35,
            profile: Profile(
              bio: 'Designer',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 50,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user3',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 28,
            profile: Profile(
              bio: 'Manager',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: ['management'],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Boolean filtering
        final activeUsers = await odm.users
            .where((filter) => filter.isActive(isEqualTo: true))
            .get();
        expect(activeUsers.length, equals(2));
        expect(activeUsers.map((u) => u.name).toSet(), {'Alice', 'Charlie'});

        // Act & Assert - Numeric filtering
        final youngUsers = await odm.users
            .where((filter) => filter.age(isLessThan: 30))
            .get();
        expect(youngUsers.length, equals(2));
        expect(youngUsers.map((u) => u.name).toSet(), {'Alice', 'Charlie'});

        // Act & Assert - String filtering
        final aliceUser = await odm.users
            .where((filter) => filter.name(isEqualTo: 'Alice'))
            .get();
        expect(aliceUser.length, equals(1));
        expect(aliceUser.first.email, equals('alice@example.com'));

        // Act & Assert - Rating filtering
        final highRatedUsers = await odm.users
            .where((filter) => filter.rating(isGreaterThanOrEqualTo: 4.0))
            .get();
        expect(highRatedUsers.length, equals(2));
        expect(highRatedUsers.map((u) => u.name).toSet(), {'Alice', 'Charlie'});
      });

      test('should filter by nested object fields', () async {
        // Arrange
        final users = [
          User(
            id: 'user1',
            name: 'Popular User',
            email: 'popular@example.com',
            age: 25,
            profile: Profile(
              bio: 'Influencer',
              avatar: 'popular.jpg',
              socialLinks: {'github': 'popular_dev'},
              interests: ['coding'],
              followers: 500,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user2',
            name: 'Regular User',
            email: 'regular@example.com',
            age: 30,
            profile: Profile(
              bio: 'Regular person',
              avatar: 'regular.jpg',
              socialLinks: {'github': 'regular_dev'},
              interests: ['reading'],
              followers: 50,
            ),
            rating: 3.8,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Filter by nested profile followers
        final popularUsers = await odm.users
            .where((filter) => filter.profile.followers(isGreaterThan: 100))
            .get();
        expect(popularUsers.length, equals(1));
        expect(popularUsers.first.name, equals('Popular User'));

        // Act & Assert - Filter by nested bio content
        final influencers = await odm.users
            .where((filter) => filter.profile.bio(isEqualTo: 'Influencer'))
            .get();
        expect(influencers.length, equals(1));
        expect(influencers.first.profile.followers, equals(500));
      });

      test('should handle range queries', () async {
        // Arrange
        final users = List.generate(10, (index) {
          return User(
            id: 'range_user_$index',
            name: 'User $index',
            email: 'user$index@example.com',
            age: 20 + index * 5, // Ages: 20, 25, 30, 35, 40, 45, 50, 55, 60, 65
            profile: Profile(
              bio: 'User $index bio',
              avatar: 'user$index.jpg',
              socialLinks: {},
              interests: [],
              followers: index * 10,
            ),
            rating: 3.0 + (index * 0.2), // Ratings: 3.0, 3.2, 3.4, ..., 4.8
            isActive: true,
            isPremium: index % 2 == 0, // Every other user is premium
            createdAt: DateTime.now(),
          );
        });

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Age range query
        final middleAgedUsers = await odm.users
            .where((filter) => filter.and(
              filter.age(isGreaterThanOrEqualTo: 30),
              filter.age(isLessThanOrEqualTo: 50),
            ))
            .get();

        expect(middleAgedUsers.length, equals(5)); // Ages: 30, 35, 40, 45, 50

        // Act & Assert - Rating range query
        final goodRatedUsers = await odm.users
            .where((filter) => filter.and(
              filter.rating(isGreaterThan: 3.5),
              filter.rating(isLessThan: 4.5),
            ))
            .get();

        expect(goodRatedUsers.length, greaterThan(0));
      });

      test('should handle array field queries', () async {
        // Arrange
        final users = [
          User(
            id: 'dev_user',
            name: 'Developer',
            email: 'dev@example.com',
            age: 25,
            profile: Profile(
              bio: 'Software Developer',
              avatar: 'dev.jpg',
              socialLinks: {},
              interests: ['coding', 'flutter', 'dart'],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            tags: ['developer', 'flutter', 'mobile'],
            scores: [95, 88, 92],
            createdAt: DateTime.now(),
          ),
          User(
            id: 'designer_user',
            name: 'Designer',
            email: 'designer@example.com',
            age: 28,
            profile: Profile(
              bio: 'UI/UX Designer',
              avatar: 'designer.jpg',
              socialLinks: {},
              interests: ['design', 'ui', 'ux'],
              followers: 80,
            ),
            rating: 4.2,
            isActive: true,
            isPremium: false,
            tags: ['designer', 'ui', 'creative'],
            scores: [85, 90, 88],
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Array contains query on tags
        final flutterDevs = await odm.users
            .where((filter) => filter.tags(arrayContains: 'flutter'))
            .get();
        expect(flutterDevs.length, equals(1));
        expect(flutterDevs.first.name, equals('Developer'));

        // Act & Assert - Array contains any query on interests
        final techPeople = await odm.users
            .where((filter) => filter.profile.interests(arrayContainsAny: ['coding', 'design']))
            .get();
        expect(techPeople.length, equals(2));
      });

      test('should handle whereIn and whereNotIn queries', () async {
        // Arrange
        final users = [
          User(
            id: 'alice',
            name: 'Alice',
            email: 'alice@example.com',
            age: 25,
            profile: Profile(
              bio: 'Developer',
              avatar: 'alice.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bob',
            name: 'Bob',
            email: 'bob@example.com',
            age: 30,
            profile: Profile(
              bio: 'Designer',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 80,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'charlie',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 35,
            profile: Profile(
              bio: 'Manager',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: ['management'],
              followers: 200,
            ),
            rating: 3.8,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - whereIn query
        final specificUsers = await odm.users
            .where((filter) => filter.name(whereIn: ['Alice', 'Bob']))
            .get();
        expect(specificUsers.length, equals(2));
        expect(specificUsers.map((u) => u.name).toSet(), {'Alice', 'Bob'});

        // Act & Assert - whereNotIn query
        final excludedUsers = await odm.users
            .where((filter) => filter.name(whereNotIn: ['Charlie']))
            .get();
        expect(excludedUsers.length, equals(2));
        expect(excludedUsers.map((u) => u.name).toSet(), {'Alice', 'Bob'});
      });
    });

    group('🔗 Complex Logical Operations', () {
      test('should perform AND operations', () async {
        // Arrange
        final users = [
          User(
            id: 'premium_young',
            name: 'Premium Young',
            email: 'premium_young@example.com',
            age: 22,
            profile: Profile(
              bio: 'Young premium user',
              avatar: 'young.jpg',
              socialLinks: {},
              interests: ['tech', 'gaming'],
              followers: 150,
            ),
            rating: 4.2,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'premium_old',
            name: 'Premium Old',
            email: 'premium_old@example.com',
            age: 45,
            profile: Profile(
              bio: 'Experienced premium user',
              avatar: 'old.jpg',
              socialLinks: {},
              interests: ['business'],
              followers: 500,
            ),
            rating: 4.8,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'free_young',
            name: 'Free Young',
            email: 'free_young@example.com',
            age: 20,
            profile: Profile(
              bio: 'Young free user',
              avatar: 'free_young.jpg',
              socialLinks: {},
              interests: ['music'],
              followers: 25,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Complex AND filter: Premium users under 30 with rating > 4.0
        final filteredUsers = await odm.users
            .where((filter) => filter.and(
              filter.isPremium(isEqualTo: true),
              filter.age(isLessThan: 30),
              filter.rating(isGreaterThan: 4.0),
              filter.isActive(isEqualTo: true),
            ))
            .get();

        expect(filteredUsers.length, equals(1));
        expect(filteredUsers.first.name, equals('Premium Young'));
        expect(filteredUsers.first.age, equals(22));
        expect(filteredUsers.first.isPremium, isTrue);
        expect(filteredUsers.first.rating, equals(4.2));
      });

      test('should perform OR operations', () async {
        // Arrange
        final users = [
          User(
            id: 'high_rated',
            name: 'High Rated',
            email: 'high@example.com',
            age: 25,
            profile: Profile(
              bio: 'High rated user',
              avatar: 'high.jpg',
              socialLinks: {},
              interests: ['quality'],
              followers: 100,
            ),
            rating: 4.8,
            isActive: true,
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
              interests: ['basic'],
              followers: 50,
            ),
            rating: 3.2,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - OR filter: Premium users OR highly rated users
        final eligibleUsers = await odm.users
            .where((filter) => filter.or(
              filter.isPremium(isEqualTo: true),
              filter.rating(isGreaterThanOrEqualTo: 4.5),
            ))
            .get();

        expect(eligibleUsers.length, equals(2));
        final names = eligibleUsers.map((u) => u.name).toSet();
        expect(names, containsAll(['High Rated', 'Premium User']));
      });

      test('should perform nested AND/OR combinations', () async {
        // Arrange
        final users = [
          User(
            id: 'user1',
            name: 'Active Premium',
            email: 'active_premium@example.com',
            age: 25,
            profile: Profile(
              bio: 'Active premium user',
              avatar: 'active_premium.jpg',
              socialLinks: {},
              interests: ['premium'],
              followers: 150,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user2',
            name: 'Young Talented',
            email: 'young_talented@example.com',
            age: 22,
            profile: Profile(
              bio: 'Young and talented',
              avatar: 'young_talented.jpg',
              socialLinks: {},
              interests: ['talent'],
              followers: 80,
            ),
            rating: 4.7,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user3',
            name: 'Inactive Premium',
            email: 'inactive_premium@example.com',
            age: 35,
            profile: Profile(
              bio: 'Inactive premium user',
              avatar: 'inactive_premium.jpg',
              socialLinks: {},
              interests: ['inactive'],
              followers: 200,
            ),
            rating: 3.8,
            isActive: false,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user4',
            name: 'Regular User',
            email: 'regular@example.com',
            age: 30,
            profile: Profile(
              bio: 'Regular user',
              avatar: 'regular.jpg',
              socialLinks: {},
              interests: ['regular'],
              followers: 40,
            ),
            rating: 3.2,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Complex nested query: (active AND premium) OR (age < 25 AND rating > 4.0)
        final complexUsers = await odm.users
            .where((filter) => filter.or(
              filter.and(
                filter.isActive(isEqualTo: true),
                filter.isPremium(isEqualTo: true),
              ),
              filter.and(
                filter.age(isLessThan: 25),
                filter.rating(isGreaterThan: 4.0),
              ),
            ))
            .get();

        expect(complexUsers.length, equals(2));
        final names = complexUsers.map((u) => u.name).toSet();
        expect(names, containsAll(['Active Premium', 'Young Talented']));
      });
    });

    group('📊 Ordering and Limiting', () {
      test('should order by single field', () async {
        // Arrange
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
              interests: [],
              followers: 150,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime(2023, 1, 1),
          ),
          User(
            id: 'user2',
            name: 'Bob',
            email: 'bob@example.com',
            age: 35,
            profile: Profile(
              bio: 'Bob bio',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: [],
              followers: 50,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime(2023, 2, 1),
          ),
          User(
            id: 'user3',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 28,
            profile: Profile(
              bio: 'Charlie bio',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: [],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime(2023, 3, 1),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Order by age descending
        final usersByAge = await odm.users
            .orderBy((order) => order.age(descending: true))
            .get();

        expect(usersByAge.length, equals(3));
        expect(usersByAge[0].name, equals('Bob')); // age 35
        expect(usersByAge[1].name, equals('Charlie')); // age 28
        expect(usersByAge[2].name, equals('Alice')); // age 25

        // Act & Assert - Order by rating ascending
        final usersByRating = await odm.users
            .orderBy((order) => order.rating())
            .get();

        expect(usersByRating[0].rating, equals(3.0));
        expect(usersByRating[1].rating, equals(4.0));
        expect(usersByRating[2].rating, equals(4.5));

        // Act & Assert - Order by nested field (followers descending)
        final usersByFollowers = await odm.users
            .orderBy((order) => order.profile.followers(descending: true))
            .get();

        expect(usersByFollowers[0].name, equals('Charlie')); // 200 followers
        expect(usersByFollowers[1].name, equals('Alice')); // 150 followers
        expect(usersByFollowers[2].name, equals('Bob')); // 50 followers
      });

      test('should handle multiple ordering criteria', () async {
        // Arrange
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
              interests: [],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime(2023, 1, 1),
          ),
          User(
            id: 'user2',
            name: 'Bob',
            email: 'bob@example.com',
            age: 25, // Same age as Alice
            profile: Profile(
              bio: 'Bob bio',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: [],
              followers: 150, // More followers than Alice
            ),
            rating: 4.5, // Same rating as Alice
            isActive: false,
            isPremium: false,
            createdAt: DateTime(2023, 2, 1),
          ),
          User(
            id: 'user3',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 28,
            profile: Profile(
              bio: 'Charlie bio',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: [],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime(2023, 3, 1),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Order by age ascending, then by followers descending
        final orderedUsers = await odm.users
            .orderBy((order) => order.age())
            .orderBy((order) => order.profile.followers(descending: true))
            .get();

        expect(orderedUsers.length, equals(3));
        // For age 25: Bob (150 followers) should come before Alice (100 followers)
        // Then Charlie (age 28)
        expect(orderedUsers[0].name, equals('Bob')); // age 25, 150 followers
        expect(orderedUsers[1].name, equals('Alice')); // age 25, 100 followers  
        expect(orderedUsers[2].name, equals('Charlie')); // age 28
      });

      test('should handle limit queries', () async {
        // Arrange
        final users = List.generate(20, (index) {
          return User(
            id: 'page_user_$index',
            name: 'Page User $index',
            email: 'page$index@example.com',
            age: 25,
            profile: Profile(
              bio: 'Page user $index',
              avatar: 'page$index.jpg',
              socialLinks: {},
              interests: [],
              followers: index,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now().add(Duration(minutes: index)),
          );
        });

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Get first 5 users ordered by creation time
        final firstPage = await odm.users
            .orderBy((order) => order.createdAt())
            .limit(5)
            .get();

        expect(firstPage.length, equals(5));

        // Verify ordering by creation time
        for (int i = 1; i < firstPage.length; i++) {
          expect(
            firstPage[i].createdAt!.isAfter(firstPage[i - 1].createdAt!),
            isTrue,
          );
        }
      });

      test('should combine filtering, ordering, and limiting', () async {
        // Arrange
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
              interests: [],
              followers: 150,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime(2023, 1, 1),
          ),
          User(
            id: 'user2',
            name: 'Bob',
            email: 'bob@example.com',
            age: 35,
            profile: Profile(
              bio: 'Bob bio',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: [],
              followers: 50,
            ),
            rating: 3.0,
            isActive: false, // Not active - should be filtered out
            isPremium: false,
            createdAt: DateTime(2023, 2, 1),
          ),
          User(
            id: 'user3',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 28,
            profile: Profile(
              bio: 'Charlie bio',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: [],
              followers: 200,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime(2023, 3, 1),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - Filter active users, order by followers, limit to 2
        final activeUsersOrdered = await odm.users
            .where((filter) => filter.isActive(isEqualTo: true))
            .orderBy((order) => order.profile.followers(descending: true))
            .limit(2)
            .get();

        expect(activeUsersOrdered.length, equals(2));
        expect(activeUsersOrdered[0].name, equals('Charlie')); // 200 followers
        expect(activeUsersOrdered[1].name, equals('Alice')); // 150 followers
      });
    });

    group('📝 Empty Results & Edge Cases', () {
      test('should handle empty query results', () async {
        // Act
        final noUsers = await odm.users
            .where((filter) => filter.age(isGreaterThan: 1000)) // Impossible condition
            .get();

        // Assert
        expect(noUsers, isEmpty);
      });

      test('should handle queries with no matching documents', () async {
        // Arrange
        final user = User(
          id: 'single_user',
          name: 'Single User',
          email: 'single@example.com',
          age: 25,
          profile: Profile(
            bio: 'Only user',
            avatar: 'single.jpg',
            socialLinks: {},
            interests: [],
            followers: 10,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('single_user').set(user);

        // Act & Assert - Query that should match
        final matchingUsers = await odm.users
            .where((filter) => filter.name(isEqualTo: 'Single User'))
            .get();
        expect(matchingUsers.length, equals(1));

        // Act & Assert - Query that should not match
        final nonMatchingUsers = await odm.users
            .where((filter) => filter.name(isEqualTo: 'Non-existent User'))
            .get();
        expect(nonMatchingUsers, isEmpty);
      });

      test('should handle complex queries with no results', () async {
        // Arrange
        final user = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 50,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('test_user').set(user);

        // Act & Assert - Complex query with impossible conditions
        final impossibleUsers = await odm.users
            .where((filter) => filter.and(
              filter.isActive(isEqualTo: true), // User is not active
              filter.isPremium(isEqualTo: true), // User is not premium
              filter.rating(isGreaterThan: 4.0), // User rating is 3.0
            ))
            .get();

        expect(impossibleUsers, isEmpty);
      });
    });
  });
}