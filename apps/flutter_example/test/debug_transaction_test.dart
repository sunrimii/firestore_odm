import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔍 Debug Transaction Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'should test direct modify of two different users without get()',
      () async {
        // Setup: Create two users first
        final user1 = User(
          id: 'debug_user_1',
          name: 'Debug User 1',
          email: 'debug1@test.com',
          age: 25,
          profile: const Profile(
            bio: 'Debug User 1',
            avatar: 'debug1.jpg',
            socialLinks: {},
            interests: ['debug'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          createdAt: DateTime.now(),
        );

        final user2 = User(
          id: 'debug_user_2',
          name: 'Debug User 2',
          email: 'debug2@test.com',
          age: 30,
          profile: const Profile(
            bio: 'Debug User 2',
            avatar: 'debug2.jpg',
            socialLinks: {},
            interests: ['debug'],
            followers: 200,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Create users first
        await odm.users(user1.id).update(user1);
        await odm.users(user2.id).update(user2);

        print('🧪 Testing direct modify without get() calls...');

        try {
          // Test: Direct modify of two different users in transaction
          await odm.runTransaction((tx) async {
            print('📝 Modifying user1...');
            await tx
                .users('debug_user_1')
                .modify(
                  (user) => user.copyWith(
                    isPremium: true,
                    profile: user.profile.copyWith(bio: 'Modified User 1'),
                  ),
                );

            print('📝 Modifying user2...');
            await tx
                .users('debug_user_2')
                .modify(
                  (user) => user.copyWith(
                    isPremium: true,
                    profile: user.profile.copyWith(bio: 'Modified User 2'),
                  ),
                );
          });

          print('✅ Transaction succeeded!');

          // Verify results
          final finalUser1 = await odm.users('debug_user_1').get();
          final finalUser2 = await odm.users('debug_user_2').get();

          expect(finalUser1!.isPremium, isTrue);
          expect(finalUser1.profile.bio, equals('Modified User 1'));
          expect(finalUser2!.isPremium, isTrue);
          expect(finalUser2.profile.bio, equals('Modified User 2'));
        } catch (e) {
          print('❌ Transaction failed: $e');
          rethrow;
        }
      },
    );
  });
}
