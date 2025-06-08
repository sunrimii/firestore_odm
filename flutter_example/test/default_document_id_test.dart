import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/simple_story.dart';

void main() {
  group('Default Document ID Field Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: firestore);
    });

    group('SimpleStory without @DocumentIdField annotation', () {
      test('should automatically use id field as document ID', () async {
        const testStoryId = 'story_123';
        final story = SimpleStory(
          id: testStoryId,
          title: 'Test Story',
          content: 'This is test content',
          authorId: 'author_123',
          tags: ['test', 'story'],
          createdAt: DateTime.now(),
        );

        // Test upsert - should use id field as document ID automatically
        await odm.simpleStories.upsert(story);

        // Verify document exists with correct ID
        final doc = await odm.simpleStories(testStoryId).get();
        expect(doc, isNotNull);
        expect(doc!.id, equals(testStoryId));
        expect(doc.title, equals('Test Story'));
      });

      test('should filter by document ID using default id field', () async {
        // Add multiple stories
        await odm.simpleStories.upsert(SimpleStory(
          id: 'story1',
          title: 'Story 1',
          content: 'Content 1',
          authorId: 'author1',
          tags: ['tag1'],
          createdAt: DateTime.now(),
        ));

        await odm.simpleStories.upsert(SimpleStory(
          id: 'story2',
          title: 'Story 2',
          content: 'Content 2',
          authorId: 'author2',
          tags: ['tag2'],
          createdAt: DateTime.now(),
        ));

        // Filter by document ID
        final query = odm.simpleStories.where((filter) => filter.id(isEqualTo: 'story2'));
        final docs = await query.get();

        expect(docs.length, equals(1));
        expect(docs.first.id, equals('story2'));
        expect(docs.first.title, equals('Story 2'));
      });

      test('should order by document ID using default id field', () async {
        // Add stories with specific IDs for ordering
        await odm.simpleStories.upsert(SimpleStory(
          id: 'c_story',
          title: 'C Story',
          content: 'Content C',
          authorId: 'author_c',
          tags: ['c'],
          createdAt: DateTime.now(),
        ));

        await odm.simpleStories.upsert(SimpleStory(
          id: 'a_story',
          title: 'A Story',
          content: 'Content A',
          authorId: 'author_a',
          tags: ['a'],
          createdAt: DateTime.now(),
        ));

        await odm.simpleStories.upsert(SimpleStory(
          id: 'b_story',
          title: 'B Story',
          content: 'Content B',
          authorId: 'author_b',
          tags: ['b'],
          createdAt: DateTime.now(),
        ));

        // Order by document ID ascending
        final ascendingQuery = odm.simpleStories.orderBy((order) => order.id());
        final ascendingDocs = await ascendingQuery.get();
        final ascendingIds = ascendingDocs.map((doc) => doc.id).toList();
        expect(ascendingIds, equals(['a_story', 'b_story', 'c_story']));

        // Order by document ID descending
        final descendingQuery = odm.simpleStories.orderBy((order) => order.id(descending: true));
        final descendingDocs = await descendingQuery.get();
        final descendingIds = descendingDocs.map((doc) => doc.id).toList();
        expect(descendingIds, equals(['c_story', 'b_story', 'a_story']));
      });

      test('should not include id field in JSON when storing', () async {
        const testStoryId = 'json_test_story';
        final story = SimpleStory(
          id: testStoryId,
          title: 'JSON Test Story',
          content: 'JSON test content',
          authorId: 'author_123',
          tags: ['json', 'test'],
          createdAt: DateTime.now(),
        );

        await odm.simpleStories.upsert(story);

        // Check the raw Firestore document
        final docSnapshot = await firestore.doc('simple_stories/$testStoryId').get();
        final rawData = docSnapshot.data()!;
        
        // The id field should not be in the stored data
        expect(rawData.containsKey('id'), isFalse);
        expect(rawData['title'], equals('JSON Test Story'));
      });

      test('should handle upsert with empty or null id', () async {
        final storyWithEmptyId = SimpleStory(
          id: '',
          title: 'Empty ID Story',
          content: 'Empty content',
          authorId: 'author_123',
          tags: [],
          createdAt: DateTime.now(),
        );

        // Should throw error for empty ID
        expect(
          () => odm.simpleStories.upsert(storyWithEmptyId),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Comparison with explicit @DocumentIdField', () {
      test('should behave identically to explicit annotation', () async {
        // Create a story with default id field
        final defaultStory = SimpleStory(
          id: 'default_story',
          title: 'Default Story',
          content: 'Default content',
          authorId: 'author1',
          tags: ['default'],
          createdAt: DateTime.now(),
        );

        await odm.simpleStories.upsert(defaultStory);

        // Verify behavior is identical
        final retrievedStory = await odm.simpleStories('default_story').get();
        expect(retrievedStory, isNotNull);
        expect(retrievedStory!.id, equals('default_story'));
        
        // Verify ID field not stored in document
        final docSnapshot = await firestore.doc('simple_stories/default_story').get();
        expect(docSnapshot.data()!.containsKey('id'), isFalse);
      });
    });
  });
}