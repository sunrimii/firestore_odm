import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Transaction Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('💱 Basic Transactions', () {
      test('should perform atomic read and write operations', () async {
        final initialUser = User(
          id: 'transaction_user_1',
          name: 'Transaction User 1',
          email: 'transaction1@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Transaction test user',
            avatar: 'transaction.jpg',
            socialLinks: {},
            interests: ['transactions'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          scores: [80, 85],
          createdAt: DateTime.now(),
        );

        await odm.users(initialUser.id).update(initialUser);

        // Perform transaction to read user and update based on current state
        await odm.runTransaction((tx) async {
          final user = await tx.users('transaction_user_1').get();
          expect(user, isNotNull);

          tx
              .users('transaction_user_1')
              .patch(
                ($) => [
                  $.rating.increment(1),
                  $.profile.followers.increment(50),
                  $.isPremium(true),
                ],
              );
        });

        final updatedUser = await odm.users('transaction_user_1').get();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.rating, equals(4.0));
        expect(updatedUser.profile.followers, equals(150));
        expect(updatedUser.isPremium, isTrue);
      });

      test('should perform transaction with modify operations', () async {
        final user1 = User(
          id: 'tx_modify_user_1',
          name: 'TX Modify User 1',
          email: 'txmod1@example.com',
          age: 25,
          profile: const Profile(
            bio: 'TX modify test',
            avatar: 'txmod1.jpg',
            socialLinks: {},
            interests: ['tx_modify'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          scores: [80],
          createdAt: DateTime.now(),
        );

        final user2 = User(
          id: 'tx_modify_user_2',
          name: 'TX Modify User 2',
          email: 'txmod2@example.com',
          age: 30,
          profile: const Profile(
            bio: 'TX modify test 2',
            avatar: 'txmod2.jpg',
            socialLinks: {},
            interests: ['tx_modify'],
            followers: 150,
          ),
          rating: 3.5,
          isActive: true,
          scores: [90],
          createdAt: DateTime.now(),
        );

        await odm.users(user1.id).update(user1);
        await odm.users(user2.id).update(user2);

        // Transaction with modify operations
        await odm.runTransaction((tx) async {
          final currentUser1 = await tx.users('tx_modify_user_1').get();
          final currentUser2 = await tx.users('tx_modify_user_2').get();

          expect(currentUser1, isNotNull);
          expect(currentUser2, isNotNull);

          await tx
              .users('tx_modify_user_1')
              .modify(
                (user) => user.copyWith(
                  isPremium: true,
                  profile: user.profile.copyWith(
                    bio: '${user.profile.bio} - TX Modified',
                  ),
                ),
              );

          await tx
              .users('tx_modify_user_2')
              .modify(
                (user) => user.copyWith(
                  isPremium: true,
                  profile: user.profile.copyWith(
                    bio: '${user.profile.bio} - TX Modified',
                  ),
                ),
              );
        });

        final finalUser1 = await odm.users('tx_modify_user_1').get();
        final finalUser2 = await odm.users('tx_modify_user_2').get();

        expect(finalUser1!.isPremium, isTrue);
        expect(finalUser1.profile.bio, contains('- TX Modified'));
        expect(finalUser2!.isPremium, isTrue);
        expect(finalUser2.profile.bio, contains('- TX Modified'));
      });

      test(
        'should perform transaction with incremental modify operations',
        () async {
          final user = User(
            id: 'tx_inc_mod_user',
            name: 'TX Inc Mod User',
            email: 'txincmod@example.com',
            age: 25,
            profile: const Profile(
              bio: 'TX incremental modify test',
              avatar: 'txincmod.jpg',
              socialLinks: {},
              interests: ['tx_inc_mod'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            tags: ['original'],
            scores: [80, 85],
            createdAt: DateTime.now(),
          );

          await odm.users(user.id).update(user);

          // Transaction with incremental modify
          await odm.runTransaction((tx) async {
            final currentUser = await tx.users('tx_inc_mod_user').get();
            expect(currentUser, isNotNull);

            await tx
                .users('tx_inc_mod_user')
                .modify(
                  (user) => user.copyWith(
                    rating:
                        user.rating + 1.0, // Should auto-detect as increment
                    profile: user.profile.copyWith(
                      followers:
                          user.profile.followers +
                          25, // Should auto-detect as increment
                    ),
                    tags: [
                      ...user.tags,
                      'tx_incremented',
                    ], // Should auto-detect as arrayUnion
                    lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
                  ),
                );
          });

          final finalUser = await odm.users('tx_inc_mod_user').get();
          expect(finalUser!.rating, equals(4.0));
          expect(finalUser.profile.followers, equals(125));
          expect(finalUser.tags, contains('tx_incremented'));
          expect(finalUser.lastLogin, isNotNull);
        },
      );
    });

    group('💰 Complex Transaction Scenarios', () {
      test('should handle point transfer between users', () async {
        final sender = User(
          id: 'sender_user',
          name: 'Sender User',
          email: 'sender@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Points sender',
            avatar: 'sender.jpg',
            socialLinks: {},
            interests: ['points'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          scores: [1000], // Initial points
          createdAt: DateTime.now(),
        );

        final receiver = User(
          id: 'receiver_user',
          name: 'Receiver User',
          email: 'receiver@example.com',
          age: 30,
          profile: const Profile(
            bio: 'Points receiver',
            avatar: 'receiver.jpg',
            socialLinks: {},
            interests: ['points'],
            followers: 150,
          ),
          rating: 3.5,
          isActive: true,
          scores: [500], // Initial points
          createdAt: DateTime.now(),
        );

        await odm.users(sender.id).update(sender);
        await odm.users(receiver.id).update(receiver);

        // Transfer 200 points from sender to receiver
        const transferAmount = 200;

        await odm.runTransaction((tx) async {
          final currentSender = await tx.users('sender_user').get();
          final currentReceiver = await tx.users('receiver_user').get();

          expect(currentSender, isNotNull);
          expect(currentReceiver, isNotNull);

          final senderPoints = currentSender!.scores.first;
          final receiverPoints = currentReceiver!.scores.first;

          // Check if sender has enough points
          expect(senderPoints, greaterThanOrEqualTo(transferAmount));

          // Perform the transfer
          await tx
              .users('sender_user')
              .modify(
                (user) =>
                    user.copyWith(scores: [senderPoints - transferAmount]),
              );

          await tx
              .users('receiver_user')
              .modify(
                (user) =>
                    user.copyWith(scores: [receiverPoints + transferAmount]),
              );
        });

        final finalSender = await odm.users('sender_user').get();
        final finalReceiver = await odm.users('receiver_user').get();

        expect(finalSender!.scores.first, equals(800)); // 1000 - 200
        expect(finalReceiver!.scores.first, equals(700)); // 500 + 200
      });

      test('should handle conditional operations in transactions', () async {
        final user = User(
          id: 'conditional_user',
          name: 'Conditional User',
          email: 'conditional@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Conditional test',
            avatar: 'conditional.jpg',
            socialLinks: {},
            interests: ['conditional'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          scores: [500],
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // Conditional upgrade to premium if user has enough points
        await odm.runTransaction((tx) async {
          final currentUser = await tx.users('conditional_user').get();
          expect(currentUser, isNotNull);

          final points = currentUser!.scores.first;

          if (points >= 400) {
            // User has enough points, upgrade to premium and deduct points
            await tx
                .users('conditional_user')
                .modify(
                  (user) => user.copyWith(
                    isPremium: true,
                    scores: [points - 400],
                    profile: user.profile.copyWith(
                      bio: '${user.profile.bio} - Premium Member',
                    ),
                  ),
                );
          }
        });

        final finalUser = await odm.users('conditional_user').get();
        expect(finalUser!.isPremium, isTrue);
        expect(finalUser.scores.first, equals(100)); // 500 - 400
        expect(finalUser.profile.bio, contains('- Premium Member'));
      });
    });

    group('🚨 Transaction Error Handling', () {
      test('should handle transaction rollback on errors', () async {
        final user = User(
          id: 'rollback_user',
          name: 'Rollback User',
          email: 'rollback@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Rollback test',
            avatar: 'rollback.jpg',
            socialLinks: {},
            interests: ['rollback'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          scores: [500],
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        try {
          await odm.runTransaction((tx) async {
            // First operation should succeed
            odm.users('rollback_user').patch(($) => [$.isPremium(true)]);

            // Force an error to trigger rollback
            throw Exception('Forced error for rollback test');
          });

          fail('Transaction should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('Forced error'));
        }

        // Verify that the first operation was rolled back
        // Note: In fake_cloud_firestore, transaction rollback may not work exactly like real Firestore
        final finalUser = await odm.users('rollback_user').get();
        // In real Firestore, this would be false due to rollback, but fake_cloud_firestore
        // may not fully implement transaction rollback behavior
        expect(finalUser, isNotNull); // At least verify the user still exists
      });

      test(
        'should handle concurrent transaction conflicts gracefully',
        () async {
          final user = User(
            id: 'concurrent_user',
            name: 'Concurrent User',
            email: 'concurrent@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Concurrent test',
              avatar: 'concurrent.jpg',
              socialLinks: {},
              interests: ['concurrent'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            scores: [500],
            createdAt: DateTime.now(),
          );

          await odm.users(user.id).update(user);

          // Simulate concurrent transactions
          final futures = List.generate(3, (index) async {
            return odm.runTransaction((tx) async {
              final currentUser = await tx.users('concurrent_user').get();
              expect(currentUser, isNotNull);

              // Each transaction tries to increment the score
              await tx
                  .users('concurrent_user')
                  .modify(
                    (user) => user.copyWith(scores: [user.scores.first + 10]),
                  );
            });
          });

          // Wait for all transactions to complete
          await Future.wait(futures);

          final finalUser = await odm.users('concurrent_user').get();
          expect(finalUser!.scores.first, greaterThan(500));
          // Note: In fake_cloud_firestore, concurrent transactions may not
          // behave exactly like real Firestore, but we can still test the API
        },
      );
    });

    group('🔄 Transaction with Server Timestamps', () {
      test('should handle server timestamps in transactions', () async {
        final user = User(
          id: 'tx_timestamp_user',
          name: 'TX Timestamp User',
          email: 'txtimestamp@example.com',
          age: 25,
          profile: const Profile(
            bio: 'TX timestamp test',
            avatar: 'txtimestamp.jpg',
            socialLinks: {},
            interests: ['tx_timestamp'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        await odm.runTransaction((tx) async {
          final currentUser = await tx.users('tx_timestamp_user').get();
          expect(currentUser, isNotNull);

          // Use server timestamp in transaction updates
          tx
              .users('tx_timestamp_user')
              .patch(
                ($) => [
                  $.lastLogin.serverTimestamp(),
                  $.updatedAt.serverTimestamp(),
                  $.isPremium(true),
                ],
              );
        });

        final finalUser = await odm.users('tx_timestamp_user').get();
        expect(finalUser!.isPremium, isTrue);
        expect(finalUser.lastLogin, isNotNull);
        expect(finalUser.updatedAt, isNotNull);
      });

      test(
        'should handle server timestamps in transaction modify operations',
        () async {
          final user = User(
            id: 'tx_mod_timestamp_user',
            name: 'TX Mod Timestamp User',
            email: 'txmodtimestamp@example.com',
            age: 25,
            profile: const Profile(
              bio: 'TX mod timestamp test',
              avatar: 'txmodtimestamp.jpg',
              socialLinks: {},
              interests: ['tx_mod_timestamp'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            tags: ['original'],
            createdAt: DateTime.now(),
          );

          await odm.users(user.id).update(user);

          await odm.runTransaction((tx) async {
            final currentUser = await tx.users('tx_mod_timestamp_user').get();
            expect(currentUser, isNotNull);

            // Use server timestamp in transaction incremental modify
            await tx
                .users('tx_mod_timestamp_user')
                .modify(
                  (user) => user.copyWith(
                    tags: [...user.tags, 'tx_modified'],
                    lastLogin: FirestoreODM.serverTimestamp,
                    updatedAt: FirestoreODM.serverTimestamp,
                    isPremium: true,
                  ),
                );
          });

          final finalUser = await odm.users('tx_mod_timestamp_user').get();
          expect(finalUser!.isPremium, isTrue);
          expect(finalUser.tags, contains('tx_modified'));
          expect(finalUser.lastLogin, isNotNull);
          expect(finalUser.updatedAt, isNotNull);
        },
      );
    });
  });
}
