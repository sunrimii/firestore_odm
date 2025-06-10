import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/story.dart';
import '../lib/models/post.dart';
import '../lib/test_schema.dart';

void main() {
  group('Core Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<$TestSchemaImpl> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🏗️ Architecture & Initialization', () {
      test('should create FirestoreODM with dependency injection', () {
        expect(odm, isNotNull);
        expect(odm.firestore, equals(fakeFirestore));
      });

      test('should access users collection with injected firestore', () {
        final usersCollection = odm.users;
        expect(usersCollection, isNotNull);
      });

      test('should access posts collection with injected firestore', () {
        final postsCollection = odm.posts;
        expect(postsCollection, isNotNull);
      });

      test('should create document references', () {
        final userDoc = odm.users('test_user');
        final postDoc = odm.posts('test_post');
        expect(userDoc, isNotNull);
        expect(postDoc, isNotNull);
      });
    });

    group('🔥 Basic CRUD Operations', () {
      test('should create and retrieve a user with nested objects', () async {
        // Arrange
        final coordinates = Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          altitude: 10.0,
        );

        final place = Place(
          name: 'San Francisco',
          address: '123 Market St',
          coordinates: coordinates,
          metadata: {'type': 'city'},
        );

        final story = Story(
          name: 'SF Adventure',
          content: 'Amazing day in SF',
          place: place,
          tags: ['travel'],
          publishedAt: DateTime.now(),
        );

        final profile = Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test-user'},
          interests: ['testing', 'flutter'],
          followers: 100,
          story: story,
        );

        final user = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          tags: ['developer', 'tester'],
          scores: [95, 88, 92],
          settings: {'theme': 'dark', 'language': 'en'},
          metadata: {'source': 'test', 'version': 1},
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users('test_user').set(user);
        final retrievedUser = await odm.users('test_user').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.name, equals('Test User'));
        expect(retrievedUser.email, equals('test@example.com'));
        expect(retrievedUser.profile.bio, equals('Test bio'));
        expect(retrievedUser.profile.story!.name, equals('SF Adventure'));
        expect(
          retrievedUser.profile.story!.place.coordinates.latitude,
          equals(37.7749),
        );
        expect(retrievedUser.tags, equals(['developer', 'tester']));
        expect(retrievedUser.scores, equals([95, 88, 92]));
        expect(retrievedUser.settings['theme'], equals('dark'));
        expect(retrievedUser.metadata['source'], equals('test'));
      });

      test('should create and retrieve a post', () async {
        // Arrange
        final post = Post(
          id: 'test_post',
          title: 'Test Post',
          content: 'This is a test post content',
          authorId: 'test_user',
          tags: ['test', 'flutter'],
          metadata: {'category': 'tech', 'priority': 1},
          likes: 10,
          views: 100,
          published: true,
          publishedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Act
        await odm.posts('test_post').set(post);
        final retrievedPost = await odm.posts('test_post').get();

        // Assert
        expect(retrievedPost, isNotNull);
        expect(retrievedPost!.title, equals('Test Post'));
        expect(retrievedPost.authorId, equals('test_user'));
        expect(retrievedPost.tags, equals(['test', 'flutter']));
        expect(retrievedPost.metadata['category'], equals('tech'));
        expect(retrievedPost.likes, equals(10));
        expect(retrievedPost.published, isTrue);
      });

      test('should delete a document', () async {
        // Arrange
        final profile = Profile(
          bio: 'To be deleted',
          avatar: 'delete.jpg',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'delete_test',
          name: 'Delete Test',
          email: 'delete@example.com',
          age: 30,
          profile: profile,
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('delete_test').set(user);

        // Act
        await odm.users('delete_test').delete();

        // Assert
        final deletedUser = await odm.users('delete_test').get();
        expect(deletedUser, isNull);
      });

      test('should handle non-existent document gracefully', () async {
        // Act
        final nonExistentUser = await odm.users('non_existent').get();
        final nonExistentPost = await odm.posts('non_existent').get();

        // Assert
        expect(nonExistentUser, isNull);
        expect(nonExistentPost, isNull);
      });

      test('should handle empty collections', () async {
        // Act
        final users = await odm.users.get();
        final posts = await odm.posts.get();

        // Assert
        expect(users, isEmpty);
        expect(posts, isEmpty);
      });
    });

    group('📝 Document Existence & Validation', () {
      test('should check document existence', () async {
        // Arrange
        final profile = Profile(
          bio: 'Existence test',
          avatar: 'exist.jpg',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'exist_test',
          name: 'Exist Test',
          email: 'exist@example.com',
          age: 25,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Act & Assert - Before creation
        final beforeCreation = await odm.users('exist_test').get();
        expect(beforeCreation, isNull);

        // Act & Assert - After creation
        await odm.users('exist_test').set(user);
        final afterCreation = await odm.users('exist_test').get();
        expect(afterCreation, isNotNull);
        expect(afterCreation!.name, equals('Exist Test'));
      });

      test('should handle overwriting existing documents', () async {
        // Arrange
        final profile1 = Profile(
          bio: 'Original bio',
          avatar: 'original.jpg',
          socialLinks: {},
          interests: [],
          followers: 50,
        );

        final user1 = User(
          id: 'overwrite_test',
          name: 'Original User',
          email: 'original@example.com',
          age: 25,
          profile: profile1,
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final profile2 = Profile(
          bio: 'Updated bio',
          avatar: 'updated.jpg',
          socialLinks: {'github': 'updated'},
          interests: ['coding'],
          followers: 100,
        );

        final user2 = User(
          id: 'overwrite_test',
          name: 'Updated User',
          email: 'updated@example.com',
          age: 30,
          profile: profile2,
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users('overwrite_test').set(user1);
        final firstVersion = await odm.users('overwrite_test').get();

        await odm.users('overwrite_test').set(user2);
        final secondVersion = await odm.users('overwrite_test').get();

        // Assert
        expect(firstVersion!.name, equals('Original User'));
        expect(firstVersion.profile.followers, equals(50));

        expect(secondVersion!.name, equals('Updated User'));
        expect(secondVersion.profile.followers, equals(100));
        expect(secondVersion.isActive, isTrue);
        expect(secondVersion.isPremium, isTrue);
      });
    });

    group('🔍 Data Integrity & Edge Cases', () {
      test('should handle empty nested objects', () async {
        // Arrange
        final profile = Profile(
          bio: '',
          avatar: '',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'empty_test',
          name: 'Empty Test',
          email: 'empty@example.com',
          age: 25,
          profile: profile,
          rating: 0.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users('empty_test').set(user);
        final retrievedUser = await odm.users('empty_test').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.profile.bio, equals(''));
        expect(retrievedUser.profile.socialLinks, isEmpty);
        expect(retrievedUser.profile.interests, isEmpty);
        expect(retrievedUser.rating, equals(0.0));
      });

      test('should handle null optional fields', () async {
        // Arrange
        final profile = Profile(
          bio: 'Null test',
          avatar: 'null.jpg',
          socialLinks: {},
          interests: [],
          followers: 10,
          lastActive: null,
          story: null,
        );

        final user = User(
          id: 'null_test',
          name: 'Null Test',
          email: 'null@example.com',
          age: 28,
          profile: profile,
          rating: 3.5,
          isActive: true,
          isPremium: false,
          lastLogin: null,
          updatedAt: null,
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users('null_test').set(user);
        final retrievedUser = await odm.users('null_test').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.lastLogin, isNull);
        expect(retrievedUser.updatedAt, isNull);
        expect(retrievedUser.profile.lastActive, isNull);
        expect(retrievedUser.profile.story, isNull);
      });

      test('should handle large nested data structures', () async {
        // Arrange - Create large nested structure
        final coordinates = Coordinates(
          latitude: 40.7128,
          longitude: -74.0060,
          altitude: 100.0,
        );

        final place = Place(
          name: 'New York City',
          address: '123 Broadway, NYC',
          coordinates: coordinates,
          metadata: {
            'country': 'USA',
            'state': 'NY',
            'timezone': 'EST',
            'population': '8000000',
          },
        );

        final story = Story(
          name: 'NYC Adventures',
          content: 'A' * 1000, // Large content
          place: place,
          tags: List.generate(20, (i) => 'tag_$i'), // Many tags
          publishedAt: DateTime.now(),
        );

        final profile = Profile(
          bio: 'Travel enthusiast with extensive experience',
          avatar: 'traveler.jpg',
          socialLinks: Map.fromIterable([
            'github',
            'twitter',
            'linkedin',
            'instagram',
            'facebook',
          ], value: (platform) => '${platform}_handle'),
          interests: List.generate(15, (i) => 'interest_$i'), // Many interests
          followers: 5000,
          story: story,
        );

        final user = User(
          id: 'large_test',
          name: 'Large Data Test',
          email: 'large@example.com',
          age: 35,
          profile: profile,
          rating: 4.8,
          isActive: true,
          isPremium: true,
          tags: List.generate(10, (i) => 'user_tag_$i'),
          scores: List.generate(50, (i) => i + 50), // Many scores
          settings: Map.fromIterable([
            'theme',
            'language',
            'notifications',
            'privacy',
          ], value: (key) => 'value_$key'),
          metadata: {
            'version': 2,
            'features': ['feature1', 'feature2', 'feature3'],
            'config': {'nested': 'value'},
          },
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users('large_test').set(user);
        final retrievedUser = await odm.users('large_test').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.profile.story!.content.length, equals(1000));
        expect(retrievedUser.profile.story!.tags.length, equals(20));
        expect(retrievedUser.profile.interests.length, equals(15));
        expect(retrievedUser.profile.socialLinks.length, equals(5));
        expect(retrievedUser.tags.length, equals(10));
        expect(retrievedUser.scores.length, equals(50));
        expect(retrievedUser.settings.length, equals(4));
        expect(retrievedUser.profile.story!.place.metadata.length, equals(4));
      });
    });
  });
}
