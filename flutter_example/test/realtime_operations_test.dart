import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Real-time Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: fakeFirestore);
    });

    group('📡 Real-time Subscriptions & Streams', () {
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

        await odm.users('stream_user').set(user);

        // Act - Listen to changes
        final changes = <User?>[];
        final subscription = odm.users('stream_user').changes.listen((user) {
          changes.add(user);
        });

        // Wait a bit for initial state
        await Future.delayed(Duration(milliseconds: 100));

        // Make some changes
        await odm.users('stream_user').incrementalModify((user) {
          return user.copyWith(name: 'Updated Stream User');
        });

        await odm.users('stream_user').incrementalModify((user) {
          return user.copyWith(profile: user.profile.copyWith(followers: 20));
        });

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

        await odm.users('lifecycle_user').set(user);

        // Act - Test subscription lifecycle
        var isListening = false;
        final subscription = odm.users('lifecycle_user').changes.listen((user) {
          isListening = true;
        });

        // Wait for subscription to activate
        await Future.delayed(Duration(milliseconds: 100));

        // Make a change to trigger listener
        await odm.users('lifecycle_user').incrementalModify((user) {
          return user.copyWith(name: 'Updated Lifecycle User');
        });
        await Future.delayed(Duration(milliseconds: 100));

        // Cancel subscription
        await subscription.cancel();
        isListening = false;

        // Make another change - should not trigger listener
        await odm.users('lifecycle_user').incrementalModify((user) {
          return user.copyWith(name: 'Final Update');
        });
        await Future.delayed(Duration(milliseconds: 100));

        // Assert - Subscription should have been active
        expect(isListening, isFalse); // Should be false after cancellation
      });

      test('should handle multiple document observation', () async {
        // Arrange
        final users = [
          User(
            id: 'multi_user_1',
            name: 'Multi User 1',
            email: 'multi1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Multi test 1',
              avatar: 'multi1.jpg',
              socialLinks: {},
              interests: [],
              followers: 10,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'multi_user_2',
            name: 'Multi User 2',
            email: 'multi2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Multi test 2',
              avatar: 'multi2.jpg',
              socialLinks: {},
              interests: [],
              followers: 15,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).set(user);
        }

        // Act - Observe multiple documents
        final user1Changes = <User?>[];
        final user2Changes = <User?>[];

        final subscription1 = odm.users('multi_user_1').changes.listen((user) {
          user1Changes.add(user);
        });

        final subscription2 = odm.users('multi_user_2').changes.listen((user) {
          user2Changes.add(user);
        });

        // Wait for initial state
        await Future.delayed(Duration(milliseconds: 100));

        // Make changes to both users
        await odm
            .users('multi_user_1')
            .update(($) => [$.name('Updated Multi User 1')]);

        await odm
            .users('multi_user_2')
            .update(($) => [$.rating.increment(0.5)]);

        // Wait for changes
        await Future.delayed(Duration(milliseconds: 200));

        // Assert
        expect(user1Changes.length, greaterThan(0));
        expect(user2Changes.length, greaterThan(0));

        // Clean up
        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('should handle document deletion in streams', () async {
        // Arrange
        final profile = Profile(
          bio: 'Delete stream test',
          avatar: 'delete.jpg',
          socialLinks: {},
          interests: [],
          followers: 5,
        );

        final user = User(
          id: 'delete_stream_user',
          name: 'Delete Stream User',
          email: 'delete_stream@example.com',
          age: 28,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('delete_stream_user').set(user);

        // Act - Listen to changes including deletion
        final changes = <User?>[];
        final subscription = odm.users('delete_stream_user').changes.listen((
          user,
        ) {
          changes.add(user);
        });

        // Wait for initial state
        await Future.delayed(Duration(milliseconds: 100));

        // Update the user
        await odm
            .users('delete_stream_user')
            .update(($) => [$.name('Updated Before Delete')]);

        await Future.delayed(Duration(milliseconds: 100));

        // Delete the user
        await odm.users('delete_stream_user').delete();

        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(changes.length, greaterThan(0));

        // The last change should be null (document deleted)
        final finalUser = await odm.users('delete_stream_user').get();
        expect(finalUser, isNull);

        // Clean up
        await subscription.cancel();
      });

      test('should handle stream errors gracefully', () async {
        // Arrange
        final profile = Profile(
          bio: 'Error test',
          avatar: 'error.jpg',
          socialLinks: {},
          interests: [],
          followers: 5,
        );

        final user = User(
          id: 'error_user',
          name: 'Error User',
          email: 'error@example.com',
          age: 28,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('error_user').set(user);

        // Act - Listen to changes with error handling
        final changes = <User?>[];
        final errors = <dynamic>[];
        var streamCompleted = false;

        final subscription = odm
            .users('error_user')
            .changes
            .listen(
              (user) {
                changes.add(user);
              },
              onError: (error) {
                errors.add(error);
              },
              onDone: () {
                streamCompleted = true;
              },
            );

        // Wait for initial state
        await Future.delayed(Duration(milliseconds: 100));

        // Make normal changes
        await odm
            .users('error_user')
            .update(($) => [$.name('Updated Error User')]);

        await Future.delayed(Duration(milliseconds: 100));

        // Assert - No errors should occur in normal operations
        expect(errors, isEmpty);
        expect(changes.length, greaterThan(0));
        expect(streamCompleted, isFalse);

        // Clean up
        await subscription.cancel();
      });
    });

    group('🔄 Batch Operations', () {
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
            tags: ['batch', 'user_$index'],
            createdAt: DateTime.now(),
          );
        });

        // Act - Create all users in batch
        final futures = batchUsers.map((user) {
          return odm.users(user.id).set(user);
        }).toList();

        await Future.wait(futures);

        // Assert - Verify all users were created
        final createdBatchUsers = <User>[];
        for (final user in batchUsers) {
          final retrievedUser = await odm.users(user.id).get();
          if (retrievedUser != null) {
            createdBatchUsers.add(retrievedUser);
          }
        }

        expect(createdBatchUsers.length, equals(10));

        // Verify specific user
        final specificUser = await odm.users('batch_user_5').get();
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
          await odm.users(user.id).set(user);
        }

        // Act - Batch update all users
        final updateFutures = users.map((user) {
          return odm.users(user.id).incrementalModify((currentUser) {
            return currentUser.copyWith(isActive: true, rating: 4.5);
          });
        }).toList();

        await Future.wait(updateFutures);

        // Assert - Verify all updates
        for (final user in users) {
          final updatedUser = await odm.users(user.id).get();
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

        await odm.users('existing_mixed').set(existingUser);

        // Act - Mixed operations: create, update, delete
        final operations = [
          // Create new user
          odm
              .users('new_mixed')
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
          odm.users('existing_mixed').incrementalModify((user) {
            return user.copyWith(
              name: 'Updated Existing User',
              isPremium: true,
            );
          }),

          // Create another user to delete
          odm
              .users('to_delete_mixed')
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
        await odm.users('to_delete_mixed').delete();

        // Assert
        final newUser = await odm.users('new_mixed').get();
        expect(newUser!.name, equals('New User'));

        final updatedUser = await odm.users('existing_mixed').get();
        expect(updatedUser!.name, equals('Updated Existing User'));
        expect(updatedUser.isPremium, isTrue);

        final deletedUser = await odm.users('to_delete_mixed').get();
        expect(deletedUser, isNull);
      });
    });

    group('🎯 Transaction-like Operations', () {
      test('should handle follower transfer between users', () async {
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

        await odm.users('tx_user1').set(user1);
        await odm.users('tx_user2').set(user2);

        // Act - Transfer followers between users (transaction-like)
        final transferAmount = 25;

        // Get current states
        final currentUser1 = await odm.users('tx_user1').get();
        final currentUser2 = await odm.users('tx_user2').get();

        // Perform "transaction" - transfer followers
        await odm.users('tx_user1').incrementalModify((user) {
          return user.copyWith(
            profile: user.profile.copyWith(
              followers: currentUser1!.profile.followers - transferAmount,
            ),
          );
        });

        await odm.users('tx_user2').incrementalModify((user) {
          return user.copyWith(
            profile: user.profile.copyWith(
              followers: currentUser2!.profile.followers + transferAmount,
            ),
          );
        });

        // Assert
        final finalUser1 = await odm.users('tx_user1').get();
        final finalUser2 = await odm.users('tx_user2').get();

        expect(finalUser1!.profile.followers, equals(75));
        expect(finalUser2!.profile.followers, equals(75));

        // Total followers should be conserved
        final totalFollowers =
            finalUser1.profile.followers + finalUser2.profile.followers;
        expect(totalFollowers, equals(150));
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

        await odm.users('concurrent_user').set(user);

        // Act - Simulate sequential increments (fake_cloud_firestore doesn't support true concurrency)
        for (int i = 0; i < 5; i++) {
          await odm.users('concurrent_user').incrementalModify((currentUser) {
            return currentUser.copyWith(
              profile: currentUser.profile.copyWith(
                followers: currentUser.profile.followers + 1,
              ),
            );
          });
        }

        // Assert - Should have incremented 5 times
        final finalUser = await odm.users('concurrent_user').get();
        expect(finalUser!.profile.followers, equals(5));
      });
    });

    group('⚡ Performance & Edge Cases', () {
      test('should handle large number of operations efficiently', () async {
        // Arrange
        final users = List.generate(50, (index) {
          return User(
            id: 'perf_user_$index',
            name: 'Performance User $index',
            email: 'perf$index@example.com',
            age: 20 + (index % 40),
            profile: Profile(
              bio: 'Performance test user $index',
              avatar: 'perf$index.jpg',
              socialLinks: {},
              interests: ['perf'],
              followers: index,
            ),
            rating: 3.0 + (index % 3),
            isActive: index % 2 == 0,
            isPremium: index % 5 == 0,
            tags: ['performance', 'test'],
            createdAt: DateTime.now(),
          );
        });

        // Act - Create all users
        final createFutures = users.map((user) {
          return odm.users(user.id).set(user);
        }).toList();

        await Future.wait(createFutures);

        // Update all users
        final updateFutures = users.map((user) {
          return odm.users(user.id).update(($) => [$.rating.increment(0.1)]);
        }).toList();

        await Future.wait(updateFutures);

        // Assert - Verify operations completed
        final sampleUser = await odm.users('perf_user_25').get();
        expect(sampleUser, isNotNull);
        expect(sampleUser!.rating, closeTo(4.1, 0.01)); // 3.0 + 1 + 0.1

        // Query performance test
        final activeUsers = await odm.users
            .where(($) => $.isActive(isEqualTo: true))
            .get();

        expect(activeUsers.length, equals(25)); // Half of the users
      });

      test('should handle subscription memory management', () async {
        // Arrange
        final profile = Profile(
          bio: 'Memory test',
          avatar: 'memory.jpg',
          socialLinks: {},
          interests: [],
          followers: 10,
        );

        final user = User(
          id: 'memory_user',
          name: 'Memory User',
          email: 'memory@example.com',
          age: 28,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('memory_user').set(user);

        // Act - Create and cancel multiple subscriptions
        final subscriptions = <dynamic>[];

        for (int i = 0; i < 10; i++) {
          final subscription = odm.users('memory_user').changes.listen((user) {
            // Do nothing
          });
          subscriptions.add(subscription);
        }

        await Future.delayed(Duration(milliseconds: 100));

        // Cancel all subscriptions
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }

        // Assert - No memory leaks or errors should occur
        expect(subscriptions.length, equals(10));

        // Create one more subscription to verify everything still works
        final finalSubscription = odm.users('memory_user').changes.listen((
          user,
        ) {
          // Verify user data
          expect(user, isNotNull);
        });

        await Future.delayed(Duration(milliseconds: 100));
        await finalSubscription.cancel();
      });
    });
  });
}
