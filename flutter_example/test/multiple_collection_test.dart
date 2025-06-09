import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';

import '../lib/models/shared_post.dart';
import '../lib/models/user.dart'; // Required for odm.users extension

void main() {
  group('Multiple Collection Tests', () {
    late FirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: firestore);
    });

    test('should generate unified collection class for SharedPost', () {
      // Verify that we can access both collections using the same class
      expect(odm.posts, isA<SharedPostCollection>());
      expect(odm.users('user123').posts, isA<SharedPostCollection>());
    });

    test('should access standalone posts collection', () async {
      // Create a post in standalone collection
      final post = SharedPost(
        id: 'post1',
        title: 'Standalone Post',
        content: 'This is a standalone post',
        authorId: 'author1',
        likes: 10,
        published: true,
        createdAt: DateTime.now(),
        tags: ['tech', 'flutter'],
      );

      // Add to standalone collection
      await odm.posts.upsert(post);

      // Verify it exists in posts collection
      final retrievedPost = await odm.posts('post1').get();
      expect(retrievedPost, isNotNull);
      expect(retrievedPost!.title, equals('Standalone Post'));
      expect(retrievedPost.authorId, equals('author1'));

      // Verify collection path
      expect(odm.posts.ref.path, equals('posts'));
    });

    test('should access user subcollection posts', () async {
      // Create a post in user subcollection
      final userPost = SharedPost(
        id: 'post2',
        title: 'User Post',
        content: 'This is a user subcollection post',
        authorId: 'user123',
        likes: 5,
        published: true,
        createdAt: DateTime.now(),
        tags: ['personal'],
      );

      // Add to user subcollection
      await odm.users('user123').posts.upsert(userPost);

      // Verify it exists in user subcollection
      final retrievedPost = await odm.users('user123').posts('post2').get();
      expect(retrievedPost, isNotNull);
      expect(retrievedPost!.title, equals('User Post'));
      expect(retrievedPost.authorId, equals('user123'));

      // Verify collection path
      expect(
        odm.users('user123').posts.ref.path,
        equals('users/user123/posts'),
      );
    });

    test('should handle different collections independently', () async {
      // Create posts in both collections
      final standalonePost = SharedPost(
        id: 'standalone1',
        title: 'Standalone',
        content: 'Standalone content',
        authorId: 'author1',
        likes: 10,
        published: true,
        createdAt: DateTime.now(),
      );

      final userPost = SharedPost(
        id: 'user1',
        title: 'User Post',
        content: 'User content',
        authorId: 'user123',
        likes: 5,
        published: true,
        createdAt: DateTime.now(),
      );

      // Add to different collections
      await odm.posts.upsert(standalonePost);
      await odm.users('user123').posts.upsert(userPost);

      // Verify they exist independently
      final standalone = await odm.posts('standalone1').get();
      final user = await odm.users('user123').posts('user1').get();

      expect(standalone, isNotNull);
      expect(user, isNotNull);
      expect(standalone!.title, equals('Standalone'));
      expect(user!.title, equals('User Post'));

      // Verify they don't interfere with each other
      final standaloneNotInUser = await odm
          .users('user123')
          .posts('standalone1')
          .get();
      final userNotInStandalone = await odm.posts('user1').get();

      expect(standaloneNotInUser, isNull);
      expect(userNotInStandalone, isNull);
    });

    test(
      'should support multiple users with independent subcollections',
      () async {
        final user1Post = SharedPost(
          id: 'post1',
          title: 'User 1 Post',
          content: 'Content for user 1',
          authorId: 'user1',
          likes: 3,
          published: true,
          createdAt: DateTime.now(),
        );

        final user2Post = SharedPost(
          id: 'post1', // Same ID but different collection
          title: 'User 2 Post',
          content: 'Content for user 2',
          authorId: 'user2',
          likes: 7,
          published: false,
          createdAt: DateTime.now(),
        );

        // Add to different user subcollections
        await odm.users('user1').posts.upsert(user1Post);
        await odm.users('user2').posts.upsert(user2Post);

        // Verify both exist independently
        final user1Retrieved = await odm.users('user1').posts('post1').get();
        final user2Retrieved = await odm.users('user2').posts('post1').get();

        expect(user1Retrieved, isNotNull);
        expect(user2Retrieved, isNotNull);
        expect(user1Retrieved!.title, equals('User 1 Post'));
        expect(user2Retrieved!.title, equals('User 2 Post'));
        expect(user1Retrieved.published, isTrue);
        expect(user2Retrieved.published, isFalse);

        // Verify correct paths
        expect(odm.users('user1').posts.ref.path, equals('users/user1/posts'));
        expect(odm.users('user2').posts.ref.path, equals('users/user2/posts'));
      },
    );

    test('should support filtering and querying in both collections', () async {
      // Add multiple posts to standalone collection
      await odm.posts.upsert(
        SharedPost(
          id: 'post1',
          title: 'Tech Post',
          content: 'Tech content',
          authorId: 'author1',
          likes: 10,
          published: true,
          createdAt: DateTime.now(),
          tags: ['tech'],
        ),
      );

      await odm.posts.upsert(
        SharedPost(
          id: 'post2',
          title: 'Personal Post',
          content: 'Personal content',
          authorId: 'author1',
          likes: 5,
          published: false,
          createdAt: DateTime.now(),
          tags: ['personal'],
        ),
      );

      // Add posts to user subcollection
      await odm
          .users('user1')
          .posts
          .upsert(
            SharedPost(
              id: 'post1',
              title: 'User Tech',
              content: 'User tech content',
              authorId: 'user1',
              likes: 15,
              published: true,
              createdAt: DateTime.now(),
              tags: ['tech'],
            ),
          );

      // Query published posts in standalone collection
      final publishedPosts = await odm.posts
          .where((filter) => filter.published(isEqualTo: true))
          .get();
      expect(publishedPosts.length, equals(1));
      expect(publishedPosts.first.title, equals('Tech Post'));

      // Query posts in user subcollection
      final userPosts = await odm
          .users('user1')
          .posts
          .where((filter) => filter.likes(isGreaterThan: 10))
          .get();
      expect(userPosts.length, equals(1));
      expect(userPosts.first.title, equals('User Tech'));
    });

    test('should support ordering and limiting in both collections', () async {
      final now = DateTime.now();

      // Add posts with different creation times
      await odm.posts.upsert(
        SharedPost(
          id: 'post1',
          title: 'First Post',
          content: 'First',
          authorId: 'author1',
          likes: 5,
          published: true,
          createdAt: now.subtract(Duration(hours: 2)),
        ),
      );

      await odm.posts.upsert(
        SharedPost(
          id: 'post2',
          title: 'Second Post',
          content: 'Second',
          authorId: 'author1',
          likes: 10,
          published: true,
          createdAt: now.subtract(Duration(hours: 1)),
        ),
      );

      await odm.posts.upsert(
        SharedPost(
          id: 'post3',
          title: 'Third Post',
          content: 'Third',
          authorId: 'author1',
          likes: 15,
          published: true,
          createdAt: now,
        ),
      );

      // Order by creation date (newest first) and limit to 2
      final recentPosts = await odm.posts
          .orderBy((order) => order.createdAt(descending: true))
          .limit(2)
          .get();

      expect(recentPosts.length, equals(2));
      expect(recentPosts[0].title, equals('Third Post'));
      expect(recentPosts[1].title, equals('Second Post'));

      // Order by likes (highest first)
      final popularPosts = await odm.posts
          .orderBy((order) => order.likes(descending: true))
          .get();

      expect(popularPosts.length, equals(3));
      expect(popularPosts[0].likes, equals(15));
      expect(popularPosts[1].likes, equals(10));
      expect(popularPosts[2].likes, equals(5));
    });

    test('should support real-time updates in both collections', () async {
      final standaloneChanges = <SharedPost?>[];
      final userChanges = <SharedPost?>[];

      // Subscribe to standalone collection document changes
      final standaloneSubscription = odm.posts('post1').changes.listen((post) {
        standaloneChanges.add(post);
      });

      // Subscribe to user subcollection document changes
      final userSubscription = odm.users('user1').posts('post1').changes.listen(
        (post) {
          userChanges.add(post);
        },
      );

      // Wait for initial null snapshots
      await Future.delayed(Duration(milliseconds: 100));

      // Add posts to both collections
      await odm.posts.upsert(
        SharedPost(
          id: 'post1',
          title: 'Standalone Post',
          content: 'Content',
          authorId: 'author1',
          likes: 1,
          published: true,
          createdAt: DateTime.now(),
        ),
      );

      await odm
          .users('user1')
          .posts
          .upsert(
            SharedPost(
              id: 'post1',
              title: 'User Post',
              content: 'User Content',
              authorId: 'user1',
              likes: 2,
              published: true,
              createdAt: DateTime.now(),
            ),
          );

      // Wait for updates
      await Future.delayed(Duration(milliseconds: 100));

      // Verify we received updates
      expect(
        standaloneChanges.length,
        greaterThanOrEqualTo(1),
      ); // At least one change
      expect(userChanges.length, greaterThanOrEqualTo(1));

      // Verify latest updates have correct data (filter out null values)
      final standaloneNonNull = standaloneChanges
          .where((p) => p != null)
          .toList();
      final userNonNull = userChanges.where((p) => p != null).toList();

      expect(standaloneNonNull.isNotEmpty, isTrue);
      expect(userNonNull.isNotEmpty, isTrue);
      expect(standaloneNonNull.last!.title, equals('Standalone Post'));
      expect(userNonNull.last!.title, equals('User Post'));

      // Clean up subscriptions
      await standaloneSubscription.cancel();
      await userSubscription.cancel();
    });

    test('should support updates and deletes in both collections', () async {
      // Create initial posts
      await odm.posts.upsert(
        SharedPost(
          id: 'post1',
          title: 'Original Title',
          content: 'Original content',
          authorId: 'author1',
          likes: 5,
          published: false,
          createdAt: DateTime.now(),
        ),
      );

      await odm
          .users('user1')
          .posts
          .upsert(
            SharedPost(
              id: 'post1',
              title: 'User Original',
              content: 'User original content',
              authorId: 'user1',
              likes: 3,
              published: false,
              createdAt: DateTime.now(),
            ),
          );

      // Update posts
      await odm
          .posts('post1')
          .update(($) => [$.title('Updated Title'), $.published(true)]);

      await odm
          .users('user1')
          .posts('post1')
          .update(($) => [$.likes(10), $.published(true)]);

      // Verify updates
      final updatedStandalone = await odm.posts('post1').get();
      final updatedUser = await odm.users('user1').posts('post1').get();

      expect(updatedStandalone!.title, equals('Updated Title'));
      expect(updatedStandalone.published, isTrue);
      expect(updatedUser!.likes, equals(10));
      expect(updatedUser.published, isTrue);

      // Delete posts
      await odm.posts('post1').delete();
      await odm.users('user1').posts('post1').delete();

      // Verify deletions
      final deletedStandalone = await odm.posts('post1').get();
      final deletedUser = await odm.users('user1').posts('post1').get();

      expect(deletedStandalone, isNull);
      expect(deletedUser, isNull);
    });
  });
}
