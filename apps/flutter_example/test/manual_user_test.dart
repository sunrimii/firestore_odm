import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/manual_user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManualUser ODM Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test(
      'should create and save ManualUser with manual serialization',
      () async {
        // Create a ManualUser instance
        const user = ManualUser(
          id: 'manual123',
          name: 'John Manual',
          email: 'john@manual.com',
          age: 30,
          isPremium: true,
          rating: 85.5,
          tags: ['manual', 'test', 'user'],
          debugInfo: 'This should not be saved',
        );

        // Save to Firestore
        await odm.manualUsers(user.id).update(user);

        // Verify the document was saved
        final retrieved = await odm.manualUsers(user.id).get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('John Manual'));
        expect(retrieved.email, equals('john@manual.com'));
        expect(retrieved.age, equals(30));
        expect(retrieved.isPremium, equals(true));
        expect(retrieved.rating, equals(85.5));
        expect(retrieved.tags, equals(['manual', 'test', 'user']));
      },
    );

    test('should respect custom field names in manual toJson', () async {
      const user = ManualUser(
        id: 'manual456',
        name: 'Jane Manual',
        email: 'jane@manual.com',
        age: 25,
        rating: 92.3,
        tags: ['flutter', 'dart'],
        debugInfo: 'Debug information',
      );

      await odm.manualUsers(user.id).update(user);

      // Check the raw Firestore data to verify custom field mapping
      final rawDoc = await firestore
          .collection('manualUsers')
          .doc(user.id)
          .get();
      final rawData = rawDoc.data()!;

      // Verify custom field names from manual toJson implementation
      expect(rawData['full_name'], equals('Jane Manual')); // name -> full_name
      expect(
        rawData['contact_email'],
        equals('jane@manual.com'),
      ); // email -> contact_email
      expect(rawData['user_age'], equals(25)); // age -> user_age
      expect(
        rawData['premium_member'],
        equals(false),
      ); // isPremium -> premium_member
      expect(rawData['user_rating'], equals(92.3)); // rating -> user_rating
      expect(
        rawData['user_tags'],
        equals(['flutter', 'dart']),
      ); // tags -> user_tags

      // Verify debugInfo is not saved (not included in toJson)
      expect(rawData.containsKey('debugInfo'), isFalse);
      expect(rawData.containsKey('debug_info'), isFalse);
    });

    test('should deserialize correctly with manual fromJson', () async {
      // Create raw Firestore data with custom field names
      final rawData = {
        'id': 'manual789',
        'full_name': 'Bob Manual', // Custom field name
        'contact_email': 'bob@manual.com', // Custom field name
        'user_age': 35, // Custom field name
        'premium_member': true, // Custom field name
        'user_rating': 78.9, // Custom field name
        'user_tags': ['backend', 'api'], // Custom field name
      };

      await firestore.collection('manualUsers').doc('manual789').set(rawData);

      // Retrieve using ODM
      final user = await odm.manualUsers('manual789').get();
      expect(user, isNotNull);

      expect(user!.id, equals('manual789'));
      expect(user.name, equals('Bob Manual'));
      expect(user.email, equals('bob@manual.com'));
      expect(user.age, equals(35));
      expect(user.isPremium, equals(true));
      expect(user.rating, equals(78.9));
      expect(user.tags, equals(['backend', 'api']));
      expect(user.debugInfo, isNull); // Default value
    });

    test('should handle missing fields with default values', () async {
      // Create minimal data without optional fields
      final rawData = {
        'id': 'manual999',
        'full_name': 'Minimal User',
        'contact_email': 'minimal@manual.com',
        'user_age': 20,
      };

      await firestore.collection('manualUsers').doc('manual999').set(rawData);

      final user = await odm.manualUsers('manual999').get();
      expect(user, isNotNull);

      // Verify default values are applied in manual fromJson
      expect(user!.isPremium, equals(false)); // Default value
      expect(user.rating, equals(0.0)); // Default value
      expect(user.tags, equals(<String>[])); // Default value
      expect(user.debugInfo, isNull); // Default value
    });

    test('should support querying on custom field names', () async {
      // Create test users
      final users = [
        const ManualUser(
          id: 'verified1',
          name: 'Verified User 1',
          email: 'verified1@manual.com',
          age: 30,
          isPremium: true,
          rating: 95,
          tags: ['premium'],
          debugInfo: 'Debug 1',
        ),
        const ManualUser(
          id: 'unverified1',
          name: 'Unverified User 1',
          email: 'unverified1@manual.com',
          age: 25,
          rating: 70,
          tags: ['basic'],
          debugInfo: 'Debug 2',
        ),
      ];

      // Save users
      for (final user in users) {
        await odm.manualUsers(user.id).update(user);
      }

      // Query for verified users - note: we need to query on the actual Firestore field name
      final verifiedQuery = await firestore
          .collection('manualUsers')
          .where('premium_member', isEqualTo: true)
          .get();

      expect(verifiedQuery.docs.length, equals(1));
      expect(verifiedQuery.docs.first.id, equals('verified1'));

      // Query for users with specific tags
      final premiumQuery = await firestore
          .collection('manualUsers')
          .where('user_tags', arrayContains: 'premium')
          .get();

      expect(premiumQuery.docs.length, equals(1));
      expect(premiumQuery.docs.first.id, equals('verified1'));

      // Query by age range
      final ageQuery = await firestore
          .collection('manualUsers')
          .where('user_age', isGreaterThan: 28)
          .get();

      expect(ageQuery.docs.length, equals(1));
      expect(ageQuery.docs.first.id, equals('verified1'));
    });

    test('should work with copyWith method', () async {
      const originalUser = ManualUser(
        id: 'copy_manual',
        name: 'Original Manual',
        email: 'original@manual.com',
        age: 30,
        rating: 75,
        tags: ['original'],
        debugInfo: 'Original debug',
      );

      await odm.manualUsers(originalUser.id).update(originalUser);

      // Create updated user using copyWith
      final updatedUser = originalUser.copyWith(
        name: 'Updated Manual',
        isPremium: true,
        rating: 90,
      );

      await odm.manualUsers(updatedUser.id).update(updatedUser);

      // Verify the update
      final user = await odm.manualUsers('copy_manual').get();
      expect(user, isNotNull);

      expect(user!.name, equals('Updated Manual'));
      expect(user.email, equals('original@manual.com')); // Unchanged
      expect(user.isPremium, equals(true)); // Changed
      expect(user.rating, equals(90.0)); // Changed
      expect(user.tags, equals(['original'])); // Unchanged
    });

    test('should handle round-trip serialization correctly', () async {
      const originalUser = ManualUser(
        id: 'roundtrip_test',
        name: 'Round Trip User',
        email: 'roundtrip@manual.com',
        age: 28,
        isPremium: true,
        rating: 88.8,
        tags: ['test', 'roundtrip', 'manual'],
        debugInfo: 'This will be lost',
      );

      // Save and retrieve
      await odm.manualUsers(originalUser.id).update(originalUser);
      final retrieved = await odm.manualUsers(originalUser.id).get();

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(originalUser.id));
      expect(retrieved.name, equals(originalUser.name));
      expect(retrieved.email, equals(originalUser.email));
      expect(retrieved.age, equals(originalUser.age));
      expect(retrieved.isPremium, equals(originalUser.isPremium));
      expect(retrieved.rating, equals(originalUser.rating));
      expect(retrieved.tags, equals(originalUser.tags));

      // debugInfo should be default value since it's not serialized
      expect(retrieved.debugInfo, isNull);
    });
  });
}
