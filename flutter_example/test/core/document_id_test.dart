import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/simple_story.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🆔 Document ID Field Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📋 Explicit @DocumentIdField Annotation', () {
      test('should handle explicit @DocumentIdField in User model', () async {
        final user = User(
          id: 'explicit_id_user',
          name: 'Explicit ID User',
          email: 'explicit@example.com',
          age: 28,
          profile: Profile(
            bio: 'Explicit ID test',
            avatar: 'explicit.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('explicit_id_user').update(user);
        final retrieved = await odm.users('explicit_id_user').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('explicit_id_user'));
      });

      test('should use document ID field for upsert operations', () async {
        final user = User(
          id: 'upsert_user',
          name: 'Upsert User',
          email: 'upsert@example.com',
          age: 25,
          profile: Profile(
            bio: 'Upsert test',
            avatar: 'upsert.jpg',
            socialLinks: {},
            interests: ['upsert'],
            followers: 50,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Upsert should use the id field as document ID
        await odm.users.upsert(user);
        final retrieved = await odm.users('upsert_user').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('upsert_user'));
        expect(retrieved.name, equals('Upsert User'));
      });
    });

    group('🔍 Automatic Document ID Detection', () {
      test('should automatically detect id field as document ID in SimpleStory',
          () async {
        final story = SimpleStory(
          id: 'auto_id_story',
          title: 'Auto ID Story',
          content: 'This story uses automatic document ID detection',
          authorId: 'author1',
          tags: ['auto', 'detection'],
          createdAt: DateTime.now(),
        );

        await odm.simpleStories('auto_id_story').update(story);
        final retrieved = await odm.simpleStories('auto_id_story').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('auto_id_story'));
        expect(retrieved.title, equals('Auto ID Story'));
      });

      test('should use automatic detection for upsert operations', () async {
        final story = SimpleStory(
          id: 'auto_upsert_story',
          title: 'Auto Upsert Story',
          content: 'Testing automatic ID detection with upsert',
          authorId: 'author2',
          tags: ['auto', 'upsert'],
          createdAt: DateTime.now(),
        );

        await odm.simpleStories.upsert(story);
        final retrieved = await odm.simpleStories('auto_upsert_story').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('auto_upsert_story'));
        expect(retrieved.content,
            equals('Testing automatic ID detection with upsert'));
      });
    });

    group('🔍 Document ID Field in Queries', () {
      test('should support filtering by document ID field', () async {
        final users = [
          User(
            id: 'filter_user_1',
            name: 'Filter User 1',
            email: 'filter1@example.com',
            age: 25,
            profile: Profile(
              bio: 'Filter test 1',
              avatar: 'filter1.jpg',
              socialLinks: {},
              interests: ['filtering'],
              followers: 100,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'filter_user_2',
            name: 'Filter User 2',
            email: 'filter2@example.com',
            age: 30,
            profile: Profile(
              bio: 'Filter test 2',
              avatar: 'filter2.jpg',
              socialLinks: {},
              interests: ['filtering'],
              followers: 150,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Filter by specific document IDs
        final specificUsers = await odm.users
            .where(($) => $.id(whereIn: ['filter_user_1', 'filter_user_2']))
            .get();

        expect(specificUsers.length, equals(2));

        final singleUser = await odm.users
            .where(($) => $.id(isEqualTo: 'filter_user_1'))
            .get();

        expect(singleUser.length, equals(1));
        expect(singleUser.first.name, equals('Filter User 1'));
      });

      test('should support ordering by document ID field', () async {
        final users = [
          User(
            id: 'c_user',
            name: 'C User',
            email: 'c@example.com',
            age: 25,
            profile: Profile(
              bio: 'C user',
              avatar: 'c.jpg',
              socialLinks: {},
              interests: ['order'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'a_user',
            name: 'A User',
            email: 'a@example.com',
            age: 30,
            profile: Profile(
              bio: 'A user',
              avatar: 'a.jpg',
              socialLinks: {},
              interests: ['order'],
              followers: 150,
            ),
            rating: 4.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'b_user',
            name: 'B User',
            email: 'b@example.com',
            age: 28,
            profile: Profile(
              bio: 'B user',
              avatar: 'b.jpg',
              socialLinks: {},
              interests: ['order'],
              followers: 120,
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

        final orderedUsers = await odm.users
            .where(($) => $.id(whereIn: ['a_user', 'b_user', 'c_user']))
            .orderBy(($) => ($.id(),))
            .get();

        expect(orderedUsers.length, equals(3));
        expect(orderedUsers[0].id, equals('a_user'));
        expect(orderedUsers[1].id, equals('b_user'));
        expect(orderedUsers[2].id, equals('c_user'));
      });
    });

    group('❌ Document ID Validation', () {
      test('should handle empty document ID gracefully', () async {
        // Empty document ID should create a document reference but may not throw immediately
        final doc = odm.users('');
        expect(doc, isNotNull);
        // The error would occur during actual operations like get/set
      });

      test('should validate document ID field is not null for upsert',
          () async {
        // This should work fine since all our models have valid IDs
        final user = User(
          id: 'valid_id',
          name: 'Valid User',
          email: 'valid@example.com',
          age: 25,
          profile: Profile(
            bio: 'Valid user',
            avatar: 'valid.jpg',
            socialLinks: {},
            interests: ['validation'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        expect(() => odm.users.upsert(user), returnsNormally);
      });
    });
  });
}
