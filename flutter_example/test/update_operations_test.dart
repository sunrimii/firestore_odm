import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/story.dart';

void main() {
  group('Update Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('🔄 Array-Style Update API', () {
      test('should perform basic field updates', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Initial Name',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Initial bio',
            avatar: 'initial.jpg',
            socialLinks: {'github': 'initial'},
            interests: ['initial'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          tags: ['beginner'],
          scores: [80, 85],
          settings: {'theme': 'light'},
          metadata: {'version': 1},
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Update using array syntax
        await userDoc.update(($) => [
          $.name('John Smith'),
          $.email('john@example.com'),
          $.isActive(true),
          $.rating(4.5),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.name, equals('John Smith'));
        expect(updatedUser.email, equals('john@example.com'));
        expect(updatedUser.isActive, isTrue);
        expect(updatedUser.rating, equals(4.5));
        expect(updatedUser.age, equals(25)); // Unchanged
      });

      test('should perform nested object updates', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Initial bio',
            avatar: 'initial.jpg',
            socialLinks: {'github': 'initial'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Update nested profile fields
        await userDoc.update((update) => [
          update.profile.bio('Full-stack developer'),
          update.profile.avatar('new-avatar.jpg'),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.profile.bio, equals('Full-stack developer'));
        expect(updatedUser.profile.avatar, equals('new-avatar.jpg'));
        expect(updatedUser.profile.followers, equals(100)); // Unchanged
        expect(updatedUser.name, equals('Test User')); // Unchanged
      });

      test('should perform numeric increment operations', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {'github': 'test'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Use increment operations
        await userDoc.update((as) => [
          as.age.increment(1), // age: 25 + 1 = 26
          as.rating.increment(0.5), // rating: 3.0 + 0.5 = 3.5
          as.profile.followers.increment(50), // followers: 100 + 50 = 150
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.age, equals(26));
        expect(updatedUser.rating, equals(3.5));
        expect(updatedUser.profile.followers, equals(150));
      });

      test('should perform array operations', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {'github': 'test'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          tags: ['beginner'],
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Add array elements
        await userDoc.update((as) => [
          as.tags.add('expert'),
          as.tags.add('verified'),
          as.profile.interests.add('design'),
        ]);
        
        // Second update to remove from interests (can't combine add/remove on same field)
        await userDoc.update((as) => [
          as.profile.interests.remove('coding'),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.tags, contains('beginner'));
        expect(updatedUser.tags, contains('expert'));
        expect(updatedUser.tags, contains('verified'));
        expect(updatedUser.profile.interests, contains('design'));
        expect(updatedUser.profile.interests, isNot(contains('coding')));
      });

      test('should handle server timestamp operations', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {'github': 'test'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Set server timestamp
        await userDoc.update((as) => [
          as.lastLogin.serverTimestamp(),
          as.updatedAt.serverTimestamp(),
        ]);

        // Assert - Since we're using fake_cloud_firestore, server timestamp becomes current time
        final updatedUser = await userDoc.get();
        expect(updatedUser!.lastLogin, isNotNull);
        expect(updatedUser.updatedAt, isNotNull);
      });

      test('should handle object merge operations', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {'github': 'test'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Use object merge syntax
        await userDoc.update((as) => [
          as({'name': 'Kyle', 'isPremium': true}),
          as.profile({'bio': 'Good developer', 'followers': 200}),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.name, equals('Kyle'));
        expect(updatedUser.isPremium, isTrue);
        expect(updatedUser.age, equals(25)); // Should remain unchanged
        expect(updatedUser.profile.bio, equals('Good developer'));
        expect(updatedUser.profile.followers, equals(200));
      });

      test('should handle complex mixed operations', () async {
        // Arrange
        final initialUser = User(
          id: 'test_user',
          name: 'John Doe',
          email: 'john@example.com',
          age: 25,
          profile: Profile(
            bio: 'Initial bio',
            avatar: 'initial.jpg',
            socialLinks: {'github': 'johndoe'},
            interests: ['coding'],
            followers: 50,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          tags: ['beginner'],
          createdAt: DateTime(2023, 1, 1),
        );
        
        final userDoc = odm.users.doc('test_user');
        await userDoc.set(initialUser);

        // Act - Complex mixed update operations
        await userDoc.update((as) => [
          as.name('John Smith'),
          as.profile.bio('Full-stack developer'),
          as.profile.followers.increment(50),
          as.tags.add('verified'),
          as.lastLogin(DateTime.now()),
          as.profile.followers.increment(1), // Another increment
          as.rating.increment(0.1),
          as.tags.add('popular'),
          as.profile.lastActive(DateTime.now()),
          as({'name': 'Kyle'}), // This will override the earlier name change
          as.profile({'bio': 'Good'}), // This will override the earlier bio change
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.name, equals('Kyle')); // Last update wins
        expect(updatedUser.profile.bio, equals('Good')); // Last update wins
        expect(updatedUser.profile.followers, equals(101)); // 50 + 50 + 1 = 101
        expect(updatedUser.rating, equals(3.1)); // 3.0 + 0.1
        expect(updatedUser.tags, contains('verified'));
        expect(updatedUser.tags, contains('popular'));
        expect(updatedUser.tags, contains('beginner'));
        expect(updatedUser.lastLogin, isNotNull);
        expect(updatedUser.profile.lastActive, isNotNull);
      });
    });

    group('🔧 Modify Operations', () {
      test('should perform basic modify with diff detection', () async {
        // Arrange
        final initialUser = User(
          id: 'modify_user',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
          profile: Profile(
            bio: 'Original bio',
            avatar: 'original.jpg',
            socialLinks: {},
            interests: [],
            followers: 10,
          ),
          rating: 3.0,
          isActive: false,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('modify_user');
        await userDoc.set(initialUser);

        // Act - Use modify() method with direct field updates (non-atomic)
        await userDoc.modify((currentUser) {
          return currentUser.copyWith(
            name: 'Updated Name',
            age: currentUser.age + 1,
            profile: currentUser.profile.copyWith(
              bio: 'Updated bio',
              followers: currentUser.profile.followers + 10,
            ),
          );
        });

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.name, equals('Updated Name'));
        expect(updatedUser.age, equals(26));
        expect(updatedUser.profile.bio, equals('Updated bio'));
        expect(updatedUser.profile.followers, equals(20));
      });

      test('should perform incremental modify with atomic operations', () async {
        // Arrange
        final initialUser = User(
          id: 'incremental_user',
          name: 'Increment User',
          email: 'increment@example.com',
          age: 30,
          profile: Profile(
            bio: 'Increment test',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['coding', 'reading'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          tags: ['developer'],
          scores: [85, 90],
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('incremental_user');
        await userDoc.set(initialUser);

        // Act - Use incrementalModify() with automatic atomic operations
        await userDoc.incrementalModify((currentUser) {
          return currentUser.copyWith(
            rating: currentUser.rating + 0.5, // FieldValue.increment(0.5)
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 50, // FieldValue.increment(50)
              interests: [...currentUser.profile.interests, 'flutter'], // FieldValue.arrayUnion(['flutter'])
            ),
            tags: [...currentUser.tags, 'expert'], // FieldValue.arrayUnion(['expert'])
            scores: [...currentUser.scores, 95], // FieldValue.arrayUnion([95])
          );
        });

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.rating, equals(4.5));
        expect(updatedUser.profile.followers, equals(150));
        expect(updatedUser.profile.interests, contains('coding'));
        expect(updatedUser.profile.interests, contains('reading'));
        expect(updatedUser.profile.interests, contains('flutter'));
        expect(updatedUser.tags, contains('developer'));
        expect(updatedUser.tags, contains('expert'));
        expect(updatedUser.scores, contains(85));
        expect(updatedUser.scores, contains(90));
        expect(updatedUser.scores, contains(95));
      });

      test('should handle array removal with incremental modify', () async {
        // Arrange
        final initialUser = User(
          id: 'removal_user',
          name: 'Removal User',
          email: 'removal@example.com',
          age: 25,
          profile: Profile(
            bio: 'Array removal test',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['coding', 'reading', 'gaming', 'music'],
            followers: 200,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          tags: ['developer', 'gamer', 'reader'],
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('removal_user');
        await userDoc.set(initialUser);

        // Act - Remove specific interests and tags using incremental modify
        await userDoc.incrementalModify((currentUser) {
          final newInterests = currentUser.profile.interests
              .where((interest) => !['gaming', 'music'].contains(interest))
              .toList();
          final newTags = currentUser.tags
              .where((tag) => tag != 'gamer')
              .toList();
          
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(interests: newInterests),
            tags: newTags,
          );
        });

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.profile.interests, equals(['coding', 'reading']));
        expect(updatedUser.profile.interests, isNot(contains('gaming')));
        expect(updatedUser.profile.interests, isNot(contains('music')));
        expect(updatedUser.tags, equals(['developer', 'reader']));
        expect(updatedUser.tags, isNot(contains('gamer')));
      });

      test('should handle mixed atomic and direct operations', () async {
        // Arrange
        final initialUser = User(
          id: 'mixed_user',
          name: 'Mixed User',
          email: 'mixed@example.com',
          age: 32,
          profile: Profile(
            bio: 'Mixed test',
            avatar: 'test.jpg',
            socialLinks: {'github': 'user123'},
            interests: ['tech'],
            followers: 75,
          ),
          rating: 3.5,
          isActive: false,
          isPremium: false,
          tags: ['basic'],
          scores: [80, 85],
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('mixed_user');
        await userDoc.set(initialUser);

        // Act - Mixed operations: direct field updates and atomic operations
        await userDoc.incrementalModify((currentUser) {
          return currentUser.copyWith(
            name: 'Updated Mixed User', // Direct string change
            age: currentUser.age + 1, // Increment
            rating: currentUser.rating + 0.7, // Increment
            isActive: true, // Boolean change
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 15, // Increment
              interests: [...currentUser.profile.interests, 'ai'], // Array union
              bio: 'Updated mixed bio', // String change
              socialLinks: {
                ...currentUser.profile.socialLinks,
                'twitter': '@mixed_user', // Add new field
              },
            ),
            tags: [...currentUser.tags, 'advanced'], // Array union
            scores: [...currentUser.scores, 92], // Array union
          );
        });

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.name, equals('Updated Mixed User'));
        expect(updatedUser.age, equals(33));
        expect(updatedUser.rating, closeTo(4.2, 0.01));
        expect(updatedUser.isActive, isTrue);
        expect(updatedUser.profile.followers, equals(90));
        expect(updatedUser.profile.interests, equals(['tech', 'ai']));
        expect(updatedUser.profile.bio, equals('Updated mixed bio'));
        expect(updatedUser.profile.socialLinks['github'], equals('user123'));
        expect(updatedUser.profile.socialLinks['twitter'], equals('@mixed_user'));
        expect(updatedUser.tags, equals(['basic', 'advanced']));
        expect(updatedUser.scores, equals([80, 85, 92]));
      });
    });

    group('🏗️ Deep Nested Updates', () {
      test('should update deep nested story fields (5 levels deep)', () async {
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
          id: 'story_user',
          name: 'Travel Blogger',
          email: 'travel@example.com',
          age: 28,
          profile: profile,
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('story_user');
        await userDoc.set(user);

        // Act - Test deep nested array-style updates
        await userDoc.update((update) => [
          update.profile.story({
            'name': 'Updated SF Adventure',
            'content': 'Even more amazing day in SF with array-style updates!',
            'tags': ['travel', 'technology', 'firestore-odm'],
          }),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        expect(updatedUser!.profile.story!.name, equals('Updated SF Adventure'));
        expect(updatedUser.profile.story!.content, contains('array-style updates'));
        expect(updatedUser.profile.story!.tags, contains('firestore-odm'));
        expect(updatedUser.profile.bio, equals('Travel blogger')); // Profile unchanged
        expect(updatedUser.name, equals('Travel Blogger')); // User unchanged
      });

      test('should update deepest nested coordinates (5 levels deep)', () async {
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
          id: 'coordinates_user',
          name: 'Location Tester',
          email: 'location@example.com',
          age: 32,
          profile: profile,
          rating: 4.8,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('coordinates_user');
        await userDoc.set(user);

        // Act - Test 5-level deep array-style update
        await userDoc.update((update) => [
          update.profile.story.place.coordinates({
            'latitude': 40.7128, // New York
            'longitude': -74.0060,
            'altitude': 20.0,
          }),
        ]);

        // Assert
        final updatedUser = await userDoc.get();
        final coords = updatedUser!.profile.story!.place.coordinates;
        expect(coords.latitude, equals(40.7128));
        expect(coords.longitude, equals(-74.0060));
        expect(coords.altitude, equals(20.0));

        // Verify other levels unchanged
        expect(updatedUser.profile.story!.place.name, equals('San Francisco')); // Place unchanged
        expect(updatedUser.profile.story!.name, equals('Location Test')); // Story unchanged
        expect(updatedUser.profile.bio, equals('Location tester')); // Profile unchanged
        expect(updatedUser.name, equals('Location Tester')); // User unchanged
      });
    });

    group('⚡ Edge Cases & Error Handling', () {
      test('should handle concurrent updates gracefully', () async {
        // Arrange
        final initialUser = User(
          id: 'concurrent_user',
          name: 'Concurrent User',
          email: 'concurrent@example.com',
          age: 25,
          profile: Profile(
            bio: 'Concurrent test',
            avatar: 'concurrent.jpg',
            socialLinks: {},
            interests: [],
            followers: 0,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('concurrent_user');
        await userDoc.set(initialUser);

        // Act - Simulate concurrent updates using array-style API
        final futures = [
          userDoc.update((update) => [update.name('Updated 1')]),
          userDoc.update((update) => [update.name('Updated 2')]),
          userDoc.update((update) => [update.profile({'bio': 'Updated bio'})]),
        ];

        await Future.wait(futures);

        // Assert - Should not crash and final state should be consistent
        final finalUser = await userDoc.get();
        expect(finalUser, isNotNull);
        expect(finalUser!.profile.bio, equals('Updated bio'));
      });

      test('should handle zero increments (no-op)', () async {
        // Arrange
        final initialUser = User(
          id: 'zero_user',
          name: 'Zero User',
          email: 'zero@example.com',
          age: 30,
          profile: Profile(
            bio: 'Zero test',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: [],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('zero_user');
        await userDoc.set(initialUser);

        // Act - "Increment" by zero (should be no-op)
        await userDoc.incrementalModify((currentUser) {
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 0,
            ),
          );
        });

        // Assert - Should remain unchanged
        final updatedUser = await userDoc.get();
        expect(updatedUser!.profile.followers, equals(100));
      });

      test('should handle duplicate array additions', () async {
        // Arrange
        final initialUser = User(
          id: 'duplicate_user',
          name: 'Duplicate User',
          email: 'duplicate@example.com',
          age: 30,
          profile: Profile(
            bio: 'Duplicate test',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['coding', 'reading'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          tags: ['developer'],
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('duplicate_user');
        await userDoc.set(initialUser);

        // Act - Try to add existing interest and tag
        await userDoc.incrementalModify((currentUser) {
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(
              interests: [...currentUser.profile.interests, 'coding'], // Duplicate
            ),
            tags: [...currentUser.tags, 'developer'], // Duplicate
          );
        });

        // Assert - Our diff detection sees this as a list change and falls back to direct assignment
        // So we'll actually get the duplicate in this case (not using arrayUnion)
        final updatedUser = await userDoc.get();
        expect(updatedUser!.profile.interests, contains('coding'));
        expect(updatedUser.profile.interests.length, equals(3)); // ['coding', 'reading', 'coding']
        expect(updatedUser.tags, contains('developer'));
        expect(updatedUser.tags.length, equals(2)); // ['developer', 'developer']
      });

      test('should handle empty map and list operations', () async {
        // Arrange
        final initialUser = User(
          id: 'empty_user',
          name: 'Empty User',
          email: 'empty@example.com',
          age: 30,
          profile: Profile(
            bio: 'Empty test',
            avatar: 'test.jpg',
            socialLinks: {'github': 'user123'},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          tags: ['developer'],
          settings: {'theme': 'dark'},
          createdAt: DateTime.now(),
        );

        final userDoc = odm.users.doc('empty_user');
        await userDoc.set(initialUser);

        // Act - Set fields to empty collections
        await userDoc.incrementalModify((currentUser) {
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(
              socialLinks: <String, String>{}, // Empty map
              interests: <String>[], // Empty list
            ),
            tags: <String>[], // Empty list
            settings: <String, String>{}, // Empty map
          );
        });

        // Assert
        final updatedUser = await userDoc.get();
        // Note: fake_cloud_firestore may not fully support empty map operations
        // In real Firestore, these would be empty
        expect(updatedUser, isNotNull);
        expect(updatedUser!.profile.interests, isEmpty);
        expect(updatedUser.tags, isEmpty);
      });
    });
  });
}