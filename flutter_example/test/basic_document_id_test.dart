import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/post.dart';

void main() {
  group('Basic DocumentIdField Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: firestore);
    });

    test('should upsert post with document ID - core functionality', () async {
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

      // Test upsert - should use id field as document ID
      await odm.posts.upsert(post);

      // Verify document exists with correct ID
      final doc = await odm.posts(testPostId).get();
      expect(doc, isNotNull);
      expect(doc!.id, equals(testPostId));
      expect(doc.title, equals('Test Post'));
    });

    test('should not include id field in JSON when storing', () async {
      const testPostId = 'json_test_post';
      final post = Post(
        id: testPostId,
        title: 'JSON Test Post',
        content: 'JSON test content',
        authorId: 'author_123',
        tags: ['json', 'test'],
        metadata: {'category': 'json'},
        createdAt: DateTime.now(),
      );

      await odm.posts.upsert(post);

      // Check the raw Firestore document
      final docSnapshot = await firestore.doc('posts/$testPostId').get();
      final rawData = docSnapshot.data()!;
      
      // The id field should not be in the stored data
      expect(rawData.containsKey('id'), isFalse);
      expect(rawData['title'], equals('JSON Test Post'));
    });

    test('should handle upsert with empty id', () async {
      final postWithEmptyId = Post(
        id: '',
        title: 'Empty ID Post',
        content: 'Empty content',
        authorId: 'author_123',
        tags: [],
        metadata: {},
        createdAt: DateTime.now(),
      );

      // Should throw error for empty ID
      expect(
        () => odm.posts.upsert(postWithEmptyId),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should retrieve multiple posts', () async {
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

      // Just get all posts to verify they exist
      final allPosts = await odm.posts.get();
      expect(allPosts.length, equals(2));
      
      final postIds = allPosts.map((post) => post.id).toSet();
      expect(postIds, contains('post_a'));
      expect(postIds, contains('post_b'));
    });
  });
}