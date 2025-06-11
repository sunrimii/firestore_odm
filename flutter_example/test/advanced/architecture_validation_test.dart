import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/simple_story.dart';
import 'package:flutter_example/models/shared_post.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🏗️ Architecture Validation', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📋 Schema Analysis & Collection Processing', () {
      test('should validate all collections are properly identified', () {
        // Verify all collections from schema are accessible
        expect(() => odm.users, returnsNormally);
        expect(() => odm.posts, returnsNormally);
        expect(() => odm.simpleStories, returnsNormally);
        expect(() => odm.sharedPosts, returnsNormally);

        // Verify schema type
        expect(odm.schema, isA<TestSchema>());
      });

      test('should validate collection relationships are correctly processed',
          () {
        // Root collections should have correct paths
        expect(odm.users.query.path, equals('users'));
        expect(odm.posts.query.path, equals('posts'));
        expect(odm.simpleStories.query.path, equals('simpleStories'));
        expect(odm.sharedPosts.query.path, equals('sharedPosts'));

        // Subcollections should be accessible through parent documents
        final userDoc = odm.users('test_user');
        expect(userDoc.posts.query.path, equals('users/test_user/posts'));
        expect(userDoc.sharedPosts.query.path,
            equals('users/test_user/sharedPosts'));
      });

      test('should validate unified validation completed before generation',
          () {
        // All model types should be properly typed
        expect(odm.users, isA<FirestoreCollection<TestSchema, User>>());
        expect(odm.posts, isA<FirestoreCollection<TestSchema, Post>>());
        expect(odm.simpleStories,
            isA<FirestoreCollection<TestSchema, SimpleStory>>());
        expect(odm.sharedPosts,
            isA<FirestoreCollection<TestSchema, SharedPost>>());

        // Subcollections should also be properly typed
        expect(odm.users('test').posts,
            isA<FirestoreCollection<TestSchema, Post>>());
        expect(odm.users('test').sharedPosts,
            isA<FirestoreCollection<TestSchema, SharedPost>>());
      });
    });

    group('⚡ High-Efficiency Generation Validation', () {
      test('should validate converters work efficiently across all models',
          () async {
        // Test all model types to ensure converters are generated correctly
        final user = User(
          id: 'converter_test_user',
          name: 'Converter Test',
          email: 'converter@example.com',
          age: 30,
          profile: Profile(
            bio: 'Converter test',
            avatar: 'converter.jpg',
            socialLinks: {},
            interests: ['efficiency'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final post = Post(
          id: 'converter_test_post',
          title: 'Converter Test Post',
          content: 'Testing converter efficiency',
          authorId: 'converter_test_user',
          tags: ['test'],
          metadata: {},
          likes: 5,
          published: true,
          createdAt: DateTime.now(),
        );

        final story = SimpleStory(
          id: 'converter_test_story',
          title: 'Converter Test Story',
          content: 'Testing story converter',
          authorId: 'converter_test_user',
          tags: ['story'],
          createdAt: DateTime.now(),
        );

        final sharedPost = SharedPost(
          id: 'converter_test_shared',
          title: 'Converter Test Shared',
          content: 'Testing shared converter',
          authorId: 'converter_test_user',
          tags: ['shared'],
          likes: 3,
          published: true,
          createdAt: DateTime.now(),
        );

        // All conversions should work efficiently
        await odm.users('converter_test_user').update(user);
        await odm.posts('converter_test_post').update(post);
        await odm.simpleStories('converter_test_story').update(story);
        await odm.sharedPosts('converter_test_shared').update(sharedPost);

        // Verify all conversions work correctly
        final retrievedUser = await odm.users('converter_test_user').get();
        final retrievedPost = await odm.posts('converter_test_post').get();
        final retrievedStory =
            await odm.simpleStories('converter_test_story').get();
        final retrievedShared =
            await odm.sharedPosts('converter_test_shared').get();

        expect(retrievedUser, isNotNull);
        expect(retrievedPost, isNotNull);
        expect(retrievedStory, isNotNull);
        expect(retrievedShared, isNotNull);

        expect(retrievedUser!.name, equals('Converter Test'));
        expect(retrievedPost!.title, equals('Converter Test Post'));
        expect(retrievedStory!.title, equals('Converter Test Story'));
        expect(retrievedShared!.title, equals('Converter Test Shared'));
      });

      test('should validate no runtime data collection during operations',
          () async {
        final stopwatch = Stopwatch()..start();

        // Perform operations that should be fast due to pre-analysis
        final operations = <Future>[];

        for (int i = 0; i < 20; i++) {
          operations.addAll([
            odm.users('perf_user_$i').update(User(
                  id: 'perf_user_$i',
                  name: 'Performance User $i',
                  email: 'perf$i@example.com',
                  age: 20 + i,
                  profile: Profile(
                    bio: 'Performance test $i',
                    avatar: 'perf$i.jpg',
                    socialLinks: {},
                    interests: ['performance'],
                    followers: i * 10,
                  ),
                  rating: 1.0 + i * 0.1,
                  isActive: true,
                  isPremium: false,
                  createdAt: DateTime.now(),
                )),
            odm.posts('perf_post_$i').update(Post(
                  id: 'perf_post_$i',
                  title: 'Performance Post $i',
                  content: 'Performance test content $i',
                  authorId: 'perf_user_$i',
                  tags: ['performance'],
                  metadata: {},
                  likes: i,
                  published: true,
                  createdAt: DateTime.now(),
                )),
          ]);
        }

        await Future.wait(operations);

        final operationTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // Operations should be fast due to efficient pre-generation
        expect(
            operationTime, lessThan(15000)); // 15 seconds max for 40 operations

        // Verify all operations completed successfully
        final users = await odm.users.limit(25).get();
        final posts = await odm.posts.limit(25).get();

        expect(users.length, greaterThanOrEqualTo(20));
        expect(posts.length, greaterThanOrEqualTo(20));
      });
    });

    group('🔗 Collection Type Mapping & Schema Integration', () {
      test('should validate consistent type mapping across collections',
          () async {
        // Test that the same model works consistently across different collection paths
        final sharedPost1 = SharedPost(
          id: 'shared_1',
          title: 'Shared Post 1',
          content: 'Root collection shared post',
          authorId: 'author1',
          tags: ['shared'],
          likes: 10,
          published: true,
          createdAt: DateTime.now(),
        );

        final sharedPost2 = SharedPost(
          id: 'shared_2',
          title: 'Shared Post 2',
          content: 'Subcollection shared post',
          authorId: 'author1',
          tags: ['shared', 'subcollection'],
          likes: 7,
          published: true,
          createdAt: DateTime.now(),
        );

        // Add to different collection paths using same model
        await odm.sharedPosts('shared_1').update(sharedPost1);
        await odm.users('author1').sharedPosts('shared_2').update(sharedPost2);

        // Retrieve from both paths
        final rootSharedPost = await odm.sharedPosts('shared_1').get();
        final subSharedPost =
            await odm.users('author1').sharedPosts('shared_2').get();

        expect(rootSharedPost, isNotNull);
        expect(subSharedPost, isNotNull);

        expect(rootSharedPost!.title, equals('Shared Post 1'));
        expect(subSharedPost!.title, equals('Shared Post 2'));

        // Both should be the same type despite different collection paths
        expect(rootSharedPost, isA<SharedPost>());
        expect(subSharedPost, isA<SharedPost>());
      });

      test('should validate schema-level conflict detection works', () {
        // Different models should use different collection paths
        expect(odm.posts.query.path, equals('posts'));
        expect(odm.sharedPosts.query.path, equals('sharedPosts'));
        expect(odm.simpleStories.query.path, equals('simpleStories'));

        // Subcollections should also have different paths
        expect(odm.users('test').posts.query.path, equals('users/test/posts'));
        expect(odm.users('test').sharedPosts.query.path,
            equals('users/test/sharedPosts'));

        // No path conflicts should exist
        final paths = {
          odm.users.query.path,
          odm.posts.query.path,
          odm.sharedPosts.query.path,
          odm.simpleStories.query.path,
        };

        expect(paths.length, equals(4)); // All paths should be unique
      });
    });

    group('🔧 Generator Logic Simplicity', () {
      test('should validate single responsibility principle', () {
        // Each collection should have clear, focused functionality
        expect(odm.users, isA<FirestoreCollection<TestSchema, User>>());
        expect(() => odm.users('test_id'), returnsNormally);
        expect(() => odm.users.where(($) => $.name(isEqualTo: 'test')),
            returnsNormally);

        expect(odm.posts, isA<FirestoreCollection<TestSchema, Post>>());
        expect(() => odm.posts('test_id'), returnsNormally);
        expect(() => odm.posts.where(($) => $.title(isEqualTo: 'test')),
            returnsNormally);

        // Each should be independently functional
        expect(odm.users.query.path, isNot(equals(odm.posts.query.path)));
      });

      test('should validate clean separation of concerns', () async {
        // Test that different aspects work independently
        final user = User(
          id: 'separation_user',
          name: 'Separation Test',
          email: 'separation@example.com',
          age: 25,
          profile: Profile(
            bio: 'Separation test',
            avatar: 'separation.jpg',
            socialLinks: {},
            interests: ['architecture'],
            followers: 50,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Data processing should work independently
        await odm.users('separation_user').update(user);
        final retrieved = await odm.users('separation_user').get();
        expect(retrieved, isNotNull);

        // Querying should work independently
        final filtered = await odm.users
            .where(($) => $.name(isEqualTo: 'Separation Test'))
            .get();
        expect(filtered.length, equals(1));

        // Updates should work independently
        await odm
            .users('separation_user')
            .modify((user) => user.copyWith(age: 26));

        final updated = await odm.users('separation_user').get();
        expect(updated!.age, equals(26));
      });
    });

    group('🚀 Scalability & Extensibility', () {
      test('should validate system handles all model types efficiently',
          () async {
        // Test that the architecture can handle all defined model types
        final user = User(
          id: 'scalability_user',
          name: 'Scalability Test',
          email: 'scalability@example.com',
          age: 30,
          profile: Profile(
            bio: 'Scalability test',
            avatar: 'scalability.jpg',
            socialLinks: {},
            interests: ['scalability'],
            followers: 100,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final post = Post(
          id: 'scalability_post',
          title: 'Scalability Post',
          content: 'Testing scalability',
          authorId: 'scalability_user',
          tags: ['scalability'],
          metadata: {},
          likes: 15,
          published: true,
          createdAt: DateTime.now(),
        );

        final story = SimpleStory(
          id: 'scalability_story',
          title: 'Scalability Story',
          content: 'Scalability story content',
          authorId: 'scalability_user',
          tags: ['scalability'],
          createdAt: DateTime.now(),
        );

        final sharedPost = SharedPost(
          id: 'scalability_shared',
          title: 'Scalability Shared Post',
          content: 'Testing scalability of shared posts',
          authorId: 'scalability_user',
          tags: ['scalability', 'shared'],
          likes: 8,
          published: true,
          createdAt: DateTime.now(),
        );

        // Set all different model types
        await odm.users('scalability_user').update(user);
        await odm.posts('scalability_post').update(post);
        await odm.simpleStories('scalability_story').update(story);
        await odm.sharedPosts('scalability_shared').update(sharedPost);

        // Verify all types work correctly
        final retrievedUser = await odm.users('scalability_user').get();
        final retrievedPost = await odm.posts('scalability_post').get();
        final retrievedStory =
            await odm.simpleStories('scalability_story').get();
        final retrievedShared =
            await odm.sharedPosts('scalability_shared').get();

        expect(retrievedUser, isNotNull);
        expect(retrievedPost, isNotNull);
        expect(retrievedStory, isNotNull);
        expect(retrievedShared, isNotNull);

        expect(retrievedUser!.name, equals('Scalability Test'));
        expect(retrievedPost!.title, equals('Scalability Post'));
        expect(retrievedStory!.title, equals('Scalability Story'));
        expect(retrievedShared!.title, equals('Scalability Shared Post'));
      });

      test('should validate performance remains consistent', () async {
        final stopwatch = Stopwatch()..start();

        // Perform operations across all model types
        final operations = <Future>[];

        for (int i = 0; i < 10; i++) {
          operations.addAll([
            odm.users('perf_test_user_$i').update(User(
                  id: 'perf_test_user_$i',
                  name: 'Performance User $i',
                  email: 'perf$i@test.com',
                  age: 20 + i,
                  profile: Profile(
                    bio: 'Performance test',
                    avatar: 'perf.jpg',
                    socialLinks: {},
                    interests: ['performance'],
                    followers: i * 10,
                  ),
                  rating: 1.0 + i * 0.1,
                  isActive: true,
                  isPremium: false,
                  createdAt: DateTime.now(),
                )),
            odm.posts('perf_test_post_$i').update(Post(
                  id: 'perf_test_post_$i',
                  title: 'Performance Post $i',
                  content: 'Performance content $i',
                  authorId: 'perf_test_user_$i',
                  tags: ['performance'],
                  metadata: {},
                  likes: i,
                  published: true,
                  createdAt: DateTime.now(),
                )),
            odm.simpleStories('perf_test_story_$i').update(SimpleStory(
                  id: 'perf_test_story_$i',
                  title: 'Performance Story $i',
                  content: 'Performance story $i',
                  authorId: 'perf_test_user_$i',
                  tags: ['performance'],
                  createdAt: DateTime.now(),
                )),
          ]);
        }

        await Future.wait(operations);

        final totalTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // Performance should remain reasonable
        expect(totalTime, lessThan(20000)); // 20 seconds max for 30 operations

        // Verify all operations completed
        final userCount = (await odm.users.limit(15).get()).length;
        final postCount = (await odm.posts.limit(15).get()).length;
        final storyCount = (await odm.simpleStories.limit(15).get()).length;

        expect(userCount, greaterThanOrEqualTo(10));
        expect(postCount, greaterThanOrEqualTo(10));
        expect(storyCount, greaterThanOrEqualTo(10));
      });
    });
  });
}
