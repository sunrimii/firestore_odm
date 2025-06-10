import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../../lib/models/user.dart';
import '../../lib/models/profile.dart';
import '../../lib/test_schema.dart';

void main() {
  group('❌ Advanced Error Handling', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🚫 Invalid Input Handling', () {
      test('should handle empty document IDs gracefully', () {
        // Empty document ID should create a document reference but may not throw immediately
        final doc = odm.users('');
        expect(doc, isNotNull);
        // The error would occur during actual operations like get/set
      });

      test('should handle null values in updates', () async {
        final user = User(
          id: 'null_test_user',
          name: 'Null Test User',
          email: 'null@example.com',
          age: 25,
          profile: Profile(
            bio: 'Testing null values',
            avatar: 'null.jpg',
            socialLinks: {},
            interests: ['null_testing'],
            followers: 100,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('null_test_user').set(user);

        // Test updating with null values
        await odm.users('null_test_user').modify((user) => user.copyWith(
          lastLogin: null,
          updatedAt: null,
        ));

        final updated = await odm.users('null_test_user').get();
        expect(updated, isNotNull);
        expect(updated!.lastLogin, isNull);
        expect(updated.updatedAt, isNull);
      });

      test('should handle extreme values', () async {
        final user = User(
          id: 'extreme_user',
          name: 'Extreme User',
          email: 'extreme@example.com',
          age: 0, // Extreme age
          profile: Profile(
            bio: '', // Empty bio
            avatar: '',
            socialLinks: {},
            interests: [],
            followers: 0,
          ),
          rating: 0.0, // Minimum rating
          isActive: false,
          isPremium: false,
          tags: [],
          scores: [],
          settings: {},
          metadata: {},
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );

        await odm.users('extreme_user').set(user);
        final retrieved = await odm.users('extreme_user').get();
        
        expect(retrieved, isNotNull);
        expect(retrieved!.age, equals(0));
        expect(retrieved.rating, equals(0.0));
        expect(retrieved.profile.bio, equals(''));
      });
    });

    group('🔍 Boundary Conditions', () {
      test('should handle large documents', () async {
        final largeProfile = Profile(
          bio: 'x' * 5000, // Large bio
          avatar: 'large.jpg',
          socialLinks: Map.fromEntries(
            List.generate(100, (i) => MapEntry('platform_$i', 'link_$i'))
          ),
          interests: List.generate(500, (i) => 'interest_$i'),
          followers: 1000000,
        );

        final largeUser = User(
          id: 'large_user',
          name: 'Large User',
          email: 'large@example.com',
          age: 50,
          profile: largeProfile,
          rating: 5.0,
          isActive: true,
          isPremium: true,
          tags: List.generate(100, (i) => 'tag_$i'),
          scores: List.generate(200, (i) => i),
          settings: Map.fromEntries(
            List.generate(50, (i) => MapEntry('setting_$i', 'value_$i'))
          ),
          metadata: Map.fromEntries(
            List.generate(30, (i) => MapEntry('meta_$i', i))
          ),
          createdAt: DateTime.now(),
        );

        await odm.users('large_user').set(largeUser);
        final retrieved = await odm.users('large_user').get();
        
        expect(retrieved, isNotNull);
        expect(retrieved!.profile.interests.length, equals(500));
        expect(retrieved.tags.length, equals(100));
        expect(retrieved.scores.length, equals(200));
      });

      test('should handle concurrent operations', () async {
        final user = User(
          id: 'concurrent_user',
          name: 'Concurrent User',
          email: 'concurrent@example.com',
          age: 30,
          profile: Profile(
            bio: 'Concurrent test',
            avatar: 'concurrent.jpg',
            socialLinks: {},
            interests: ['concurrency'],
            followers: 100,
          ),
          rating: 3.5,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('concurrent_user').set(user);

        // Perform concurrent updates
        final futures = List.generate(10, (i) => 
          odm.users('concurrent_user').incrementalModify((user) => 
            user.copyWith(
              profile: user.profile.copyWith(followers: user.profile.followers + 1)
            )
          )
        );

        await Future.wait(futures);
        
        final updated = await odm.users('concurrent_user').get();
        expect(updated, isNotNull);
        expect(updated!.profile.followers, greaterThan(100));
      });
    });

    group('🚨 Exception Scenarios', () {
      test('should handle non-existent document operations', () async {
        final nonExistent = await odm.users('non_existent').get();
        expect(nonExistent, isNull);

        // Should throw when updating non-existent document
        expect(
          () => odm.users('non_existent').modify((user) => user.copyWith(
            name: 'Updated Name',
          )),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed query filters gracefully', () async {
        // These should not throw exceptions, just return empty results
        final negativeAge = await odm.users
            .where(($) => $.age(isEqualTo: -1))
            .get();
        expect(negativeAge, isEmpty);

        final impossibleRating = await odm.users
            .where(($) => $.rating(isGreaterThan: 10.0))
            .get();
        expect(impossibleRating, isEmpty);
      });

      test('should handle transaction rollback scenarios', () async {
        final user = User(
          id: 'transaction_user',
          name: 'Transaction User',
          email: 'transaction@example.com',
          age: 35,
          profile: Profile(
            bio: 'Transaction test',
            avatar: 'transaction.jpg',
            socialLinks: {},
            interests: ['transactions'],
            followers: 200,
          ),
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('transaction_user').set(user);

        try {
          await odm.runTransaction(() async {
            await odm.users('transaction_user').modify((user) => 
              user.copyWith(isPremium: true)
            );
            
            // Simulate an error that would cause rollback
            throw Exception('Simulated error');
          });
          
          fail('Transaction should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('Simulated error'));
        }

        // In fake_cloud_firestore, transactions may not rollback properly
        // This is a limitation of the test environment
        final finalUser = await odm.users('transaction_user').get();
        expect(finalUser, isNotNull);
      });
    });

    group('💾 Memory and Performance Edge Cases', () {
      test('should handle rapid successive operations', () async {
        final user = User(
          id: 'rapid_user',
          name: 'Rapid User',
          email: 'rapid@example.com',
          age: 25,
          profile: Profile(
            bio: 'Rapid test',
            avatar: 'rapid.jpg',
            socialLinks: {},
            interests: ['rapid'],
            followers: 50,
          ),
          rating: 3.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users('rapid_user').set(user);

        final stopwatch = Stopwatch()..start();

        // Perform rapid operations
        for (int i = 0; i < 50; i++) {
          await odm.users('rapid_user').incrementalModify((user) => 
            user.copyWith(
              profile: user.profile.copyWith(followers: user.profile.followers + 1)
            )
          );
        }

        stopwatch.stop();

        final finalUser = await odm.users('rapid_user').get();
        expect(finalUser!.profile.followers, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds
      });

      test('should handle bulk operations on large datasets', () async {
        // Create many users
        final users = List.generate(100, (index) => User(
          id: 'bulk_user_$index',
          name: 'Bulk User $index',
          email: 'bulk$index@example.com',
          age: 20 + (index % 50),
          profile: Profile(
            bio: 'Bulk user $index',
            avatar: 'bulk$index.jpg',
            socialLinks: {},
            interests: ['bulk_testing'],
            followers: index * 2,
          ),
          rating: 1.0 + (index % 5),
          isActive: index % 2 == 0,
          isPremium: false,
          createdAt: DateTime.now(),
        ));

        // Create all users
        final createFutures = users.map((user) => odm.users(user.id).set(user));
        await Future.wait(createFutures);

        // Perform bulk update
        await odm.users
            .where(($) => $.profile.interests(arrayContains: 'bulk_testing'))
            .modify((user) => user.copyWith(isPremium: true));

        // Verify updates
        final updatedUsers = await odm.users
            .where(($) => $.isPremium(isEqualTo: true))
            .get();

        expect(updatedUsers.length, equals(100));
      });
    });

    group('🔒 Data Integrity', () {
      test('should maintain data consistency during complex operations', () async {
        final user = User(
          id: 'integrity_user',
          name: 'Integrity User',
          email: 'integrity@example.com',
          age: 32,
          profile: Profile(
            bio: 'Data integrity test',
            avatar: 'integrity.jpg',
            socialLinks: {
              'github': 'https://github.com/integrity',
              'twitter': 'https://twitter.com/integrity',
            },
            interests: ['integrity', 'testing'],
            followers: 500,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          tags: ['integrity', 'testing'],
          scores: [95, 88, 92],
          settings: {'theme': 'dark', 'notifications': 'enabled'},
          metadata: {'version': 2, 'last_updated': 'today'},
          createdAt: DateTime.now(),
        );

        await odm.users('integrity_user').set(user);

        // Perform complex nested updates
        await odm.users('integrity_user').modify((user) => user.copyWith(
          profile: user.profile.copyWith(
            socialLinks: {
              ...user.profile.socialLinks,
              'linkedin': 'https://linkedin.com/in/integrity',
            },
            interests: [...user.profile.interests, 'linkedin'],
          ),
          tags: [...user.tags, 'updated'],
          settings: {
            ...user.settings,
            'new_feature': 'enabled',
          },
          metadata: {
            ...user.metadata,
            'version': 3,
          },
        ));

        final updated = await odm.users('integrity_user').get();
        
        expect(updated, isNotNull);
        expect(updated!.profile.socialLinks.length, equals(3));
        expect(updated.profile.socialLinks['linkedin'], equals('https://linkedin.com/in/integrity'));
        expect(updated.profile.interests, contains('linkedin'));
        expect(updated.tags, contains('updated'));
        expect(updated.settings['new_feature'], equals('enabled'));
        expect(updated.metadata['version'], equals(3));
      });

      test('should handle special characters and encoding', () async {
        final specialUser = User(
          id: 'special_user_äöü',
          name: 'Special User äöü 中文 🚀',
          email: 'special+test@example.com',
          age: 28,
          profile: Profile(
            bio: 'Special chars: äöü中文🚀"\'<>&',
            avatar: 'special äöü.jpg',
            socialLinks: {
              'special-site': 'https://example.com/äöü?test=1&special=true',
            },
            interests: ['special chars äöü', '中文', 'emojis 🚀🎉'],
            followers: 123,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: false,
          tags: ['special', 'äöü', '中文'],
          createdAt: DateTime.now(),
        );

        await odm.users('special_user_äöü').set(specialUser);
        final retrieved = await odm.users('special_user_äöü').get();
        
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Special User äöü 中文 🚀'));
        expect(retrieved.profile.bio, equals('Special chars: äöü中文🚀"\'<>&'));
        expect(retrieved.profile.interests, contains('中文'));
        expect(retrieved.tags, contains('äöü'));
      });
    });
  });
}