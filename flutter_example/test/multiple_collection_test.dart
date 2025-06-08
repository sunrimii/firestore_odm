import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/shared_post.dart';

void main() {
  group('Multiple @Collection Support', () {
    late FirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore);
    });

    test('should support standalone collection access', () async {
      // Test the @Collection('posts') path
      final post = SharedPost(
        id: 'post1',
        title: 'Test Post',
        content: 'This is a test post',
        authorId: 'author1',
        likes: 10,
        published: true,
        createdAt: DateTime.now(),
        tags: ['test', 'demo'],
      );

      // Access standalone collection: odm.posts
      await odm.posts.upsert(post);
      
      final retrievedPost = await odm.posts.doc('post1').get();
      expect(retrievedPost.data(), isNotNull);
      expect(retrievedPost.data()!.title, equals('Test Post'));
      expect(retrievedPost.data()!.authorId, equals('author1'));
    });

    test('should support subcollection access', () async {
      // Test the @Collection('users/*/posts') path
      final userPost = SharedPost(
        id: 'post2',
        title: 'User Post',
        content: 'This is a user-specific post',
        authorId: 'user123',
        likes: 5,
        published: true,
        createdAt: DateTime.now(),
        tags: ['user', 'personal'],
      );

      // Access subcollection: odm.users('user123').posts
      await odm.users('user123').posts.upsert(userPost);
      
      final retrievedUserPost = await odm.users('user123').posts.doc('post2').get();
      expect(retrievedUserPost.data(), isNotNull);
      expect(retrievedUserPost.data()!.title, equals('User Post'));
      expect(retrievedUserPost.data()!.authorId, equals('user123'));
    });

    test('should support querying both collections independently', () async {
      // Add posts to both collections
      final globalPost = SharedPost(
        id: 'global1',
        title: 'Global Post',
        content: 'Available globally',
        authorId: 'author1',
        likes: 100,
        published: true,
        createdAt: DateTime.now(),
        tags: ['global'],
      );

      final userPost = SharedPost(
        id: 'user1',
        title: 'User Post',
        content: 'User specific',
        authorId: 'user123',
        likes: 5,
        published: true,
        createdAt: DateTime.now(),
        tags: ['personal'],
      );

      // Add to standalone collection
      await odm.posts.upsert(globalPost);
      
      // Add to user subcollection
      await odm.users('user123').posts.upsert(userPost);

      // Query standalone collection
      final globalPosts = await odm.posts
          .where((q) => q.published.equals(true))
          .get();
      expect(globalPosts.docs.length, equals(1));
      expect(globalPosts.docs.first.data().title, equals('Global Post'));

      // Query user subcollection
      final userPosts = await odm.users('user123').posts
          .where((q) => q.published.equals(true))
          .get();
      expect(userPosts.docs.length, equals(1));
      expect(userPosts.docs.first.data().title, equals('User Post'));
    });

    test('should maintain separate document paths', () {
      // Verify the collections point to different Firestore paths
      final standaloneCollection = odm.posts;
      final userSubcollection = odm.users('user123').posts;

      // They should have different collection references
      expect(standaloneCollection.ref.path, equals('posts'));
      expect(userSubcollection.ref.path, equals('users/user123/posts'));
    });
  });
}