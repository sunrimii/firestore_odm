import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/story.dart';

void main() {
  group('Firestore ODM TDD Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('🏗️ Architecture Tests', () {
      test('should create FirestoreODM with dependency injection', () {
        expect(odm, isNotNull);
        expect(odm.firestore, equals(fakeFirestore));
      });

      test('should access users collection with injected firestore', () {
        final usersCollection = odm.users;
        expect(usersCollection, isNotNull);
      });

      test('should create user document reference', () {
        final userDoc = odm.users.doc('test_user');
        expect(userDoc, isNotNull);
      });
    });

    group('🔥 Basic CRUD Operations', () {
      test('should create and retrieve a user', () async {
        // Arrange
        final profile = Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test-user'},
          interests: ['testing'],
          followers: 0,
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
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users.doc('test_user').set(user);
        final retrievedUser = await odm.users.doc('test_user').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.name, equals('Test User'));
        expect(retrievedUser.email, equals('test@example.com'));
        expect(retrievedUser.profile.bio, equals('Test bio'));
      });

      test('should update top-level fields', () async {
        // Arrange
        final profile = Profile(
          bio: 'Original bio',
          avatar: 'original.jpg',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'update_test',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
          profile: profile,
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('update_test').set(user);

        // Act
        await odm.users
            .doc('update_test')
            .update(name: 'Updated Name', age: 26, isActive: true);

        // Assert
        final updatedUser = await odm.users.doc('update_test').get();
        expect(updatedUser!.name, equals('Updated Name'));
        expect(updatedUser.age, equals(26));
        expect(updatedUser.isActive, isTrue);
        expect(updatedUser.email, equals('original@example.com')); // Unchanged
      });

      test('should delete a user', () async {
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

        await odm.users.doc('delete_test').set(user);

        // Act
        await odm.users.doc('delete_test').delete();

        // Assert
        final deletedUser = await odm.users.doc('delete_test').get();
        expect(deletedUser, isNull);
      });
    });

    group('🔗 Chained Updates (Revolutionary Feature)', () {
      test('should update nested profile fields using chained API', () async {
        // Arrange
        final profile = Profile(
          bio: 'Original bio',
          avatar: 'original.jpg',
          socialLinks: {'github': 'original'},
          interests: ['original'],
          followers: 10,
        );

        final user = User(
          id: 'nested_test',
          name: 'Nested Test',
          email: 'nested@example.com',
          age: 30,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('nested_test').set(user);

        // Act - Test revolutionary chained update API
        await odm.users
            .doc('nested_test')
            .update
            .profile(
              bio: 'Updated bio via chained API',
              followers: 100,
              socialLinks: {
                'github': 'updated-user',
                'twitter': '@updated_user',
                'linkedin': 'updated-developer',
              },
            );

        // Assert
        final updatedUser = await odm.users.doc('nested_test').get();
        expect(updatedUser!.profile.bio, equals('Updated bio via chained API'));
        expect(updatedUser.profile.followers, equals(100));
        expect(
          updatedUser.profile.socialLinks['github'],
          equals('updated-user'),
        );
        expect(
          updatedUser.profile.socialLinks['twitter'],
          equals('@updated_user'),
        );
        expect(
          updatedUser.profile.socialLinks['linkedin'],
          equals('updated-developer'),
        );
        expect(updatedUser.name, equals('Nested Test')); // Top-level unchanged
      });

      test('should update deep nested story fields (3 levels deep)', () async {
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
          bio: 'Travel blogger',
          avatar: 'traveler.jpg',
          socialLinks: {},
          interests: ['travel'],
          followers: 200,
          story: story,
        );

        final user = User(
          id: 'story_test',
          name: 'Travel Blogger',
          email: 'travel@example.com',
          age: 28,
          profile: profile,
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('story_test').set(user);

        // Act - Test 3-level deep chained updates
        await odm.users
            .doc('story_test')
            .update
            .profile
            .story(
              name: 'Updated SF Adventure',
              content: 'Even more amazing day in SF with chained updates!',
              tags: ['travel', 'technology', 'firestore-odm'],
            );

        // Assert
        final updatedUser = await odm.users.doc('story_test').get();
        expect(
          updatedUser!.profile.story!.name,
          equals('Updated SF Adventure'),
        );
        expect(updatedUser.profile.story!.content, contains('chained updates'));
        expect(updatedUser.profile.story!.tags, contains('firestore-odm'));
        expect(
          updatedUser.profile.bio,
          equals('Travel blogger'),
        ); // Profile unchanged
        expect(updatedUser.name, equals('Travel Blogger')); // User unchanged
      });

      test(
        'should update deepest nested coordinates (5 levels deep!)',
        () async {
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
            name: 'Location Test',
            content: 'Testing deep nesting',
            place: place,
            tags: ['test'],
            publishedAt: DateTime.now(),
          );

          final profile = Profile(
            bio: 'Location tester',
            avatar: 'tester.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 50,
            story: story,
          );

          final user = User(
            id: 'coordinates_test',
            name: 'Location Tester',
            email: 'location@example.com',
            age: 32,
            profile: profile,
            rating: 4.8,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          );

          await odm.users.doc('coordinates_test').set(user);

          // Act - Test 5-level deep chained update (REVOLUTIONARY!)
          await odm.users
              .doc('coordinates_test')
              .update
              .profile
              .story
              .place
              .coordinates(
                latitude: 40.7128, // New York
                longitude: -74.0060,
                altitude: 20.0,
              );

          // Assert
          final updatedUser = await odm.users.doc('coordinates_test').get();
          final coords = updatedUser!.profile.story!.place.coordinates;
          expect(coords.latitude, equals(40.7128));
          expect(coords.longitude, equals(-74.0060));
          expect(coords.altitude, equals(20.0));

          // Verify other levels unchanged
          expect(
            updatedUser.profile.story!.place.name,
            equals('San Francisco'),
          ); // Place unchanged
          expect(
            updatedUser.profile.story!.name,
            equals('Location Test'),
          ); // Story unchanged
          expect(
            updatedUser.profile.bio,
            equals('Location tester'),
          ); // Profile unchanged
          expect(updatedUser.name, equals('Location Tester')); // User unchanged
        },
      );
    });

    group('🔍 Advanced Querying', () {
      test('should query users by age', () async {
        // Arrange - Create multiple users
        final users = [
          User(
            id: 'user1',
            name: 'Young User',
            email: 'young@example.com',
            age: 20,
            profile: Profile(
              bio: 'Young developer',
              avatar: 'young.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 10,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'user2',
            name: 'Experienced User',
            email: 'experienced@example.com',
            age: 50,
            profile: Profile(
              bio: 'Senior developer',
              avatar: 'senior.jpg',
              socialLinks: {},
              interests: ['architecture'],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act
        final youngUsers = await odm.users
            .where((filter) => filter.age(isLessThan: 30))
            .get();

        final experiencedUsers = await odm.users
            .where((filter) => filter.age(isGreaterThanOrEqualTo: 30))
            .get();

        // Assert
        expect(youngUsers.length, equals(1));
        expect(youngUsers.first.name, equals('Young User'));
        expect(experiencedUsers.length, equals(1));
        expect(experiencedUsers.first.name, equals('Experienced User'));
      });

      test('should query users by premium status and rating', () async {
        // Arrange
        final users = [
          User(
            id: 'free_user',
            name: 'Free User',
            email: 'free@example.com',
            age: 25,
            profile: Profile(
              bio: 'Free tier user',
              avatar: 'free.jpg',
              socialLinks: {},
              interests: [],
              followers: 5,
            ),
            rating: 3.5,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'premium_user',
            name: 'Premium User',
            email: 'premium@example.com',
            age: 30,
            profile: Profile(
              bio: 'Premium subscriber',
              avatar: 'premium.jpg',
              socialLinks: {},
              interests: [],
              followers: 50,
            ),
            rating: 4.8,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act
        final premiumUsers = await odm.users
            .where((filter) => filter.and(
              filter.isPremium(isEqualTo: true),
              filter.rating(isGreaterThan: 4.0),
            ))
            .get();

        final freeUsers = await odm.users
            .where((filter) => filter.isPremium(isEqualTo: false))
            .get();

        // Assert
        expect(premiumUsers.length, equals(1));
        expect(premiumUsers.first.name, equals('Premium User'));
        expect(freeUsers.length, equals(1));
        expect(freeUsers.first.name, equals('Free User'));
      });

      test('should perform complex queries with multiple conditions', () async {
        // Arrange
        final users = [
          User(
            id: 'target_user',
            name: 'Target User',
            email: 'target@example.com',
            age: 28,
            profile: Profile(
              bio: 'Perfect match',
              avatar: 'target.jpg',
              socialLinks: {},
              interests: [],
              followers: 100,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'other_user',
            name: 'Other User',
            email: 'other@example.com',
            age: 35,
            profile: Profile(
              bio: 'Does not match',
              avatar: 'other.jpg',
              socialLinks: {},
              interests: [],
              followers: 20,
            ),
            rating: 3.0,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act - Complex query with multiple conditions
        final filteredUsers = await odm.users
            .where((filter) => filter.and(
              filter.age(isGreaterThan: 25),
              filter.rating(isGreaterThanOrEqualTo: 4.0),
              filter.isActive(isEqualTo: true),
              filter.isPremium(isEqualTo: true),
            ))
            .get();

        // Assert
        expect(filteredUsers.length, equals(1));
        expect(filteredUsers.first.name, equals('Target User'));
      });
    });

    group('🛡️ Error Handling & Edge Cases', () {
      test('should handle non-existent document gracefully', () async {
        // Act
        final nonExistentUser = await odm.users.doc('non_existent').get();

        // Assert
        expect(nonExistentUser, isNull);
      });

      test('should handle empty query results', () async {
        // Act
        final noUsers = await odm.users
            .where((filter) => filter.age(isGreaterThan: 1000)) // Impossible condition
            .get();

        // Assert
        expect(noUsers, isEmpty);
      });

      test('should handle concurrent updates', () async {
        // Arrange
        final profile = Profile(
          bio: 'Concurrent test',
          avatar: 'concurrent.jpg',
          socialLinks: {},
          interests: [],
          followers: 0,
        );

        final user = User(
          id: 'concurrent_test',
          name: 'Concurrent User',
          email: 'concurrent@example.com',
          age: 25,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('concurrent_test').set(user);

        // Act - Simulate concurrent updates
        final futures = [
          odm.users.doc('concurrent_test').update(name: 'Updated 1'),
          odm.users.doc('concurrent_test').update(name: 'Updated 2'),
          odm.users.doc('concurrent_test').update.profile(bio: 'Updated bio'),
        ];

        await Future.wait(futures);

        // Assert - Should not crash and final state should be consistent
        final finalUser = await odm.users.doc('concurrent_test').get();
        expect(finalUser, isNotNull);
        expect(finalUser!.profile.bio, equals('Updated bio'));
      });
    });

    group('🎯 Real-World Scenarios', () {
      test('should handle social media profile update scenario', () async {
        // Arrange
        final profile = Profile(
          bio: 'Regular user',
          avatar: 'regular.jpg',
          socialLinks: {'github': 'regular-user'},
          interests: ['coding'],
          followers: 50,
        );

        final user = User(
          id: 'social_user',
          name: 'Social User',
          email: 'social@example.com',
          age: 26,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('social_user').set(user);

        // Act - Social media influencer upgrade
        await odm.users
            .doc('social_user')
            .update
            .profile(
              bio:
                  '🚀 Flutter Developer | 📱 Mobile Expert | 🎯 Tech Influencer',
              followers: 10000,
              socialLinks: {
                'github': 'flutter-expert',
                'twitter': '@flutter_expert',
                'linkedin': 'flutter-expert-dev',
                'instagram': '@flutter_content',
                'youtube': 'FlutterTutorials',
                'website': 'https://flutter-expert.dev',
              },
              interests: [
                'flutter',
                'mobile-development',
                'content-creation',
                'tech-talks',
                'open-source',
              ],
            );

        // Assert
        final updatedUser = await odm.users.doc('social_user').get();
        expect(updatedUser!.profile.followers, equals(10000));
        expect(updatedUser.profile.socialLinks.length, equals(6));
        expect(updatedUser.profile.interests, contains('flutter'));
        expect(updatedUser.profile.bio, contains('🚀'));
      });

      test('should handle travel blogger location update scenario', () async {
        // Arrange - Travel blogger in Tokyo
        final tokyoCoords = Coordinates(
          latitude: 35.6762,
          longitude: 139.6503,
          altitude: 40.0,
        );

        final tokyoPlace = Place(
          name: 'Tokyo',
          address: 'Shibuya, Tokyo, Japan',
          coordinates: tokyoCoords,
          metadata: {'country': 'Japan', 'city': 'Tokyo'},
        );

        final tokyoStory = Story(
          name: 'Tokyo Adventure',
          content: 'Exploring the amazing city of Tokyo!',
          place: tokyoPlace,
          tags: ['travel', 'japan', 'tokyo'],
          publishedAt: DateTime.now(),
        );

        final profile = Profile(
          bio: 'Travel blogger',
          avatar: 'traveler.jpg',
          socialLinks: {'instagram': '@traveler'},
          interests: ['travel', 'photography'],
          followers: 5000,
          story: tokyoStory,
        );

        final user = User(
          id: 'travel_blogger',
          name: 'Travel Blogger',
          email: 'travel@example.com',
          age: 29,
          profile: profile,
          rating: 4.7,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('travel_blogger').set(user);

        // Act - Move to Paris and update everything
        await odm.users
            .doc('travel_blogger')
            .update
            .profile
            .story
            .place
            .coordinates(
              latitude: 48.8566, // Paris coordinates
              longitude: 2.3522,
              altitude: 35.0,
            );

        await odm.users
            .doc('travel_blogger')
            .update
            .profile
            .story
            .place(
              name: 'Paris',
              address: 'Champs-Élysées, Paris, France',
              metadata: {'country': 'France', 'city': 'Paris'},
            );

        await odm.users
            .doc('travel_blogger')
            .update
            .profile
            .story(
              name: 'Paris Romance',
              content: 'Falling in love with the City of Light!',
              tags: ['travel', 'france', 'paris', 'romance'],
            );

        // Assert
        final updatedUser = await odm.users.doc('travel_blogger').get();
        final story = updatedUser!.profile.story!;

        expect(story.name, equals('Paris Romance'));
        expect(story.place.name, equals('Paris'));
        expect(story.place.coordinates.latitude, equals(48.8566));
        expect(story.tags, contains('paris'));
        expect(story.tags, contains('romance'));

        // Verify user and profile unchanged
        expect(updatedUser.name, equals('Travel Blogger'));
        expect(updatedUser.profile.bio, equals('Travel blogger'));
      });
    });
  });
}
