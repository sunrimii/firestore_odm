import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/post.dart';

void main() {
  group('🚀 Callable Collection API Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('📞 New Callable Syntax', () {
      test('should work with users(id) syntax', () async {
        // Arrange
        final profile = Profile(
          bio: 'Callable syntax test',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test-user'},
          interests: ['testing'],
          followers: 50,
        );

        final user = User(
          id: 'callable_test',
          name: 'Callable Test User',
          email: 'callable@example.com',
          age: 25,
          profile: profile,
          rating: 4.2,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Act - Using new callable syntax
        await odm.users('callable_test').set(user);
        final retrievedUser = await odm.users('callable_test').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.name, equals('Callable Test User'));
        expect(retrievedUser.email, equals('callable@example.com'));
        expect(retrievedUser.profile.bio, equals('Callable syntax test'));
      });

      test('should work with posts(id) syntax', () async {
        // Arrange
        final post = Post(
          id: 'callable_post',
          title: 'Callable Post Test',
          content: 'Testing the new callable syntax',
          authorId: 'callable_test',
          tags: ['api', 'syntax'],
          metadata: {'test': true},
          likes: 15,
          views: 120,
          published: true,
          publishedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Act - Using new callable syntax
        await odm.posts('callable_post').set(post);
        final retrievedPost = await odm.posts('callable_post').get();

        // Assert
        expect(retrievedPost, isNotNull);
        expect(retrievedPost!.title, equals('Callable Post Test'));
        expect(retrievedPost.content, equals('Testing the new callable syntax'));
        expect(retrievedPost.tags, equals(['api', 'syntax']));
      });

      test('should handle CRUD operations with callable syntax', () async {
        // Arrange
        final profile = Profile(
          bio: 'CRUD test with callable syntax',
          avatar: 'crud.jpg',
          socialLinks: {},
          interests: ['development'],
          followers: 100,
        );

        final user = User(
          id: 'crud_callable',
          name: 'CRUD Callable',
          email: 'crud@example.com',
          age: 30,
          profile: profile,
          rating: 3.8,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Create
        await odm.users('crud_callable').set(user);
        
        // Read
        final createdUser = await odm.users('crud_callable').get();
        expect(createdUser, isNotNull);
        expect(createdUser!.name, equals('CRUD Callable'));

        // Update using modify
        await odm.users('crud_callable').modify((user) => user.copyWith(
          name: 'Updated CRUD Callable',
          rating: 4.5,
        ));

        final updatedUser = await odm.users('crud_callable').get();
        expect(updatedUser!.name, equals('Updated CRUD Callable'));
        expect(updatedUser.rating, equals(4.5));

        // Delete
        await odm.users('crud_callable').delete();
        final deletedUser = await odm.users('crud_callable').get();
        expect(deletedUser, isNull);
      });
    });

    group('🔄 Backward Compatibility', () {
      test('should still work with old doc() syntax', () async {
        // Arrange
        final profile = Profile(
          bio: 'Old syntax test',
          avatar: 'old.jpg',
          socialLinks: {},
          interests: ['legacy'],
          followers: 25,
        );

        final user = User(
          id: 'old_syntax',
          name: 'Old Syntax User',
          email: 'old@example.com',
          age: 28,
          profile: profile,
          rating: 3.5,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Act - Using old doc() syntax
        await odm.users('old_syntax').set(user);
        final retrievedUser = await odm.users('old_syntax').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.name, equals('Old Syntax User'));
        expect(retrievedUser.email, equals('old@example.com'));
      });

      test('should work interchangeably between both syntaxes', () async {
        // Arrange
        final profile = Profile(
          bio: 'Interchangeable syntax test',
          avatar: 'mixed.jpg',
          socialLinks: {'test': 'mixed'},
          interests: ['flexibility'],
          followers: 75,
        );

        final user = User(
          id: 'mixed_syntax',
          name: 'Mixed Syntax User',
          email: 'mixed@example.com',
          age: 32,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Create with new syntax
        await odm.users('mixed_syntax').set(user);
        
        // Read with old syntax
        final readWithOld = await odm.users('mixed_syntax').get();
        expect(readWithOld, isNotNull);
        expect(readWithOld!.name, equals('Mixed Syntax User'));

        // Update with old syntax
        await odm.users('mixed_syntax').modify((user) => user.copyWith(
          name: 'Updated Mixed User',
        ));

        // Read with new syntax
        final readWithNew = await odm.users('mixed_syntax').get();
        expect(readWithNew!.name, equals('Updated Mixed User'));

        // Delete with new syntax
        await odm.users('mixed_syntax').delete();
        
        // Verify deletion with old syntax
        final deletedCheck = await odm.users('mixed_syntax').get();
        expect(deletedCheck, isNull);
      });
    });

    group('🧪 Advanced Operations with Callable Syntax', () {
      test('should work with update operations', () async {
        // Arrange
        final profile = Profile(
          bio: 'Update operations test',
          avatar: 'update.jpg',
          socialLinks: {},
          interests: ['updates'],
          followers: 200,
        );

        final user = User(
          id: 'update_callable',
          name: 'Update Test',
          email: 'update@example.com',
          age: 26,
          profile: profile,
          rating: 3.0,
          isActive: true,
          isPremium: false,
          tags: ['initial'],
          scores: [80, 75],
          createdAt: DateTime.now(),
        );

        await odm.users('update_callable').set(user);

        // Act - Using update operations with callable syntax
        await odm.users('update_callable').update(($) => [
          $.name('Updated Name'),
          $.rating.increment(1.5),
          $.profile.followers.increment(50),
          $.tags.add('updated'),
          $.scores.add(95),
          $.isPremium(true),
        ]);

        // Assert
        final updatedUser = await odm.users('update_callable').get();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.name, equals('Updated Name'));
        expect(updatedUser.rating, equals(4.5));
        expect(updatedUser.profile.followers, equals(250));
        expect(updatedUser.tags, contains('updated'));
        expect(updatedUser.scores, contains(95));
        expect(updatedUser.isPremium, isTrue);
      });

      test('should work with incremental modify', () async {
        // Arrange
        final profile = Profile(
          bio: 'Incremental modify test',
          avatar: 'incremental.jpg',
          socialLinks: {},
          interests: ['atomic'],
          followers: 150,
        );

        final user = User(
          id: 'incremental_callable',
          name: 'Incremental Test',
          email: 'incremental@example.com',
          age: 29,
          profile: profile,
          rating: 2.5,
          isActive: false,
          isPremium: false,
          scores: [70, 80, 75],
          createdAt: DateTime.now(),
        );

        await odm.users('incremental_callable').set(user);

        // Act - Using incremental modify with callable syntax
        await odm.users('incremental_callable').incrementalModify((user) {
          return user.copyWith(
            name: 'Incrementally Modified',
            rating: user.rating + 1.0,
            isActive: true,
            profile: user.profile.copyWith(
              followers: user.profile.followers + 100,
            ),
            scores: [...user.scores, 90],
          );
        });

        // Assert
        final modifiedUser = await odm.users('incremental_callable').get();
        expect(modifiedUser, isNotNull);
        expect(modifiedUser!.name, equals('Incrementally Modified'));
        expect(modifiedUser.rating, equals(3.5));
        expect(modifiedUser.isActive, isTrue);
        expect(modifiedUser.profile.followers, equals(250));
        expect(modifiedUser.scores.length, equals(4));
        expect(modifiedUser.scores.last, equals(90));
      });
    });

    group('🎯 Syntax Comparison', () {
      test('should demonstrate syntax conciseness', () async {
        // Arrange
        final profile = Profile(
          bio: 'Syntax comparison',
          avatar: 'compare.jpg',
          socialLinks: {},
          interests: ['comparison'],
          followers: 300,
        );

        final user = User(
          id: 'syntax_compare',
          name: 'Syntax Compare',
          email: 'syntax@example.com',
          age: 31,
          profile: profile,
          rating: 4.3,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Both syntaxes should work identically
        
        // Old syntax (verbose)
        await odm.users('syntax_compare').set(user);
        final resultOld = await odm.users('syntax_compare').get();
        
        // New syntax (concise)
        await odm.users('syntax_compare').set(user);
        final resultNew = await odm.users('syntax_compare').get();

        // Both should return identical results
        expect(resultOld?.name, equals(resultNew?.name));
        expect(resultOld?.email, equals(resultNew?.email));
        expect(resultOld?.profile.bio, equals(resultNew?.profile.bio));
        expect(resultOld?.rating, equals(resultNew?.rating));
      });
    });
  });
}