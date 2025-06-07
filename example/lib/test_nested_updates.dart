import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';

/// Test nested update functionality
void main() async {
  print('🎯 Testing Nested Update Functionality');
  
  await testNestedUpdates();
  await testComparisonWithTraditionalWay();
}

/// Test the new nested update methods
Future<void> testNestedUpdates() async {
  print('\n=== Nested Update Methods ===');
  
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('kyle');

  // Create initial user
  final initialProfile = Profile(
    bio: 'Software Developer',
    avatar: 'kyle.jpg',
    socialLinks: {
      'github': 'kyle-dev',
      'twitter': '@kyle_dev',
    },
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
  await userDoc.updateProfile(bio: 'handsome boy');
  print('✅ Updated bio to "handsome boy" using: userDoc.updateProfile(bio: "handsome boy")');

  // 🎯 Test 2: Update multiple nested fields
  print('\n🔥 Test 2: Update multiple nested fields');
  await userDoc.updateProfile(
    bio: 'Handsome Flutter Developer',
    followers: 150,
    avatar: 'kyle_new.jpg',
  );
  print('✅ Updated multiple profile fields at once');

  // 🎯 Test 3: Update nested social links
  print('\n🔥 Test 3: Update nested social links');
  await userDoc.updateProfile(
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
  await userDoc.updateProfile(
    interests: ['flutter', 'dart', 'firebase', 'mobile-dev'],
  );
  print('✅ Updated interests array');

  // 🎯 Test 5: Update nested date field
  print('\n🔥 Test 5: Update nested date field');
  await userDoc.updateProfile(
    lastActive: DateTime.now(),
  );
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
  print('\n=== Comparison: Traditional vs Nested Updates ===');
  
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('comparison_test');

  // Create test user
  final profile = Profile(
    bio: 'Original bio',
    avatar: 'original.jpg',
    socialLinks: {'github': 'original'},
    interests: ['original'],
    followers: 50,
  );

  await userDoc.set(User(
    id: 'comparison_test',
    name: 'Test User',
    email: 'test@example.com',
    age: 30,
    profile: profile,
    rating: 3.0,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  ));

  print('\n❌ Traditional Way (Verbose & Error-Prone):');
  print('```dart');
  print('// Traditional Firestore way');
  print('await userDoc.updateFields({');
  print('  "profile.bio": "Updated bio",');
  print('  "profile.followers": 75,');
  print('  "profile.avatar": "new.jpg",');
  print('});');
  print('```');

  // Traditional way
  await userDoc.updateFields({
    'profile.bio': 'Updated via traditional way',
    'profile.followers': 75,
    'profile.avatar': 'traditional.jpg',
  });
  print('✅ Updated using traditional updateFields()');

  print('\n✅ New Nested Way (Clean & Type-Safe):');
  print('```dart');
  print('// New nested update way');
  print('await userDoc.updateProfile(');
  print('  bio: "Updated bio",');
  print('  followers: 100,');
  print('  avatar: "new.jpg",');
  print(');');
  print('```');

  // New nested way
  await userDoc.updateProfile(
    bio: 'Updated via nested method',
    followers: 100,
    avatar: 'nested.jpg',
  );
  print('✅ Updated using new updateProfile() method');

  print('\n🎯 Benefits of Nested Updates:');
  print('  ✅ Type Safety: Compile-time checking of field names and types');
  print('  ✅ Auto-completion: IDE provides field suggestions');
  print('  ✅ Cleaner Syntax: No string literals for field paths');
  print('  ✅ Refactoring Safe: Renames are automatically handled');
  print('  ✅ Less Error-Prone: No typos in field paths');
  print('  ✅ Better Documentation: Method signatures are self-documenting');
}

/// Advanced nested update patterns
Future<void> testAdvancedPatterns() async {
  print('\n=== Advanced Nested Update Patterns ===');
  
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('advanced_test');

  // Create user
  await userDoc.set(User(
    id: 'advanced_test',
    name: 'Advanced User',
    email: 'advanced@example.com',
    age: 28,
    profile: Profile(
      bio: 'Advanced user',
      avatar: 'advanced.jpg',
      socialLinks: {},
      interests: [],
      followers: 0,
    ),
    rating: 4.0,
    isActive: true,
    isPremium: true,
    createdAt: DateTime.now(),
  ));

  print('\n🔥 Pattern 1: Conditional nested updates');
  // Example of conditional updates
  await userDoc.updateProfile(
    bio: 'Conditionally updated bio',
  );
  print('✅ Conditional nested updates completed');

  print('\n🔥 Pattern 2: Incremental nested updates');
  // Get current state
  final currentUser = await userDoc.get();
  if (currentUser != null) {
    // Increment followers
    await userDoc.updateProfile(
      followers: currentUser.profile.followers + 10,
    );
    print('✅ Incremented followers from ${currentUser.profile.followers} to ${currentUser.profile.followers + 10}');
  }

  print('\n🔥 Pattern 3: Combining top-level and nested updates');
  // Update both top-level and nested fields
  await userDoc.update(
    name: 'Updated Advanced User',
    age: 29,
  );
  
  await userDoc.updateProfile(
    bio: 'Updated in combination with top-level fields',
    lastActive: DateTime.now(),
  );
  print('✅ Combined top-level and nested updates');

  print('\n🔥 Pattern 4: Null value handling');
  await userDoc.updateProfile(
    lastActive: null, // Remove the field
  );
  print('✅ Set nested field to null (removes field)');
}

/// Real-world usage examples
Future<void> realWorldExamples() async {
  print('\n=== Real-World Usage Examples ===');
  
  final odm = FirestoreODM();

  print('\n📱 Example 1: Social Media Profile Update');
  final socialUserDoc = odm.users.doc('social_user');
  
  // User updates their social media profile
  await socialUserDoc.updateProfile(
    bio: '🚀 Flutter Developer | 📱 Mobile App Enthusiast | ☕ Coffee Lover',
    socialLinks: {
      'github': 'flutter-dev',
      'twitter': '@flutter_dev',
      'linkedin': 'flutter-developer',
      'website': 'https://flutter-dev.com',
    },
    interests: ['Flutter', 'Dart', 'Mobile Development', 'UI/UX', 'Open Source'],
  );
  print('✅ Social media profile updated');

  print('\n🎮 Example 2: Gaming Profile Update');
  final gamerDoc = odm.users.doc('gamer');
  
  // Gamer gains followers and updates bio
  await gamerDoc.updateProfile(
    bio: '🎮 Pro Gamer | 🏆 Tournament Winner | 📺 Streamer',
    followers: 1500,
    avatar: 'gamer_champion.jpg',
    interests: ['Gaming', 'Streaming', 'Esports', 'Content Creation'],
  );
  print('✅ Gaming profile updated');

  print('\n💼 Example 3: Professional Profile Update');
  final professionalDoc = odm.users.doc('professional');
  
  // Professional updates their work profile
  await professionalDoc.updateProfile(
    bio: '💼 Senior Software Engineer at TechCorp | 🎓 Computer Science PhD',
    socialLinks: {
      'linkedin': 'senior-software-engineer',
      'github': 'tech-professional',
      'website': 'https://professional-portfolio.com',
    },
    interests: ['Software Architecture', 'Machine Learning', 'Cloud Computing'],
    lastActive: DateTime.now(),
  );
  print('✅ Professional profile updated');
}