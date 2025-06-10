import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../../lib/models/user.dart';
import '../../lib/models/post.dart';
import '../../lib/models/simple_story.dart';
import '../../lib/models/profile.dart';
import '../../lib/test_schema.dart';

void main() {
  group('🏢 Multiple ODM Instance Tests', () {
    late FakeFirebaseFirestore mainFirestore;
    late FakeFirebaseFirestore analyticsFirestore;
    late FirestoreODM<TestSchema> mainODM;
    late FirestoreODM<TestSchema> analyticsODM;

    setUp(() {
      mainFirestore = FakeFirebaseFirestore();
      analyticsFirestore = FakeFirebaseFirestore();
      
      // Create multiple ODM instances with different Firestore instances
      mainODM = FirestoreODM(testSchema, firestore: mainFirestore);
      analyticsODM = FirestoreODM(testSchema, firestore: analyticsFirestore);
    });

    group('🔗 Independent ODM Instances', () {
      test('should maintain separate data across different ODM instances', () async {
        final mainUser = User(
          id: 'main_user',
          name: 'Main User',
          email: 'main@example.com',
          age: 25,
          profile: Profile(
            bio: 'Main user bio',
            avatar: 'main.jpg',
            socialLinks: {},
            interests: ['main'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final analyticsUser = User(
          id: 'analytics_user',
          name: 'Analytics User',
          email: 'analytics@example.com',
          age: 30,
          profile: Profile(
            bio: 'Analytics user bio',
            avatar: 'analytics.jpg',
            socialLinks: {},
            interests: ['analytics'],
            followers: 200,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Store users in different ODM instances
        await mainODM.users(mainUser.id).set(mainUser);
        await analyticsODM.users(analyticsUser.id).set(analyticsUser);

        // Verify data isolation
        final mainRetrieved = await mainODM.users('main_user').get();
        final analyticsRetrieved = await analyticsODM.users('analytics_user').get();

        expect(mainRetrieved, isNotNull);
        expect(mainRetrieved!.name, equals('Main User'));
        expect(mainRetrieved.profile.interests, contains('main'));

        expect(analyticsRetrieved, isNotNull);
        expect(analyticsRetrieved!.name, equals('Analytics User'));
        expect(analyticsRetrieved.profile.interests, contains('analytics'));

        // Verify cross-instance isolation
        final crossMainUser = await analyticsODM.users('main_user').get();
        final crossAnalyticsUser = await mainODM.users('analytics_user').get();

        expect(crossMainUser, isNull);
        expect(crossAnalyticsUser, isNull);
      });

      test('should handle same user ID across different ODM instances', () async {
        final sameId = 'shared_user_id';
        
        final mainUserData = User(
          id: sameId,
          name: 'Main Version',
          email: 'main@shared.com',
          age: 25,
          profile: Profile(
            bio: 'Main version of shared user',
            avatar: 'main_shared.jpg',
            socialLinks: {},
            interests: ['main'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final analyticsUserData = User(
          id: sameId,
          name: 'Analytics Version',
          email: 'analytics@shared.com',
          age: 30,
          profile: Profile(
            bio: 'Analytics version of shared user',
            avatar: 'analytics_shared.jpg',
            socialLinks: {},
            interests: ['analytics'],
            followers: 200,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        // Store same ID in both ODM instances with different data
        await mainODM.users(sameId).set(mainUserData);
        await analyticsODM.users(sameId).set(analyticsUserData);

        // Verify each ODM instance maintains its own data
        final mainRetrieved = await mainODM.users(sameId).get();
        final analyticsRetrieved = await analyticsODM.users(sameId).get();

        expect(mainRetrieved!.name, equals('Main Version'));
        expect(mainRetrieved.email, equals('main@shared.com'));
        expect(mainRetrieved.age, equals(25));
        expect(mainRetrieved.isPremium, isFalse);

        expect(analyticsRetrieved!.name, equals('Analytics Version'));
        expect(analyticsRetrieved.email, equals('analytics@shared.com'));
        expect(analyticsRetrieved.age, equals(30));
        expect(analyticsRetrieved.isPremium, isTrue);
      });
    });

    group('🔄 Independent Operations', () {
      test('should perform independent updates across ODM instances', () async {
        final userId = 'update_test_user';
        
        final initialUser = User(
          id: userId,
          name: 'Update Test User',
          email: 'update@test.com',
          age: 25,
          profile: Profile(
            bio: 'Initial bio',
            avatar: 'initial.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          scores: [500],
          createdAt: DateTime.now(),
        );

        // Set same initial user in both ODM instances
        await mainODM.users(userId).set(initialUser);
        await analyticsODM.users(userId).set(initialUser);

        // Perform different updates in each ODM instance
        await mainODM.users(userId).update(($) => [
          $.name('Main Updated User'),
          $.rating.increment(1.0),
          $.isPremium(true),
        ]);

        await analyticsODM.users(userId).incrementalModify((user) => user.copyWith(
          name: 'Analytics Updated User',
          age: user.age + 5,
          profile: user.profile.copyWith(
            followers: user.profile.followers + 50,
          ),
          scores: [user.scores.first + 200],
        ));

        // Verify independent updates
        final mainUpdated = await mainODM.users(userId).get();
        final analyticsUpdated = await analyticsODM.users(userId).get();

        expect(mainUpdated!.name, equals('Main Updated User'));
        expect(mainUpdated.rating, equals(4.0));
        expect(mainUpdated.isPremium, isTrue);
        expect(mainUpdated.age, equals(25)); // Unchanged in main

        expect(analyticsUpdated!.name, equals('Analytics Updated User'));
        expect(analyticsUpdated.age, equals(30)); // Updated in analytics
        expect(analyticsUpdated.profile.followers, equals(150));
        expect(analyticsUpdated.scores.first, equals(700));
        expect(analyticsUpdated.isPremium, isFalse); // Unchanged in analytics
      });

      test('should handle independent queries across ODM instances', () async {
        final users = [
          User(
            id: 'query_user_1',
            name: 'Query User 1',
            email: 'query1@test.com',
            age: 25,
            profile: Profile(
              bio: 'Query test 1',
              avatar: 'query1.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 100,
            ),
            rating: 3.0,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'query_user_2',
            name: 'Query User 2',
            email: 'query2@test.com',
            age: 30,
            profile: Profile(
              bio: 'Query test 2',
              avatar: 'query2.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 200,
            ),
            rating: 4.0,
            isActive: false,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Add users to main ODM only
        for (final user in users) {
          await mainODM.users(user.id).set(user);
        }

        // Add only active users to analytics ODM
        final activeUsers = users.where((u) => u.isActive).toList();
        for (final user in activeUsers) {
          await analyticsODM.users(user.id).set(user);
        }

        // Query both ODM instances
        final mainResults = await mainODM.users
            .where(($) => $.profile.interests(arrayContains: 'testing'))
            .get();

        final analyticsResults = await analyticsODM.users
            .where(($) => $.profile.interests(arrayContains: 'testing'))
            .get();

        expect(mainResults.length, equals(2)); // All users
        expect(analyticsResults.length, equals(1)); // Only active users
        expect(analyticsResults.first.isActive, isTrue);
      });
    });

    group('🏗️ Different Collection Configurations', () {
      test('should handle multiple collections across ODM instances', () async {
        final user = User(
          id: 'multi_collection_user',
          name: 'Multi Collection User',
          email: 'multi@test.com',
          age: 25,
          profile: Profile(
            bio: 'Multi collection test',
            avatar: 'multi.jpg',
            socialLinks: {},
            interests: ['multi'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final post = Post(
          id: 'multi_collection_post',
          title: 'Multi Collection Post',
          content: 'Testing multiple collections',
          authorId: 'multi_collection_user',
          likes: 10,
          tags: ['multi', 'test'],
          published: true,
          metadata: {'collection': 'multi'},
          createdAt: DateTime.now(),
        );

        final story = SimpleStory(
          id: 'multi_collection_story',
          title: 'Multi Collection Story',
          content: 'Testing story in multiple collections',
          authorId: 'multi_collection_user',
          tags: ['multi', 'story'],
          createdAt: DateTime.now(),
        );

        // Add data to main ODM
        await mainODM.users(user.id).set(user);
        await mainODM.posts(post.id).set(post);
        await mainODM.simpleStories(story.id).set(story);

        // Add only user to analytics ODM
        await analyticsODM.users(user.id).set(user);

        // Verify collection access across ODM instances
        final mainUser = await mainODM.users(user.id).get();
        final mainPost = await mainODM.posts(post.id).get();
        final mainStory = await mainODM.simpleStories(story.id).get();

        final analyticsUser = await analyticsODM.users(user.id).get();
        final analyticsPost = await analyticsODM.posts(post.id).get();
        final analyticsStory = await analyticsODM.simpleStories(story.id).get();

        expect(mainUser, isNotNull);
        expect(mainPost, isNotNull);
        expect(mainStory, isNotNull);

        expect(analyticsUser, isNotNull);
        expect(analyticsPost, isNull); // Not added to analytics
        expect(analyticsStory, isNull); // Not added to analytics
      });

      test('should handle subcollections across ODM instances', () async {
        final user = User(
          id: 'subcol_user',
          name: 'Subcollection User',
          email: 'subcol@test.com',
          age: 25,
          profile: Profile(
            bio: 'Subcollection test',
            avatar: 'subcol.jpg',
            socialLinks: {},
            interests: ['subcol'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final userPost = Post(
          id: 'subcol_post',
          title: 'Subcollection Post',
          content: 'Testing subcollection access',
          authorId: 'subcol_user',
          likes: 5,
          tags: ['subcol'],
          published: true,
          metadata: {},
          createdAt: DateTime.now(),
        );

        // Set user in both ODM instances
        await mainODM.users(user.id).set(user);
        await analyticsODM.users(user.id).set(user);

        // Add post to user's subcollection in main ODM only
        await mainODM.users(user.id).posts(userPost.id).set(userPost);

        // Verify subcollection access
        final mainSubPost = await mainODM.users(user.id).posts(userPost.id).get();
        final analyticsSubPost = await analyticsODM.users(user.id).posts(userPost.id).get();

        expect(mainSubPost, isNotNull);
        expect(mainSubPost!.title, equals('Subcollection Post'));

        expect(analyticsSubPost, isNull); // Not in analytics ODM
      });
    });

    group('🔄 Transaction Independence', () {
      test('should handle independent transactions across ODM instances', () async {
        final userId = 'tx_independence_user';
        
        final initialUser = User(
          id: userId,
          name: 'TX Independence User',
          email: 'txindep@test.com',
          age: 25,
          profile: Profile(
            bio: 'Transaction independence test',
            avatar: 'txindep.jpg',
            socialLinks: {},
            interests: ['tx'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          scores: [1000],
          createdAt: DateTime.now(),
        );

        // Set same initial user in both ODM instances
        await mainODM.users(userId).set(initialUser);
        await analyticsODM.users(userId).set(initialUser);

        // Run independent transactions
        await Future.wait([
          mainODM.runTransaction(() async {
            final user = await mainODM.users(userId).get();
            await mainODM.users(userId).update(($) => [
              $.name('Main TX User'),
              $.rating.increment(1.0),
            ]);
          }),
          analyticsODM.runTransaction(() async {
            final user = await analyticsODM.users(userId).get();
            await analyticsODM.users(userId).incrementalModify((user) => user.copyWith(
              name: 'Analytics TX User',
              scores: [user.scores.first + 500],
            ));
          }),
        ]);

        // Verify independent transaction results
        final mainResult = await mainODM.users(userId).get();
        final analyticsResult = await analyticsODM.users(userId).get();

        expect(mainResult!.name, equals('Main TX User'));
        expect(mainResult.rating, equals(4.0));
        expect(mainResult.scores.first, equals(1000)); // Unchanged

        expect(analyticsResult!.name, equals('Analytics TX User'));
        expect(analyticsResult.rating, equals(3.0)); // Unchanged
        expect(analyticsResult.scores.first, equals(1500)); // Updated
      });
    });

    group('🎯 Real-world Scenarios', () {
      test('should simulate main app and analytics separation', () async {
        // Simulate main app storing user activity
        final user = User(
          id: 'real_world_user',
          name: 'Real World User',
          email: 'realworld@test.com',
          age: 28,
          profile: Profile(
            bio: 'Real world test user',
            avatar: 'realworld.jpg',
            socialLinks: {'github': 'realworld'},
            interests: ['development', 'testing'],
            followers: 250,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          tags: ['developer', 'tester'],
          scores: [1500, 1200],
          createdAt: DateTime.now(),
        );

        // Main app stores full user data
        await mainODM.users(user.id).set(user);

        // Analytics stores anonymized/minimal data
        final analyticsUser = user.copyWith(
          email: 'anonymized@analytics.com',
          profile: user.profile.copyWith(
            socialLinks: {}, // Remove personal links
            bio: 'Analytics user',
          ),
        );

        await analyticsODM.users(user.id).set(analyticsUser);

        // Main app performs regular operations
        await mainODM.users(user.id).update(($) => [
          $.lastLogin.serverTimestamp(),
          $.profile.followers.increment(10),
        ]);

        // Analytics performs aggregation operations
        await analyticsODM.users(user.id).incrementalModify((user) => user.copyWith(
          scores: [user.scores.first + 50], // Track engagement score
          tags: [...user.tags, 'analytics_processed'],
        ));

        // Verify data separation
        final mainFinal = await mainODM.users(user.id).get();
        final analyticsFinal = await analyticsODM.users(user.id).get();

        expect(mainFinal!.email, equals('realworld@test.com'));
        expect(mainFinal.profile.socialLinks.containsKey('github'), isTrue);
        expect(mainFinal.profile.followers, equals(260));
        expect(mainFinal.lastLogin, isNotNull);

        expect(analyticsFinal!.email, equals('anonymized@analytics.com'));
        expect(analyticsFinal.profile.socialLinks.isEmpty, isTrue);
        expect(analyticsFinal.profile.followers, equals(250)); // Unchanged
        expect(analyticsFinal.tags, contains('analytics_processed'));
        expect(analyticsFinal.scores.first, equals(1550));
      });
    });
  });
}