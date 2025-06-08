import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/post.dart';
import '../lib/models/profile.dart';

void main() {
  group('DocumentIdField Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: firestore);
    });

    group('User DocumentIdField', () {
      test('should use id field as document ID', () async {
        const testUserId = 'user_123';
        final user = User(
          id: testUserId,
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'avatar_url',
            socialLinks: {'twitter': '@test'},
            interests: ['testing'],
          ),
        );

        // Test upsert - should use id field as document ID
        await odm.users.upsert(user);

        // Verify document exists with correct ID
        final doc = await odm.users(testUserId).get();
        expect(doc, isNotNull);
        expect(doc!.id, equals(testUserId));
        expect(doc.name, equals('Test User'));
      });

      test('should filter by document ID using id field', () async {
        // Add multiple users
        await odm.users.upsert(User(
          id: 'user1',
          name: 'User 1',
          email: 'user1@example.com',
          age: 20,
          profile: Profile(
            bio: 'Bio 1',
            avatar: 'avatar1',
            socialLinks: {},
            interests: [],
          ),
        ));

        await odm.users.upsert(User(
          id: 'user2', 
          name: 'User 2',
          email: 'user2@example.com',
          age: 30,
          profile: Profile(
            bio: 'Bio 2',
            avatar: 'avatar2',
            socialLinks: {},
            interests: [],
          ),
        ));

        // Filter by document ID
        final query = odm.users.where((filter) => filter.id(isEqualTo: 'user2'));
        final docs = await query.get();

        expect(docs.length, equals(1));
        expect(docs.first.id, equals('user2'));
        expect(docs.first.name, equals('User 2'));
      });

      test('should order by document ID using id field', () async {
        // Add users with specific IDs for ordering
        await odm.users.upsert(User(
          id: 'c_user',
          name: 'C User',
          email: 'c@example.com',
          age: 25,
          profile: Profile(
            bio: 'Bio C',
            avatar: 'avatar_c',
            socialLinks: {},
            interests: [],
          ),
        ));

        await odm.users.upsert(User(
          id: 'a_user',
          name: 'A User', 
          email: 'a@example.com',
          age: 30,
          profile: Profile(
            bio: 'Bio A',
            avatar: 'avatar_a',
            socialLinks: {},
            interests: [],
          ),
        ));

        await odm.users.upsert(User(
          id: 'b_user',
          name: 'B User',
          email: 'b@example.com',
          age: 35,
          profile: Profile(
            bio: 'Bio B',
            avatar: 'avatar_b',
            socialLinks: {},
            interests: [],
          ),
        ));

        // Order by document ID ascending
        final ascendingQuery = odm.users.orderBy((order) => order.id());
        final ascendingDocs = await ascendingQuery.get();
        final ascendingIds = ascendingDocs.map((doc) => doc.id).toList();
        expect(ascendingIds, equals(['a_user', 'b_user', 'c_user']));

        // Order by document ID descending
        final descendingQuery = odm.users.orderBy((order) => order.id(descending: true));
        final descendingDocs = await descendingQuery.get();
        final descendingIds = descendingDocs.map((doc) => doc.id).toList();
        expect(descendingIds, equals(['c_user', 'b_user', 'a_user']));
      });

      test('should not include id field in JSON when storing', () async {
        const testUserId = 'json_test_user';
        final user = User(
          id: testUserId,
          name: 'JSON Test User',
          email: 'json@example.com',
          age: 28,
          profile: Profile(
            bio: 'JSON Test Bio',
            avatar: 'json_avatar',
            socialLinks: {},
            interests: [],
          ),
        );

        await odm.users.upsert(user);

        // Check the raw Firestore document
        final docSnapshot = await firestore.doc('users/$testUserId').get();
        final rawData = docSnapshot.data()!;
        
        // The id field should not be in the stored data
        expect(rawData.containsKey('id'), isFalse);
        expect(rawData['name'], equals('JSON Test User'));
      });

      test('should handle upsert with empty or null id', () async {
        final userWithEmptyId = User(
          id: '',
          name: 'Empty ID User',
          email: 'empty@example.com',
          age: 25,
          profile: Profile(
            bio: 'Empty Bio',
            avatar: 'empty_avatar',
            socialLinks: {},
            interests: [],
          ),
        );

        // Should throw error for empty ID
        expect(
          () => odm.users.upsert(userWithEmptyId),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Post DocumentIdField', () {
      test('should use id field as document ID for Post', () async {
        const testPostId = 'post_123';
        final post = Post(
          id: testPostId,
          title: 'Test Post',
          content: 'This is test content',
          authorId: 'author_123',
          tags: ['test', 'example'],
          metadata: {'category': 'test'},
          createdAt: DateTime.now(),
        );

        // Test upsert
        await odm.posts.upsert(post);

        // Verify document exists
        final doc = await odm.posts(testPostId).get();
        expect(doc, isNotNull);
        expect(doc!.id, equals(testPostId));
        expect(doc.title, equals('Test Post'));
      });

      test('should filter and order Post by document ID', () async {
        // Add posts
        await odm.posts.upsert(Post(
          id: 'post_a',
          title: 'Post A',
          content: 'Content A',
          authorId: 'author1',
          tags: ['a'],
          metadata: {},
          createdAt: DateTime.now(),
        ));

        await odm.posts.upsert(Post(
          id: 'post_b',
          title: 'Post B', 
          content: 'Content B',
          authorId: 'author2',
          tags: ['b'],
          metadata: {},
          createdAt: DateTime.now(),
        ));

        // Filter by document ID
        final filteredQuery = odm.posts.where((filter) => filter.id(isEqualTo: 'post_b'));
        final filteredPosts = await filteredQuery.get();
        expect(filteredPosts.length, equals(1));
        expect(filteredPosts.first.id, equals('post_b'));

        // Order by document ID
        final orderedQuery = odm.posts.orderBy((order) => order.id());
        final orderedPosts = await orderedQuery.get();
        final postIds = orderedPosts.map((post) => post.id).toList();
        expect(postIds, equals(['post_a', 'post_b']));
      });
    });

    group('Mixed Field Operations', () {
      test('should filter by document ID and other fields', () async {
        // Add users
        await odm.users.upsert(User(
          id: 'active_user_1',
          name: 'Active User 1',
          email: 'active1@example.com',
          age: 25,
          isActive: true,
          profile: Profile(
            bio: 'Active Bio',
            avatar: 'active_avatar',
            socialLinks: {},
            interests: [],
          ),
        ));

        await odm.users.upsert(User(
          id: 'inactive_user_1',
          name: 'Inactive User 1', 
          email: 'inactive1@example.com',
          age: 30,
          isActive: false,
          profile: Profile(
            bio: 'Inactive Bio',
            avatar: 'inactive_avatar',
            socialLinks: {},
            interests: [],
          ),
        ));

        // Filter by document ID
        final query = odm.users.where((filter) => filter.id(isEqualTo: 'active_user_1'));
        final docs = await query.get();
        expect(docs.length, equals(1));
        expect(docs.first.id, equals('active_user_1'));
        expect(docs.first.isActive, isTrue);

        // Filter by active status
        final activeQuery = odm.users.where((filter) => filter.isActive(isEqualTo: true));
        final activeDocs = await activeQuery.get();
        expect(activeDocs.length, equals(1));
        expect(activeDocs.first.isActive, isTrue);
      });
    });
  });
}