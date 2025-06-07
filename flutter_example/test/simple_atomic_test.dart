import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Simple Atomic Operations Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(fakeFirestore);
    });

    test('should verify numeric increment works', () async {
      // Arrange
      final profile = Profile(
        bio: 'Test',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: [],
        followers: 100,
      );

      final user = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 30,
        profile: profile,
        rating: 4.0,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      await odm.users.doc('test_user').set(user);

      // Act - Simple increment
      await odm.users.doc('test_user').incrementalModify((currentUser) {
        return currentUser.copyWith(
          profile: currentUser.profile.copyWith(
            followers: currentUser.profile.followers + 50,
          ),
        );
      });

      // Assert
      final updatedUser = await odm.users.doc('test_user').get();
      expect(updatedUser!.profile.followers, equals(150));
    });

    test('should verify array union works', () async {
      // Arrange
      final profile = Profile(
        bio: 'Test',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: ['coding'],
        followers: 100,
      );

      final user = User(
        id: 'array_user',
        name: 'Array User',
        email: 'array@example.com',
        age: 30,
        profile: profile,
        rating: 4.0,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      await odm.users.doc('array_user').set(user);

      // Act - Add new interest
      await odm.users.doc('array_user').incrementalModify((currentUser) {
        return currentUser.copyWith(
          profile: currentUser.profile.copyWith(
            interests: [...currentUser.profile.interests, 'flutter'],
          ),
        );
      });

      // Assert
      final updatedUser = await odm.users.doc('array_user').get();
      expect(updatedUser!.profile.interests, equals(['coding', 'flutter']));
    });

    test('should debug what happens with empty map', () async {
      // Arrange
      final profile = Profile(
        bio: 'Test',
        avatar: 'test.jpg',
        socialLinks: {'github': 'user123'},
        interests: [],
        followers: 100,
      );

      final user = User(
        id: 'debug_user',
        name: 'Debug User',
        email: 'debug@example.com',
        age: 30,
        profile: profile,
        rating: 4.0,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      await odm.users.doc('debug_user').set(user);

      print('Before update: ${user.profile.socialLinks}');

      // Act - Set to empty map
      await odm.users.doc('debug_user').incrementalModify((currentUser) {
        print('Current user socialLinks: ${currentUser.profile.socialLinks}');
        final newUser = currentUser.copyWith(
          profile: currentUser.profile.copyWith(
            socialLinks: <String, String>{},
          ),
        );
        print('New user socialLinks: ${newUser.profile.socialLinks}');
        return newUser;
      });

      // Assert
      final updatedUser = await odm.users.doc('debug_user').get();
      print('After update: ${updatedUser!.profile.socialLinks}');

      // Let's see what actually happened
      final rawDoc = await fakeFirestore
          .collection('users')
          .doc('debug_user')
          .get();
      print('Raw Firestore data: ${rawDoc.data()}');
    });
  });
}
