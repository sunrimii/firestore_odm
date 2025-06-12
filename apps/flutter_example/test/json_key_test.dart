import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/json_key_user.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔑 JsonKey Annotation Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should rename fields using @JsonKey(name) annotation', () async {
      // Create user with JsonKey annotations
      final user = JsonKeyUser(
        id: 'json_key_user_1',
        name: 'Bob JsonKey',
        email: 'bob@jsonkey.com',
        age: 32,
        isPremium: true,
        rating: 4.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['flutter', 'json', 'annotations'],
      );

      // Save to Firestore
      await odm.jsonKeyUsers(user.id).update(user);

      // Check raw data in FakeFirebaseFirestore to verify field names are renamed
      final rawDoc = await fakeFirestore
          .collection('jsonKeyUsers')
          .doc(user.id)
          .get();

      expect(rawDoc.exists, isTrue);
      final rawData = rawDoc.data()!;

      // Verify that field names are correctly renamed in JSON
      expect(
        rawData.containsKey('email_address'),
        isTrue,
        reason: 'email field should be renamed to email_address',
      );
      expect(
        rawData.containsKey('user_age'),
        isTrue,
        reason: 'age field should be renamed to user_age',
      );
      expect(
        rawData.containsKey('is_premium_member'),
        isTrue,
        reason: 'isPremium field should be renamed to is_premium_member',
      );
      expect(
        rawData.containsKey('account_rating'),
        isTrue,
        reason: 'rating field should be renamed to account_rating',
      );
      expect(
        rawData.containsKey('created_timestamp'),
        isTrue,
        reason: 'createdAt field should be renamed to created_timestamp',
      );
      expect(
        rawData.containsKey('last_updated'),
        isTrue,
        reason: 'updatedAt field should be renamed to last_updated',
      );

      // Verify that original field names are NOT present
      expect(
        rawData.containsKey('email'),
        isFalse,
        reason: 'Original email field should not exist',
      );
      expect(
        rawData.containsKey('age'),
        isFalse,
        reason: 'Original age field should not exist',
      );
      expect(
        rawData.containsKey('isPremium'),
        isFalse,
        reason: 'Original isPremium field should not exist',
      );
      expect(
        rawData.containsKey('rating'),
        isFalse,
        reason: 'Original rating field should not exist',
      );
      expect(
        rawData.containsKey('createdAt'),
        isFalse,
        reason: 'Original createdAt field should not exist',
      );
      expect(
        rawData.containsKey('updatedAt'),
        isFalse,
        reason: 'Original updatedAt field should not exist',
      );

      // Verify the actual values
      expect(rawData['email_address'], equals('bob@jsonkey.com'));
      expect(rawData['user_age'], equals(32));
      expect(rawData['is_premium_member'], equals(true));
      expect(rawData['account_rating'], equals(4.5));

      print('✅ Field renaming verified:');
      print('   email -> email_address: ${rawData['email_address']}');
      print('   age -> user_age: ${rawData['user_age']}');
      print(
        '   isPremium -> is_premium_member: ${rawData['is_premium_member']}',
      );
      print('   rating -> account_rating: ${rawData['account_rating']}');
    });

    test(
      'should ignore fields with @JsonKey(includeFromJson: false, includeToJson: false)',
      () async {
        // Create user with secretField (which should be ignored)
        final user = JsonKeyUser(
          id: 'json_key_user_2',
          name: 'Alice Secret',
          email: 'alice@secret.com',
          age: 28,
          secretField: 'This should not be saved',
          isPremium: false,
          rating: 3.8,
          tags: ['secret', 'test'],
        );

        // Save to Firestore
        await odm.jsonKeyUsers(user.id).update(user);

        // Check raw data to verify secretField is ignored
        final rawDoc = await fakeFirestore
            .collection('jsonKeyUsers')
            .doc(user.id)
            .get();

        expect(rawDoc.exists, isTrue);
        final rawData = rawDoc.data()!;

        // Verify that secretField is NOT present in the saved data
        expect(
          rawData.containsKey('secretField'),
          isFalse,
          reason: 'secretField should be ignored and not saved',
        );

        // Verify other fields are present
        expect(rawData.containsKey('name'), isTrue);
        expect(rawData.containsKey('email_address'), isTrue);
        expect(rawData['name'], equals('Alice Secret'));

        print('✅ Field ignoring verified:');
        print('   secretField is not present in saved data');
        print('   Other fields saved correctly: name = ${rawData['name']}');
      },
    );

    test('should retrieve and deserialize JsonKey user correctly', () async {
      // Create user and save to Firestore
      final originalUser = JsonKeyUser(
        id: 'json_key_user_3',
        name: 'Charlie Deserialize',
        email: 'charlie@deserialize.com',
        age: 35,
        isPremium: true,
        rating: 4.9,
        createdAt: DateTime.now(),
        tags: ['deserialize', 'test', 'json'],
      );

      await odm.jsonKeyUsers(originalUser.id).update(originalUser);

      // Retrieve using ODM
      final retrievedUser = await odm.jsonKeyUsers(originalUser.id).get();

      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(originalUser.id));
      expect(retrievedUser.name, equals(originalUser.name));
      expect(retrievedUser.email, equals(originalUser.email));
      expect(retrievedUser.age, equals(originalUser.age));
      expect(retrievedUser.isPremium, equals(originalUser.isPremium));
      expect(retrievedUser.rating, equals(originalUser.rating));
      expect(retrievedUser.tags, equals(originalUser.tags));

      // Verify secretField is null (since it's ignored)
      expect(
        retrievedUser.secretField,
        isNull,
        reason: 'secretField should be null when retrieved',
      );

      print('✅ Deserialization verified:');
      print('   Retrieved user: ${retrievedUser.name}');
      print('   Email: ${retrievedUser.email}');
      print('   Age: ${retrievedUser.age}');
      print('   Premium: ${retrievedUser.isPremium}');
      print('   Rating: ${retrievedUser.rating}');
      print('   Secret field: ${retrievedUser.secretField} (should be null)');
    });

    test('should handle JsonKey annotations in queries', () async {
      // Create multiple users with different premium status
      final users = [
        JsonKeyUser(
          id: 'premium_user_1',
          name: 'Premium User 1',
          email: 'premium1@test.com',
          age: 30,
          isPremium: true,
          rating: 4.8,
          tags: ['premium'],
        ),
        JsonKeyUser(
          id: 'premium_user_2',
          name: 'Premium User 2',
          email: 'premium2@test.com',
          age: 25,
          isPremium: true,
          rating: 4.9,
          tags: ['premium'],
        ),
        JsonKeyUser(
          id: 'regular_user_1',
          name: 'Regular User 1',
          email: 'regular1@test.com',
          age: 28,
          isPremium: false,
          rating: 3.5,
          tags: ['regular'],
        ),
      ];

      // Save all users
      for (final user in users) {
        await odm.jsonKeyUsers(user.id).update(user);
      }

      // Query for premium users using the renamed field
      final premiumUsers = await odm.jsonKeyUsers
          .where(($) => $.isPremium(isEqualTo: true))
          .get();

      expect(premiumUsers.length, equals(2));
      expect(premiumUsers.every((user) => user.isPremium), isTrue);

      // Query by age range using the renamed field
      final youngUsers = await odm.jsonKeyUsers
          .where(($) => $.age(isLessThan: 30))
          .get();

      expect(youngUsers.length, equals(2)); // ages 25 and 28
      expect(youngUsers.every((user) => user.age < 30), isTrue);

      print('✅ Query operations verified:');
      print('   Premium users found: ${premiumUsers.length}');
      print('   Young users found: ${youngUsers.length}');
      print('   Premium users: ${premiumUsers.map((u) => u.name).join(', ')}');
      print(
        '   Young users: ${youngUsers.map((u) => '${u.name} (${u.age})').join(', ')}',
      );
    });
  });
}
