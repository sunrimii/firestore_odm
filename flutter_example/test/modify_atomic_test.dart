import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Modify Method Atomic Operations Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    test(
      'modify() should use atomic operations for numeric increments',
      () async {
        // Arrange
        final profile = Profile(
          bio: 'Modify test',
          avatar: 'test.jpg',
          socialLinks: {},
          interests: [],
          followers: 100,
        );

        final user = User(
          id: 'modify_user',
          name: 'Modify User',
          email: 'modify@example.com',
          age: 30,
          profile: profile,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('modify_user').set(user);

        // Act - Use modify() method with atomic increment
        await odm.users.doc('modify_user').modify((currentUser) {
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 25,
            ),
            rating: currentUser.rating + 0.3,
          );
        });

        // Assert
        final updatedUser = await odm.users.doc('modify_user').get();
        expect(updatedUser!.profile.followers, equals(125));
        expect(updatedUser.rating, closeTo(4.3, 0.01));
      },
    );

    test(
      'modify() should use atomic operations for array operations',
      () async {
        // Arrange
        final profile = Profile(
          bio: 'Array modify test',
          avatar: 'test.jpg',
          socialLinks: {},
          interests: ['coding', 'reading'],
          followers: 50,
        );

        final user = User(
          id: 'array_modify_user',
          name: 'Array Modify User',
          email: 'array_modify@example.com',
          age: 28,
          profile: profile,
          rating: 3.8,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('array_modify_user').set(user);

        // Act - Use modify() method with array union
        await odm.users.doc('array_modify_user').modify((currentUser) {
          return currentUser.copyWith(
            profile: currentUser.profile.copyWith(
              interests: [...currentUser.profile.interests, 'flutter', 'dart'],
            ),
          );
        });

        // Assert
        final updatedUser = await odm.users.doc('array_modify_user').get();
        expect(updatedUser!.profile.interests, contains('coding'));
        expect(updatedUser.profile.interests, contains('reading'));
        expect(updatedUser.profile.interests, contains('flutter'));
        expect(updatedUser.profile.interests, contains('dart'));
        expect(updatedUser.profile.interests.length, equals(4));
      },
    );

    test('modify() should handle mixed atomic operations', () async {
      // Arrange
      final profile = Profile(
        bio: 'Mixed modify test',
        avatar: 'test.jpg',
        socialLinks: {'github': 'user123'},
        interests: ['tech'],
        followers: 75,
      );

      final user = User(
        id: 'mixed_modify_user',
        name: 'Mixed Modify User',
        email: 'mixed_modify@example.com',
        age: 32,
        profile: profile,
        rating: 3.5,
        isActive: false,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      await odm.users.doc('mixed_modify_user').set(user);

      // Act - Mixed operations: increment, array add, boolean change, string change
      await odm.users.doc('mixed_modify_user').modify((currentUser) {
        return currentUser.copyWith(
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
        );
      });

      // Assert
      final updatedUser = await odm.users.doc('mixed_modify_user').get();
      expect(updatedUser!.age, equals(33));
      expect(updatedUser.rating, closeTo(4.2, 0.01));
      expect(updatedUser.isActive, isTrue);
      expect(updatedUser.profile.followers, equals(90));
      expect(updatedUser.profile.interests, equals(['tech', 'ai']));
      expect(updatedUser.profile.bio, equals('Updated mixed bio'));
      expect(updatedUser.profile.socialLinks['github'], equals('user123'));
      expect(updatedUser.profile.socialLinks['twitter'], equals('@mixed_user'));
    });

    test(
      'modify() vs incrementalModify() should produce same results',
      () async {
        // Arrange - Create two identical users
        final profile1 = Profile(
          bio: 'Comparison test 1',
          avatar: 'test1.jpg',
          socialLinks: {},
          interests: ['coding'],
          followers: 100,
        );

        final profile2 = Profile(
          bio: 'Comparison test 2',
          avatar: 'test2.jpg',
          socialLinks: {},
          interests: ['coding'],
          followers: 100,
        );

        final user1 = User(
          id: 'compare_user1',
          name: 'Compare User 1',
          email: 'compare1@example.com',
          age: 30,
          profile: profile1,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final user2 = User(
          id: 'compare_user2',
          name: 'Compare User 2',
          email: 'compare2@example.com',
          age: 30,
          profile: profile2,
          rating: 4.0,
          isActive: true,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        await odm.users.doc('compare_user1').set(user1);
        await odm.users.doc('compare_user2').set(user2);

        // Act - Apply same changes using both methods
        final updateFunction = (User currentUser) {
          return currentUser.copyWith(
            rating: currentUser.rating + 0.5,
            profile: currentUser.profile.copyWith(
              followers: currentUser.profile.followers + 50,
              interests: [...currentUser.profile.interests, 'flutter'],
            ),
          );
        };

        await odm.users.doc('compare_user1').modify(updateFunction);
        await odm.users.doc('compare_user2').incrementalModify(updateFunction);

        // Assert - Both should have same results
        final updatedUser1 = await odm.users.doc('compare_user1').get();
        final updatedUser2 = await odm.users.doc('compare_user2').get();

        expect(updatedUser1!.rating, equals(updatedUser2!.rating));
        expect(
          updatedUser1.profile.followers,
          equals(updatedUser2.profile.followers),
        );
        expect(
          updatedUser1.profile.interests,
          equals(updatedUser2.profile.interests),
        );
      },
    );

    test('modify() should handle array removal operations', () async {
      // Arrange
      final profile = Profile(
        bio: 'Array removal test',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: ['coding', 'reading', 'gaming', 'music'],
        followers: 200,
      );

      final user = User(
        id: 'removal_user',
        name: 'Removal User',
        email: 'removal@example.com',
        age: 25,
        profile: profile,
        rating: 4.2,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      await odm.users.doc('removal_user').set(user);

      // Act - Remove specific interests using modify()
      await odm.users.doc('removal_user').modify((currentUser) {
        final newInterests = currentUser.profile.interests
            .where((interest) => !['gaming', 'music'].contains(interest))
            .toList();
        return currentUser.copyWith(
          profile: currentUser.profile.copyWith(interests: newInterests),
        );
      });

      // Assert
      final updatedUser = await odm.users.doc('removal_user').get();
      expect(updatedUser!.profile.interests, equals(['coding', 'reading']));
      expect(updatedUser.profile.interests, isNot(contains('gaming')));
      expect(updatedUser.profile.interests, isNot(contains('music')));
    });
  });
}
