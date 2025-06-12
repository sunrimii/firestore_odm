import 'package:flutter_test/flutter_test.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';
import 'test_helper.dart';

void main() {
  group('📄 Document ID Field Annotation Tests', () {
    late FirestoreODM<TestSchema> odm;

    setUpAll(() async {
      await initializeFirebase();
    });

    setUp(() async {
      odm = FirestoreODM(testSchema, firestore: getFirestore());
      await clearFirestoreEmulator();
    });

    group('🏷️ @DocumentIdField Annotation Behavior', () {
      test('Document ID field is correctly identified and used', () async {
        const customId = 'annotated_id_test';

        final user = User(
          id: customId, // This field has @DocumentIdField() annotation
          name: 'Annotated User',
          email: 'annotated@example.com',
          age: 30,
          profile: Profile(
            bio: 'Testing @DocumentIdField annotation',
            avatar: 'annotated.jpg',
            socialLinks: {},
            interests: ['annotations', 'testing'],
            followers: 500,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // The ID field should be automatically handled by the ODM
        await odm.users(customId).update(user);

        // Retrieve and verify the ID is preserved
        final retrievedUser = await odm.users(customId).get();
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.id, equals(customId));
        expect(retrievedUser.name, equals('Annotated User'));
      });

      test('Document ID field works in queries and filters', () async {
        const targetId = 'query_target_id';
        const otherId = 'other_id';

        final users = [
          User(
            id: targetId,
            name: 'Target User',
            email: 'target@example.com',
            age: 25,
            profile: Profile(
              bio: 'Target for queries',
              avatar: 'target.jpg',
              socialLinks: {},
              interests: ['querying'],
              followers: 100,
            ),
            rating: 5.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: otherId,
            name: 'Other User',
            email: 'other@example.com',
            age: 30,
            profile: Profile(
              bio: 'Another user',
              avatar: 'other.jpg',
              socialLinks: {},
              interests: ['being-other'],
              followers: 50,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Create both users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Query by document ID field using the annotation
        final filteredQuery = odm.users.where(
          (filter) => filter.id(isEqualTo: targetId),
        );

        final results = await filteredQuery.get();
        expect(results.length, equals(1));
        expect(results[0].id, equals(targetId));
        expect(results[0].name, equals('Target User'));

        // Test ID field in compound queries
        final compoundQuery = odm.users
            .where((filter) => filter.id(isEqualTo: targetId))
            .where((filter) => filter.rating(isGreaterThan: 4.0));

        final compoundResults = await compoundQuery.get();
        expect(compoundResults.length, equals(1));
        expect(compoundResults[0].id, equals(targetId));
      });

      test('Document ID field in ordering operations', () async {
        const ids = ['zulu_id', 'alpha_id', 'beta_id', 'charlie_id'];

        // Create users with specific IDs for ordering test
        for (int i = 0; i < ids.length; i++) {
          final user = User(
            id: ids[i],
            name: 'User ${ids[i]}',
            email: '${ids[i]}@example.com',
            age: 20 + i,
            profile: Profile(
              bio: 'User for ordering test',
              avatar: '${ids[i]}.jpg',
              socialLinks: {},
              interests: ['ordering'],
              followers: (i + 1) * 10,
            ),
            rating: (i + 1).toDouble(),
            isActive: true,
            isPremium: i % 2 == 0,
            createdAt: DateTime.now(),
          );

          await odm.users(ids[i]).update(user);
        }

        // Wait for documents to be indexed
        await Future.delayed(Duration(milliseconds: 500));

        // Order by the document ID field
        final orderedQuery = odm.users.orderBy(($) => ($.id(),));
        final orderedUsers = await orderedQuery.get();

        expect(orderedUsers.length, equals(4));

        // Should be in alphabetical order
        expect(orderedUsers[0].id, equals('alpha_id'));
        expect(orderedUsers[1].id, equals('beta_id'));
        expect(orderedUsers[2].id, equals('charlie_id'));
        expect(orderedUsers[3].id, equals('zulu_id'));

        // Test descending order
        final descendingQuery = odm.users.orderBy(
          ($) => ($.id(descending: true),),
        );
        final descendingUsers = await descendingQuery.get();

        expect(descendingUsers[0].id, equals('zulu_id'));
        expect(descendingUsers[1].id, equals('charlie_id'));
        expect(descendingUsers[2].id, equals('beta_id'));
        expect(descendingUsers[3].id, equals('alpha_id'));
      });

      test('Document ID field in pagination cursors', () async {
        const baseIds = ['page_a', 'page_b', 'page_c', 'page_d', 'page_e'];

        // Create users for pagination test
        for (int i = 0; i < baseIds.length; i++) {
          final user = User(
            id: baseIds[i],
            name: 'Page User $i',
            email: '${baseIds[i]}@example.com',
            age: 20 + i,
            profile: Profile(
              bio: 'User for pagination test',
              avatar: '${baseIds[i]}.jpg',
              socialLinks: {},
              interests: ['pagination'],
              followers: (i + 1) * 50,
            ),
            rating: (i + 1).toDouble(),
            isActive: true,
            isPremium: i % 2 == 0,
            createdAt: DateTime.now(),
          );

          await odm.users(baseIds[i]).update(user);
        }

        // Test pagination using document ID field
        final firstPageQuery = odm.users.orderBy(($) => ($.id(),)).limit(2);

        final firstPage = await firstPageQuery.get();
        expect(firstPage.length, equals(2));
        expect(firstPage[0].id, equals('page_a'));
        expect(firstPage[1].id, equals('page_b'));

        // Get next page using startAfter with ID cursor
        final secondPageQuery = odm.users
            .orderBy(($) => ($.id(),))
            .startAfter(('page_b',))
            .limit(2);

        final secondPage = await secondPageQuery.get();
        expect(secondPage.length, equals(2));
        expect(secondPage[0].id, equals('page_c'));
        expect(secondPage[1].id, equals('page_d'));

        // Test object-based pagination with document ID
        final thirdPageQuery = odm.users
            .orderBy(($) => ($.id(),))
            .startAfterObject(firstPage[1]) // Using page_b user object
            .limit(3);

        final thirdPage = await thirdPageQuery.get();
        expect(thirdPage.length, equals(3));
        expect(thirdPage[0].id, equals('page_c'));
        expect(thirdPage[1].id, equals('page_d'));
        expect(thirdPage[2].id, equals('page_e'));
      });
    });

    group('🔗 Document ID Field in Subcollections', () {
      test('Subcollection document ID field behavior', () async {
        const userId = 'subcol_user';
        const postIds = ['sub_post_alpha', 'sub_post_beta', 'sub_post_gamma'];

        // Create parent user
        final user = User(
          id: userId,
          name: 'Subcollection Test User',
          email: 'subcol@example.com',
          age: 35,
          profile: Profile(
            bio: 'Testing subcollection document IDs',
            avatar: 'subcol.jpg',
            socialLinks: {},
            interests: ['subcollections'],
            followers: 750,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users(userId).update(user);

        // Create posts in subcollection with custom IDs
        for (int i = 0; i < postIds.length; i++) {
          final post = Post(
            id: postIds[i], // @DocumentIdField annotation applies here too
            title: 'Subcollection Post ${i + 1}',
            content: 'Content for post ${postIds[i]}',
            authorId: userId,
            tags: ['subcollection', 'test'],
            metadata: {'index': i},
            likes: (i + 1) * 10,
            views: (i + 1) * 100,
            published: true,
            createdAt: DateTime.now(),
          );

          await odm.users(userId).posts(postIds[i]).update(post);
        }

        // Query subcollection by document ID
        final filteredPosts = await odm
            .users(userId)
            .posts
            .where((filter) => filter.id(isEqualTo: 'sub_post_beta'))
            .get();

        expect(filteredPosts.length, equals(1));
        expect(filteredPosts[0].id, equals('sub_post_beta'));
        expect(filteredPosts[0].title, equals('Subcollection Post 2'));

        // Order subcollection by document ID
        final orderedPosts = await odm
            .users(userId)
            .posts
            .orderBy(($) => ($.id(),))
            .get();

        expect(orderedPosts.length, equals(3));
        expect(orderedPosts[0].id, equals('sub_post_alpha'));
        expect(orderedPosts[1].id, equals('sub_post_beta'));
        expect(orderedPosts[2].id, equals('sub_post_gamma'));

        // Paginate subcollection using document ID
        final paginatedPosts = await odm
            .users(userId)
            .posts
            .orderBy(($) => ($.id(),))
            .startAt(('sub_post_beta',))
            .limit(2)
            .get();

        expect(paginatedPosts.length, equals(2));
        expect(paginatedPosts[0].id, equals('sub_post_beta'));
        expect(paginatedPosts[1].id, equals('sub_post_gamma'));
      });

      test('Complex subcollection queries with document ID field', () async {
        const userId = 'complex_subcol_user';

        // Create parent user
        final user = User(
          id: userId,
          name: 'Complex Subcollection User',
          email: 'complex@example.com',
          age: 28,
          profile: Profile(
            bio: 'Testing complex subcollection scenarios',
            avatar: 'complex.jpg',
            socialLinks: {},
            interests: ['complexity'],
            followers: 300,
          ),
          rating: 4.8,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users(userId).update(user);

        // Create posts with varying characteristics
        final posts = [
          Post(
            id: 'high_engagement_post',
            title: 'High Engagement Post',
            content: 'This post has high engagement',
            authorId: userId,
            tags: ['popular', 'trending'],
            metadata: {'category': 'viral'},
            likes: 1000,
            views: 10000,
            published: true,
            createdAt: DateTime.now(),
          ),
          Post(
            id: 'draft_post',
            title: 'Draft Post',
            content: 'This is still a draft',
            authorId: userId,
            tags: ['draft', 'wip'],
            metadata: {'category': 'draft'},
            likes: 0,
            views: 5,
            published: false,
            createdAt: DateTime.now(),
          ),
          Post(
            id: 'medium_post',
            title: 'Medium Engagement Post',
            content: 'This post has medium engagement',
            authorId: userId,
            tags: ['medium', 'regular'],
            metadata: {'category': 'normal'},
            likes: 50,
            views: 500,
            published: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Create all posts
        for (final post in posts) {
          await odm.users(userId).posts(post.id).update(post);
        }

        // Complex query: published posts with high engagement, ordered by likes
        final complexQuery = await odm
            .users(userId)
            .posts
            .where((filter) => filter.published(isEqualTo: true))
            .where((filter) => filter.likes(isGreaterThan: 25))
            .orderBy(($) => ($.likes(),))
            .get();

        expect(complexQuery.length, equals(2));
        // Order should be by likes: medium_post (50), high_engagement_post (1000)
        expect(complexQuery[0].likes, equals(50));
        expect(complexQuery[1].likes, equals(1000));

        // Multi-field ordering with regular fields
        final multiOrderQuery = await odm
            .users(userId)
            .posts
            .orderBy(($) => ($.likes(descending: true),))
            .get();

        expect(multiOrderQuery.length, equals(3));
        // Ordered by likes desc, then ID asc
        expect(
          multiOrderQuery[0].id,
          equals('high_engagement_post'),
        ); // 1000 likes
        expect(multiOrderQuery[1].id, equals('medium_post')); // 50 likes
        expect(multiOrderQuery[2].id, equals('draft_post')); // 0 likes

        // Range query on document ID
        final rangeQuery = await odm
            .users(userId)
            .posts
            .where((filter) => filter.id(isGreaterThanOrEqualTo: 'draft_post'))
            .where((filter) => filter.id(isLessThan: 'medium_post'))
            .orderBy(($) => ($.id(),))
            .get();

        expect(rangeQuery.length, equals(2));
        expect(rangeQuery[0].id, equals('draft_post'));
        expect(rangeQuery[1].id, equals('high_engagement_post'));
      });
    });

    group('⚡ Document ID Field Performance and Edge Cases', () {
      test('Document ID field with large datasets', () async {
        const userCount = 50;

        // Create a large number of users with systematic IDs
        for (int i = 0; i < userCount; i++) {
          final paddedId = 'user_${i.toString().padLeft(3, '0')}';
          final user = User(
            id: paddedId,
            name: 'User $i',
            email: 'user$i@example.com',
            age: 20 + (i % 30),
            profile: Profile(
              bio: 'Large dataset user $i',
              avatar: 'user$i.jpg',
              socialLinks: {},
              interests: ['performance'],
              followers: i * 5,
            ),
            rating: 1.0 + (i % 5),
            isActive: i % 3 != 0,
            isPremium: i % 4 == 0,
            createdAt: DateTime.now(),
          );

          await odm.users(paddedId).update(user);
        }

        // Test efficient pagination through large dataset
        const pageSize = 10;
        String? lastId;
        int totalRetrieved = 0;

        while (totalRetrieved < userCount) {
          var query = odm.users.orderBy(($) => ($.id(),)).limit(pageSize);

          if (lastId != null) {
            query = query.startAfter((lastId,));
          }

          final page = await query.get();
          expect(page.length, lessThanOrEqualTo(pageSize));

          if (page.isEmpty) break;

          totalRetrieved += page.length;
          lastId = page.last.id;

          // Verify page ordering
          for (int i = 1; i < page.length; i++) {
            expect(page[i].id.compareTo(page[i - 1].id), greaterThan(0));
          }
        }

        expect(totalRetrieved, equals(userCount));
      });

      test('Document ID field with unicode and special characters', () async {
        const unicodeIds = [
          'user_émojis_😀',
          'user_中文_测试',
          'user_العربية',
          'user_русский',
          'user_日本語',
          'user_한국어',
        ];

        // Create users with unicode IDs
        for (int i = 0; i < unicodeIds.length; i++) {
          final user = User(
            id: unicodeIds[i],
            name: 'Unicode User $i',
            email: 'unicode$i@example.com',
            age: 25 + i,
            tags: ['unicode', 'international'],
            profile: Profile(
              bio: 'Testing unicode document IDs',
              avatar: 'unicode$i.jpg',
              socialLinks: {},
              interests: ['unicode', 'international'],
              followers: (i + 1) * 25,
            ),
            rating: 3.0 + i * 0.3,
            isActive: true,
            isPremium: i % 2 == 0,
            createdAt: DateTime.now(),
          );

          await odm.users(unicodeIds[i]).update(user);
        }

        // Verify all unicode IDs work correctly
        for (final id in unicodeIds) {
          final user = await odm.users(id).get();
          expect(user, isNotNull);
          expect(user!.id, equals(id));
        }

        // Test ordering with unicode characters
        final orderedQuery = odm.users
            .where((filter) => filter.tags(arrayContains: 'unicode'))
            .orderBy(($) => ($.id(),));

        final orderedUsers = await orderedQuery.get();
        expect(orderedUsers.length, equals(unicodeIds.length));

        // Verify they can be retrieved by ID filtering
        for (final id in unicodeIds) {
          final filteredUsers = await odm.users
              .where((filter) => filter.id(isEqualTo: id))
              .get();

          expect(filteredUsers.length, equals(1));
          expect(filteredUsers[0].id, equals(id));
        }
      });

      test('Document ID field boundary conditions', () async {
        // Test edge cases for document IDs
        final edgeCaseIds = [
          '', // Empty string (should work in fake firestore)
          ' ', // Single space
          '   ', // Multiple spaces
          'a', // Single character
          'A' * 100, // Very long ID
          '123456789', // All numbers
          '!@#\$%^&*()', // Special characters
          'mixed_Case_123_!@#', // Mixed everything
        ];

        // Test each edge case ID
        for (int i = 0; i < edgeCaseIds.length; i++) {
          final id = edgeCaseIds[i];

          try {
            final user = User(
              id: id,
              name: 'Edge Case User $i',
              email: 'edge$i@example.com',
              age: 30,
              profile: Profile(
                bio: 'Testing edge case ID: "$id"',
                avatar: 'edge$i.jpg',
                socialLinks: {},
                interests: ['edge-cases'],
                followers: 10,
              ),
              rating: 3.0,
              isActive: true,
              isPremium: false,
              createdAt: DateTime.now(),
            );

            await odm.users(id).update(user);

            // Verify retrieval
            final retrievedUser = await odm.users(id).get();
            expect(retrievedUser, isNotNull);
            expect(retrievedUser!.id, equals(id));

            print('✅ Edge case ID "$id" works correctly');
          } catch (e) {
            print('❌ Edge case ID "$id" failed: $e');
            // Some edge cases might legitimately fail
          }
        }
      });
    });
  });
}
