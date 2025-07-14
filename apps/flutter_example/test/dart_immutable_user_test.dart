import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/dart_immutable_user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartImmutableUser ODM Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test(
      'should create and save DartImmutableUser with json_serializable',
      () async {
        // Create a DartImmutableUser instance
        const user = DartImmutableUser(
          id: 'user123',
          name: 'John Doe',
          email: 'john@example.com',
          age: 30,
          isPremium: true,
          rating: 4.5,
          skills: ['Flutter', 'Dart', 'Firebase'],
          internalNotes: 'This should be ignored',
        );

        // Save to Firestore
        await odm.dartImmutableUsers(user.id).update(user);

        // Verify the document was saved
        final retrieved = await odm.dartImmutableUsers(user.id).get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('John Doe'));
        expect(retrieved.email, equals('john@example.com'));
        expect(retrieved.age, equals(30));
        expect(retrieved.isPremium, equals(true));
        expect(retrieved.rating, equals(4.5));
        expect(retrieved.skills, equals(['Flutter', 'Dart', 'Firebase']));
      },
    );

    test('should respect @JsonKey annotations for field mapping', () async {
      const user = DartImmutableUser(
        id: 'user456',
        name: 'Jane Smith',
        email: 'jane@example.com',
        age: 25,
        rating: 3.8,
        skills: ['React', 'JavaScript'],
        internalNotes: 'Internal note',
      );

      await odm.dartImmutableUsers(user.id).update(user);

      // Check the raw Firestore data to verify field mapping
      final rawDoc = await firestore
          .collection('dartImmutableUsers')
          .doc(user.id)
          .get();
      final rawData = rawDoc.data()!;

      // Verify @JsonKey mappings
      expect(
        rawData['user_email'],
        equals('jane@example.com'),
      ); // email -> user_email
      expect(
        rawData['premium_status'],
        equals(false),
      ); // isPremium -> premium_status
      expect(
        rawData['skill_tags'],
        equals(['React', 'JavaScript']),
      ); // skills -> skill_tags

      // Verify @JsonKey(includeFromJson: false, includeToJson: false) works
      expect(rawData.containsKey('internalNotes'), isFalse);
      expect(rawData.containsKey('internal_notes'), isFalse);
    });

    test('should deserialize correctly with @JsonKey mappings', () async {
      // Create raw Firestore data with custom field names
      final rawData = {
        'id': 'user789',
        'name': 'Bob Wilson',
        'user_email': 'bob@example.com', // Custom field name
        'age': 35,
        'premium_status': true, // Custom field name
        'rating': 4.2,
        'skill_tags': ['Python', 'Django'], // Custom field name
      };

      await firestore
          .collection('dartImmutableUsers')
          .doc('user789')
          .set(rawData);

      // Retrieve using ODM
      final user = await odm.dartImmutableUsers('user789').get();
      expect(user, isNotNull);
      expect(user!.id, equals('user789'));
      expect(user.name, equals('Bob Wilson'));
      expect(user.email, equals('bob@example.com'));
      expect(user.age, equals(35));
      expect(user.isPremium, equals(true));
      expect(user.rating, equals(4.2));
      expect(user.skills, equals(['Python', 'Django']));
      expect(user.internalNotes, isNull); // Default value
    });

    test('should handle default values correctly', () async {
      // Create minimal data without optional fields
      final rawData = {
        'id': 'user999',
        'name': 'Minimal User',
        'user_email': 'minimal@example.com',
        'age': 20,
      };

      await firestore
          .collection('dartImmutableUsers')
          .doc('user999')
          .set(rawData);

      final user = await odm.dartImmutableUsers('user999').get();
      expect(user, isNotNull);

      // Verify default values are applied
      expect(user!.isPremium, equals(false)); // Default from @JsonKey
      expect(user.rating, equals(0.0)); // Default from @JsonKey
      expect(user.skills, equals(<String>[])); // Default from @JsonKey
      expect(user.internalNotes, isNull); // Default from constructor
    });

    test('should support querying on renamed fields', () async {
      // Create test users
      final users = [
        const DartImmutableUser(
          id: 'premium1',
          name: 'Premium User 1',
          email: 'premium1@example.com',
          age: 30,
          isPremium: true,
          rating: 4.5,
          skills: ['Flutter'],
          internalNotes: 'Note 1',
        ),
        const DartImmutableUser(
          id: 'regular1',
          name: 'Regular User 1',
          email: 'regular1@example.com',
          age: 25,
          rating: 3,
          skills: ['HTML'],
          internalNotes: 'Note 2',
        ),
      ];

      // Save users
      for (final user in users) {
        await odm.dartImmutableUsers(user.id).update(user);
      }

      // Query for premium users - note: we need to query on the actual Firestore field name
      final premiumQuery = await firestore
          .collection('dartImmutableUsers')
          .where('premium_status', isEqualTo: true)
          .get();

      expect(premiumQuery.docs.length, equals(1));
      expect(premiumQuery.docs.first.id, equals('premium1'));

      // Query for users with specific skills
      final flutterQuery = await firestore
          .collection('dartImmutableUsers')
          .where('skill_tags', arrayContains: 'Flutter')
          .get();

      expect(flutterQuery.docs.length, equals(1));
      expect(flutterQuery.docs.first.id, equals('premium1'));
    });

    test('should work with copyWith method', () async {
      const originalUser = DartImmutableUser(
        id: 'copy_test',
        name: 'Original Name',
        email: 'original@example.com',
        age: 30,
        rating: 3,
        skills: ['Dart'],
        internalNotes: 'Original note',
      );

      await odm.dartImmutableUsers(originalUser.id).update(originalUser);

      // Create updated user using copyWith
      final updatedUser = originalUser.copyWith(
        name: 'Updated Name',
        isPremium: true,
        rating: 4.5,
      );

      await odm.dartImmutableUsers(updatedUser.id).update(updatedUser);

      // Verify the update
      final user = await odm.dartImmutableUsers('copy_test').get();
      expect(user, isNotNull);

      expect(user!.name, equals('Updated Name'));
      expect(user.email, equals('original@example.com')); // Unchanged
      expect(user.isPremium, equals(true)); // Changed
      expect(user.rating, equals(4.5)); // Changed
      expect(user.skills, equals(['Dart'])); // Unchanged
    });
  });
}
