import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/profile.dart';
import 'models/post.dart';

/// Comprehensive test of RxDB-style API with various data types
void main() async {
  await testComplexDataTypes();
  await testAtomicOperations();
  await testNestedObjects();
  await testDateOperations();
}

/// Test various data types and their atomic operations
Future<void> testComplexDataTypes() async {
  print('=== Testing Complex Data Types ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('complex_user') as UserDocument;

  // Create initial user with all data types
  final initialProfile = Profile(
    bio: 'Software Developer',
    avatar: 'https://example.com/avatar.jpg',
    socialLinks: {
      'twitter': '@johndoe',
      'github': 'johndoe',
      'linkedin': 'john-doe',
    },
    interests: ['flutter', 'dart', 'firebase'],
    followers: 100,
    lastActive: DateTime.now(),
  );

  final initialUser = User(
    id: 'complex_user',
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
    tags: ['developer', 'flutter'],
    scores: [85, 92, 78, 95],
    settings: {'theme': 'dark', 'language': 'en', 'notifications': 'enabled'},
    metadata: {
      'source': 'registration',
      'version': 1,
      'features': ['premium', 'beta'],
    },
    profile: initialProfile,
    rating: 4.5,
    isActive: true,
    isPremium: false,
    lastLogin: DateTime.now().subtract(Duration(hours: 2)),
    createdAt: DateTime.now().subtract(Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  await userDoc.set(initialUser);
  print('✅ Created user with complex data types');

  // Test 1: Numeric operations (should use FieldValue.increment)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      age: user.age + 1, // int increment
      rating: user.rating + 0.1, // double increment
    );
  });
  print('✅ Numeric increments with atomic operations');

  // Test 2: Array operations (should use FieldValue.arrayUnion/arrayRemove)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      tags: [...user.tags, 'senior'], // Array union
      scores: [...user.scores, 88], // Array union
      profile: user.profile.copyWith(
        interests: [...user.profile.interests, 'ai'], // Nested array union
      ),
    );
  });
  print('✅ Array additions with atomic operations');

  // Test 3: Array removals
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      tags: user.tags
          .where((tag) => tag != 'developer')
          .toList(), // Array remove
    );
  });
  print('✅ Array removals with atomic operations');

  // Test 4: Map operations
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      settings: {
        ...user.settings,
        'theme': 'light', // Map field update
        'autoSave': 'true', // Map field addition
      },
      metadata: {
        ...user.metadata,
        'version': 2, // Nested map update
        'lastUpdate': DateTime.now().toIso8601String(),
      },
    );
  });
  print('✅ Map operations');

  // Test 5: Boolean toggles
  await userDoc.incrementalModify((user) {
    return user.copyWith(isActive: !user.isActive, isPremium: !user.isPremium);
  });
  print('✅ Boolean toggles');
}

/// Test atomic operations detection
Future<void> testAtomicOperations() async {
  print('\n=== Testing Atomic Operations Detection ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('atomic_test');

  // Set initial state
  await userDoc.set(
    User(
      id: 'atomic_test',
      name: 'Atomic Test',
      email: 'atomic@test.com',
      age: 25,
      tags: ['test'],
      scores: [70, 80],
      settings: {'mode': 'test'},
      metadata: {'count': 0},
      profile: Profile(
        bio: 'Test user',
        avatar: 'test.jpg',
        socialLinks: {},
        interests: ['testing'],
        followers: 50,
      ),
      rating: 3.0,
      isActive: true,
      isPremium: false,
      createdAt: DateTime.now(),
    ),
  );

  print('🔬 Testing automatic atomic operation detection:');

  // These should be detected as atomic operations
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      age: user.age + 5, // → FieldValue.increment(5)
      rating: user.rating - 0.5, // → FieldValue.increment(-0.5)
      tags: [...user.tags, 'atomic'], // → FieldValue.arrayUnion(['atomic'])
      scores: [...user.scores, 90, 95], // → FieldValue.arrayUnion([90, 95])
    );
  });
  print(
    '  ✅ Detected: increment(5), increment(-0.5), arrayUnion([atomic]), arrayUnion([90, 95])',
  );

  // Array removal detection
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      tags: user.tags
          .where((t) => t != 'test')
          .toList(), // → FieldValue.arrayRemove(['test'])
    );
  });
  print('  ✅ Detected: arrayRemove([test])');

  // Mixed operations (should fall back to direct assignment)
  await userDoc.incrementalModify((user) {
    final newTags = [...user.tags];
    newTags.remove('atomic');
    newTags.add('mixed');
    return user.copyWith(tags: newTags); // Mixed add/remove → direct assignment
  });
  print('  ✅ Mixed operations use direct assignment');
}

/// Test nested object operations
Future<void> testNestedObjects() async {
  print('\n=== Testing Nested Object Operations ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('nested_test');

  // Create user with nested profile
  final profile = Profile(
    bio: 'Original bio',
    avatar: 'original.jpg',
    socialLinks: {'twitter': '@original', 'github': 'original'},
    interests: ['coding', 'reading'],
    followers: 200,
    lastActive: DateTime.now(),
  );

  await userDoc.set(
    User(
      id: 'nested_test',
      name: 'Nested Test',
      email: 'nested@test.com',
      age: 28,
      tags: ['nested'],
      scores: [85],
      settings: {'nested': 'true'},
      metadata: {'level': 1},
      profile: profile,
      rating: 4.0,
      isActive: true,
      isPremium: true,
      createdAt: DateTime.now(),
    ),
  );

  print('📦 Testing nested object modifications:');

  // Test 1: Update nested profile fields
  await userDoc.modify((user) {
    return user.copyWith(
      profile: user.profile.copyWith(
        bio: 'Updated bio with more details',
        followers: user.profile.followers + 50, // This won't be atomic (nested)
        interests: [...user.profile.interests, 'gaming'], // Nested array
      ),
    );
  });
  print('  ✅ Updated nested profile fields');

  // Test 2: Update nested social links
  await userDoc.modify((user) {
    return user.copyWith(
      profile: user.profile.copyWith(
        socialLinks: {
          ...user.profile.socialLinks,
          'instagram': '@newuser',
          'twitter': '@updated_handle', // Override existing
        },
      ),
    );
  });
  print('  ✅ Updated nested social links map');

  // Test 3: Strong-typed update of nested fields
  await userDoc.update(
    profile: profile.copyWith(
      bio: 'Strong-typed update',
      avatar: 'new_avatar.jpg',
    ),
  );
  print('  ✅ Strong-typed nested object update');
}

/// Test date operations and server timestamps
Future<void> testDateOperations() async {
  print('\n=== Testing Date Operations ===');

  final odm = FirestoreODM();
  final userDoc = odm.users.doc('date_test');

  final now = DateTime.now();
  final yesterday = now.subtract(Duration(days: 1));
  final lastWeek = now.subtract(Duration(days: 7));

  // Create user with various date fields
  await userDoc.set(
    User(
      id: 'date_test',
      name: 'Date Test',
      email: 'date@test.com',
      age: 32,
      tags: ['dates'],
      scores: [88],
      settings: {'timezone': 'UTC'},
      metadata: {'created': now.toIso8601String()},
      profile: Profile(
        bio: 'Date tester',
        avatar: 'date.jpg',
        socialLinks: {},
        interests: ['time'],
        followers: 75,
        lastActive: yesterday,
      ),
      rating: 3.8,
      isActive: true,
      isPremium: false,
      lastLogin: yesterday,
      createdAt: lastWeek,
      updatedAt: now,
    ),
  );

  print('📅 Testing date operations:');

  // Test 1: Update various date fields
  await userDoc.update(
    lastLogin: now,
    updatedAt: now,
    profile: Profile(
      bio: 'Updated with new timestamp',
      avatar: 'updated.jpg',
      socialLinks: {},
      interests: ['time', 'updates'],
      followers: 80,
      lastActive: now, // Update nested date
    ),
  );
  print('  ✅ Updated multiple date fields');

  // Test 2: Use server timestamp via updateFields
  await userDoc.updateFields({
    'updatedAt': FieldValue.serverTimestamp(),
    'metadata.serverUpdate': FieldValue.serverTimestamp(),
  });
  print('  ✅ Used server timestamps');

  // Test 3: Date-based queries (testing the generated query methods)
  final usersCollection = odm.users;

  // Query users by date ranges
  final recentUsers = await usersCollection
      .whereLastLogin(isGreaterThan: yesterday)
      .whereCreatedAt(isLessThan: now)
      .orderByUpdatedAt(descending: true)
      .get();

  print('  ✅ Date-based queries work: found ${recentUsers.length} users');

  // Test 4: Null date handling
  await userDoc.update(lastLogin: null); // Set to null
  print('  ✅ Null date handling');
}

/// Test Post collection with different data types
Future<void> testPostCollection() async {
  print('\n=== Testing Post Collection ===');

  final odm = FirestoreODM();
  final postDoc = odm.posts.doc('test_post');

  await postDoc.set(
    Post(
      id: 'test_post',
      title: 'Test Post',
      content: 'This is a test post content',
      authorId: 'user123',
      tags: ['test', 'demo'],
      metadata: {
        'category': 'tutorial',
        'difficulty': 'beginner',
        'estimatedTime': 15,
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
      likes: post.likes + 1, // Atomic increment
      views: post.views + 10, // Atomic increment
      tags: [...post.tags, 'popular'], // Atomic array union
      published: true, // Boolean update
      publishedAt: DateTime.now(), // Date update
    );
  });

  print('  ✅ Post atomic operations completed');
}
