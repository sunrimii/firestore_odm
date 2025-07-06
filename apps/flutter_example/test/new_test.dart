import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:test/test.dart';

void main() {
  group('Batch Nested Operations Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(firestore: fakeFirestore);
    });

    
    group('📝 CRUD Operations', () {
      test('should create and retrieve a user', () async {
        final user = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 30,
          profile: const Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users('test_user').update(user);
        final retrieved = await odm.users.doc('test_user').patch(($) => [
          $.isPremium(true),
          $.lastLogin.serverTimestamp()
        ]);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('test_user'));
        expect(retrieved.name, equals('Test User'));
        expect(retrieved.email, equals('test@example.com'));
      });
  });
}
