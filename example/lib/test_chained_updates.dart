import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';
import 'models/story.dart';

/// Test the new chained update API similar to copyWith
void main() async {
  print('🔥 Testing Chained Update API (copyWith-style)');
  
  await testBasicChainedUpdates();
  await testDeepNestedUpdates();
  await testRealWorldScenarios();
}

/// Test basic chained updates
Future<void> testBasicChainedUpdates() async {
  print('\n=== Basic Chained Updates ===');
  
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('kyle');

  // Create initial user with nested data
  final coordinates = Coordinates(
    latitude: 37.7749,
    longitude: -122.4194,
    altitude: 10.0,
  );

  final place = Place(
    name: 'San Francisco',
    address: '123 Market St, San Francisco, CA',
    coordinates: coordinates,
    metadata: {'type': 'city', 'population': '884363'},
  );

  final story = Story(
    name: 'My SF Adventure',
    content: 'Amazing day in San Francisco!',
    place: place,
    tags: ['travel', 'adventure'],
    publishedAt: DateTime.now(),
  );

  final profile = Profile(
    bio: 'Software Developer',
    avatar: 'kyle.jpg',
    socialLinks: {
      'github': 'kyle-dev',
      'twitter': '@kyle_dev',
    },
    interests: ['coding', 'travel'],
    followers: 100,
    story: story,
  );

  final user = User(
    id: 'kyle',
    name: 'Kyle',
    email: 'kyle@example.com',
    age: 25,
    profile: profile,
    rating: 4.2,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  );

  await userDoc.set(user);
  print('✅ Created user with deep nested structure');

  // 🎯 Test 1: Top-level updates
  print('\n🔥 Test 1: Top-level field updates');
  await userDoc.update(name: 'Kyle Tse');
  print('✅ users.doc("kyle").update(name: "Kyle Tse")');

  // 🎯 Test 2: First-level nested updates
  print('\n🔥 Test 2: First-level nested updates');
  await userDoc.update.profile(bio: 'handsome boy');
  print('✅ users.doc("kyle").update.profile(bio: "handsome boy")');

  // 🎯 Test 3: Second-level nested updates
  print('\n🔥 Test 3: Second-level nested updates');
  await userDoc.update.profile.story(name: 'story 1');
  print('✅ users.doc("kyle").update.profile.story(name: "story 1")');

  // 🎯 Test 4: Third-level nested updates
  print('\n🔥 Test 4: Third-level nested updates');
  await userDoc.update.profile.story.place(name: 'New York City');
  print('✅ users.doc("kyle").update.profile.story.place(name: "New York City")');

  // 🎯 Test 5: Fourth-level nested updates (deepest level)
  print('\n🔥 Test 5: Fourth-level nested updates');
  await userDoc.update.profile.story.place.coordinates(
    latitude: 40.7128,
    longitude: -74.0060,
  );
  print('✅ users.doc("kyle").update.profile.story.place.coordinates(latitude: 40.7128, longitude: -74.0060)');
}

/// Test deep nested updates with multiple fields
Future<void> testDeepNestedUpdates() async {
  print('\n=== Deep Nested Updates ===');
  
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('deep_test');

  // Create test user
  await userDoc.set(User(
    id: 'deep_test',
    name: 'Deep Test User',
    email: 'deep@example.com',
    age: 30,
    profile: Profile(
      bio: 'Deep test',
      avatar: 'deep.jpg',
      socialLinks: {},
      interests: [],
      followers: 0,
      story: Story(
        name: 'Original Story',
        content: 'Original content',
        place: Place(
          name: 'Original Place',
          address: 'Original Address',
          coordinates: Coordinates(
            latitude: 0.0,
            longitude: 0.0,
          ),
          metadata: {},
        ),
        tags: [],
      ),
    ),
    rating: 3.0,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  ));

  print('\n🔥 Testing multiple field updates at each level:');

  // Update multiple fields at profile level
  await userDoc.update.profile(
    bio: 'Updated deep test user',
    followers: 50,
    avatar: 'updated.jpg',
    socialLinks: {
      'github': 'deep-test',
      'linkedin': 'deep-test-user',
    },
    interests: ['testing', 'deep-updates'],
  );
  print('✅ Multiple profile fields updated');

  // Update multiple fields at story level
  await userDoc.update.profile.story(
    name: 'Updated Story Title',
    content: 'This story has been updated with new content',
    tags: ['updated', 'story', 'test'],
    publishedAt: DateTime.now(),
  );
  print('✅ Multiple story fields updated');

  // Update multiple fields at place level
  await userDoc.update.profile.story.place(
    name: 'Updated Place Name',
    address: '456 Updated St, New City, State',
    metadata: {
      'type': 'updated',
      'category': 'test-location',
      'verified': 'true',
    },
  );
  print('✅ Multiple place fields updated');

  // Update multiple fields at coordinates level
  await userDoc.update.profile.story.place.coordinates(
    latitude: 51.5074,
    longitude: -0.1278,
    altitude: 35.0,
  );
  print('✅ Multiple coordinates fields updated');
}

/// Test real-world scenarios
Future<void> testRealWorldScenarios() async {
  print('\n=== Real-World Scenarios ===');
  
  final odm = FirestoreODM();

  print('\n📱 Scenario 1: User Profile Update');
  final profileDoc = odm.users.doc('profile_user');
  
  // User updates their bio
  await profileDoc.update.profile(bio: '🚀 Flutter Developer | 📱 Mobile Expert');
  print('✅ Bio updated via chained API');

  print('\n🗺️ Scenario 2: Travel Story Update');
  final travelDoc = odm.users.doc('traveler');
  
  // User updates their travel story location
  await travelDoc.update.profile.story.place(
    name: 'Tokyo, Japan',
    address: 'Shibuya Crossing, Tokyo',
  );
  print('✅ Travel location updated');

  print('\n📍 Scenario 3: GPS Coordinates Update');
  final gpsDoc = odm.users.doc('gps_user');
  
  // App updates user's current coordinates
  await gpsDoc.update.profile.story.place.coordinates(
    latitude: 35.6762,
    longitude: 139.6503,
  );
  print('✅ GPS coordinates updated');

  print('\n🎯 Scenario 4: Social Media Integration');
  final socialDoc = odm.users.doc('social_user');
  
  // User connects new social media accounts
  await socialDoc.update.profile(
    socialLinks: {
      'github': 'awesome-dev',
      'twitter': '@awesome_dev',
      'linkedin': 'awesome-developer',
      'instagram': '@awesome_photos',
      'youtube': 'awesome-channel',
    },
  );
  print('✅ Social media links updated');

  print('\n📝 Scenario 5: Story Publishing Workflow');
  final publishDoc = odm.users.doc('publisher');
  
  // User publishes their story
  await publishDoc.update.profile.story(
    name: 'My Amazing Journey',
    content: 'This is the story of my incredible adventure...',
    tags: ['adventure', 'travel', 'inspiration'],
    publishedAt: DateTime.now(),
  );
  print('✅ Story published');
}

/// Demonstrate the API benefits
void demonstrateAPIBenefits() {
  print('\n=== API Benefits Demonstration ===');
  
  print('\n❌ Traditional Firestore Way (Error-Prone):');
  print('```dart');
  print('await userDoc.updateFields({');
  print('  "profile.story.place.coordinates.latitude": 40.7128,');
  print('  "profile.story.place.coordinates.longitude": -74.0060,');
  print('});');
  print('```');
  print('Problems:');
  print('  - String literals (typo-prone)');
  print('  - No type checking');
  print('  - No auto-completion');
  print('  - Hard to refactor');
  print('  - No compile-time validation');

  print('\n✅ New Chained API (Type-Safe & Clean):');
  print('```dart');
  print('await userDoc.update.profile.story.place.coordinates(');
  print('  latitude: 40.7128,');
  print('  longitude: -74.0060,');
  print(');');
  print('```');
  print('Benefits:');
  print('  ✅ Full type safety');
  print('  ✅ Auto-completion at every level');
  print('  ✅ Compile-time validation');
  print('  ✅ Refactoring safe');
  print('  ✅ Clean, readable syntax');
  print('  ✅ No naming conflicts');
  print('  ✅ Infinite nesting support');

  print('\n🎯 Supported Nesting Levels:');
  print('  Level 1: userDoc.update(name: "Kyle")');
  print('  Level 2: userDoc.update.profile(bio: "handsome")');
  print('  Level 3: userDoc.update.profile.story(name: "story 1")');
  print('  Level 4: userDoc.update.profile.story.place(name: "NYC")');
  print('  Level 5: userDoc.update.profile.story.place.coordinates(lat: 40.7)');
  print('  Level ∞: Supports unlimited nesting depth!');
}