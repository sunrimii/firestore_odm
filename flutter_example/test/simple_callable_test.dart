import 'package:test/test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Callable Collection API Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: fakeFirestore);
    });

    test('should support callable syntax users(id)', () async {
      // Arrange
      final profile = Profile(
        bio: 'Test bio',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: ['testing'],
        followers: 100,
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

      // Act - Using new callable syntax
      await odm.users('test_user').set(user);
      final retrievedUser = await odm.users('test_user').get();

      // Assert
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.name, equals('Test User'));
      expect(retrievedUser.email, equals('test@example.com'));
    });

    test('should maintain backward compatibility with doc() syntax', () async {
      // Arrange
      final profile = Profile(
        bio: 'Backward compatible test',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: ['compatibility'],
        followers: 50,
      );

      final user = User(
        id: 'compat_user',
        name: 'Compat User',
        email: 'compat@example.com',
        age: 30,
        profile: profile,
        rating: 3.5,
        isActive: false,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      // Act - Using old doc() syntax
      await odm.users('compat_user').set(user);
      final retrievedUser = await odm.users('compat_user').get();

      // Assert
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.name, equals('Compat User'));
      expect(retrievedUser.email, equals('compat@example.com'));
    });

    test('should work interchangeably between both syntaxes', () async {
      // Arrange
      final profile = Profile(
        bio: 'Mixed syntax test',
        avatar: 'mixed.jpg',
        socialLinks: {},
        interests: ['flexibility'],
        followers: 75,
      );

      final user = User(
        id: 'mixed_user',
        name: 'Mixed User',
        email: 'mixed@example.com',
        age: 28,
        profile: profile,
        rating: 4.2,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
      );

      // Create with new syntax
      await odm.users('mixed_user').set(user);

      // Read with old syntax
      final readWithOld = await odm.users('mixed_user').get();
      expect(readWithOld, isNotNull);
      expect(readWithOld!.name, equals('Mixed User'));

      // Update with old syntax
      await odm
          .users('mixed_user')
          .modify((user) => user.copyWith(name: 'Updated Mixed User'));

      // Read with new syntax
      final readWithNew = await odm.users('mixed_user').get();
      expect(readWithNew!.name, equals('Updated Mixed User'));
    });
  });
}
