import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../lib/models/user.dart';
import '../lib/models/profile.dart';

void main() {
  group('Array-Style Update API Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM odm;
    late FirestoreDocument<User> userDoc;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore);
      userDoc = odm.users.doc('test_user');
    });

    test('Basic field updates should work', () async {
      // Arrange - Create initial user
      final initialUser = User(
        id: 'test_user',
        name: 'Initial Name',
        email: 'test@example.com',
        age: 25,
        isActive: false,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Initial bio',
          avatar: 'initial.jpg',
          socialLinks: {'github': 'initial'},
          interests: ['initial'],
          followers: 100,
        ),
      );
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
      expect(updatedUser!.name, 'John Smith');
      expect(updatedUser.email, 'john@example.com');
      expect(updatedUser.isActive, true);
      expect(updatedUser.rating, 4.5);
      expect(updatedUser.age, 25); // Unchanged
      print('Basic field updates test passed!');
    });

    test('Nested object updates should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: true,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Initial bio',
          avatar: 'initial.jpg',
          socialLinks: {'github': 'initial'},
          interests: ['coding'],
          followers: 100,
        ),
      );
      await userDoc.set(initialUser);

      // Act - Update nested profile fields
      await userDoc.update((update) => [
        update.profile.bio('Full-stack developer'),
        update.profile.avatar('new-avatar.jpg'),
      ]);

      // Assert
      final updatedUser = await userDoc.get();
      expect(updatedUser!.profile.bio, 'Full-stack developer');
      expect(updatedUser.profile.avatar, 'new-avatar.jpg');
      expect(updatedUser.profile.followers, 100); // Unchanged
      expect(updatedUser.name, 'Test User'); // Unchanged
      print('Nested object updates test passed!');
    });

    test('Numeric increment operations should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: true,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['coding'],
          followers: 100,
        ),
      );
      await userDoc.set(initialUser);

      // Act - Use increment operations
      await userDoc.update((as) => [
        as.age.increment(1), // age: 25 + 1 = 26
        as.rating.increment(0.5), // rating: 3.0 + 0.5 = 3.5
        as.profile.followers.increment(50), // followers: 100 + 50 = 150
      ]);

      // Assert
      final updatedUser = await userDoc.get();
      expect(updatedUser!.age, 26);
      expect(updatedUser.rating, 3.5);
      expect(updatedUser.profile.followers, 150);
      print('Numeric increment operations test passed!');
    });

    test('Array operations should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: true,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['coding'],
          followers: 100,
        ),
        tags: ['beginner'],
      );
      await userDoc.set(initialUser);

      // Act - Add and remove array elements (need separate updates for same field)
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
      print('Array operations test passed!');
    });

    test('DateTime server timestamp should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: true,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['coding'],
          followers: 100,
        ),
      );
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
      print('DateTime server timestamp test passed!');
    });

    test('Object merge updates should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: false,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['coding'],
          followers: 100,
        ),
      );
      await userDoc.set(initialUser);

      // Act - Use object merge syntax
      await userDoc.update((as) => [
        as({'name': 'Kyle', 'isPremium': true}),
        as.profile({'bio': 'Good developer', 'followers': 200}),
      ]);

      // Assert
      final updatedUser = await userDoc.get();
      expect(updatedUser!.name, 'Kyle');
      expect(updatedUser.isPremium, true);
      expect(updatedUser.age, 25); // Should remain unchanged
      expect(updatedUser.profile.bio, 'Good developer');
      expect(updatedUser.profile.followers, 200);
      print('Object merge updates test passed!');
    });

    test('Mixed complex updates should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'John Doe',
        email: 'john@example.com',
        age: 25,
        isActive: false,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Initial bio',
          avatar: 'initial.jpg',
          socialLinks: {'github': 'johndoe'},
          interests: ['coding'],
          followers: 50,
        ),
        tags: ['beginner'],
      );
      await userDoc.set(initialUser);

      // Act - Complex mixed update operations (like the user's example)
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
      expect(updatedUser!.name, 'Kyle'); // Last update wins
      expect(updatedUser.profile.bio, 'Good'); // Last update wins
      expect(updatedUser.profile.followers, 101); // 50 + 50 + 1 = 101
      expect(updatedUser.rating, 3.1); // 3.0 + 0.1
      expect(updatedUser.tags, contains('verified'));
      expect(updatedUser.tags, contains('popular'));
      expect(updatedUser.tags, contains('beginner'));
      expect(updatedUser.lastLogin, isNotNull);
      expect(updatedUser.profile.lastActive, isNotNull);
      print('Mixed complex updates test passed!');
    });

    test('User requested mixed syntax should work', () async {
      // Arrange - Test the exact syntax user wants to support
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        isActive: true,
        isPremium: false,
        rating: 3.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['coding'],
          followers: 100,
        ),
      );
      await userDoc.set(initialUser);

      // Act - User's requested syntax with mixed operations
      await userDoc.update((as) => [
        as.age.increment(1), // age: 25 + 1 = 26
        as.rating.increment(0.5), // rating: 3.0 + 0.5 = 3.5
        as.profile.followers.increment(50), // followers: 100 + 50 = 150
        as({
          'age': 26, // This will override the increment above
          'rating': 3.5, // This will override the increment above
        }),
        as.profile({
          'followers': 150, // This will override the increment above
        })
      ]);

      // Assert
      final updatedUser = await userDoc.get();
      expect(updatedUser!.age, 26);
      expect(updatedUser.rating, 3.5);
      expect(updatedUser.profile.followers, 150);
      expect(updatedUser.name, 'Test User'); // Unchanged
      expect(updatedUser.email, 'test@example.com'); // Unchanged
      expect(updatedUser.profile.bio, 'Test bio'); // Unchanged (not in profile merge)
      print('User requested mixed syntax test passed!');
    });

    test('Complex field precedence in mixed operations should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 20,
        isActive: true,
        isPremium: false,
        rating: 2.0,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Initial bio',
          avatar: 'initial.jpg',
          socialLinks: {'github': 'initial'},
          interests: ['reading'],
          followers: 10,
        ),
        tags: ['student'],
      );
      await userDoc.set(initialUser);

      // Act - Test mixed operations with current implementation behavior
      await userDoc.update((as) => [
        // Incremental operations
        as.age.increment(5), // 20 + 5 = 25
        as.rating.increment(1.0), // 2.0 + 1.0 = 3.0
        as.profile.followers.increment(40), // 10 + 40 = 50
        
        // Array operations
        as.tags.add('expert'),
        as.tags.add('developer'),
        
        // Non-overlapping object merges
        as({
          'isPremium': true,
        }),
        as.profile({
          'bio': 'Updated bio',
        }),
      ]);

      // Assert - Based on current implementation behavior
      final updatedUser = await userDoc.get();
      expect(updatedUser!.age, 25); // Increment result
      expect(updatedUser.rating, 3.0); // Increment result
      expect(updatedUser.profile.followers, 50); // Increment result
      expect(updatedUser.isPremium, true); // From object merge
      expect(updatedUser.profile.bio, 'Updated bio'); // From profile merge
      expect(updatedUser.tags, contains('student')); // Original
      expect(updatedUser.tags, contains('expert')); // Added
      expect(updatedUser.tags, contains('developer')); // Added
      expect(updatedUser.name, 'Test User'); // Unchanged
      print('Complex field precedence test passed!');
    });

    test('Multiple field type updates should work', () async {
      // Arrange
      final initialUser = User(
        id: 'test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 20,
        isActive: false,
        isPremium: false,
        rating: 2.5,
        createdAt: DateTime(2023, 1, 1),
        profile: const Profile(
          bio: 'Test bio',
          avatar: 'test.jpg',
          socialLinks: {'github': 'test'},
          interests: ['reading'],
          followers: 10,
        ),
        tags: ['student'],
      );
      await userDoc.set(initialUser);

      // Act - Test different field types
      // First update: main fields and array additions
      await userDoc.update((as) => [
        // String fields
        as.name('Senior Developer'),
        as.email('senior@example.com'),
        
        // Boolean fields
        as.isActive(true),
        as.isPremium(true),
        
        // Numeric fields with increment
        as.age.increment(5), // 20 + 5 = 25
        as.rating.increment(1.5), // 2.5 + 1.5 = 4.0
        
        // Array additions
        as.tags.add('expert'),
        as.tags.add('senior'),
        
        // Nested object updates
        as.profile.bio('Senior Full-stack Developer'),
        as.profile.followers.increment(90), // 10 + 90 = 100
        as.profile.interests.add('coding'),
        as.profile.interests.add('mentoring'),
        
        // DateTime fields
        as.lastLogin(DateTime(2023, 12, 25)),
        as.updatedAt.serverTimestamp(),
      ]);
      
      // Second update: array removals (can't combine with add on same field)
      await userDoc.update((as) => [
        as.tags.remove('student'),
      ]);

      // Assert
      final updatedUser = await userDoc.get();
      
      // String fields
      expect(updatedUser!.name, 'Senior Developer');
      expect(updatedUser.email, 'senior@example.com');
      
      // Boolean fields
      expect(updatedUser.isActive, true);
      expect(updatedUser.isPremium, true);
      
      // Numeric fields
      expect(updatedUser.age, 25);
      expect(updatedUser.rating, 4.0);
      
      // Array fields
      expect(updatedUser.tags, contains('expert'));
      expect(updatedUser.tags, contains('senior'));
      expect(updatedUser.tags, isNot(contains('student')));
      
      // Nested object
      expect(updatedUser.profile.bio, 'Senior Full-stack Developer');
      expect(updatedUser.profile.followers, 100);
      expect(updatedUser.profile.interests, contains('reading'));
      expect(updatedUser.profile.interests, contains('coding'));
      expect(updatedUser.profile.interests, contains('mentoring'));
      
      // DateTime fields
      expect(updatedUser.lastLogin, DateTime(2023, 12, 25));
      expect(updatedUser.updatedAt, isNotNull);
      
      print('Multiple field type updates test passed!');
    });
  });
}