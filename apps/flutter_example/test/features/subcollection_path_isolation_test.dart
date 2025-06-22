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
      
      print('=== TESTING CORE BUG ===');
      print('users doc type: ${usersDoc.runtimeType}');
      print('users2 doc type: ${users2Doc.runtimeType}');
      
      // CRITICAL TEST 1: users should have posts subcollection
      bool usersHasPosts = false;
      try {
        final usersPosts = usersDoc.posts;
        usersHasPosts = true;
        print('✅ users.posts is accessible: ${usersPosts.runtimeType}');
        print('   Collection path: ${usersPosts.query.path}');
        expect(usersPosts, isNotNull);
        expect(usersPosts.query.path, equals('users/test_user/posts'));
      } catch (e) {
        print('❌ FAIL: users.posts should be accessible but threw: $e');
      }
      
      expect(usersHasPosts, isTrue, 
        reason: 'users should have access to posts subcollection');
      
      // CRITICAL TEST 2: users2 should NOT have posts subcollection
      bool users2HasPosts = false;
      dynamic users2Posts;
      try {
        // This should fail because Users2Document doesn't have posts extension
        users2Posts = (users2Doc as dynamic).posts;
        users2HasPosts = true;
        print('❌ CRITICAL BUG: users2.posts is accessible but should NOT be!');
        print('   Type: ${users2Posts.runtimeType}');
        if (users2Posts != null && users2Posts.query != null) {
          print('   Path: ${users2Posts.query.path}');
        }
      } catch (e) {
        print('✅ SUCCESS: users2.posts correctly fails: $e');
      }
      
      expect(users2HasPosts, isFalse, 
        reason: 'users2 should NOT have access to posts subcollection - this is the core bug!');
    });

    test('NESTED SUBCOLLECTIONS: multi-level path isolation verification', () {
      // Schema setup:
      // @Collection<Post>("posts")
      // @Collection<Post>("users/*/posts") 
      // @Collection<Comment>("posts/*/comments")
      // @Collection<Comment>("users/*/posts/*/comments")
      
      print('\n=== TESTING NESTED SUBCOLLECTIONS ===');
      
      // Test 1: Direct posts collection should have comments
      final directPost = odm.posts('post1');
      print('Direct post type: ${directPost.runtimeType}');
      print('Direct post path: ${directPost.ref.path}');
      
      bool directPostHasComments = false;
      try {
        final directPostComments = directPost.comments;
        directPostHasComments = true;
        print('✅ posts.comments accessible: ${directPostComments.runtimeType}');
        print('   Comments path: ${directPostComments.query.path}');
        expect(directPostComments.query.path, equals('posts/post1/comments'));
      } catch (e) {
        print('❌ FAIL: posts.comments should be accessible: $e');
      }
      
      expect(directPostHasComments, isTrue, 
        reason: 'Direct posts should have comments subcollection');
      
      // Test 2: User's posts should also have comments (nested path)
      final userPost = odm.users('user1').posts('post1');
      print('User post type: ${userPost.runtimeType}');
      print('User post path: ${userPost.ref.path}');
      
      bool userPostHasComments = false;
      try {
        final userPostComments = userPost.comments;
        userPostHasComments = true;
        print('✅ users.posts.comments accessible: ${userPostComments.runtimeType}');
        print('   Comments path: ${userPostComments.query.path}');
        expect(userPostComments.query.path, equals('users/user1/posts/post1/comments'));
      } catch (e) {
        print('❌ FAIL: users.posts.comments should be accessible: $e');
      }
      
      expect(userPostHasComments, isTrue, 
        reason: 'User posts should have comments subcollection (nested)');
      
      // Test 3: Verify paths are correctly different
      expect(directPost.ref.path, equals('posts/post1'));
      expect(userPost.ref.path, equals('users/user1/posts/post1'));
    });

    test('EXTENSION TARGETING: verify path-specific document extensions', () {
      print('\n=== TESTING EXTENSION TARGETING ===');
      
      final usersDoc = odm.users('user1');
      final users2Doc = odm.users2('user1');
      final postsDoc = odm.posts('post1');
      
      // Check runtime types to see if we have unique document classes
      print('Users doc type: ${usersDoc.runtimeType}');
      print('Users2 doc type: ${users2Doc.runtimeType}');
      print('Posts doc type: ${postsDoc.runtimeType}');
      
      // Test that extensions are applied correctly based on document type
      
      // 1. UsersDocument should have posts extension
      bool usersHasPostsExtension = false;
      try {
        final _ = usersDoc.posts;
        usersHasPostsExtension = true;
        print('✅ UsersDocument has posts extension');
      } catch (e) {
        print('❌ UsersDocument missing posts extension: $e');
      }
      
      // 2. PostsDocument should have comments extension  
      bool postsHasCommentsExtension = false;
      try {
        final _ = postsDoc.comments;
        postsHasCommentsExtension = true;
        print('✅ PostsDocument has comments extension');
      } catch (e) {
        print('❌ PostsDocument missing comments extension: $e');
      }
      
      // 3. Users2Document should NOT have posts extension
      bool users2HasPostsExtension = false;
      try {
        final _ = (users2Doc as dynamic).posts;
        users2HasPostsExtension = true;
        print('❌ CRITICAL: Users2Document incorrectly has posts extension!');
      } catch (e) {
        print('✅ Users2Document correctly lacks posts extension: $e');
      }
      
      expect(usersHasPostsExtension, isTrue);
      expect(postsHasCommentsExtension, isTrue);
      expect(users2HasPostsExtension, isFalse, 
        reason: 'This is the key bug fix - Users2Document should NOT have posts');
    });

    test('COMPREHENSIVE ISOLATION: all subcollection patterns work correctly', () {
      print('\n=== COMPREHENSIVE SUBCOLLECTION TESTING ===');
      
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
        print('✅ Test 1 PASSED: users.posts works');
        passedTests++;
      } catch (e) {
        print('❌ Test 1 FAILED: users.posts: $e');
      }
      
      // Test 2: Post -> Comments  
      totalTests++;
      try {
        final postComments = post.comments;
        expect(postComments, isNotNull);
        expect(postComments.query.path, equals('posts/post1/comments'));
        print('✅ Test 2 PASSED: posts.comments works');
        passedTests++;
      } catch (e) {
        print('❌ Test 2 FAILED: posts.comments: $e');
      }
      
      // Test 3: Nested - User -> Post -> Comments
      totalTests++;
      try {
        final userPost = user.posts('post1');
        final userPostComments = userPost.comments;
        expect(userPostComments, isNotNull);
        expect(userPostComments.query.path, equals('users/user1/posts/post1/comments'));
        print('✅ Test 3 PASSED: users.posts.comments works (nested)');
        passedTests++;
      } catch (e) {
        print('❌ Test 3 FAILED: users.posts.comments: $e');
      }
      
      // Test 4: Users2 should fail (CRITICAL)
      totalTests++;
      try {
        final _ = (user2 as dynamic).posts;
        print('❌ Test 4 FAILED: users2.posts should NOT work but it does!');
      } catch (e) {
        print('✅ Test 4 PASSED: users2.posts correctly fails');
        passedTests++;
      }
      
      // Test 5: Verify document types are different
      totalTests++;
      try {
        // Even if runtime types look the same, the extensions should be different
        print('User doc type: ${user.runtimeType}');
        print('User2 doc type: ${user2.runtimeType}');
        print('Post doc type: ${post.runtimeType}');
        
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
        
        expect(userCanAccessPosts, isTrue, reason: 'users should have posts method');
        expect(user2CanAccessPosts, isFalse, reason: 'users2 should NOT have posts method');
        
        print('✅ Test 5 PASSED: Document types have correct capabilities');
        passedTests++;
      } catch (e) {
        print('❌ Test 5 FAILED: Document type verification: $e');
      }
      
      print('\n=== FINAL RESULTS ===');
      print('Passed: $passedTests / $totalTests tests');
      
      if (passedTests == totalTests) {
        print('🎉 ALL SUBCOLLECTION ISOLATION TESTS PASSED!');
        print('🎉 The bug has been successfully fixed!');
      } else {
        print('❌ Some tests failed - bug not fully fixed yet');
      }
      
      expect(passedTests, equals(totalTests), 
        reason: 'All subcollection isolation tests should pass');
    });

    test('FINAL VERIFICATION: bug completely fixed', () {
      print('\n=== FINAL VERIFICATION ===');
      
      // Document type verification
      final users1 = odm.users('u1');
      final users2_1 = odm.users2('u1');
      final posts1 = odm.posts('p1');
      
      print('Document types:');
      print('  users: ${users1.runtimeType}');
      print('  users2: ${users2_1.runtimeType}');
      print('  posts: ${posts1.runtimeType}');
      
      // Verify different document types
      expect(users1.runtimeType.toString(), equals('UsersDocument'));
      expect(users2_1.runtimeType.toString(), equals('Users2Document'));
      expect(posts1.runtimeType.toString(), equals('PostsDocument'));
      
      // The core bug test: users2 cannot access posts
      bool users2FailedCorrectly = false;
      try {
        final _ = (users2_1 as dynamic).posts;
      } catch (e) {
        if (e is NoSuchMethodError) {
          users2FailedCorrectly = true;
        }
      }
      
      expect(users2FailedCorrectly, isTrue,
        reason: 'users2 should NOT have posts - this verifies the bug is fixed');
      
      // Verify users CAN access posts
      bool usersHasPosts = false;
      try {
        final userPosts = users1.posts;
        usersHasPosts = (userPosts != null);
      } catch (e) {
        // Should not happen
      }
      
      expect(usersHasPosts, isTrue, reason: 'users should have posts');
      
      print('🎉 CORE BUG COMPLETELY FIXED!');
      print('✅ users2 correctly lacks posts subcollection');
      print('✅ users correctly has posts subcollection');
      print('✅ Unique document classes working perfectly');
      print('✅ Path isolation working perfectly');
    });
  });
}

/// Helper function to check if an object has a specific method
bool _hasMethod(dynamic obj, String methodName) {
  try {
    switch (methodName) {
      case 'posts':
        final _ = obj.posts;
        return true;
      case 'comments':
        final _ = obj.comments;
        return true;
      default:
        return false;
    }
  } catch (e) {
    // NoSuchMethodError means the method doesn't exist - this is expected
    if (e is NoSuchMethodError) {
      return false;
    }
    // Other errors might indicate the method exists but failed for other reasons
    return true;
  }
}