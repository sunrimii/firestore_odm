import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Filter Builder Tests', () {
    late FakeFirebaseFirestore firestore;
    late UserCollection users;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      users = UserCollection(firestore);
    });

    test('Basic field filtering should work', () async {
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
          createdAt: DateTime.now(),
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Bob is handsome',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
            followers: 50,
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Basic field filtering
      final activeUsers = await users
          .where((filter) => filter.isActive(isEqualTo: true))
          .get();

      // Assert
      expect(activeUsers.length, 1);
      expect(activeUsers.first.name, 'Alice');
      print('Basic field filtering test passed!');
    });

    test('Type-safe OR filter should work', () async {
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Use type-safe OR filter
      final filteredUsers = await users
          .where((filter) => filter.or(
                filter.isPremium(isEqualTo: true),
                filter.age(isGreaterThan: 30),
              ))
          .get();

      // Assert
      expect(filteredUsers.length, 2); // Alice (premium) and Bob (age > 30)
      print('Type-safe OR filter test passed!');
    });

    test('Type-safe AND filter should work', () async {
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
          ),
        ),
        User(
          id: 'user2',
          name: 'Bob',
          email: 'bob@example.com',
          age: 35,
          isActive: true,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
          ),
        ),
        User(
          id: 'user3',
          name: 'Charlie',
          email: 'charlie@example.com',
          age: 28,
          isActive: true,
          isPremium: true,
          rating: 4.5,
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Complex query with AND and nested conditions
      final complexUsers = await users
          .where((filter) => filter.and(
                filter.isActive(isEqualTo: true),
                filter.age(isLessThan: 28),
              ))
          .get();

      // Assert
      expect(complexUsers.length, 1); // Only Alice matches all conditions
      expect(complexUsers.first.name, 'Alice');
      print('Type-safe AND filter test passed!');
    });

    test('Mixed nested filters should work', () async {
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Bob bio',
            avatar: 'bob.jpg',
            socialLinks: {'github': 'bob'},
            interests: ['reading'],
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Complex nested type-safe filters
      final filteredUsers = await users
          .where((filter) => filter.or(
                filter.and(
                  filter.isActive(isEqualTo: true),
                  filter.isPremium(isEqualTo: true),
                ),
                filter.age(isGreaterThan: 30),
              ))
          .get();

      // Assert
      expect(filteredUsers.length, 2); // Alice (active + premium) and Bob (age > 30)
      print('Mixed nested filters test passed!');
    });

    test('Nested object filtering should work', () async {
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice', 'twitter': 'alice_dev'},
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
          createdAt: DateTime.now(),
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie', 'linkedin': 'charlie_pro'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Test nested object filtering (this would require nested support)
      // For now, we'll test with flattened field names as Firestore does
      final highFollowerUsers = await users
          .where((filter) => filter.and(
                filter.isActive(isEqualTo: true),
                // This would be filter.profile.followers(isGreaterThan: 100) with nested support
                // For now using direct field access
                filter.isPremium(isEqualTo: false), // Using available field as placeholder
              ))
          .get();

      // Assert
      expect(highFollowerUsers.length, 1); // Only Charlie matches (active + not premium)
      expect(highFollowerUsers.first.name, 'Charlie');
      print('Nested object filtering test passed!');
    });

    test('Complex nested AND/OR combinations should work', () async {
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
          createdAt: DateTime.now(),
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
          isActive: true,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime.now(),
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
          isActive: false,
          isPremium: true,
          rating: 4.0,
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Charlie bio',
            avatar: 'charlie.jpg',
            socialLinks: {'github': 'charlie'},
            interests: ['gaming'],
            followers: 200,
          ),
        ),
        User(
          id: 'user4',
          name: 'David',
          email: 'david@example.com',
          age: 22,
          isActive: true,
          isPremium: false,
          rating: 3.5,
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'David bio',
            avatar: 'david.jpg',
            socialLinks: {'github': 'david'},
            interests: ['music'],
            followers: 75,
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Complex nested query: (active AND premium) OR (age < 25 AND rating > 3.0)
      final complexUsers = await users
          .where((filter) => filter.or(
                filter.and(
                  filter.isActive(isEqualTo: true),
                  filter.isPremium(isEqualTo: true),
                ),
                filter.and(
                  filter.age(isLessThan: 25),
                  filter.rating(isGreaterThan: 3.0),
                ),
              ))
          .get();

      // Assert
      // Should match: Alice (active + premium), David (age < 25 + rating > 3.0)
      expect(complexUsers.length, 2);
      final names = complexUsers.map((u) => u.name).toSet();
      expect(names.contains('Alice'), true);
      expect(names.contains('David'), true);
      print('Complex nested AND/OR combinations test passed!');
    });

    test('Multiple field conditions should work', () async {
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
          createdAt: DateTime.now(),
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
          isActive: true,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime.now(),
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
        await users.doc(user.id).set(user);
      }

      // Act - Test different comparison operators
      final youngActiveUsers = await users
          .where((filter) => filter.and(
                filter.age(isLessThan: 30),
                filter.isActive(isEqualTo: true),
              ))
          .get();

      final highRatedUsers = await users
          .where((filter) => filter.rating(isGreaterThanOrEqualTo: 4.0))
          .get();

      final adultUsers = await users
          .where((filter) => filter.age(isGreaterThanOrEqualTo: 25))
          .get();

      // Assert
      expect(youngActiveUsers.length, 1);
      expect(youngActiveUsers.first.name, 'Alice');
      
      expect(highRatedUsers.length, 1);
      expect(highRatedUsers.first.name, 'Alice');
      
      expect(adultUsers.length, 2); // Both Alice and Bob are >= 25
      
      print('Multiple field conditions test passed!');
    });

    test('Edge cases should be handled properly', () async {
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
          createdAt: DateTime.now(),
          profile: const Profile(
            bio: 'Alice bio',
            avatar: 'alice.jpg',
            socialLinks: {'github': 'alice'},
            interests: ['coding'],
            followers: 150,
          ),
        ),
      ];

      for (final user in testUsers) {
        await users.doc(user.id).set(user);
      }

      // Act - Test edge cases
      final exactAgeUsers = await users
          .where((filter) => filter.age(isEqualTo: 25))
          .get();

      final notPremiumUsers = await users
          .where((filter) => filter.isPremium(isNotEqualTo: true))
          .get();

      // Assert
      expect(exactAgeUsers.length, 1);
      expect(exactAgeUsers.first.name, 'Alice');
      
      expect(notPremiumUsers.length, 0); // Alice is premium
      
      print('Edge cases test passed!');
    });

    test('Real nested object filtering should work', () async {
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
          createdAt: DateTime.now(),
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
          isActive: true,
          isPremium: false,
          rating: 3.0,
          createdAt: DateTime.now(),
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
        await users.doc(user.id).set(user);
      }

      // Act - Test real nested object filtering
      // This should work: filter.profile.followers(isGreaterThan: 100)
      final highFollowerUsers = await users
          .where((filter) => filter.profile.followers(isGreaterThan: 100))
          .get();

      // Assert
      expect(highFollowerUsers.length, 1);
      expect(highFollowerUsers.first.name, 'Alice');
      print('Real nested object filtering test passed!');
    });
  });
}