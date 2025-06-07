import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Firestore Update Behavior Test', () {
    test('should test direct Firestore update with nested objects', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('test').doc('test_doc');

      // Set initial data
      await docRef.set({
        'profile': {
          'socialLinks': {'github': 'user123'},
          'name': 'Test User',
        },
      });

      print('Initial data: ${(await docRef.get()).data()}');

      // Try to update nested field
      await docRef.update({
        'profile': {'socialLinks': <String, String>{}, 'name': 'Test User'},
      });

      print('After update: ${(await docRef.get()).data()}');

      // Try with dot notation
      await docRef.update({'profile.socialLinks': <String, String>{}});

      print('After dot notation update: ${(await docRef.get()).data()}');

      // Try with set + merge
      await docRef.set({
        'profile': {'socialLinks': <String, String>{}, 'name': 'Test User'},
      }, SetOptions(merge: true));

      print('After set with merge: ${(await docRef.get()).data()}');
    });
  });
}
