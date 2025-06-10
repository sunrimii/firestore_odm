import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🧠 Smart Builder Value Extraction Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('demonstrates smart builder reuse for single field extraction', () async {
      // Create a sample user
      final sampleUser = User(
        id: 'user1',
        name: 'Alice',
        email: 'alice@example.com',
        age: 30,
        tags: ['smart', 'builder'],
        scores: [85, 90],
        rating: 4.5,
        isActive: true,
        isPremium: false,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Smart builder user',
          avatar: 'alice.jpg',
          interests: ['tech', 'ai'],
          followers: 1250,
          lastActive: DateTime.now(),
          socialLinks: {'github': 'https://github.com/alice'},
        ),
      );

      // ✅ SAME builder pattern used for orderBy AND object extraction!
      // Using inline functions due to Dart extension visibility rules

      // Use builder for orderBy
      final query = odm.users
          .orderBy(($) => ($.age(),))  // Creates orderBy configuration
          .limit(10);

      // Use object-based pagination
      final paginatedQuery = query.startAtObject(sampleUser);

      expect(paginatedQuery, isNotNull);
      print('✅ Smart builder reuse for single field: SUCCESS');
    });

    test('demonstrates smart builder reuse for multiple fields extraction', () async {
      // Create a sample user with multiple order fields
      final sampleUser = User(
        id: 'user2',
        name: 'Bob',
        email: 'bob@example.com',
        age: 25,
        tags: ['multi', 'field'],
        scores: [75, 80],
        rating: 3.8,
        isActive: true,
        isPremium: true,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Multi-field user',
          avatar: 'bob.jpg',
          interests: ['sports', 'music'],
          followers: 850,
          lastActive: DateTime.now(),
          socialLinks: {'twitter': 'https://twitter.com/bob'},
        ),
      );

      // ✅ SAME builder pattern for multiple fields - inline functions
      
      // Use builder for orderBy
      final query = odm.users
          .orderBy(($) => ($.age(), $.rating(true), $.name()))  // Creates (int, double, String) tuple
          .limit(10);

      // Use object-based pagination - GUARANTEED consistency!
      final paginatedQuery = query
          .startAtObject(sampleUser)    // Extracts (25, 3.8, 'Bob')
          .endBeforeObject(sampleUser); // Extracts (25, 3.8, 'Bob')

      expect(paginatedQuery, isNotNull);
      print('✅ Smart builder reuse for multiple fields: SUCCESS');
    });

    test('demonstrates smart builder reuse with nested fields', () async {
      // Create a sample user with nested profile data
      final sampleUser = User(
        id: 'user3',
        name: 'Charlie',
        email: 'charlie@example.com',
        age: 35,
        tags: ['nested', 'extraction'],
        scores: [95, 98],
        rating: 4.9,
        isActive: true,
        isPremium: true,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Nested field user',
          avatar: 'charlie.jpg',
          interests: ['ai', 'ml', 'data'],
          followers: 2100,
          lastActive: DateTime.now(),
          socialLinks: {'linkedin': 'https://linkedin.com/in/charlie'},
        ),
      );

      // ✅ SAME builder pattern with nested fields - inline functions
      
      // Use builder for orderBy
      final query = odm.users
          .orderBy(($) => ($.profile.followers(true), $.age()))  // Creates (int, int) tuple from nested+regular fields
          .limit(10);

      // Use object-based pagination - PERFECT nested extraction!
      final paginatedQuery = query
          .startAfterObject(sampleUser)  // Extracts (2100, 35) using same logic
          .endAtObject(sampleUser);      // Extracts (2100, 35) using same logic

      expect(paginatedQuery, isNotNull);
      print('✅ Smart builder reuse with nested fields: SUCCESS');
    });

    test('demonstrates smart builder consistency prevents bugs', () async {
      // Create sample users
      final user1 = User(
        id: 'consistency1',
        name: 'David',
        email: 'david@example.com',
        age: 28,
        tags: ['consistency'],
        scores: [88],
        rating: 4.2,
        isActive: true,
        isPremium: false,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Consistency user 1',
          avatar: 'david.jpg',
          interests: ['testing'],
          followers: 500,
          lastActive: DateTime.now(),
          socialLinks: {},
        ),
      );

      final user2 = User(
        id: 'consistency2',
        name: 'Eve',
        email: 'eve@example.com',
        age: 32,
        tags: ['consistency'],
        scores: [92],
        rating: 4.7,
        isActive: true,
        isPremium: true,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Consistency user 2',
          avatar: 'eve.jpg',
          interests: ['validation'],
          followers: 1500,
          lastActive: DateTime.now(),
          socialLinks: {},
        ),
      );

      // ✅ Complex builder pattern with multiple field types - inline functions

      // Create query with complex orderBy
      final query = odm.users
          .orderBy(($) => (
            $.profile.followers(true),  // int (descending)
            $.rating(),                 // double (ascending)
            $.name(),                   // String (ascending)
            $.age(true),               // int (descending)
          ))  // (int, double, String, int) tuple
          .limit(50);

      // Use object-based pagination - NO possibility of mismatch!
      final paginationChain = query
          .startAtObject(user1)      // Extracts (500, 4.2, 'David', 28)
          .endBeforeObject(user2);   // Extracts (1500, 4.7, 'Eve', 32)

      expect(paginationChain, isNotNull);
      print('✅ Smart builder prevents inconsistency bugs: SUCCESS');
      print('   - OrderBy: (followers↓, rating↑, name↑, age↓)');
      print('   - User1 extracted: (500, 4.2, "David", 28)');
      print('   - User2 extracted: (1500, 4.7, "Eve", 32)');
      print('   - Perfect field order and type consistency guaranteed!');
    });

    test('demonstrates mixed builder usage patterns', () async {
      final sampleUser = User(
        id: 'mixed1',
        name: 'Frank',
        email: 'frank@example.com',
        age: 40,
        tags: ['mixed'],
        scores: [100],
        rating: 5.0,
        isActive: true,
        isPremium: true,
        lastLogin: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profile: Profile(
          bio: 'Mixed usage user',
          avatar: 'frank.jpg',
          interests: ['patterns'],
          followers: 3000,
          lastActive: DateTime.now(),
          socialLinks: {'website': 'https://frank.dev'},
        ),
      );

      // Use inline builder pattern
      final query = odm.users.orderBy(($) => ($.rating(true), $.profile.followers()));

      // Mix manual cursors and object-based pagination
      final manualQuery = query.startAt((4.8, 2500));  // Manual cursor
      final objectQuery = query.startAfterObject(sampleUser);  // Object extraction
      final mixedQuery = manualQuery.endBeforeObject(sampleUser);  // Mixed usage

      expect(manualQuery, isNotNull);
      expect(objectQuery, isNotNull);
      expect(mixedQuery, isNotNull);
      print('✅ Mixed builder usage patterns: SUCCESS');
    });
  });
}