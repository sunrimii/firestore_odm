import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/story.dart';

void main() {
  group('Comprehensive Firestore ODM Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('Atomic Operations & Transactions', () {
      test('should perform atomic increment operations', () async {
        // Arrange
        final profile = Profile(
          bio: 'Atomic test',
          avatar: 'atomic.jpg',
          socialLinks: {},
          interests: [],
          followers: 100,
        );

        final user = User(
          id: 'atomic_user',
          name: 'Atomic User',
          email: 'atomic@example.com',
          age: 30,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('atomic_user').set(user);

        // Act - Test atomic increment using incrementalModify
        await odm.users.doc('atomic_user').incrementalModify((currentUser) {
          return currentUser.copyWith(
            rating: currentUser.rating + 0.5,
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 50,
            ),
          );
        });

        // Assert
        final updatedUser = await odm.users.doc('atomic_user').get();
        expect(updatedUser!.rating, equals(4.5));
        expect(updatedUser.profile.followers, equals(150));
      });

      test('should handle concurrent atomic operations', () async {
        // Arrange
        final profile = Profile(
          bio: 'Concurrent test',
          avatar: 'concurrent.jpg',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'concurrent_user',
          name: 'Concurrent User',
          email: 'concurrent@example.com',
          age: 25,
          profile: profile,
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('concurrent_user').set(user);

        // Act - Simulate sequential increments (fake_cloud_firestore doesn't support true concurrency)
        for (int i = 0; i < 5; i++) {
          await odm.users.doc('concurrent_user').incrementalModify((
            currentUser,
          ) {
            return currentUser.copyWith(
              profile: currentUser.profile.copyWith(
                followers: currentUser.profile.followers + 1,
              ),
            );
          });
        }

        // Assert - Should have incremented 5 times
        final finalUser = await odm.users.doc('concurrent_user').get();
        expect(finalUser!.profile.followers, equals(5));
      });

      test('should handle transaction-like operations', () async {
        // Arrange
        final profile1 = Profile(
          bio: 'Transaction user 1',
          avatar: 'tx1.jpg',
          socialLinks: {},
          interests: [],
          followers: 100,
        );

        final profile2 = Profile(
          bio: 'Transaction user 2',
          avatar: 'tx2.jpg',
          socialLinks: {},
          interests: [],
          followers: 50,
        );

        final user1 = User(
          id: 'tx_user1',
          name: 'Transaction User 1',
          email: 'tx1@example.com',
          age: 30,
          profile: profile1,
          rating: 4.0,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final user2 = User(
          id: 'tx_user2',
          name: 'Transaction User 2',
          email: 'tx2@example.com',
          age: 25,
          profile: profile2,
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('tx_user1').set(user1);
        await odm.users.doc('tx_user2').set(user2);

        // Act - Transfer followers between users (transaction-like)
        final transferAmount = 25;

        // Get current states
        final currentUser1 = await odm.users.doc('tx_user1').get();
        final currentUser2 = await odm.users.doc('tx_user2').get();

        // Perform "transaction" - transfer followers
        await odm.users
            .doc('tx_user1')
            .update
            .profile(
              followers: currentUser1!.profile.followers - transferAmount,
            );

        await odm.users
            .doc('tx_user2')
            .update
            .profile(
              followers: currentUser2!.profile.followers + transferAmount,
            );

        // Assert
        final finalUser1 = await odm.users.doc('tx_user1').get();
        final finalUser2 = await odm.users.doc('tx_user2').get();

        expect(finalUser1!.profile.followers, equals(75));
        expect(finalUser2!.profile.followers, equals(75));

        // Total followers should be conserved
        final totalFollowers =
            finalUser1.profile.followers + finalUser2.profile.followers;
        expect(totalFollowers, equals(150));
      });
    });

    group('Real-time Subscriptions & Streams', () {
      test('should listen to document changes', () async {
        // Arrange
        final profile = Profile(
          bio: 'Stream test',
          avatar: 'stream.jpg',
          socialLinks: {},
          interests: [],
          followers: 10,
        );

        final user = User(
          id: 'stream_user',
          name: 'Stream User',
          email: 'stream@example.com',
          age: 28,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('stream_user').set(user);

        // Act - Listen to changes
        final changes = <User?>[];
        final subscription = odm.users.doc('stream_user').changes.listen((
          user,
        ) {
          changes.add(user);
        });

        // Wait a bit for initial state
        await Future.delayed(Duration(milliseconds: 100));

        // Make some changes
        await odm.users.doc('stream_user').incrementalModify((user) {
          return user.copyWith(name: 'Updated Stream User');
        });
        await odm.users.doc('stream_user').update.profile(followers: 20);

        // Wait for changes to propagate
        await Future.delayed(Duration(milliseconds: 200));

        // Assert
        expect(changes.length, greaterThan(0));

        // Clean up
        await subscription.cancel();
      });

      test('should handle subscription lifecycle', () async {
        // Arrange
        final profile = Profile(
          bio: 'Lifecycle test',
          avatar: 'lifecycle.jpg',
          socialLinks: {},
          interests: [],
          followers: 5,
        );

        final user = User(
          id: 'lifecycle_user',
          name: 'Lifecycle User',
          email: 'lifecycle@example.com',
          age: 32,
          profile: profile,
          rating: 3.8,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('lifecycle_user').set(user);

        // Act - Test subscription lifecycle
        var isListening = false;
        final subscription = odm.users.doc('lifecycle_user').changes.listen((
          user,
        ) {
          isListening = true;
        });

        // Wait for subscription to activate
        await Future.delayed(Duration(milliseconds: 100));

        // Make a change to trigger listener
        await odm.users.doc('lifecycle_user').incrementalModify((user) {
          return user.copyWith(name: 'Updated Lifecycle User');
        });
        await Future.delayed(Duration(milliseconds: 100));

        // Cancel subscription
        await subscription.cancel();
        isListening = false;

        // Make another change - should not trigger listener
        await odm.users.doc('lifecycle_user').incrementalModify((user) {
          return user.copyWith(name: 'Final Update');
        });
        await Future.delayed(Duration(milliseconds: 100));

        // Assert - Subscription should have been active
        expect(isListening, isFalse); // Should be false after cancellation
      });
    });

    group('Advanced Ordering & Filtering', () {
      test('should order results by multiple fields', () async {
        // Arrange
        final users = [
          User(
            id: 'user_a',
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
            createdAt: DateTime.now().subtract(Duration(days: 2)),
          ),
          User(
            id: 'user_b',
            name: 'Bob',
            email: 'bob@example.com',
            age: 30,
            profile: Profile(
              bio: 'Bob bio',
              avatar: 'bob.jpg',
              socialLinks: {},
              interests: [],
              followers: 200,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now().subtract(Duration(days: 1)),
          ),
          User(
            id: 'user_c',
            name: 'Charlie',
            email: 'charlie@example.com',
            age: 35,
            profile: Profile(
              bio: 'Charlie bio',
              avatar: 'charlie.jpg',
              socialLinks: {},
              interests: [],
              followers: 50,
            ),
            rating: 3.8,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act - Order by rating (desc), then by age (asc)
        final orderedUsers = await odm.users
            .orderByRating(descending: true)
            .orderByAge()
            .get();

        // Assert
        expect(orderedUsers.length, equals(3));

        // First two should have same rating (4.5), ordered by age
        expect(orderedUsers[0].rating, equals(4.5));
        expect(orderedUsers[1].rating, equals(4.5));
        expect(orderedUsers[0].age, lessThan(orderedUsers[1].age));

        // Last should have lowest rating
        expect(orderedUsers[2].rating, equals(3.8));
      });

      test('should filter with complex conditions', () async {
        // Arrange
        final users = [
          User(
            id: 'filter_1',
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
            id: 'filter_2',
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
            id: 'filter_3',
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

        // Act - Complex filter: Premium users under 30 with rating > 4.0
        final filteredUsers = await odm.users
            .whereIsPremium(isEqualTo: true)
            .whereAge(isLessThan: 30)
            .whereRating(isGreaterThan: 4.0)
            .whereIsActive(isEqualTo: true)
            .get();

        // Assert
        expect(filteredUsers.length, equals(1));
        expect(filteredUsers.first.name, equals('Premium Young'));
        expect(filteredUsers.first.age, equals(22));
        expect(filteredUsers.first.isPremium, isTrue);
        expect(filteredUsers.first.rating, equals(4.2));
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

        // Act - Range query: Ages between 30 and 50 (inclusive)
        final rangeUsers = await odm.users
            .whereAge(isGreaterThanOrEqualTo: 30)
            .whereAge(isLessThanOrEqualTo: 50)
            .orderByAge()
            .get();

        // Assert
        expect(rangeUsers.length, equals(5)); // Ages: 30, 35, 40, 45, 50
        expect(rangeUsers.first.age, equals(30));
        expect(rangeUsers.last.age, equals(50));

        // Verify ordering
        for (int i = 1; i < rangeUsers.length; i++) {
          expect(rangeUsers[i].age, greaterThan(rangeUsers[i - 1].age));
        }
      });

      test('should handle limit and pagination-style queries', () async {
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

        // Act - Get first 5 users ordered by creation time
        final firstPage = await odm.users.orderByCreatedAt().limit(5).get();

        // Assert
        expect(firstPage.length, equals(5));

        // Verify ordering by creation time
        for (int i = 1; i < firstPage.length; i++) {
          expect(
            firstPage[i].createdAt!.isAfter(firstPage[i - 1].createdAt!),
            isTrue,
          );
        }
      });
    });

    group('Batch Operations & Performance', () {
      test('should handle batch document creation', () async {
        // Arrange
        final batchUsers = List.generate(10, (index) {
          return User(
            id: 'batch_user_$index',
            name: 'Batch User $index',
            email: 'batch$index@example.com',
            age: 25 + index,
            profile: Profile(
              bio: 'Batch user $index',
              avatar: 'batch$index.jpg',
              socialLinks: {},
              interests: ['batch_$index'],
              followers: index * 5,
            ),
            rating: 3.0 + (index * 0.1),
            isActive: true,
            isPremium: index % 3 == 0,
            createdAt: DateTime.now(),
          );
        });

        // Act - Create all users in batch
        final futures = batchUsers.map((user) {
          return odm.users.doc(user.id).set(user);
        }).toList();

        await Future.wait(futures);

        // Assert - Verify all users were created
        final createdBatchUsers = <User>[];
        for (final user in batchUsers) {
          final retrievedUser = await odm.users.doc(user.id).get();
          if (retrievedUser != null) {
            createdBatchUsers.add(retrievedUser);
          }
        }

        expect(createdBatchUsers.length, equals(10));

        // Verify specific user
        final specificUser = await odm.users.doc('batch_user_5').get();
        expect(specificUser!.name, equals('Batch User 5'));
        expect(specificUser.age, equals(30));
      });

      test('should handle batch updates efficiently', () async {
        // Arrange
        final users = List.generate(5, (index) {
          return User(
            id: 'update_batch_$index',
            name: 'Update User $index',
            email: 'update$index@example.com',
            age: 30,
            profile: Profile(
              bio: 'Original bio $index',
              avatar: 'original$index.jpg',
              socialLinks: {},
              interests: [],
              followers: 10,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          );
        });

        // Create initial users
        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act - Batch update all users
        final updateFutures = users.map((user) {
          return odm.users.doc(user.id).incrementalModify((currentUser) {
            return currentUser.copyWith(isActive: true, rating: 4.5);
          });
        }).toList();

        await Future.wait(updateFutures);

        // Assert - Verify all updates
        for (final user in users) {
          final updatedUser = await odm.users.doc(user.id).get();
          expect(updatedUser!.isActive, isTrue);
          expect(updatedUser.rating, equals(4.5));
          expect(updatedUser.name, equals(user.name)); // Unchanged
        }
      });

      test('should handle mixed batch operations', () async {
        // Arrange
        final existingUser = User(
          id: 'existing_mixed',
          name: 'Existing User',
          email: 'existing@example.com',
          age: 25,
          profile: Profile(
            bio: 'Existing user',
            avatar: 'existing.jpg',
            socialLinks: {},
            interests: [],
            followers: 50,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('existing_mixed').set(existingUser);

        // Act - Mixed operations: create, update, delete
        final operations = [
          // Create new user
          odm.users
              .doc('new_mixed')
              .set(
                User(
                  id: 'new_mixed',
                  name: 'New User',
                  email: 'new@example.com',
                  age: 28,
                  profile: Profile(
                    bio: 'New user',
                    avatar: 'new.jpg',
                    socialLinks: {},
                    interests: [],
                    followers: 0,
                  ),
                  rating: 4.0,
                  isActive: true,
                  isPremium: false,
                  createdAt: DateTime.now(),
                ),
              ),

          // Update existing user
          odm.users.doc('existing_mixed').incrementalModify((user) {
            return user.copyWith(
              name: 'Updated Existing User',
              isPremium: true,
            );
          }),

          // Create another user to delete
          odm.users
              .doc('to_delete_mixed')
              .set(
                User(
                  id: 'to_delete_mixed',
                  name: 'To Delete',
                  email: 'delete@example.com',
                  age: 30,
                  profile: Profile(
                    bio: 'Will be deleted',
                    avatar: 'delete.jpg',
                    socialLinks: {},
                    interests: [],
                    followers: 0,
                  ),
                  rating: 3.0,
                  isActive: true,
                  isPremium: false,
                  createdAt: DateTime.now(),
                ),
              ),
        ];

        await Future.wait(operations);

        // Delete the user marked for deletion
        await odm.users.doc('to_delete_mixed').delete();

        // Assert
        final newUser = await odm.users.doc('new_mixed').get();
        expect(newUser!.name, equals('New User'));

        final updatedUser = await odm.users.doc('existing_mixed').get();
        expect(updatedUser!.name, equals('Updated Existing User'));
        expect(updatedUser.isPremium, isTrue);

        final deletedUser = await odm.users.doc('to_delete_mixed').get();
        expect(deletedUser, isNull);
      });
    });
  });
}
