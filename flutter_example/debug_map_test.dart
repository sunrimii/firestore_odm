import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() async {
  final fakeFirestore = FakeFirebaseFirestore();
  final odm = FirestoreODM(testSchema, firestore: fakeFirestore);

  // Create a test user with specific settings
  final user = User(
    id: 'test-user',
    name: 'Map User',
    email: 'map@example.com',
    age: 30,
    isActive: true,
    profile: Profile(
      bio: 'Test bio',
      avatar: 'avatar.jpg',
      socialLinks: {'github': 'test-user'},
      interests: ['maps'],
      followers: 100,
      lastActive: DateTime.now(),
      story: null,
    ),
    settings: {'theme': 'auto', 'notifications': 'enabled'},
    metadata: {'version': '1.0'},
    tags: [],
    rating: 4.0,
    createdAt: DateTime.now(),
  );

  await odm.users(user.id).update(user);
  print('✅ Created user with settings: ${user.settings}');

  // Test 1: Check what's actually stored
  final stored = await odm.users(user.id).get();
  print('📋 Stored user settings: ${stored?.settings}');

  // Test 2: Try exact map equality
  print('🧪 Testing exact map equality...');
  final exactMatch = await odm.users
      .where(
        ($) => $.settings(
          isEqualTo: {'theme': 'auto', 'notifications': 'enabled'},
        ),
      )
      .get();

  print('📊 Exact match results: ${exactMatch.length}');
  if (exactMatch.isNotEmpty) {
    print('✅ Found matching user: ${exactMatch.first.name}');
  } else {
    print('❌ No matching users found');
  }

  // Test 3: Try individual key access (which should work)
  print('🔑 Testing key access...');
  final keyMatch = await odm.users
      .where(($) => $.settings.key('theme')(isEqualTo: 'auto'))
      .get();

  print('📊 Key access results: ${keyMatch.length}');
  if (keyMatch.isNotEmpty) {
    print('✅ Found user by key access: ${keyMatch.first.name}');
  } else {
    print('❌ No users found by key access');
  }
}
