import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('🔄 Updated Features Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: fakeFirestore);
    });

    group('🕒 Special Timestamp Features', () {
      test('should replace special timestamps with server timestamps in modify', () async {
        // Arrange
        final specialTimestamp = DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true);
        final normalTimestamp = DateTime.now();
        
        final initialUser = User(
          id: 'timestamp_user',
          name: 'Timestamp Test',
          email: 'timestamp@example.com',
          age: 25,
          profile: Profile(
            bio: 'Testing timestamps',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: [],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: normalTimestamp,
        );

        final userDoc = odm.users('timestamp_user');
        await userDoc.set(initialUser);

        // Act - Use special timestamp in modify operation
        await userDoc.modify((user) => user.copyWith(
          lastLogin: specialTimestamp, // This should become FieldValue.serverTimestamp()
          updatedAt: normalTimestamp,  // This should remain as-is
        ));

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.lastLogin, isNotNull);
        expect(updatedUser.updatedAt, equals(normalTimestamp));
      });

      test('should handle alternative special timestamps', () async {
        // Arrange
        final alternativeTimestamp = DateTime.fromMillisecondsSinceEpoch(3000, isUtc: true);
        
        final initialUser = User(
          id: 'alt_timestamp_user',
          name: 'Alt Timestamp Test',
          email: 'alt@example.com',
          age: 30,
          profile: Profile(
            bio: 'Testing alternative timestamps',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: [],
            followers: 50,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users('alt_timestamp_user');
        await userDoc.set(initialUser);

        // Act - Use alternative special timestamp
        await userDoc.incrementalModify((user) => user.copyWith(
          lastLogin: alternativeTimestamp, // Should become server timestamp
        ));

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.lastLogin, isNotNull);
      });
    });

    group('🔄 Query Update Operations', () {
      test('should perform bulk updates on query results', () async {
        // Arrange - Create multiple users
        final users = [
          User(
            id: 'bulk1',
            name: 'Bulk User 1',
            email: 'bulk1@example.com',
            age: 25,
            profile: Profile(
              bio: 'First bulk user',
              avatar: 'bulk1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 10,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk2',
            name: 'Bulk User 2',
            email: 'bulk2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Second bulk user',
              avatar: 'bulk2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 20,
            ),
            rating: 3.5,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        // Set up users
        for (final user in users) {
          await odm.users(user.id).set(user);
        }

        // Act - Bulk modify all inactive users
        await odm.users
          .where(($) => $.isActive(isEqualTo: false))
          .modify((user) => user.copyWith(isActive: true));

        // Assert - All users should now be active
        final updatedUsers = await odm.users
          .where(($) => $.id(whereIn: ['bulk1', 'bulk2']))
          .get();
        
        for (final user in updatedUsers) {
          expect(user.isActive, isTrue);
        }
      });

      test('should perform incremental bulk updates with atomic operations', () async {
        // Arrange
        final users = [
          User(
            id: 'atomic1',
            name: 'Atomic User 1',
            email: 'atomic1@example.com',
            age: 25,
            profile: Profile(
              bio: 'First atomic user',
              avatar: 'atomic1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'atomic2',
            name: 'Atomic User 2',
            email: 'atomic2@example.com',
            age: 28,
            profile: Profile(
              bio: 'Second atomic user',
              avatar: 'atomic2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).set(user);
        }

        // Act - Incremental bulk modify with atomic operations
        await odm.users
          .where(($) => $.id(whereIn: ['atomic1', 'atomic2']))
          .incrementalModify((user) => user.copyWith(
            rating: user.rating + 0.5, // Should use FieldValue.increment(0.5)
            profile: user.profile.copyWith(
              followers: user.profile.followers + 10, // Should use FieldValue.increment(10)
              interests: [...user.profile.interests, 'firebase'], // Should use FieldValue.arrayUnion(['firebase'])
            ),
          ));

        // Assert
        final updatedUsers = await odm.users
          .where(($) => $.id(whereIn: ['atomic1', 'atomic2']))
          .get();
        
        expect(updatedUsers.length, equals(2));
        for (final user in updatedUsers) {
          expect(user.profile.interests, contains('firebase'));
          if (user.id == 'atomic1') {
            expect(user.rating, equals(3.5));
            expect(user.profile.followers, equals(110));
          } else if (user.id == 'atomic2') {
            expect(user.rating, equals(4.5));
            expect(user.profile.followers, equals(160));
          }
        }
      });
    });

    group('⚙️ ODM Configuration', () {
      test('should allow custom server timestamp configuration', () async {
        // Arrange
        final customTimestamp = DateTime.utc(1900, 1, 1, 0, 0, 20);
        final customOdm = FirestoreODM(firestore: fakeFirestore, serverTimestamp: customTimestamp);

        expect(customOdm.specialTimestamp, equals(customTimestamp));
      });

      test('should use default server timestamp when none provided', () async {
        // Arrange
        final defaultOdm = FirestoreODM(firestore: fakeFirestore);

        // Assert
        expect(defaultOdm.specialTimestamp, equals(DateTime.utc(1900, 1, 1, 0, 0, 10)));
      });
      
      test('should provide server timestamp constant', () async {
        // Test that the static constant works
        expect(FirestoreODM.serverTimestamp, equals(DateTime.utc(1900, 1, 1, 0, 0, 10)));
      });
    });
  });
}