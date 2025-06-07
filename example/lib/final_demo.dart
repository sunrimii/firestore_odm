import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';
import 'models/story.dart';

/// 🔥 Final Demo: Complete Firestore ODM with Chained Updates
///
/// This demo showcases the complete Firestore ODM library with:
/// - Type-safe collections and documents
/// - Advanced querying with method chaining
/// - Nested field updates with chained API
/// - Multi-level nesting support (up to infinite depth)
/// - Real-world usage patterns
void main() async {
  print('🔥 Firestore ODM - Complete Demo');
  print('=====================================');

  await demoBasicOperations();
  await demoAdvancedQuerying();
  await demoChainedUpdates();
  await demoDeepNesting();
  await demoRealWorldUsage();

  print('\n🎉 Demo completed successfully!');
  print('\n📚 Key Features Demonstrated:');
  print('  ✅ Type-safe collections and documents');
  print('  ✅ Advanced querying with method chaining');
  print('  ✅ Nested field updates with chained API');
  print('  ✅ Multi-level nesting support');
  print('  ✅ Real-world usage patterns');
  print('  ✅ Compile-time validation');
  print('  ✅ Auto-completion support');
}

/// Demo basic CRUD operations
Future<void> demoBasicOperations() async {
  print('\n=== 1. Basic CRUD Operations ===');

  final odm = FirestoreODM();

  // Create user
  final profile = Profile(
    bio: 'Flutter Developer',
    avatar: 'avatar.jpg',
    socialLinks: {'github': 'flutter-dev'},
    interests: ['flutter', 'dart'],
    followers: 100,
  );

  final user = User(
    id: 'demo_user',
    name: 'Demo User',
    email: 'demo@example.com',
    age: 25,
    profile: profile,
    rating: 4.5,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  );

  // Set document
  await odm.users.doc('demo_user').set(user);
  print('✅ Created user document');

  // Get document
  final retrievedUser = await odm.users.doc('demo_user').get();
  print('✅ Retrieved user: ${retrievedUser?.name}');

  // Update document
  await odm.users.doc('demo_user').update(name: 'Updated Demo User');
  print('✅ Updated user name');

  // Delete document
  await odm.users.doc('demo_user').delete();
  print('✅ Deleted user document');
}

/// Demo advanced querying capabilities
Future<void> demoAdvancedQuerying() async {
  print('\n=== 2. Advanced Querying ===');

  final odm = FirestoreODM();

  // Create sample users
  final users = [
    User(
      id: 'user1',
      name: 'Alice',
      email: 'alice@example.com',
      age: 25,
      profile: Profile(
        bio: 'Designer',
        avatar: 'alice.jpg',
        socialLinks: {},
        interests: ['design', 'ui'],
        followers: 150,
      ),
      rating: 4.2,
      isActive: true,
      isPremium: true,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    User(
      id: 'user2',
      name: 'Bob',
      email: 'bob@example.com',
      age: 30,
      profile: Profile(
        bio: 'Developer',
        avatar: 'bob.jpg',
        socialLinks: {},
        interests: ['coding', 'flutter'],
        followers: 200,
      ),
      rating: 4.8,
      isActive: true,
      isPremium: false,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
    ),
  ];

  // Add users
  for (final user in users) {
    await odm.users.doc(user.id).set(user);
  }
  print('✅ Created sample users');

  // Query by age
  final youngUsers = await odm.users
      .whereAge(isLessThan: 28)
      .orderByAge()
      .get();
  print('✅ Found ${youngUsers.length} users under 28');

  // Query by rating
  final topRatedUsers = await odm.users
      .whereRating(isGreaterThan: 4.5)
      .orderByRating(descending: true)
      .get();
  print('✅ Found ${topRatedUsers.length} top-rated users');

  // Query by premium status
  final premiumUsers = await odm.users
      .whereIsPremium(isEqualTo: true)
      .whereIsActive(isEqualTo: true)
      .get();
  print('✅ Found ${premiumUsers.length} active premium users');

  // Complex query with multiple conditions
  final complexQuery = await odm.users
      .whereAge(isGreaterThanOrEqualTo: 25)
      .whereRating(isGreaterThan: 4.0)
      .whereIsActive(isEqualTo: true)
      .orderByRating(descending: true)
      .limit(10)
      .get();
  print('✅ Complex query returned ${complexQuery.length} users');
}

/// Demo chained updates for nested fields
Future<void> demoChainedUpdates() async {
  print('\n=== 3. Chained Updates (copyWith-style) ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('chained_user');

  // Create user with nested data
  final coordinates = Coordinates(
    latitude: 37.7749,
    longitude: -122.4194,
    altitude: 10.0,
  );

  final place = Place(
    name: 'San Francisco',
    address: '123 Market St',
    coordinates: coordinates,
    metadata: {'type': 'city'},
  );

  final story = Story(
    name: 'My Story',
    content: 'Amazing adventure!',
    place: place,
    tags: ['adventure'],
    publishedAt: DateTime.now(),
  );

  final profile = Profile(
    bio: 'Adventurer',
    avatar: 'adventurer.jpg',
    socialLinks: {'instagram': '@adventurer'},
    interests: ['travel'],
    followers: 50,
    story: story,
  );

  final user = User(
    id: 'chained_user',
    name: 'Chain User',
    email: 'chain@example.com',
    age: 28,
    profile: profile,
    rating: 4.0,
    isActive: true,
    isPremium: false,
    createdAt: DateTime.now(),
  );

  await userDoc.set(user);
  print('✅ Created user with deep nested structure');

  // Level 1: Top-level updates
  await userDoc.update(name: 'Updated Chain User', age: 29);
  print('✅ Level 1: userDoc.update(name: "Updated Chain User", age: 29)');

  // Level 2: Profile updates
  await userDoc.update.profile(bio: 'Expert Adventurer', followers: 100);
  print(
    '✅ Level 2: userDoc.update.profile(bio: "Expert Adventurer", followers: 100)',
  );

  // Level 3: Story updates
  await userDoc.update.profile.story(
    name: 'Epic Adventure',
    content: 'The most amazing journey ever!',
  );
  print('✅ Level 3: userDoc.update.profile.story(name: "Epic Adventure", ...)');

  // Level 4: Place updates
  await userDoc.update.profile.story.place(
    name: 'New York City',
    address: '456 Broadway, NYC',
  );
  print(
    '✅ Level 4: userDoc.update.profile.story.place(name: "New York City", ...)',
  );

  // Level 5: Coordinates updates (deepest level)
  await userDoc.update.profile.story.place.coordinates(
    latitude: 40.7128,
    longitude: -74.0060,
    altitude: 20.0,
  );
  print(
    '✅ Level 5: userDoc.update.profile.story.place.coordinates(lat: 40.7128, ...)',
  );

  print('\n🎯 Chained API Benefits:');
  print('  ✅ Type-safe at every level');
  print('  ✅ Auto-completion support');
  print('  ✅ Compile-time validation');
  print('  ✅ Refactoring safe');
  print('  ✅ Clean, readable syntax');
  print('  ✅ Supports infinite nesting depth');
}

/// Demo deep nesting capabilities
Future<void> demoDeepNesting() async {
  print('\n=== 4. Deep Nesting Support ===');

  final odm = FirestoreODM();

  print('🔥 Demonstrating multi-level nesting:');
  print('  User → Profile → Story → Place → Coordinates');
  print('  (5 levels deep with type safety!)');

  final userDoc = odm.users.doc('deep_nesting_demo');

  // Show the power of deep nesting
  print('\n📍 Updating GPS coordinates 5 levels deep:');
  print('userDoc.update.profile.story.place.coordinates(');
  print('  latitude: 51.5074,   // London');
  print('  longitude: -0.1278,');
  print('  altitude: 35.0,');
  print(');');

  await userDoc.update.profile.story.place.coordinates(
    latitude: 51.5074,
    longitude: -0.1278,
    altitude: 35.0,
  );
  print('✅ Successfully updated coordinates 5 levels deep!');

  print('\n🌟 This would be impossible with traditional Firestore:');
  print('❌ await userDoc.updateFields({');
  print('  "profile.story.place.coordinates.latitude": 51.5074,');
  print('  "profile.story.place.coordinates.longitude": -0.1278,');
  print('  "profile.story.place.coordinates.altitude": 35.0,');
  print('});');
  print('Problems: String literals, no type safety, error-prone!');
}

/// Demo real-world usage patterns
Future<void> demoRealWorldUsage() async {
  print('\n=== 5. Real-World Usage Patterns ===');

  final odm = FirestoreODM();

  // Social media app scenario
  print('\n📱 Social Media App Scenario:');
  final socialUser = odm.users.doc('social_influencer');

  await socialUser.update.profile(
    bio: '🌟 Travel Influencer | 📸 Photographer | ✈️ Digital Nomad',
    followers: 10000,
    socialLinks: {
      'instagram': '@travel_influencer',
      'youtube': 'TravelVlogs',
      'tiktok': '@travel_content',
      'website': 'https://travel-blog.com',
    },
    interests: [
      'travel',
      'photography',
      'content-creation',
      'digital-nomad',
      'adventure',
    ],
  );
  print('✅ Updated social media influencer profile');

  // Travel blog scenario
  print('\n✈️ Travel Blog Update:');
  await socialUser.update.profile.story(
    name: 'Bali Adventure 2024',
    content:
        'Incredible 2-week journey through the beautiful islands of Bali...',
    tags: ['bali', 'indonesia', 'travel', 'adventure', '2024'],
    publishedAt: DateTime.now(),
  );

  await socialUser.update.profile.story.place(
    name: 'Ubud, Bali',
    address: 'Ubud, Gianyar Regency, Bali, Indonesia',
    metadata: {
      'country': 'Indonesia',
      'region': 'Bali',
      'type': 'cultural-center',
      'highlights': 'rice-terraces,temples,art',
    },
  );

  await socialUser.update.profile.story.place.coordinates(
    latitude: -8.5069,
    longitude: 115.2625,
    altitude: 200.0,
  );
  print('✅ Updated travel story with location details');

  // Gaming app scenario
  print('\n🎮 Gaming App Scenario:');
  final gamerDoc = odm.users.doc('pro_gamer');

  await gamerDoc.update.profile(
    bio: '🏆 Esports Champion | 🎯 Pro Player | 📺 Streamer',
    followers: 50000,
    socialLinks: {
      'twitch': 'pro_gamer_stream',
      'youtube': 'ProGamerChannel',
      'discord': 'ProGamer#1234',
      'twitter': '@pro_gamer',
    },
    interests: [
      'esports',
      'competitive-gaming',
      'streaming',
      'game-strategy',
      'tournaments',
    ],
  );
  print('✅ Updated pro gamer profile');

  // Business app scenario
  print('\n💼 Business App Scenario:');
  final businessDoc = odm.users.doc('startup_founder');

  await businessDoc.update.profile(
    bio: '🚀 Startup Founder | 💡 Tech Innovator | 📈 Growth Hacker',
    followers: 5000,
    socialLinks: {
      'linkedin': 'startup-founder',
      'twitter': '@startup_founder',
      'medium': '@startup-insights',
      'website': 'https://startup-company.com',
    },
    interests: [
      'entrepreneurship',
      'startup-growth',
      'tech-innovation',
      'venture-capital',
      'product-development',
    ],
  );
  print('✅ Updated startup founder profile');

  print('\n🎯 Real-world benefits demonstrated:');
  print('  ✅ Clean, maintainable code');
  print('  ✅ Type-safe data updates');
  print('  ✅ Reduced development time');
  print('  ✅ Fewer runtime errors');
  print('  ✅ Better developer experience');
}
