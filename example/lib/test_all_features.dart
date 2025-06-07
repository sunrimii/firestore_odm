import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';
import 'models/post.dart';

/// Test all features of the RxDB-style API
void main() async {
  print('🚀 Testing Firestore ODM with RxDB-style API');

  await testBasicOperations();
  await testComplexDataTypes();
  await testAtomicOperations();
  await testExtensionMethods();
}

/// Test basic CRUD operations
Future<void> testBasicOperations() async {
  print('\n=== Basic Operations ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('test_user');

  // Create user with all required fields
  final profile = Profile(
    bio: 'Test user bio',
    avatar: 'test.jpg',
    socialLinks: {'github': 'testuser'},
    interests: ['testing'],
    followers: 10,
  );

  final user = User(
    id: 'test_user',
    name: 'Test User',
    email: 'test@example.com',
    age: 25,
    profile: profile,
    createdAt: DateTime.now(),
  );

  await userDoc.set(user);
  print('✅ Created user');

  final retrieved = await userDoc.get();
  print('✅ Retrieved user: ${retrieved?.name}');
}

/// Test complex data types
Future<void> testComplexDataTypes() async {
  print('\n=== Complex Data Types ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('complex_user');

  // Test all data types
  final profile = Profile(
    bio: 'Complex user with all data types',
    avatar: 'complex.jpg',
    socialLinks: {
      'twitter': '@complex',
      'github': 'complex',
      'linkedin': 'complex-user',
    },
    interests: ['dart', 'flutter', 'firebase'],
    followers: 500,
    lastActive: DateTime.now(),
  );

  final user = User(
    id: 'complex_user',
    name: 'Complex User',
    email: 'complex@example.com',
    age: 30,
    tags: ['developer', 'senior', 'flutter'],
    scores: [95, 88, 92, 87],
    settings: {'theme': 'dark', 'language': 'en', 'notifications': 'enabled'},
    metadata: {
      'source': 'api',
      'version': 2,
      'features': ['premium', 'beta'],
      'lastUpdate': DateTime.now().toIso8601String(),
    },
    profile: profile,
    rating: 4.8,
    isActive: true,
    isPremium: true,
    lastLogin: DateTime.now().subtract(Duration(hours: 1)),
    createdAt: DateTime.now().subtract(Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  await userDoc.set(user);
  print('✅ Created user with complex data types');
  print(
    '  - Nested object: Profile with ${profile.interests.length} interests',
  );
  print('  - Arrays: ${user.tags.length} tags, ${user.scores.length} scores');
  print(
    '  - Maps: ${user.settings.length} settings, ${user.metadata.length} metadata',
  );
  print('  - Dates: createdAt, updatedAt, lastLogin');
  print('  - Numbers: int age (${user.age}), double rating (${user.rating})');
  print(
    '  - Booleans: isActive (${user.isActive}), isPremium (${user.isPremium})',
  );
}

/// Test atomic operations
Future<void> testAtomicOperations() async {
  print('\n=== Atomic Operations ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('atomic_user');

  // Set initial state
  final profile = Profile(
    bio: 'Atomic test user',
    avatar: 'atomic.jpg',
    socialLinks: {},
    interests: ['testing'],
    followers: 100,
  );

  await userDoc.set(
    User(
      id: 'atomic_user',
      name: 'Atomic User',
      email: 'atomic@example.com',
      age: 25,
      tags: ['test'],
      scores: [80],
      settings: {'mode': 'test'},
      metadata: {'count': 1},
      profile: profile,
      rating: 3.0,
      isActive: true,
      isPremium: false,
      createdAt: DateTime.now(),
    ),
  );

  print('🔬 Testing automatic atomic operation detection:');

  // Test 1: Numeric increments (should use FieldValue.increment)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      age: user.age + 5, // → FieldValue.increment(5)
      rating: user.rating + 0.5, // → FieldValue.increment(0.5)
    );
  });
  print('  ✅ Numeric increments: age +5, rating +0.5');

  // Test 2: Array additions (should use FieldValue.arrayUnion)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      tags: [
        ...user.tags,
        'atomic',
        'advanced',
      ], // → FieldValue.arrayUnion(['atomic', 'advanced'])
      scores: [...user.scores, 90, 95], // → FieldValue.arrayUnion([90, 95])
    );
  });
  print('  ✅ Array additions: tags +2, scores +2');

  // Test 3: Array removals (should use FieldValue.arrayRemove)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      tags: user.tags
          .where((t) => t != 'test')
          .toList(), // → FieldValue.arrayRemove(['test'])
    );
  });
  print('  ✅ Array removal: removed "test" tag');

  // Test 4: Map updates
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      settings: {...user.settings, 'theme': 'dark', 'autoSave': 'true'},
      metadata: {
        ...user.metadata,
        'count': 2,
        'updated': DateTime.now().toIso8601String(),
      },
    );
  });
  print('  ✅ Map updates: settings and metadata');

  // Test 5: Boolean toggles
  await userDoc.incrementalModify((user) {
    return user.copyWith(isActive: !user.isActive, isPremium: !user.isPremium);
  });
  print('  ✅ Boolean toggles: isActive and isPremium');
}

/// Test extension methods
Future<void> testExtensionMethods() async {
  print('\n=== Extension Methods (Strong-Typed Updates) ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('extension_user');

  // Set initial state
  final profile = Profile(
    bio: 'Extension test user',
    avatar: 'extension.jpg',
    socialLinks: {'github': 'extension'},
    interests: ['extensions'],
    followers: 50,
  );

  await userDoc.set(
    User(
      id: 'extension_user',
      name: 'Extension User',
      email: 'extension@example.com',
      age: 28,
      profile: profile,
      rating: 4.0,
      isActive: true,
      isPremium: false,
      createdAt: DateTime.now(),
    ),
  );

  print('🎯 Testing strong-typed update methods:');

  // Test 1: Basic field updates
  await userDoc.update(
    name: 'Updated Extension User',
    age: 29,
    email: 'updated@example.com',
  );
  print('  ✅ Basic field updates: name, age, email');

  // Test 2: Array updates
  await userDoc.update(
    tags: ['extension', 'updated', 'test'],
    scores: [85, 90, 88],
  );
  print('  ✅ Array updates: tags and scores');

  // Test 3: Map updates
  await userDoc.update(
    settings: {'theme': 'light', 'language': 'zh', 'notifications': 'disabled'},
    metadata: {
      'source': 'extension_test',
      'version': 3,
      'lastUpdate': DateTime.now().toIso8601String(),
    },
  );
  print('  ✅ Map updates: settings and metadata');

  // Test 4: Nested object update
  final updatedProfile = Profile(
    bio: 'Updated via extension method',
    avatar: 'updated.jpg',
    socialLinks: {'github': 'updated-extension', 'twitter': '@updated'},
    interests: ['extensions', 'updates', 'testing'],
    followers: 75,
    lastActive: DateTime.now(),
  );

  await userDoc.update(profile: updatedProfile);
  print('  ✅ Nested object update: complete profile replacement');

  // Test 5: Date and boolean updates
  await userDoc.update(
    lastLogin: DateTime.now(),
    updatedAt: DateTime.now(),
    isActive: false,
    isPremium: true,
    rating: 4.5,
  );
  print(
    '  ✅ Date and boolean updates: lastLogin, updatedAt, isActive, isPremium, rating',
  );

  // Test 6: Null updates (removing fields)
  await userDoc.update(lastLogin: null);
  print('  ✅ Null update: removed lastLogin');
}

/// Test Post collection
Future<void> testPostCollection() async {
  print('\n=== Post Collection Test ===');

  final odm = FirestoreODM();
  final postDoc = odm.posts.doc('test_post');

  await postDoc.set(
    Post(
      id: 'test_post',
      title: 'Test Post with RxDB API',
      content: 'This post demonstrates the RxDB-style API features',
      authorId: 'test_user',
      tags: ['test', 'rxdb', 'api'],
      metadata: {
        'category': 'tutorial',
        'difficulty': 'intermediate',
        'estimatedTime': 20,
      },
      likes: 0,
      views: 0,
      published: false,
      createdAt: DateTime.now(),
    ),
  );

  // Test atomic operations on Post
  await postDoc.incrementalModify((post) {
    return post.copyWith(
      likes: post.likes + 10, // Atomic increment
      views: post.views + 100, // Atomic increment
      tags: [...post.tags, 'popular'], // Atomic array union
      published: true, // Boolean update
      publishedAt: DateTime.now(), // Date update
    );
  });

  // Test strong-typed update on Post
  await postDoc.update(
    title: 'Updated: Test Post with RxDB API',
    content: 'This post has been updated to show more features',
    metadata: {
      'category': 'advanced',
      'difficulty': 'expert',
      'estimatedTime': 30,
      'updated': true,
    },
  );

  print('  ✅ Post operations completed');
}
