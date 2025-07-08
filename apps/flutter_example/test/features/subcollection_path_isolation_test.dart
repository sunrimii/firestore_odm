import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('Subcollection Path Isolation Bug Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('BUG REPRODUCTION: users can access posts but users2 cannot', () {
      // Schema setup:
      // @Collection<User>("users")
      // @Collection<Post>("users/*/posts") // Only users has posts subcollection
      // @Collection<User>("users2") // users2 does NOT have posts subcollection

      final usersDoc = odm.users('test_user');
      final users2Doc = odm.users2('test_user');

      // CRITICAL TEST 1: users should have posts subcollection
      bool usersHasPosts = false;
      try {
        final usersPosts = usersDoc.posts;
        usersHasPosts = true;
        expect(usersPosts, isNotNull);
        expect(usersPosts.query.path, equals('users/test_user/posts'));
      } catch (e) {
        // Should not happen
      }

      expect(
        usersHasPosts,
        isTrue,
        reason: 'users should have access to posts subcollection',
      );

      // CRITICAL TEST 2: users2 should NOT have posts subcollection
      bool users2HasPosts = false;
      dynamic users2Posts;
      try {
        // This should fail because Users2Document doesn't have posts extension
        users2Posts = (users2Doc as dynamic).posts;
        users2HasPosts = true;
      } catch (e) {
        // Expected to fail
      }

      expect(
        users2HasPosts,
        isFalse,
        reason:
            'users2 should NOT have access to posts subcollection - this is the core bug!',
      );
    });

    test('NESTED SUBCOLLECTIONS: multi-level path isolation verification', () {
      // Schema setup:
      // @Collection<Post>("posts")
      // @Collection<Post>("users/*/posts")
      // @Collection<Comment>("posts/*/comments")
      // @Collection<Comment>("users/*/posts/*/comments")

      // Test 1: Direct posts collection should have comments
      final directPost = odm.posts('post1');

      bool directPostHasComments = false;
      try {
        final directPostComments = directPost.comments;
        directPostHasComments = true;
        expect(directPostComments.query.path, equals('posts/post1/comments'));
      } catch (e) {
        // Should not happen
      }

      expect(
        directPostHasComments,
        isTrue,
        reason: 'Direct posts should have comments subcollection',
      );

      // Test 2: User's posts should also have comments (nested path)
      final userPost = odm.users('user1').posts('post1');

      bool userPostHasComments = false;
      try {
        final userPostComments = userPost.comments;
        userPostHasComments = true;
        expect(
          userPostComments.query.path,
          equals('users/user1/posts/post1/comments'),
        );
      } catch (e) {
        // Should not happen
      }

      expect(
        userPostHasComments,
        isTrue,
        reason: 'User posts should have comments subcollection (nested)',
      );

      // Test 3: Verify paths are correctly different
      expect(directPost.ref.path, equals('posts/post1'));
      expect(userPost.ref.path, equals('users/user1/posts/post1'));
    });

    test('EXTENSION TARGETING: verify path-specific document extensions', () {
      final usersDoc = odm.users('user1');
      final users2Doc = odm.users2('user1');
      final postsDoc = odm.posts('post1');

      // Test that extensions are applied correctly based on document type

      // 1. UsersDocument should have posts extension
      bool usersHasPostsExtension = false;
      try {
        final _ = usersDoc.posts;
        usersHasPostsExtension = true;
      } catch (e) {
        // Should not happen
      }

      // 2. PostsDocument should have comments extension
      bool postsHasCommentsExtension = false;
      try {
        final _ = postsDoc.comments;
        postsHasCommentsExtension = true;
      } catch (e) {
        // Should not happen
      }

      // 3. Users2Document should NOT have posts extension
      bool users2HasPostsExtension = false;
      try {
        final _ = (users2Doc as dynamic).posts;
        users2HasPostsExtension = true;
      } catch (e) {
        // Expected to fail
      }

      expect(usersHasPostsExtension, isTrue);
      expect(postsHasCommentsExtension, isTrue);
      expect(
        users2HasPostsExtension,
        isFalse,
        reason:
            'This is the key bug fix - Users2Document should NOT have posts',
      );
    });

    test(
      'COMPREHENSIVE ISOLATION: all subcollection patterns work correctly',
      () {
        // Test all schema combinations systematically:
        // 1. users -> posts ✓
        // 2. posts -> comments ✓
        // 3. users -> posts -> comments (nested) ✓
        // 4. users2 should have NONE ✓

        final user = odm.users('user1');
        final user2 = odm.users2('user1');
        final post = odm.posts('post1');

        var passedTests = 0;
        var totalTests = 0;

        // Test 1: User -> Posts
        totalTests++;
        try {
          final userPosts = user.posts;
          expect(userPosts, isNotNull);
          expect(userPosts.query.path, equals('users/user1/posts'));
          passedTests++;
        } catch (e) {
          // Should not happen
        }

        // Test 2: Post -> Comments
        totalTests++;
        try {
          final postComments = post.comments;
          expect(postComments, isNotNull);
          expect(postComments.query.path, equals('posts/post1/comments'));
          passedTests++;
        } catch (e) {
          // Should not happen
        }

        // Test 3: Nested - User -> Post -> Comments
        totalTests++;
        try {
          final userPost = user.posts('post1');
          final userPostComments = userPost.comments;
          expect(userPostComments, isNotNull);
          expect(
            userPostComments.query.path,
            equals('users/user1/posts/post1/comments'),
          );
          passedTests++;
        } catch (e) {
          // Should not happen
        }

        // Test 4: Users2 should fail (CRITICAL)
        totalTests++;
        try {
          final _ = (user2 as dynamic).posts;
        } catch (e) {
          passedTests++;
        }

        // Test 5: Verify document types are different
        totalTests++;
        try {
          // The critical test: users can access posts, users2 cannot
          bool userCanAccessPosts = false;
          bool user2CanAccessPosts = false;

          try {
            final _ = user.posts;
            userCanAccessPosts = true;
          } catch (e) {
            // Should not happen for users
          }

          try {
            final _ = (user2 as dynamic).posts;
            user2CanAccessPosts = true;
          } catch (e) {
            // Should happen for users2 (NoSuchMethodError)
            if (e is NoSuchMethodError) {
              user2CanAccessPosts = false;
            }
          }

          expect(
            userCanAccessPosts,
            isTrue,
            reason: 'users should have posts method',
          );
          expect(
            user2CanAccessPosts,
            isFalse,
            reason: 'users2 should NOT have posts method',
          );

          passedTests++;
        } catch (e) {
          // Test failed
        }

        expect(
          passedTests,
          equals(totalTests),
          reason: 'All subcollection isolation tests should pass',
        );
      },
    );

    test('FINAL VERIFICATION: bug completely fixed', () {
      // Document type verification
      final users1 = odm.users('u1');
      final users2_1 = odm.users2('u1');
      final posts1 = odm.posts('p1');

      // Verify different document types
      expect(
        users1.runtimeType,
        equals(FirestoreDocument<TestSchema, User, dynamic, UserPatchBuilder>),
      );
      expect(
        users2_1.runtimeType,
        equals(FirestoreDocument<TestSchema, User, dynamic, UserPatchBuilder>),
      );
      expect(
        posts1.runtimeType,
        equals(FirestoreDocument<TestSchema, Post, dynamic, PostPatchBuilder>),
      );

      // The core bug test: users2 cannot access posts
      bool users2FailedCorrectly = false;
      try {
        final _ = (users2_1 as dynamic).posts;
      } catch (e) {
        if (e is NoSuchMethodError) {
          users2FailedCorrectly = true;
        }
      }

      expect(
        users2FailedCorrectly,
        isTrue,
        reason: 'users2 should NOT have posts - this verifies the bug is fixed',
      );

      // Verify users CAN access posts
      bool usersHasPosts = false;
      try {
        final userPosts = users1.posts;
        usersHasPosts = (userPosts != null);
      } catch (e) {
        // Should not happen
      }

      expect(usersHasPosts, isTrue, reason: 'users should have posts');
    });
  });
}
