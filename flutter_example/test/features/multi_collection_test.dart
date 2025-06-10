import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/shared_post.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🏢 Multi-Collection Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📁 Root Collections', () {
      test('should access standalone collections independently', () {
        expect(odm.users.ref.path, equals('users'));
        expect(odm.posts.ref.path, equals('posts'));
        expect(odm.simpleStories.ref.path, equals('simpleStories'));
        expect(odm.sharedPosts.ref.path, equals('sharedPosts'));
      });

      test('should work with same model in different collections', () async {
        // Post in main collection
        final mainPost = Post(
          id: 'main_post',
          title: 'Main Collection Post',
          content: 'This is in the main posts collection',
          authorId: 'author1',
          tags: ['main'],
          metadata: {'type': 'main'},
          likes: 10,
          published: true,
          createdAt: DateTime.now(),
        );

        // SharedPost in its own collection
        final sharedPost = SharedPost(
          id: 'shared_post',
          title: 'Shared Collection Post',
          content: 'This is in the shared posts collection',
          authorId: 'author1',
          tags: ['shared'],
          likes: 5,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.posts('main_post').set(mainPost);
        await odm.sharedPosts('shared_post').set(sharedPost);

        final retrievedMain = await odm.posts('main_post').get();
        final retrievedShared = await odm.sharedPosts('shared_post').get();

        expect(retrievedMain, isNotNull);
        expect(retrievedShared, isNotNull);
        expect(retrievedMain!.title, equals('Main Collection Post'));
        expect(retrievedShared!.title, equals('Shared Collection Post'));
      });
    });

    group('🔗 Subcollections', () {
      test('should access user subcollections', () async {
        final userDoc = odm.users('test_user');

        expect(userDoc.posts.ref.path, equals('users/test_user/posts'));
        expect(userDoc.sharedPosts.ref.path,
            equals('users/test_user/sharedPosts'));
      });

      test('should work with posts in user subcollections', () async {
        // Create a user first
        final user = User(
          id: 'subcollection_user',
          name: 'Subcollection User',
          email: 'subcollection@example.com',
          age: 30,
          profile: Profile(
            bio: 'Testing subcollections',
            avatar: 'subcollection.jpg',
            socialLinks: {},
            interests: ['subcollections'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('subcollection_user').set(user);

        // Add posts to user's subcollection
        final userPost = Post(
          id: 'user_post_1',
          title: 'User Specific Post',
          content: 'This is a post in user subcollection',
          authorId: 'subcollection_user',
          tags: ['personal'],
          metadata: {'private': true},
          likes: 3,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm
            .users('subcollection_user')
            .posts('user_post_1')
            .set(userPost);

        final retrievedPost =
            await odm.users('subcollection_user').posts('user_post_1').get();

        expect(retrievedPost, isNotNull);
        expect(retrievedPost!.title, equals('User Specific Post'));
        expect(retrievedPost.authorId, equals('subcollection_user'));
      });

      test('should handle shared posts in user subcollections', () async {
        final user = User(
          id: 'sharing_user',
          name: 'Sharing User',
          email: 'sharing@example.com',
          age: 28,
          profile: Profile(
            bio: 'Loves sharing',
            avatar: 'sharing.jpg',
            socialLinks: {},
            interests: ['sharing'],
            followers: 150,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users('sharing_user').set(user);

        final userSharedPost = SharedPost(
          id: 'user_shared_1',
          title: 'User Shared Post',
          content: 'This is a shared post in user subcollection',
          authorId: 'sharing_user',
          tags: ['user_shared'],
          likes: 8,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm
            .users('sharing_user')
            .sharedPosts('user_shared_1')
            .set(userSharedPost);

        final retrieved =
            await odm.users('sharing_user').sharedPosts('user_shared_1').get();

        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('User Shared Post'));
        expect(retrieved.authorId, equals('sharing_user'));
      });
    });

    group('🔄 Cross-Collection Operations', () {
      test('should query across different collections independently', () async {
        // Create data in different collections
        final user = User(
          id: 'cross_user',
          name: 'Cross User',
          email: 'cross@example.com',
          age: 32,
          profile: Profile(
            bio: 'Cross collection test',
            avatar: 'cross.jpg',
            socialLinks: {},
            interests: ['cross_testing'],
            followers: 200,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final mainPost = Post(
          id: 'cross_main_post',
          title: 'Cross Main Post',
          content: 'Main collection post for cross testing',
          authorId: 'cross_user',
          tags: ['cross', 'main'],
          metadata: {},
          likes: 15,
          published: true,
          createdAt: DateTime.now(),
        );

        final userPost = Post(
          id: 'cross_user_post',
          title: 'Cross User Post',
          content: 'User subcollection post for cross testing',
          authorId: 'cross_user',
          tags: ['cross', 'user'],
          metadata: {},
          likes: 8,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.users('cross_user').set(user);
        await odm.posts('cross_main_post').set(mainPost);
        await odm.users('cross_user').posts('cross_user_post').set(userPost);

        // Query each collection independently
        final users =
            await odm.users.where(($) => $.name(isEqualTo: 'Cross User')).get();

        final mainPosts =
            await odm.posts.where(($) => $.tags(arrayContains: 'main')).get();

        final userPosts = await odm
            .users('cross_user')
            .posts
            .where(($) => $.tags(arrayContains: 'user'))
            .get();

        expect(users.length, equals(1));
        expect(mainPosts.length, equals(1));
        expect(userPosts.length, equals(1));

        expect(users.first.id, equals('cross_user'));
        expect(mainPosts.first.id, equals('cross_main_post'));
        expect(userPosts.first.id, equals('cross_user_post'));
      });

      test('should handle bulk operations across collections', () async {
        // Create multiple users
        final users = List.generate(
            3,
            (index) => User(
                  id: 'bulk_user_$index',
                  name: 'Bulk User $index',
                  email: 'bulk$index@example.com',
                  age: 25 + index,
                  profile: Profile(
                    bio: 'Bulk test user $index',
                    avatar: 'bulk$index.jpg',
                    socialLinks: {},
                    interests: ['bulk_testing'],
                    followers: 100 + index * 50,
                  ),
                  rating: 3.0 + index * 0.5,
                  isActive: false, // Start inactive
                  isPremium: false,
                  createdAt: DateTime.now(),
                ));

        // Create posts for each user
        final posts = List.generate(
            3,
            (index) => Post(
                  id: 'bulk_post_$index',
                  title: 'Bulk Post $index',
                  content: 'Bulk post content $index',
                  authorId: 'bulk_user_$index',
                  tags: ['bulk'],
                  metadata: {},
                  likes: index * 2,
                  published: false, // Start unpublished
                  createdAt: DateTime.now(),
                ));

        // Set all users and posts
        for (final user in users) {
          await odm.users(user.id).set(user);
        }
        for (final post in posts) {
          await odm.posts(post.id).set(post);
        }

        // Bulk activate all users
        await odm.users
            .where(($) => $.profile.interests(arrayContains: 'bulk_testing'))
            .modify((user) => user.copyWith(isActive: true));

        // Bulk publish all posts
        await odm.posts
            .where(($) => $.tags(arrayContains: 'bulk'))
            .modify((post) => post.copyWith(published: true));

        // Verify changes
        final activeUsers =
            await odm.users.where(($) => $.isActive(isEqualTo: true)).get();

        final publishedPosts =
            await odm.posts.where(($) => $.published(isEqualTo: true)).get();

        expect(activeUsers.length, equals(3));
        expect(publishedPosts.length, equals(3));
      });
    });

    group('🎯 Collection Type Safety', () {
      test('should maintain type safety across collections', () async {
        // Ensure each collection returns the correct type
        expect(odm.users, isA<FirestoreCollection<TestSchema, User>>());
        expect(odm.posts, isA<FirestoreCollection<TestSchema, Post>>());
        expect(odm.sharedPosts,
            isA<FirestoreCollection<TestSchema, SharedPost>>());

        // Subcollections should also be properly typed
        expect(odm.users('test').posts,
            isA<FirestoreCollection<TestSchema, Post>>());
        expect(odm.users('test').sharedPosts,
            isA<FirestoreCollection<TestSchema, SharedPost>>());
      });

      test('should prevent type confusion between collections', () async {
        final post = Post(
          id: 'type_test_post',
          title: 'Type Test Post',
          content: 'Testing type safety',
          authorId: 'type_author',
          tags: ['type_test'],
          metadata: {},
          likes: 1,
          published: true,
          createdAt: DateTime.now(),
        );

        final sharedPost = SharedPost(
          id: 'type_test_shared',
          title: 'Type Test Shared',
          content: 'Testing shared type safety',
          authorId: 'type_author',
          tags: ['type_test'],
          likes: 2,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.posts('type_test_post').set(post);
        await odm.sharedPosts('type_test_shared').set(sharedPost);

        final retrievedPost = await odm.posts('type_test_post').get();
        final retrievedShared = await odm.sharedPosts('type_test_shared').get();

        expect(retrievedPost, isA<Post>());
        expect(retrievedShared, isA<SharedPost>());
        expect(retrievedPost, isNot(isA<SharedPost>()));
        expect(retrievedShared, isNot(isA<Post>()));
      });
    });
  });
}
