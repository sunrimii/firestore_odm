import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';

/// Test nested field updates using the new chained API
void main() async {
  print('🔥 Testing Nested Field Updates with Chained API');

  await testBasicNestedUpdates();
  await testComparisonWithTraditionalWay();
  await testAdvancedNestedUpdates();
  await testRealWorldScenarios();
}

/// Test basic nested field updates
Future<void> testBasicNestedUpdates() async {
  print('\n=== Basic Nested Updates ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('kyle');

  // Create initial user with profile
  final initialProfile = Profile(
    bio: 'Software Developer',
    avatar: 'kyle.jpg',
    socialLinks: {'github': 'kyle-dev', 'twitter': '@kyle_dev'},
    interests: ['coding', 'gaming'],
    followers: 100,
    lastActive: DateTime.now().subtract(Duration(hours: 2)),
  );

  final user = User(
    id: 'kyle',
    name: 'Kyle',
    email: 'kyle@example.com',
    age: 25,
    profile: initialProfile,
    rating: 4.2,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now().subtract(Duration(days: 10)),
  );

  await userDoc.set(user);
  print('✅ Created initial user with profile');

  // 🎯 Test 1: Update single nested field
  print('\n🔥 Test 1: Update single nested field');
  await userDoc.update.profile(bio: 'handsome boy');
  print('✅ Updated bio using: userDoc.update.profile(bio: "handsome boy")');

  // 🎯 Test 2: Update multiple nested fields
  print('\n🔥 Test 2: Update multiple nested fields');
  await userDoc.update.profile(
    bio: 'Handsome Flutter Developer',
    followers: 150,
    avatar: 'kyle_new.jpg',
  );
  print('✅ Updated multiple profile fields at once');

  // 🎯 Test 3: Update nested social links
  print('\n🔥 Test 3: Update nested social links');
  await userDoc.update.profile(
    socialLinks: {
      'github': 'kyle-flutter',
      'twitter': '@kyle_flutter',
      'linkedin': 'kyle-developer',
      'instagram': '@kyle_photos',
    },
  );
  print('✅ Updated social links map');

  // 🎯 Test 4: Update nested interests array
  print('\n🔥 Test 4: Update nested interests array');
  await userDoc.update.profile(
    interests: ['flutter', 'dart', 'firebase', 'mobile-dev'],
  );
  print('✅ Updated interests array');

  // 🎯 Test 5: Update nested date field
  print('\n🔥 Test 5: Update nested date field');
  await userDoc.update.profile(lastActive: DateTime.now());
  print('✅ Updated lastActive timestamp');

  // Verify the final state
  final updatedUser = await userDoc.get();
  if (updatedUser != null) {
    print('\n📊 Final Profile State:');
    print('  Bio: ${updatedUser.profile.bio}');
    print('  Followers: ${updatedUser.profile.followers}');
    print('  Avatar: ${updatedUser.profile.avatar}');
    print('  Social Links: ${updatedUser.profile.socialLinks}');
    print('  Interests: ${updatedUser.profile.interests}');
    print('  Last Active: ${updatedUser.profile.lastActive}');
  }
}

/// Compare with traditional update methods
Future<void> testComparisonWithTraditionalWay() async {
  print('\n=== Comparison: Traditional vs Chained Updates ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('comparison_test');

  // Create test user
  final profile = Profile(
    bio: 'Original bio',
    avatar: 'original.jpg',
    socialLinks: {'github': 'original'},
    interests: ['original'],
    followers: 0,
  );

  final user = User(
    id: 'comparison_test',
    name: 'Test User',
    email: 'test@example.com',
    age: 30,
    profile: profile,
    rating: 3.0,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  );

  await userDoc.set(user);

  print('\n❌ Traditional Firestore Way (Error-Prone):');
  print('await userDoc.updateFields({');
  print('  "profile.bio": "Updated via traditional way",');
  print('  "profile.followers": 200,');
  print('});');

  await userDoc.updateFields({
    'profile.bio': 'Updated via traditional way',
    'profile.followers': 200,
  });
  print('✅ Updated using traditional updateFields');

  print('\n✅ New Chained API (Type-Safe & Clean):');
  print('await userDoc.update.profile(');
  print('  bio: "Updated via chained API",');
  print('  followers: 300,');
  print(');');

  await userDoc.update.profile(bio: 'Updated via chained API', followers: 300);
  print('✅ Updated using chained API');

  print('\n🎯 Benefits of Chained API:');
  print('  ✅ Full type safety');
  print('  ✅ Auto-completion');
  print('  ✅ Compile-time validation');
  print('  ✅ Refactoring safe');
  print('  ✅ No string literals');
  print('  ✅ Clean syntax');
}

/// Test advanced nested update scenarios
Future<void> testAdvancedNestedUpdates() async {
  print('\n=== Advanced Nested Updates ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('advanced_test');

  // Create user with complex nested data
  final profile = Profile(
    bio: 'Advanced test user',
    avatar: 'advanced.jpg',
    socialLinks: {'github': 'advanced-user', 'twitter': '@advanced_user'},
    interests: ['testing', 'advanced-features'],
    followers: 500,
    lastActive: DateTime.now().subtract(Duration(minutes: 30)),
  );

  final user = User(
    id: 'advanced_test',
    name: 'Advanced User',
    email: 'advanced@example.com',
    age: 28,
    profile: profile,
    rating: 4.8,
    isActive: true,
    isPremium: true,
    createdAt: DateTime.now().subtract(Duration(days: 30)),
  );

  await userDoc.set(user);

  // Test conditional updates
  print('\n🔥 Test: Conditional Updates');
  final currentUser = await userDoc.get();
  if (currentUser != null && currentUser.profile.followers < 1000) {
    await userDoc.update.profile(bio: 'Conditionally updated bio');
    print('✅ Conditionally updated profile based on current state');
  }

  // Test incremental updates
  print('\n🔥 Test: Incremental Updates');
  final userForIncrement = await userDoc.get();
  if (userForIncrement != null) {
    await userDoc.update.profile(
      followers: userForIncrement.profile.followers + 10,
    );
    print('✅ Incrementally updated followers count');
  }

  // Test complex data updates
  print('\n🔥 Test: Complex Data Updates');
  await userDoc.update.profile(
    socialLinks: {
      'github': 'advanced-github',
      'twitter': '@advanced_twitter',
      'linkedin': 'advanced-linkedin',
      'youtube': 'advanced-youtube',
      'website': 'https://advanced-user.dev',
    },
  );

  await userDoc.update.profile(
    interests: [
      'flutter',
      'dart',
      'firebase',
      'mobile-development',
      'web-development',
      'backend-development',
    ],
  );
  print('✅ Updated complex nested data structures');
}

/// Test real-world usage scenarios
Future<void> testRealWorldScenarios() async {
  print('\n=== Real-World Scenarios ===');

  final odm = FirestoreODM();

  // Scenario 1: Social Media Profile Update
  print('\n📱 Scenario 1: Social Media Profile Update');
  final socialUserDoc = odm.users.doc('social_user');

  await socialUserDoc.update.profile(
    bio: '🚀 Flutter Developer | 📱 Mobile Expert | 🎯 Tech Enthusiast',
    socialLinks: {
      'github': 'flutter-expert',
      'twitter': '@flutter_expert',
      'linkedin': 'flutter-expert-dev',
      'instagram': '@flutter_photos',
      'youtube': 'flutter-tutorials',
    },
    interests: [
      'flutter',
      'mobile-development',
      'ui-ux',
      'open-source',
      'tech-talks',
    ],
  );
  print('✅ Social media profile updated');

  // Scenario 2: Gaming Profile Update
  print('\n🎮 Scenario 2: Gaming Profile Update');
  final gamerDoc = odm.users.doc('gamer_user');

  await gamerDoc.update.profile(
    bio: '🎮 Pro Gamer | 🏆 Tournament Winner | 🎯 Streaming',
    avatar: 'gamer_avatar.jpg',
    interests: [
      'gaming',
      'esports',
      'streaming',
      'game-development',
      'tournaments',
    ],
    followers: 5000,
  );
  print('✅ Gaming profile updated');

  // Scenario 3: Professional Profile Update
  print('\n💼 Scenario 3: Professional Profile Update');
  final professionalDoc = odm.users.doc('professional_user');

  await professionalDoc.update.profile(
    bio: '💼 Senior Software Engineer | 🚀 Tech Lead | 📈 Startup Advisor',
    socialLinks: {
      'linkedin': 'senior-engineer',
      'github': 'tech-lead',
      'website': 'https://professional-dev.com',
      'medium': '@tech-articles',
    },
    interests: [
      'software-architecture',
      'team-leadership',
      'startup-consulting',
      'technical-writing',
      'mentoring',
    ],
  );
  print('✅ Professional profile updated');

  print('\n🎯 All real-world scenarios completed successfully!');
}
