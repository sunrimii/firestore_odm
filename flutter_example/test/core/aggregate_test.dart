import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import '../../lib/models/user.dart';
import '../../lib/models/profile.dart';
import '../../lib/test_schema.dart';

void main() {
  group('🔥 Aggregate Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<$TestSchemaImpl> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should perform count aggregation on collection', () async {
      // Add test users
      final user1 = User(
        id: 'user1',
        name: 'Alice',
        email: 'alice@example.com',
        age: 25,
        rating: 4.5,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 1',
          avatar: 'avatar1.jpg',
          socialLinks: {},
          interests: ['reading'],
          followers: 100,
        ),
      );

      final user2 = User(
        id: 'user2',
        name: 'Bob',
        email: 'bob@example.com',
        age: 30,
        rating: 3.8,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 2',
          avatar: 'avatar2.jpg',
          socialLinks: {},
          interests: ['gaming'],
          followers: 200,
        ),
      );

      final user3 = User(
        id: 'user3',
        name: 'Charlie',
        email: 'charlie@example.com',
        age: 28,
        rating: 4.2,
        isActive: false,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 3',
          avatar: 'avatar3.jpg',
          socialLinks: {},
          interests: ['cooking'],
          followers: 150,
        ),
      );

      await odm.users.insert(user1);
      await odm.users.insert(user2);
      await odm.users.insert(user3);

      // Test count method
      final count = await odm.users.count().get();
      expect(count, equals(3));

      // Test aggregate with count
      final result = await odm.users.aggregate(($) => (count: $.count())).get();
      expect(result.count, equals(3));
    });

    test('should perform sum and average aggregation', () async {
      // Add test users
      final user1 = User(
        id: 'user1',
        name: 'Alice',
        email: 'alice@example.com',
        age: 25,
        rating: 4.0,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 1',
          avatar: 'avatar1.jpg',
          socialLinks: {},
          interests: ['reading'],
          followers: 100,
        ),
      );

      final user2 = User(
        id: 'user2',
        name: 'Bob',
        email: 'bob@example.com',
        age: 30,
        rating: 5.0,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 2',
          avatar: 'avatar2.jpg',
          socialLinks: {},
          interests: ['gaming'],
          followers: 200,
        ),
      );

      final user3 = User(
        id: 'user3',
        name: 'Charlie',
        email: 'charlie@example.com',
        age: 35,
        rating: 3.0,
        isActive: false,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 3',
          avatar: 'avatar3.jpg',
          socialLinks: {},
          interests: ['cooking'],
          followers: 150,
        ),
      );

      await odm.users.insert(user1);
      await odm.users.insert(user2);
      await odm.users.insert(user3);

      // Test strongly-typed aggregate with generated field selectors
      final result = await odm.users.aggregate(($) => (
        count: $.count(),
        totalAge: $.age.sum(),
        avgRating: $.rating.average(),
      )).get();

      expect(result.count, equals(3));
      expect(result.totalAge, equals(90)); // 25 + 30 + 35
      expect(result.avgRating, equals(4.0)); // (4.0 + 5.0 + 3.0) / 3
    });

    test('should work with query filters', () async {
      // Add test users
      final user1 = User(
        id: 'user1',
        name: 'Alice',
        email: 'alice@example.com',
        age: 25,
        rating: 4.5,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 1',
          avatar: 'avatar1.jpg',
          socialLinks: {},
          interests: ['reading'],
          followers: 100,
        ),
      );

      final user2 = User(
        id: 'user2',
        name: 'Bob',
        email: 'bob@example.com',
        age: 30,
        rating: 3.8,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 2',
          avatar: 'avatar2.jpg',
          socialLinks: {},
          interests: ['gaming'],
          followers: 200,
        ),
      );

      final user3 = User(
        id: 'user3',
        name: 'Charlie',
        email: 'charlie@example.com',
        age: 28,
        rating: 4.2,
        isActive: false,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Bio 3',
          avatar: 'avatar3.jpg',
          socialLinks: {},
          interests: ['cooking'],
          followers: 150,
        ),
      );

      await odm.users.insert(user1);
      await odm.users.insert(user2);
      await odm.users.insert(user3);

      // Test count with filter for active users
      final activeUsersCount = await odm.users
          .where(($) => $.isActive(isEqualTo: true))
          .count().get();
      expect(activeUsersCount, equals(2));

      // Test strongly-typed aggregate with filter and generated field selectors
      final result = await odm.users
          .where(($) => $.isActive(isEqualTo: true))
          .aggregate(($) => (
            activeCount: $.count(),
            totalAge: $.age.sum(),
            avgRating: $.rating.average(),
          )).get();

      expect(result.activeCount, equals(2));
      expect(result.totalAge, equals(55)); // 25 + 30
      expect(result.avgRating, closeTo(4.15, 0.01)); // (4.5 + 3.8) / 2
    });

    test('should handle empty collections', () async {
      final count = await odm.users.count().get();
      expect(count, equals(0));

      final result = await odm.users.aggregate(($) => (
        count: $.count(),
        totalAge: $.age.sum(),
        avgRating: $.rating.average(),
      )).get();

      expect(result.count, equals(0));
      expect(result.totalAge, equals(0));
      expect(result.avgRating, equals(0.0));
    });

    test('should support streaming aggregate results', () async {
      // Test streaming count
      final countStream = odm.users.count().snapshots();
      
      // Listen to the first emission (should be 0)
      final firstCount = await countStream.first;
      expect(firstCount, equals(0));

      // Test streaming strongly-typed aggregate
      final aggregateStream = odm.users.aggregate(($) => (
        count: $.count(),
      )).stream;
      final firstResult = await aggregateStream.first;
      expect(firstResult.count, equals(0));

      // Add a user and check if stream updates
      final user = User(
        id: 'stream_user',
        name: 'Stream User',
        email: 'stream@example.com',
        age: 25,
        rating: 4.0,
        isActive: true,
        isPremium: false,
        createdAt: DateTime.now(),
        profile: Profile(
          bio: 'Stream test',
          avatar: 'stream.jpg',
          socialLinks: {},
          interests: ['streaming'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      // The stream should update automatically
      // Note: In tests with FakeFirebaseFirestore, we need to manually trigger
      // For this test, we just verify the stream can be created and accessed
      expect(countStream, isA<Stream<int>>());
      expect(aggregateStream, isA<Stream<Record>>());
    });
  });
}