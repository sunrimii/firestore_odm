import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔥 Core Basic Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📋 ODM Initialization', () {
      test('should create FirestoreODM with dependency injection', () {
        expect(odm, isNotNull);
        expect(odm.firestore, equals(fakeFirestore));
      });

      test('should access all collections', () {
        expect(() => odm.users, returnsNormally);
        expect(() => odm.posts, returnsNormally);
        expect(() => odm.simpleStories, returnsNormally);
        expect(() => odm.sharedPosts, returnsNormally);
      });
    });

    group('📝 CRUD Operations', () {
      test('should create and retrieve a user', () async {
        final user = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 30,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('test_user').update(user);
        final retrieved = await odm.users('test_user').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('test_user'));
        expect(retrieved.name, equals('Test User'));
        expect(retrieved.email, equals('test@example.com'));
      });

      test('should update a user', () async {
        final user = User(
          id: 'update_user',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
          profile: Profile(
            bio: 'Original bio',
            avatar: 'original.jpg',
            socialLinks: {},
            interests: ['original'],
            followers: 50,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('update_user').update(user);

        await odm.users('update_user').modify((user) => user.copyWith(
              name: 'Updated Name',
              isActive: true,
            ));

        final updated = await odm.users('update_user').get();
        expect(updated!.name, equals('Updated Name'));
        expect(updated.isActive, isTrue);
      });

      test('should delete a user', () async {
        final user = User(
          id: 'delete_user',
          name: 'Delete Me',
          email: 'delete@example.com',
          age: 30,
          profile: Profile(
            bio: 'To be deleted',
            avatar: 'delete.jpg',
            socialLinks: {},
            interests: [],
            followers: 0,
          ),
          rating: 2.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('delete_user').update(user);
        await odm.users('delete_user').delete();

        final deleted = await odm.users('delete_user').get();
        expect(deleted, isNull);
      });
    });

    group('🔍 Basic Queries', () {
      test('should query users by simple conditions', () async {
        final users = [
          User(
            id: 'active_user',
            name: 'Active User',
            email: 'active@example.com',
            age: 25,
            profile: Profile(
              bio: 'Active user',
              avatar: 'active.jpg',
              socialLinks: {},
              interests: ['activity'],
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
              bio: 'Inactive user',
              avatar: 'inactive.jpg',
              socialLinks: {},
              interests: ['rest'],
              followers: 50,
            ),
            rating: 2.0,
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
    });
  });
}
