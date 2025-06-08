import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  test('Test fake_cloud_firestore nested array operations', () async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('test').doc('doc1');
    
    // Set initial data
    await docRef.set({
      'tags': ['beginner'],
      'profile': {
        'interests': ['coding'],
        'bio': 'test bio',
      }
    });
    
    // Test top-level array operation
    await docRef.update({
      'tags': FieldValue.arrayUnion(['expert']),
    });
    
    // Test nested array operation
    await docRef.update({
      'profile.interests': FieldValue.arrayUnion(['design']),
    });
    
    final doc = await docRef.get();
    final data = doc.data()!;
    
    print('Final data: $data');
    print('Tags: ${data['tags']}');
    print('Profile.interests: ${(data['profile'] as Map)['interests']}');
  });
}