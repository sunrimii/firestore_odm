import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';
import '../lib/models/story.dart';
import '../lib/models/post.dart';

void main() {
  group('Comprehensive Feature Coverage Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    group('🌟 Advanced Filter Builder Coverage', () {
      test('should handle all comparison operators comprehensively', () async {
        // Arrange
        final users = List.generate(10, (index) {
          return User(
            id: 'comparison_user_$index',
            name: 'User $index',
            email: 'user$index@example.com',
            age: 20 + index * 3, // 20, 23, 26, 29, 32, 35, 38, 41, 44, 47
            profile: Profile(
              bio: 'User $index bio',
              avatar: 'user$index.jpg',
              socialLinks: {},
              interests: ['interest_$index'],
              followers: index * 10,
            ),
            rating: 1.0 + index * 0.4, // 1.0, 1.4, 1.8, 2.2, 2.6, 3.0, 3.4, 3.8, 4.2, 4.6
            isActive: index % 2 == 0,
            isPremium: index % 3 == 0,
            tags: ['tag_$index'],
            createdAt: DateTime.now(),
          );
        });

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Test isEqualTo
        final exactAge = await odm.users
            .where((filter) => filter.age(isEqualTo: 26))
            .get();
        expect(exactAge.length, equals(1));
        expect(exactAge.first.name, equals('User 2'));

        // Test isNotEqualTo
        final notAge20 = await odm.users
            .where((filter) => filter.age(isNotEqualTo: 20))
            .get();
        expect(notAge20.length, equals(9));

        // Test isLessThan
        final youngUsers = await odm.users
            .where((filter) => filter.age(isLessThan: 30))
            .get();
        expect(youngUsers.length, equals(4)); // Ages 20, 23, 26, 29

        // Test isLessThanOrEqualTo
        final young30Users = await odm.users
            .where((filter) => filter.age(isLessThanOrEqualTo: 30))
            .get();
        expect(young30Users.length, equals(4)); // Ages 20, 23, 26, 29

        // Test isGreaterThan
        final olderUsers = await odm.users
            .where((filter) => filter.age(isGreaterThan: 35))
            .get();
        expect(olderUsers.length, equals(4)); // Ages 38, 41, 44, 47

        // Test isGreaterThanOrEqualTo
        final older35Users = await odm.users
            .where((filter) => filter.age(isGreaterThanOrEqualTo: 35))
            .get();
        expect(older35Users.length, equals(5)); // Ages 35, 38, 41, 44, 47

        // Test whereIn
        final specificAges = await odm.users
            .where((filter) => filter.age(whereIn: [23, 32, 41]))
            .get();
        expect(specificAges.length, equals(3));

        // Test whereNotIn
        final excludedAges = await odm.users
            .where((filter) => filter.age(whereNotIn: [20, 47]))
            .get();
        expect(excludedAges.length, equals(8));

        // Test arrayContains
        final specificTag = await odm.users
            .where((filter) => filter.tags(arrayContains: 'tag_5'))
            .get();
        expect(specificTag.length, equals(1));
        expect(specificTag.first.name, equals('User 5'));

        // Test arrayContainsAny
        final multipleTags = await odm.users
            .where((filter) => filter.tags(arrayContainsAny: ['tag_2', 'tag_7']))
            .get();
        expect(multipleTags.length, equals(2));
      });

      test('should handle complex nested AND/OR filter combinations', () async {
        // Arrange
        final users = [
          User(
            id: 'complex_1',
            name: 'Young Premium Active',
            email: 'ypa@example.com',
            age: 22,
            profile: Profile(
              bio: 'Young premium active user',
              avatar: 'ypa.jpg',
              socialLinks: {},
              interests: ['tech', 'gaming'],
              followers: 150,
            ),
            rating: 4.2,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_2',
            name: 'Old Premium Inactive',
            email: 'opi@example.com',
            age: 45,
            profile: Profile(
              bio: 'Old premium inactive user',
              avatar: 'opi.jpg',
              socialLinks: {},
              interests: ['business'],
              followers: 500,
            ),
            rating: 4.8,
            isActive: false,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_3',
            name: 'Young Free Active High Rated',
            email: 'yfahr@example.com',
            age: 20,
            profile: Profile(
              bio: 'Young free active high rated user',
              avatar: 'yfahr.jpg',
              socialLinks: {},
              interests: ['music'],
              followers: 25,
            ),
            rating: 4.7,
            isActive: true,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_4',
            name: 'Young Free Inactive Low Rated',
            email: 'yfilr@example.com',
            age: 24,
            profile: Profile(
              bio: 'Young free inactive low rated user',
              avatar: 'yfilr.jpg',
              socialLinks: {},
              interests: ['reading'],
              followers: 10,
            ),
            rating: 2.5,
            isActive: false,
            isPremium: false,
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Test: (active AND premium) OR (young AND high-rated)
        final complexQuery1 = await odm.users
            .where((filter) => filter.or(
              filter.and(
                filter.isActive(isEqualTo: true),
                filter.isPremium(isEqualTo: true),
              ),
              filter.and(
                filter.age(isLessThan: 25),
                filter.rating(isGreaterThan: 4.0),
              ),
            ))
            .get();

        expect(complexQuery1.length, equals(2)); // Young Premium Active, Young Free Active High Rated

        // Test: premium AND (young OR high-followers)
        final complexQuery2 = await odm.users
            .where((filter) => filter.and(
              filter.isPremium(isEqualTo: true),
              filter.or(
                filter.age(isLessThan: 30),
                filter.profile.followers(isGreaterThan: 300),
              ),
            ))
            .get();

        expect(complexQuery2.length, equals(2)); // Young Premium Active, Old Premium Inactive

        // Test: active AND (premium OR high-rated) AND young
        final complexQuery3 = await odm.users
            .where((filter) => filter.and(
              filter.isActive(isEqualTo: true),
              filter.or(
                filter.isPremium(isEqualTo: true),
                filter.rating(isGreaterThanOrEqualTo: 4.5),
              ),
              filter.age(isLessThan: 30),
            ))
            .get();

        expect(complexQuery3.length, equals(2)); // Young Premium Active, Young Free Active High Rated
      });

      test('should handle edge cases in filtering', () async {
        // Arrange
        final users = [
          User(
            id: 'edge_1',
            name: 'Null Fields User',
            email: 'null@example.com',
            age: 25,
            profile: Profile(
              bio: 'User with null fields',
              avatar: 'null.jpg',
              socialLinks: {},
              interests: [],
              followers: 0,
              lastActive: null, // Null field
            ),
            rating: 0.0, // Zero rating
            isActive: false,
            isPremium: false,
            lastLogin: null, // Null field
            createdAt: DateTime.now(),
          ),
          User(
            id: 'edge_2',
            name: 'Extreme Values User',
            email: 'extreme@example.com',
            age: 100, // Extreme age
            profile: Profile(
              bio: 'User with extreme values',
              avatar: 'extreme.jpg',
              socialLinks: {},
              interests: List.generate(20, (i) => 'interest_$i'), // Many interests
              followers: 999999, // Large number
            ),
            rating: 5.0, // Max rating
            isActive: true,
            isPremium: true,
            lastLogin: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Test null field handling (skip isNull filtering due to fake_cloud_firestore limitations)
        final allUsers = await odm.users.get();
        final nullLoginUsers = allUsers.where((user) => user.lastLogin == null).toList();
        expect(nullLoginUsers.length, equals(1));
        expect(nullLoginUsers.first.name, equals('Null Fields User'));

        // Test zero value filtering
        final zeroRatingUsers = await odm.users
            .where((filter) => filter.rating(isEqualTo: 0.0))
            .get();
        expect(zeroRatingUsers.length, equals(1));

        // Test extreme value filtering
        final extremeAgeUsers = await odm.users
            .where((filter) => filter.age(isGreaterThan: 50))
            .get();
        expect(extremeAgeUsers.length, equals(1));
        expect(extremeAgeUsers.first.name, equals('Extreme Values User'));

        // Test large follower count
        final popularUsers = await odm.users
            .where((filter) => filter.profile.followers(isGreaterThan: 100000))
            .get();
        expect(popularUsers.length, equals(1));
      });
    });

    group('🎯 Real-World Scenarios', () {
      test('should handle social media platform scenario', () async {
        // Arrange - Social media platform with users, posts, and interactions
        final users = [
          User(
            id: 'influencer',
            name: 'Tech Influencer',
            email: 'influencer@social.com',
            age: 28,
            profile: Profile(
              bio: '🚀 Tech Expert | 📱 Mobile Dev | 🎯 Content Creator',
              avatar: 'influencer.jpg',
              socialLinks: {
                'twitter': '@tech_influencer',
                'youtube': 'TechInfluencerChannel',
                'github': 'tech-expert',
                'linkedin': 'tech-influencer',
              },
              interests: ['technology', 'mobile-dev', 'content-creation'],
              followers: 50000,
            ),
            rating: 4.9,
            isActive: true,
            isPremium: true,
            tags: ['influencer', 'verified', 'tech-expert'],
            scores: [98, 96, 99, 97],
            settings: {
              'privacy': 'public',
              'notifications': 'all',
              'theme': 'dark',
            },
            metadata: {
              'verification_date': '2023-01-15',
              'partnership_tier': 'gold',
              'content_categories': ['tech', 'reviews', 'tutorials'],
            },
            createdAt: DateTime(2022, 1, 1),
          ),
          User(
            id: 'developer',
            name: 'Flutter Developer',
            email: 'dev@flutter.com',
            age: 32,
            profile: Profile(
              bio: 'Flutter & Dart enthusiast. Building amazing mobile apps.',
              avatar: 'developer.jpg',
              socialLinks: {
                'github': 'flutter-dev',
                'stackoverflow': 'flutter-expert',
                'medium': '@flutter-dev',
              },
              interests: ['flutter', 'dart', 'mobile-development', 'ui-design'],
              followers: 5000,
            ),
            rating: 4.7,
            isActive: true,
            isPremium: false,
            tags: ['developer', 'flutter', 'mobile'],
            scores: [95, 88, 92, 90],
            settings: {
              'privacy': 'friends',
              'notifications': 'mentions',
              'theme': 'auto',
            },
            metadata: {
              'years_experience': 8,
              'preferred_frameworks': ['flutter', 'react-native'],
              'certifications': ['google-flutter', 'dart-certified'],
            },
            createdAt: DateTime(2022, 6, 15),
          ),
        ];

        final posts = [
          Post(
            id: 'tech_post_1',
            title: 'The Future of Mobile Development',
            content: 'Exploring the latest trends in mobile app development...',
            authorId: 'influencer',
            tags: ['mobile', 'development', 'trends', 'technology'],
            metadata: {
              'category': 'technology',
              'read_time': 5,
              'featured': true,
            },
            likes: 2500,
            views: 15000,
            published: true,
            publishedAt: DateTime.now().subtract(Duration(days: 2)),
            createdAt: DateTime.now().subtract(Duration(days: 3)),
          ),
          Post(
            id: 'flutter_post_1',
            title: 'Building Beautiful UIs with Flutter',
            content: 'A comprehensive guide to creating stunning user interfaces...',
            authorId: 'developer',
            tags: ['flutter', 'ui', 'design', 'tutorial'],
            metadata: {
              'category': 'tutorial',
              'difficulty': 'intermediate',
              'code_examples': true,
            },
            likes: 850,
            views: 4200,
            published: true,
            publishedAt: DateTime.now().subtract(Duration(days: 1)),
            createdAt: DateTime.now().subtract(Duration(days: 1)),
          ),
        ];

        // Setup data
        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }
        for (final post in posts) {
          await odm.posts.doc(post.id).set(post);
        }

        // Act & Assert - Complex queries simulating real scenarios

        // Find verified tech influencers with high engagement
        final topInfluencers = await odm.users
            .where((filter) => filter.and(
              filter.tags(arrayContains: 'influencer'),
              filter.rating(isGreaterThan: 4.5),
              filter.profile.followers(isGreaterThan: 10000),
              filter.isPremium(isEqualTo: true),
            ))
            .orderBy(($) => $.profile.followers(descending: true))
            .get();

        expect(topInfluencers.length, equals(1));
        expect(topInfluencers.first.name, equals('Tech Influencer'));

        // Find recent popular posts
        final popularPosts = await odm.posts
            .where((filter) => filter.and(
              filter.published(isEqualTo: true),
              filter.likes(isGreaterThan: 500),
              filter.views(isGreaterThan: 3000),
            ))
            .orderBy(($) => $.publishedAt(descending: true))
            .get();

        expect(popularPosts.length, equals(2));

        // Find Flutter developers for collaboration
        final flutterExperts = await odm.users
            .where((filter) => filter.and(
              filter.tags(arrayContains: 'flutter'),
              filter.profile.interests(arrayContains: 'flutter'),
              filter.isActive(isEqualTo: true),
            ))
            .get();

        expect(flutterExperts.length, equals(1));
        expect(flutterExperts.first.name, equals('Flutter Developer'));

        // Find content by category and engagement
        final techContent = await odm.posts
            .where((filter) => filter.and(
              filter.tags(arrayContainsAny: ['technology', 'mobile']),
              filter.likes(isGreaterThan: 1000),
            ))
            .get();

        expect(techContent.length, equals(1));
        expect(techContent.first.title, equals('The Future of Mobile Development'));
      });

      test('should handle e-commerce platform scenario', () async {
        // Arrange - E-commerce users with different tiers and purchase history
        final users = [
          User(
            id: 'vip_customer',
            name: 'VIP Customer',
            email: 'vip@ecommerce.com',
            age: 35,
            profile: Profile(
              bio: 'Loyal customer since 2020',
              avatar: 'vip.jpg',
              socialLinks: {},
              interests: ['electronics', 'fashion', 'home-decor'],
              followers: 100,
            ),
            rating: 4.9, // Customer satisfaction rating
            isActive: true,
            isPremium: true, // VIP membership
            tags: ['vip', 'loyal-customer', 'high-value'],
            scores: [95, 88, 92, 97], // Purchase satisfaction scores
            settings: {
              'email_promotions': 'true',
              'push_notifications': 'true',
              'preferred_payment': 'card',
            },
            metadata: {
              'total_orders': 45,
              'total_spent': 15000.0,
              'last_purchase': '2024-01-15',
              'favorite_categories': ['electronics', 'fashion'],
            },
            createdAt: DateTime(2020, 3, 15),
          ),
          User(
            id: 'regular_customer',
            name: 'Regular Customer',
            email: 'regular@ecommerce.com',
            age: 28,
            profile: Profile(
              bio: 'Occasional shopper',
              avatar: 'regular.jpg',
              socialLinks: {},
              interests: ['books', 'electronics'],
              followers: 25,
            ),
            rating: 4.2,
            isActive: true,
            isPremium: false,
            tags: ['customer', 'occasional-buyer'],
            scores: [80, 75, 85, 78],
            settings: {
              'email_promotions': 'false',
              'push_notifications': 'false',
              'preferred_payment': 'paypal',
            },
            metadata: {
              'total_orders': 8,
              'total_spent': 1200.0,
              'last_purchase': '2023-12-20',
              'favorite_categories': ['books'],
            },
            createdAt: DateTime(2023, 5, 10),
          ),
          User(
            id: 'inactive_customer',
            name: 'Inactive Customer',
            email: 'inactive@ecommerce.com',
            age: 42,
            profile: Profile(
              bio: 'Haven\'t shopped recently',
              avatar: 'inactive.jpg',
              socialLinks: {},
              interests: ['home-garden'],
              followers: 5,
            ),
            rating: 3.5,
            isActive: false, // Inactive for promotions
            isPremium: false,
            tags: ['customer', 'inactive'],
            scores: [70, 65, 68, 72],
            settings: {
              'email_promotions': 'true',
              'push_notifications': 'false',
              'preferred_payment': 'card',
            },
            metadata: {
              'total_orders': 3,
              'total_spent': 450.0,
              'last_purchase': '2023-06-01',
              'favorite_categories': ['home-garden'],
            },
            createdAt: DateTime(2023, 1, 5),
          ),
        ];

        for (final user in users) {
          await odm.users.doc(user.id).set(user);
        }

        // Act & Assert - E-commerce specific queries

        // Find VIP customers for exclusive promotions
        final vipCustomers = await odm.users
            .where((filter) => filter.and(
              filter.isPremium(isEqualTo: true),
              filter.tags(arrayContains: 'vip'),
              filter.rating(isGreaterThan: 4.5),
            ))
            .get();

        expect(vipCustomers.length, equals(1));
        expect(vipCustomers.first.name, equals('VIP Customer'));

        // Find customers for re-engagement campaign (inactive but opted-in)
        final reengagementTargets = await odm.users
            .where((filter) => filter.isActive(isEqualTo: false))
            .get();

        expect(reengagementTargets.length, equals(1));
        expect(reengagementTargets.first.name, equals('Inactive Customer'));

        // Find customers interested in electronics for targeted promotion
        final electronicsInterested = await odm.users
            .where((filter) => filter.and(
              filter.profile.interests(arrayContains: 'electronics'),
              filter.isActive(isEqualTo: true),
            ))
            .orderBy(($) => $.rating(descending: true))
            .get();

        expect(electronicsInterested.length, equals(2));
        expect(electronicsInterested.first.name, equals('VIP Customer')); // Higher rating

        // Find customers by spending tier
        final highValueCustomers = await odm.users
            .where((filter) => filter.tags(arrayContains: 'high-value'))
            .get();

        expect(highValueCustomers.length, equals(1));

        // Find premium customers (simplified query)
        final premiumCustomers = await odm.users
            .where((filter) => filter.isPremium(isEqualTo: true))
            .get();

        expect(premiumCustomers.length, equals(1));
        expect(premiumCustomers.first.name, equals('VIP Customer'));
      });
    });

    group('🔬 Edge Cases & Stress Testing', () {
      test('should handle firestore specific data types and edge cases', () async {
        // Arrange - Test Firestore-specific behaviors
        final testDoc = fakeFirestore.collection('test').doc('firestore_test');

        // Test direct Firestore operations that ODM should handle
        await testDoc.set({
          'timestamp_field': FieldValue.serverTimestamp(),
          'increment_field': 10,
          'array_field': ['item1', 'item2'],
          'nested_object': {
            'inner_field': 'value',
            'inner_array': [1, 2, 3],
          },
          'null_field': null,
          'empty_string': '',
          'zero_number': 0,
          'false_boolean': false,
        });

        // Test FieldValue operations
        await testDoc.update({
          'increment_field': FieldValue.increment(5),
          'array_field': FieldValue.arrayUnion(['item3']),
          'timestamp_field': FieldValue.serverTimestamp(),
        });

        // Test nested field updates
        await testDoc.update({
          'nested_object.inner_field': 'updated_value',
          'nested_object.new_field': 'new_value',
        });

        // Verify the updates worked
        final docSnapshot = await testDoc.get();
        final data = docSnapshot.data()!;

        expect(data['increment_field'], equals(15)); // 10 + 5
        expect(data['array_field'], contains('item3'));
        expect(data['nested_object']['inner_field'], equals('updated_value'));
        expect(data['nested_object']['new_field'], equals('new_value'));
        expect(data['null_field'], isNull);
        expect(data['empty_string'], equals(''));
        expect(data['zero_number'], equals(0));
        expect(data['false_boolean'], isFalse);
      });

      test('should handle large data structures and unicode content', () async {
        // Arrange - Test with large and complex data
        final largeContent = 'A' * 10000; // 10KB string
        final unicodeContent = '🚀🔥💯🎯✨🌟⭐🎉🎊🎈 Unicode test with emojis 中文测试 العربية тест русский';
        final largeArray = List.generate(1000, (i) => 'item_$i');
        final largeMap = <String, String>{};
        for (int i = 0; i < 100; i++) {
          largeMap['key_$i'] = 'value_for_key_$i';
        }

        final user = User(
          id: 'large_data_user',
          name: unicodeContent,
          email: 'large@example.com',
          age: 30,
          profile: Profile(
            bio: largeContent,
            avatar: 'large.jpg',
            socialLinks: largeMap,
            interests: largeArray,
            followers: 999999,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          tags: List.generate(50, (i) => 'tag_$i'),
          scores: List.generate(100, (i) => i),
          settings: largeMap,
          metadata: {
            'large_content': largeContent,
            'unicode_content': unicodeContent,
            'nested_large_array': largeArray,
            'deeply_nested': {
              'level1': {
                'level2': {
                  'level3': largeArray.take(10).toList(),
                },
              },
            },
          },
          createdAt: DateTime.now(),
        );

        // Act
        await odm.users.doc('large_data_user').set(user);
        final retrievedUser = await odm.users.doc('large_data_user').get();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.name, equals(unicodeContent));
        expect(retrievedUser.profile.bio.length, equals(10000));
        expect(retrievedUser.profile.interests.length, equals(1000));
        expect(retrievedUser.profile.socialLinks.length, equals(100));
        expect(retrievedUser.tags.length, equals(50));
        expect(retrievedUser.scores.length, equals(100));

        // Test querying with unicode content
        final unicodeQuery = await odm.users
            .where((filter) => filter.name(isEqualTo: unicodeContent))
            .get();
        expect(unicodeQuery.length, equals(1));
      });

      test('should handle concurrent operations without data corruption', () async {
        // Arrange
        final baseUser = User(
          id: 'concurrent_test_user',
          name: 'Concurrent Test',
          email: 'concurrent@example.com',
          age: 25,
          profile: Profile(
            bio: 'Concurrent operations test',
            avatar: 'concurrent.jpg',
            socialLinks: {},
            interests: [],
            followers: 0,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          tags: [],
          scores: [],
          createdAt: DateTime.now(),
        );

        await odm.users.doc('concurrent_test_user').set(baseUser);

        // Act - Simulate concurrent operations
        final futures = <Future>[];

        // Multiple increments
        for (int i = 0; i < 10; i++) {
          futures.add(
            odm.users.doc('concurrent_test_user').update(($) => [
              $.profile.followers.increment(1),
              $.rating.increment(0.01),
            ]),
          );
        }

        // Multiple array additions
        for (int i = 0; i < 5; i++) {
          futures.add(
            odm.users.doc('concurrent_test_user').update(($) => [
              $.tags.add('tag_$i'),
              $.scores.add(80 + i),
            ]),
          );
        }

        // Multiple field updates
        for (int i = 0; i < 3; i++) {
          futures.add(
            odm.users.doc('concurrent_test_user').update(($) => [
              $.name('Updated Name $i'),
            ]),
          );
        }

        await Future.wait(futures);

        // Assert - Verify final state is consistent
        final finalUser = await odm.users.doc('concurrent_test_user').get();
        expect(finalUser, isNotNull);
        expect(finalUser!.profile.followers, equals(10)); // 10 increments
        expect(finalUser.rating, closeTo(3.1, 0.01)); // 10 * 0.01 = 0.1 increment
        expect(finalUser.tags.length, equals(5)); // 5 tag additions
        expect(finalUser.scores.length, equals(5)); // 5 score additions
        // Name should be one of the updated values
        expect(finalUser.name, startsWith('Updated Name'));
      });
    });

    group('🧪 Integration Testing', () {
      test('should integrate all features in a complete workflow', () async {
        // Arrange - Complete user lifecycle simulation
        final initialUser = User(
          id: 'lifecycle_user',
          name: 'New User',
          email: 'new@example.com',
          age: 25,
          profile: Profile(
            bio: 'Just joined',
            avatar: 'default.jpg',
            socialLinks: {},
            interests: [],
            followers: 0,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          tags: ['newbie'],
          scores: [],
          settings: {'theme': 'light'},
          metadata: {'source': 'registration'},
          createdAt: DateTime.now(),
        );

        // Act 1 - User registration
        await odm.users.doc('lifecycle_user').set(initialUser);

        // Act 2 - Profile completion
        await odm.users.doc('lifecycle_user').update(($) => [
          $.profile.bio('Flutter enthusiast and mobile developer'),
          $.profile.avatar('custom_avatar.jpg'),
          $.profile(socialLinks: {'github': 'flutter_dev'}),
          $.profile.interests.add('flutter'),
          $.profile.interests.add('mobile-development'),
          $.tags.add('developer'),
        ]);

        // Act 3 - Engagement and activity
        await odm.users.doc('lifecycle_user').incrementalModify((user) {
          return user.copyWith(
            profile: user.profile.copyWith(
              followers: user.profile.followers + 50,
            ),
            rating: user.rating + 0.5,
            scores: [...user.scores, 85, 90, 88],
          );
        });

        // Act 4 - Premium upgrade
        await odm.users.doc('lifecycle_user').update(($) => [
          $.isPremium(true),
          $.tags.add('premium'),
          $.rating.increment(0.3),
          $.lastLogin.serverTimestamp(),
        ]);

        // Act 5 - Advanced user activities
        await odm.users.doc('lifecycle_user').incrementalModify((user) {
          return user.copyWith(
            name: 'Experienced Flutter Dev',
            profile: user.profile.copyWith(
              followers: user.profile.followers + 200,
              interests: [...user.profile.interests, 'ui-design', 'state-management'],
              socialLinks: {
                ...user.profile.socialLinks,
                'twitter': '@flutter_expert',
                'linkedin': 'flutter-expert-dev',
              },
            ),
            tags: [...user.tags, 'expert', 'influencer'],
            scores: [...user.scores, 95, 98, 92],
            settings: {
              ...user.settings,
              'notifications': 'all',
              'privacy': 'public',
            },
            metadata: {
              ...user.metadata,
              'last_achievement': 'flutter_expert',
              'community_score': 95,
            },
          );
        });

        // Assert - Verify complete user evolution
        final finalUser = await odm.users.doc('lifecycle_user').get();
        expect(finalUser, isNotNull);
        expect(finalUser!.name, equals('Experienced Flutter Dev'));
        expect(finalUser.profile.followers, equals(250)); // 0 + 50 + 200
        expect(finalUser.rating, closeTo(3.8, 0.01)); // 3.0 + 0.5 + 0.3
        expect(finalUser.isPremium, isTrue);
        expect(finalUser.tags, containsAll(['newbie', 'developer', 'premium', 'expert', 'influencer']));
        expect(finalUser.profile.interests, containsAll(['flutter', 'mobile-development', 'ui-design', 'state-management']));
        expect(finalUser.scores.length, equals(6)); // 3 + 3 scores
        expect(finalUser.profile.socialLinks.length, equals(3)); // github, twitter, linkedin
        expect(finalUser.settings.length, equals(3)); // theme, notifications, privacy
        expect(finalUser.lastLogin, isNotNull);

        // Act 6 - Query the evolved user
        final expertUsers = await odm.users
            .where((filter) => filter.and(
              filter.tags(arrayContains: 'expert'),
              filter.isPremium(isEqualTo: true),
              filter.rating(isGreaterThan: 3.5),
              filter.profile.followers(isGreaterThan: 100),
            ))
            .get();

        expect(expertUsers.length, equals(1));
        expect(expertUsers.first.name, equals('Experienced Flutter Dev'));

        // Act 7 - Stream the final changes
        final changes = <User?>[];
        final subscription = odm.users.doc('lifecycle_user').changes.listen((user) {
          changes.add(user);
        });

        await Future.delayed(Duration(milliseconds: 50));

        // Make final update
        await odm.users.doc('lifecycle_user').update(($) => [
          $.name('Final Updated Name'),
        ]);

        await Future.delayed(Duration(milliseconds: 100));
        await subscription.cancel();

        expect(changes.length, greaterThan(0));
      });
    });
  });
}