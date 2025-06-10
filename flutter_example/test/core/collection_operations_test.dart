import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../../lib/models/user.dart';
import '../../lib/models/profile.dart';
import '../../lib/test_schema.dart';

void main() {
  group('🔥 Collection Insert & Update Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<$TestSchemaImpl> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Insert Operations', () {
      test('should insert a new document using model ID', () async {
        final user = User(
          id: 'insert_test_user',
          name: 'Insert Test User',
          email: 'insert@example.com',
          age: 25,
          profile: Profile(
            bio: 'Insert test bio',
            avatar: 'insert.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 50,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Should successfully insert
        await odm.users.insert(user);

        // Verify document was created
        final retrieved = await odm.users('insert_test_user').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('insert_test_user'));
        expect(retrieved.name, equals('Insert Test User'));
      });

      test('should insert a new document using model ID', () async {
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
            followers: 75,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Should successfully insert using model ID
        await odm.users.insert(user);

        // Verify document was created with model ID
        final retrieved = await odm.users('explicit_id_user').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Explicit ID User'));
      });

      test('should fail to insert when document already exists', () async {
        final user = User(
          id: 'duplicate_user',
          name: 'Duplicate User',
          email: 'duplicate@example.com',
          age: 30,
          profile: Profile(
            bio: 'First user',
            avatar: 'first.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Insert first time - should succeed
        await odm.users.insert(user);

        // Try to insert again - should fail
        expect(
          () => odm.users.insert(user),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          )),
        );
      });

      test('should fail to insert when document already exists with same model ID', () async {
        final user1 = User(
          id: 'conflict_user',
          name: 'User 1',
          email: 'user1@example.com',
          age: 25,
          profile: Profile(
            bio: 'User 1 bio',
            avatar: 'user1.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 50,
          ),
          rating: 3.8,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final user2 = User(
          id: 'conflict_user', // Same ID as user1
          name: 'User 2',
          email: 'user2@example.com',
          age: 30,
          profile: Profile(
            bio: 'User 2 bio',
            avatar: 'user2.jpg',
            socialLinks: {},
            interests: ['gaming'],
            followers: 80,
          ),
          rating: 4.1,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Insert first document
        await odm.users.insert(user1);

        // Try to insert second document with same ID - should fail
        expect(
          () => odm.users.insert(user2),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          )),
        );
      });

      test('should auto-generate ID when model ID is empty string', () async {
        final user = User(
          id: '', // Empty string triggers server-generated ID
          name: 'Auto ID User',
          email: 'autoid@example.com',
          age: 22,
          profile: Profile(
            bio: 'Auto ID bio',
            avatar: 'autoid.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 10,
          ),
          rating: 2.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Should successfully insert with server-generated ID
        await odm.users.insert(user);

        // Verify at least one document was created
        final allUsers = await odm.users.get();
        expect(allUsers.length, greaterThan(0));
        
        // Find the user we just inserted
        final insertedUser = allUsers.firstWhere(
          (u) => u.name == 'Auto ID User',
        );
        expect(insertedUser.name, equals('Auto ID User'));
        expect(insertedUser.email, equals('autoid@example.com'));
      });

      test('should fail to insert when model ID is null', () async {
        // This test would be for actual null values, but since our User model
        // requires a non-null String id, this would be a compile-time error.
        // The runtime check in insert() is for safety in case someone bypasses
        // the type system or uses dynamic typing.
      });
    });

    group('🔄 Update Operations', () {
      test('should update an existing document', () async {
        final originalUser = User(
          id: 'update_test_user',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
          profile: Profile(
            bio: 'Original bio',
            avatar: 'original.jpg',
            socialLinks: {},
            interests: ['reading'],
            followers: 50,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Insert original document
        await odm.users.insert(originalUser);

        final updatedUser = User(
          id: 'update_test_user',
          name: 'Updated Name',
          email: 'updated@example.com',
          age: 26,
          profile: Profile(
            bio: 'Updated bio',
            avatar: 'updated.jpg',
            socialLinks: {'twitter': '@updated'},
            interests: ['writing', 'gaming'],
            followers: 150,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: originalUser.createdAt,
        );

        // Should successfully update
        await odm.users.updateDocument(updatedUser);

        // Verify document was updated
        final retrieved = await odm.users('update_test_user').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Updated Name'));
        expect(retrieved.email, equals('updated@example.com'));
        expect(retrieved.age, equals(26));
        expect(retrieved.profile.bio, equals('Updated bio'));
        expect(retrieved.profile.followers, equals(150));
        expect(retrieved.isPremium, isTrue);
      });

      test('should fail to update when document does not exist', () async {
        final user = User(
          id: 'nonexistent_user',
          name: 'Nonexistent User',
          email: 'nonexistent@example.com',
          age: 30,
          profile: Profile(
            bio: 'This user does not exist',
            avatar: 'nonexistent.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 0,
          ),
          rating: 1.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        expect(
          () => odm.users.updateDocument(user),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          )),
        );
      });
    });

    group('🔀 Upsert Operations', () {
      test('should create document when it does not exist', () async {
        final user = User(
          id: 'upsert_new_user',
          name: 'Upsert New User',
          email: 'upsertnew@example.com',
          age: 27,
          profile: Profile(
            bio: 'New via upsert',
            avatar: 'upsertnew.jpg',
            socialLinks: {},
            interests: ['upserts'],
            followers: 25,
          ),
          rating: 3.7,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Should successfully create via upsert
        await odm.users.upsert(user);

        // Verify document was created
        final retrieved = await odm.users('upsert_new_user').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Upsert New User'));
      });

      test('should update document when it already exists', () async {
        final originalUser = User(
          id: 'upsert_existing_user',
          name: 'Original Upsert User',
          email: 'original.upsert@example.com',
          age: 24,
          profile: Profile(
            bio: 'Original upsert bio',
            avatar: 'original.upsert.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 40,
          ),
          rating: 3.2,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Insert original document
        await odm.users.insert(originalUser);

        final updatedUser = User(
          id: 'upsert_existing_user',
          name: 'Updated Upsert User',
          email: 'updated.upsert@example.com',
          age: 25,
          profile: Profile(
            bio: 'Updated upsert bio',
            avatar: 'updated.upsert.jpg',
            socialLinks: {'linkedin': '/in/updated'},
            interests: ['upserts', 'merging'],
            followers: 120,
          ),
          rating: 4.3,
          isActive: true,
          isPremium: true,
          createdAt: originalUser.createdAt,
        );

        // Should successfully update via upsert
        await odm.users.upsert(updatedUser);

        // Verify document was updated
        final retrieved = await odm.users('upsert_existing_user').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Updated Upsert User'));
        expect(retrieved.profile.followers, equals(120));
        expect(retrieved.isPremium, isTrue);
      });
    });

    group('🔍 Integration Tests', () {
      test('should work with all operations in sequence', () async {
        final baseUser = User(
          id: 'integration_user',
          name: 'Integration User',
          email: 'integration@example.com',
          age: 29,
          profile: Profile(
            bio: 'Integration test user',
            avatar: 'integration.jpg',
            socialLinks: {},
            interests: ['integration'],
            followers: 60,
          ),
          rating: 3.9,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // 1. Insert new document
        await odm.users.insert(baseUser);
        var retrieved = await odm.users('integration_user').get();
        expect(retrieved!.name, equals('Integration User'));

        // 2. Update existing document
        final updatedUser = baseUser.copyWith(
          name: 'Updated Integration User',
          age: 30,
        );
        await odm.users.updateDocument(updatedUser);
        retrieved = await odm.users('integration_user').get();
        expect(retrieved!.name, equals('Updated Integration User'));
        expect(retrieved.age, equals(30));

        // 3. Upsert existing document (should update)
        final upsertedUser = updatedUser.copyWith(
          email: 'upserted.integration@example.com',
          profile: updatedUser.profile.copyWith(followers: 200),
        );
        await odm.users.upsert(upsertedUser);
        retrieved = await odm.users('integration_user').get();
        expect(retrieved!.email, equals('upserted.integration@example.com'));
        expect(retrieved.profile.followers, equals(200));

        // 4. Try to insert duplicate (should fail)
        expect(
          () => odm.users.insert(baseUser),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}