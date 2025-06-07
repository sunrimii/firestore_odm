import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('OrderBy API Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore);
    });

    test('Basic field ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 3, 1),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Order by age descending
      final usersByAge = await odm.users
          .orderBy((order) => order.age(descending: true))
          .get();

      // Assert
      expect(usersByAge.length, 3);
      expect(usersByAge[0].name, 'Bob'); // age 35
      expect(usersByAge[1].name, 'Charlie'); // age 28
      expect(usersByAge[2].name, 'Alice'); // age 25
      print('Basic field ordering test passed!');
    });

    test('Nested object ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 3, 1),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Order by nested profile.followers descending
      final usersByFollowers = await odm.users
          .orderBy((order) => order.profile.followers(descending: true))
          .get();

      // Assert
      expect(usersByFollowers.length, 3);
      expect(usersByFollowers[0].name, 'Charlie'); // 200 followers
      expect(usersByFollowers[1].name, 'Alice'); // 150 followers
      expect(usersByFollowers[2].name, 'Bob'); // 50 followers
      print('Nested object ordering test passed!');
    });

    test('Multiple chained ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 100,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 25, // Same age as Alice
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 150, // More followers than Alice
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 3, 1),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Order by age ascending, then by followers descending
      final orderedUsers = await odm.users
          .orderBy((order) => order.age())
          .orderBy((order) => order.profile.followers(descending: true))
          .get();

      // Assert
      expect(orderedUsers.length, 3);
      // For age 25: Bob (150 followers) should come before Alice (100 followers)
      // Then Charlie (age 28)
      expect(orderedUsers[0].name, 'Bob'); // age 25, 150 followers
      expect(orderedUsers[1].name, 'Alice'); // age 25, 100 followers  
      expect(orderedUsers[2].name, 'Charlie'); // age 28
      print('Multiple chained ordering test passed!');
    });

    test('Combined filtering and ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: false, // Not active - should be filtered out
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 3, 1),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Filter active users and order by followers
      final activeUsersOrdered = await odm.users
          .where((filter) => filter.isActive(isEqualTo: true))
          .orderBy((order) => order.profile.followers(descending: true))
          .get();

      // Assert
      expect(activeUsersOrdered.length, 2); // Only Alice and Charlie are active
      expect(activeUsersOrdered[0].name, 'Charlie'); // 200 followers
      expect(activeUsersOrdered[1].name, 'Alice'); // 150 followers
      print('Combined filtering and ordering test passed!');
    });

    test('String field ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Alice',
          email: 'alice@example.com',
          age: 35,
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
        User(
          id: 'user3',
          name: 'Bob',
          email: 'bob@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 3, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Order by name alphabetically
      final usersByName = await odm.users
          .orderBy((order) => order.name())
          .get();

      // Assert
      expect(usersByName.length, 3);
      expect(usersByName[0].name, 'Alice'); // Alphabetically first
      expect(usersByName[1].name, 'Bob');
      expect(usersByName[2].name, 'Charlie'); // Alphabetically last
      print('String field ordering test passed!');
    });

    test('DateTime field ordering should work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 3, 1), // Latest
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 1, 1), // Earliest
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: false,
          rating: 4.0,
          createdAt: DateTime(2023, 2, 1), // Middle
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Order by createdAt descending (newest first)
      final usersByDate = await odm.users
          .orderBy((order) => order.createdAt(descending: true))
          .get();

      // Assert
      expect(usersByDate.length, 3);
      expect(usersByDate[0].name, 'Alice'); // 2023-03-01 (newest)
      expect(usersByDate[1].name, 'Charlie'); // 2023-02-01
      expect(usersByDate[2].name, 'Bob'); // 2023-01-01 (oldest)
      print('DateTime field ordering test passed!');
    });

    test('Legacy orderBy methods should still work', () async {
      // Arrange
      final testUsers = [
        User(
          id: 'user1',
          name: 'Alice',
          email: 'alice@example.com',
          age: 25,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime(2023, 1, 1),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: false,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime(2023, 2, 1),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
      ];

      for (final user in testUsers) {
        await odm.users.doc(user.id).set(user);
      }

      // Act - Use legacy orderByAge method
      final usersByAge = await odm.users
          .orderByAge(descending: true)
          .get();

      // Assert
      expect(usersByAge.length, 2);
      expect(usersByAge[0].name, 'Bob'); // age 35
      expect(usersByAge[1].name, 'Alice'); // age 25
      print('Legacy orderBy methods test passed!');
    });
  });
}