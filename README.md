# Firestore ODM for Dart/Flutter

**Stop fighting with Firestore queries. Start building amazing apps.**

Transform your Firestore development experience with type-safe, intuitive database operations that feel natural and productive.

## Why We Built This

If you've worked with Flutter and Firestore, you know the pain:

- **No Type Safety** - String-based field paths that break at runtime, not compile time
- **Incomplete Solutions** - FlutterFire's ODM is incomplete and not actively maintained
- **Developer Frustration** - Wrestling with complex queries, manual serialization, and runtime errors

We got tired of these limitations. We wanted a solution that:
- ✅ Provides complete type safety throughout your entire data layer
- ✅ Offers intuitive, readable query syntax that feels natural in Dart
- ✅ Is actively maintained and built specifically for real-world Flutter development
- ✅ Eliminates runtime errors before they reach production

So we built Firestore ODM - a comprehensive, type-safe Object Document Mapper that makes Firestore development a joy instead of a chore.

## Before vs After

**Before (Raw Firestore):**
```dart
// Fragile, error-prone, hard to maintain
final result = await FirebaseFirestore.instance
  .collection('users')
  .where('isActive', isEqualTo: true)
  .where('profile.followers', isGreaterThan: 100)
  .where('age', isLessThan: 30)
  .get();

// Runtime errors waiting to happen
await userDoc.update({
  'profile.followers': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['verified']),
  'lastLogin': FieldValue.serverTimestamp(),
});
```

**After (Firestore ODM):**
```dart
// Type-safe, readable, maintainable
final result = await odm.users
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.profile.followers(isGreaterThan: 100),
    $.age(isLessThan: 30),
  ))
  .get();

// IDE autocomplete, compile-time safety
await userDoc.update(($) => [
  $.profile.followers.increment(1),
  $.tags.add('verified'),
  $.lastLogin.serverTimestamp(),
]);
```

## Key Benefits

- **⚡ 10x Faster Development** - Autocomplete, type safety, and intuitive APIs
- **🛡️ Runtime Error Prevention** - Catch mistakes at compile-time, not in production
- **🎯 Intuitive Queries** - Write complex filters that read like natural language
- **🔄 Smart Updates** - Three different update patterns for every use case
- **🔗 Unified Collections** - Single models work across multiple collection paths
- **🏗️ Schema-Based Architecture** - Multiple ODM instances with different structures
- **📱 Flutter-First** - Built specifically for Flutter development patterns

## Quick Start

### 1. Add Dependencies

```bash
flutter pub add firestore_odm firestore_odm_annotation
flutter pub add --dev firestore_odm_builder build_runner
```

### 2. Define Your Data Model

```dart
// lib/models/user.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    required bool isActive,
    @Default([]) List<String> tags,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 3. Define Your Schema

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

part 'schema.odm.dart';

@Collection<User>("users")
final appSchema = _$AppSchema;
```

### 4. Generate Code & Start Using

```bash
# Generate the ODM code
dart run build_runner build
```

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(appSchema, firestore: firestore);

  // Create users effortlessly
  await odm.users.upsert(User(
    id: 'jane',
    name: 'Jane Smith',
    email: 'jane@example.com',
    age: 28,
    isActive: true,
    tags: ['designer', 'flutter'],
  )); // Uses jane's id as document ID automatically

  // Query with confidence
  final activeDevs = await odm.users
    .where(($) => $.and(
      $.isActive(isEqualTo: true),
      $.tags(arrayContains: 'developer'),
    ))
    .get();

  print('Found ${activeDevs.length} active developers');
}
```

## Schema-Based Architecture

The new schema-based approach solves major limitations of traditional ODM patterns:

### **Multiple ODM Instances**
```dart
// Different schemas for different parts of your app
@Collection<User>("main_users")
@Collection<Post>("main_posts")
final mainSchema = _$MainSchema;

@Collection<User>("analytics_users")
@Collection<Post>("analytics_posts")
final analyticsSchema = _$AnalyticsSchema;

// Multiple ODM instances can coexist
final mainODM = FirestoreODM(mainSchema, firestore: mainFirestore);
final analyticsODM = FirestoreODM(analyticsSchema, firestore: analyticsFirestore);
```

### **No Manual Imports**
```dart
// ❌ OLD: Manual imports required in each model
@Collection("users/*/posts")
class Post with _$Post {
  // Had to manually import User model
}

// ✅ NEW: Schema-level definitions eliminate manual imports
@Collection<User>("users")
@Collection<Post>("users/*/posts")  // Parent-child relationships auto-detected
final schema = _$Schema;
```

### **Type-Safe Schema Compilation**
- **Compile-time validation** of collection paths and model relationships
- **Automatic parent-child detection** from collection path patterns
- **Schema-specific typing** with `FirestoreODM<T>` for better IDE support

## Core Features

### 🔍 Type-Safe Querying

Write complex queries that are readable, maintainable, and catch errors at compile time:

```dart
// Simple filtering
final youngUsers = await odm.users
  .where(($) => $.age(isLessThan: 30))
  .get();

// Complex logical operations
final engagedUsers = await odm.users
  .where(($) => $.and(
    $.age(isGreaterThan: 18),
    $.isActive(isEqualTo: true),
    $.or(
      $.tags(arrayContains: 'premium'),
      $.rating(isGreaterThan: 4.5),
    ),
  ))
  .orderBy(($) => $.rating(descending: true))
  .limit(50)
  .get();

// Nested object queries
final users = await odm.users
  .where(($) => $.and(
    $.profile.bio(isNotEqualTo: null),
    $.profile.followers(isGreaterThan: 100),
  ))
  .get();
```

### 🔄 Three Powerful Update Methods

Choose the update style that fits your workflow:

```dart
// 1. Array-Style Updates (Explicit atomic operations)
await userDoc.update(($) => [
  $.name('John Smith'),           // Direct update
  $.age.increment(1),             // Atomic increment
  $.tags.add('verified'),         // Array addition
  $.lastLogin.serverTimestamp(),  // Server timestamp
]);

// 2. Modify (Immutable diff-based updates)
await userDoc.modify((user) => user.copyWith(
  name: 'John Smith',
  age: user.age + 1,              // Regular math operations
  tags: [...user.tags, 'verified'], // Standard Dart list operations
  lastLogin: FirestoreODM.serverTimestamp, // Special timestamp constant
));

// 3. Incremental Modify (Automatic atomic detection - RECOMMENDED)
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,              // Auto-detects → FieldValue.increment(1)
  tags: [...user.tags, 'expert'], // Auto-detects → FieldValue.arrayUnion(['expert'])
  lastLogin: FirestoreODM.serverTimestamp, // Auto-converts to server timestamp
));
```

**All update methods work on both individual documents AND bulk query operations:**

```dart
// Bulk operations use the same API
await odm.users
  .where(($) => $.isActive(isEqualTo: false))
  .update(($) => [$.isActive(true)]);         // Bulk array-style update

await odm.users
  .where(($) => $.age(isLessThan: 18))
  .modify((user) => user.copyWith(            // Bulk modify
    category: 'minor',
  ));

await odm.users
  .where(($) => $.points(isLessThan: 100))
  .incrementalModify((user) => user.copyWith( // Bulk incremental modify
    points: user.points + 10,                 // Atomic increment for all matching docs
  ));
```

### 🏗️ Document ID Fields

Handle document IDs naturally with automatic detection or explicit annotation:

```dart
// Method 1: Explicit annotation (recommended)
@freezed
@Collection('posts')
class Post with _$Post {
  const factory Post({
    @DocumentIdField() required String id, // Virtual field, auto-synced
    required String title,
    required String content,
  }) = _Post;
}

// Method 2: Automatic detection
@freezed
@Collection('articles')
class Article with _$Article {
  const factory Article({
    required String id, // Automatically detected as document ID field
    required String title,
    required String content,
  }) = _Article;
}
```

**Key Benefits:**
- Virtual storage - ID field is never stored in document data
- Automatic sync - Field value always matches Firestore document ID
- Type-safe queries - Full filtering and ordering support on ID field
- Seamless upsert - Automatic document creation/updates

```dart
// Use document ID in queries
final specificPosts = await odm.posts
  .where(($) => $.id(whereIn: ['post1', 'post2', 'post3']))
  .get();

// Upsert with document ID field
await odm.posts.upsert(Post(
  id: 'my-post-id', // Used as Firestore document ID
  title: 'My Post',
  content: 'Content here',
));
```

### 🔄 Real-time Data Streams

```dart
// Live updates in your Flutter UI
class UserProfileWidget extends StatelessWidget {
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: odm.users(userId).changes,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return Text('Loading...');
        
        return Column(children: [
          Text('${user.name} (${user.age})'),
          Chip(label: Text('${user.tags.length} tags')),
        ]);
      },
    );
  }
}
```

### 🏦 Safe Transactions

```dart
// Multi-document operations with ACID guarantees
await odm.runTransaction(() async {
  final sender = await odm.users('user1').get();
  final receiver = await odm.users('user2').get();
  
  if (sender!.points >= 100) {
    await odm.users('user1').incrementalModify((user) =>
      user.copyWith(points: user.points - 100));
      
    await odm.users('user2').incrementalModify((user) =>
      user.copyWith(points: user.points + 100));
  }
});
```

## Advanced Features

### 🏗️ Multiple Collections & Subcollections

Use a single model for multiple collection paths with schema-based configuration:

```dart
// lib/models/post.dart
@freezed
class Post with _$Post {
  const factory Post({
    @DocumentIdField() required String id,
    required String title,
    required String content,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    @Default(0) int likes,
    required DateTime createdAt,
  }) = _Post;
  
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

// lib/app_schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/post.dart';

part 'app_schema.odm.dart';

// Schema-based collection definitions
@Collection<User>("users")
@Collection<Post>("posts")           // Top-level posts collection
@Collection<Post>("users/*/posts")   // User subcollection posts
final appSchema = _$AppSchema;

// Usage with the same model:
final odm = FirestoreODM(appSchema);

// 1. Top-level posts collection
await odm.posts.upsert(Post(
  id: 'global1',
  title: 'Global Post',
  content: 'Visible to everyone!',
  tags: ['announcement'],
  metadata: {'featured': true},
  likes: 42,
  createdAt: DateTime.now(),
));

// 2. User-specific subcollection
await odm.users('alice').posts.upsert(Post(
  id: 'personal1',
  title: 'Alice\'s Personal Post',
  content: 'Just for me!',
  tags: ['personal'],
  metadata: {},
  likes: 5,
  createdAt: DateTime.now(),
));

// Multiple schemas for different parts of your app
@Collection<Project>("organizations/*/departments/*/teams/*/projects")
final projectSchema = _$ProjectSchema;

final projectODM = FirestoreODM(projectSchema);
final teamProjects = projectODM.organizations('acme')
  .departments('engineering')
  .teams('mobile')
  .projects;
```

### 🕒 Smart Server Timestamps

Never worry about server timestamp conflicts:

```dart
final odm = FirestoreODM();

// In any update method, use the constant for server timestamps:
await userDoc.modify((user) => user.copyWith(
  lastLogin: FirestoreODM.serverTimestamp,    // Becomes FieldValue.serverTimestamp()
  updatedAt: DateTime.now(),                  // Stays as regular DateTime
));

await userDoc.incrementalModify((user) => user.copyWith(
  lastActivity: FirestoreODM.serverTimestamp, // Auto-converted to server timestamp
  sessionCount: user.sessionCount + 1,       // Auto-converted to increment
));
```

## Current Limitations

While Firestore ODM provides powerful type-safe operations, some advanced features are not yet implemented:

### 🚧 Not Yet Supported

- **Map Field Access**: Direct access to map fields like `profile.socialLinks.github`
  ```dart
  // ❌ NOT SUPPORTED YET
  await odm.users.where(($) => $.profile.socialLinks.github(isEqualTo: 'username')).get();
  
  // ✅ WORKAROUND: Use map-level filtering
  await odm.users.where(($) => $.profile.socialLinks(isNotEqualTo: null)).get();
  ```

- **Complex Nested Map Updates**: Individual map key updates need full map replacement
  ```dart
  // ❌ NOT SUPPORTED YET
  await userDoc.update(($) => [$.profile.socialLinks.github('new_username')]);
  
  // ✅ WORKAROUND: Update entire map
  await userDoc.update(($) => [$.profile.socialLinks({'github': 'new_username', 'twitter': 'handle'})]);
  ```

- **GeoPoint Queries**: Geospatial queries and GeoPoint field filtering
- **Reference Field Operations**: Direct DocumentReference field filtering and updates

### 🎯 Fully Supported Features

✅ **Document ID Fields** - Virtual `@DocumentIdField()` with automatic detection  
✅ **Type-safe Filtering** - All Firestore operators on primitive and custom types  
✅ **Nested Object Queries** - Deep filtering on custom class fields  
✅ **Array Operations** - Complete support for array operations  
✅ **Atomic Updates** - Increments, server timestamps, and mixed operations  
✅ **Real-time Streams** - Automatic subscription management  
✅ **Transactions** - Full transaction support with automatic context detection  
✅ **Three Update Methods** - Array-style, modify, and incremental modify  
✅ **Upsert Operations** - Document creation/updates using Document ID fields  
✅ **Subcollection Support** - Fluent API for nested collections  
✅ **Testing Support** - Full compatibility with `fake_cloud_firestore`

## Installation & Setup

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  firestore_odm: ^1.0.0
  firestore_odm_annotation: ^1.0.0
  freezed_annotation: ^3.0.0

dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.9
  freezed: ^3.0.6
  json_serializable: ^6.9.5
```

### Code Generation

```bash
# One-time build
dart run build_runner build

# Watch for changes during development
dart run build_runner watch
```

### Project Structure

The library generates these files for each model:
- `user.odm.dart` - Generated ODM classes and extensions
- Works alongside your existing `user.freezed.dart` and `user.g.dart`

## Testing

Perfect testing support with `fake_cloud_firestore`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart'; // Your schema file

void main() {
  test('user queries work perfectly', () async {
    final firestore = FakeFirebaseFirestore();
    final odm = FirestoreODM(appSchema, firestore: firestore);
    
    // Test your queries with confidence
    final results = await odm.users
      .where(($) => $.isActive(isEqualTo: true))
      .get();
      
    expect(results.length, 0);
  });
}
```

## Examples & Learning

- 📁 **[Complete Example App](flutter_example/)** - Real working Flutter app with comprehensive features
- 🧪 **[Test Suite](flutter_example/test/)** - 69 tests demonstrating every feature
- 📚 **[API Documentation](#api-reference)** - Complete reference guide

## Migration from Raw Firestore

Coming from raw Firestore? Here's how common patterns translate:

```dart
// OLD: Manual field paths and error-prone strings
await doc.update({
  'nested.field': newValue,
  'arrayField': FieldValue.arrayUnion(['item']),
  'count': FieldValue.increment(1),
});

// NEW: Type-safe, autocompleted updates
await doc.update(($) => [
  $.nested.field(newValue),
  $.arrayField.add('item'),
  $.count.increment(1),
]);

// OLD: Complex nested queries with string field paths
await collection
  .where('user.profile.isActive', isEqualTo: true)
  .where('user.age', isGreaterThan: 18)
  .get();

// NEW: Readable, type-safe queries
await odm.users
  .where(($) => $.and(
    $.profile.isActive(isEqualTo: true),
    $.age(isGreaterThan: 18),
  ))
  .get();
```

## API Reference

### Collection Operations

```dart
final users = odm.users;

// Basic CRUD
await users.doc('id').set(user);
await users.doc('id').delete();
final user = await users.doc('id').get();

// Advanced operations
await users.doc('id').modify((user) => user.copyWith(age: 26));
await users.doc('id').incrementalModify((user) => user.copyWith(age: user.age + 1));
await users.upsert(user); // Uses document ID field
```

### Query Operations

```dart
// Filtering
users.where(($) => $.field(isEqualTo: value))
users.where(($) => $.field(isNotEqualTo: value))
users.where(($) => $.field(isLessThan: value))
users.where(($) => $.field(isLessThanOrEqualTo: value))
users.where(($) => $.field(isGreaterThan: value))
users.where(($) => $.field(isGreaterThanOrEqualTo: value))
users.where(($) => $.field(whereIn: [values]))
users.where(($) => $.field(whereNotIn: [values]))
users.where(($) => $.field(isNull: true))

// Array operations
users.where(($) => $.arrayField(arrayContains: value))
users.where(($) => $.arrayField(arrayContainsAny: [values]))

// Logical operations
users.where(($) => $.and(filter1, filter2, filter3))
users.where(($) => $.or(filter1, filter2, filter3))

// Ordering and limiting
users.orderBy(($) => $.field(descending: true))
users.limit(10)
users.startAfter(document)
users.endBefore(document)
```

### Update Operations

```dart
// Array-style updates
await doc.update(($) => [
  $.field(newValue),                    // Direct assignment
  $.nestedObject.field(value),          // Nested updates
  $.arrayField.add(item),               // Array union
  $.arrayField.remove(item),            // Array remove
  $.numericField.increment(5),          // Numeric increment
  $.timestampField.serverTimestamp(),   // Server timestamp
]);

// Modify operations
await doc.modify((current) => current.copyWith(
  field: newValue,
  nestedObject: current.nestedObject.copyWith(field: value),
));

// Incremental modify (automatic atomic operations)
await doc.incrementalModify((current) => current.copyWith(
  age: current.age + 1,                 // Auto-increment
  tags: [...current.tags, 'new'],       // Auto-arrayUnion
  scores: current.scores.where((s) => s > 0).toList(), // Auto-arrayRemove
));
```

### Real-time Streams

```dart
// Document changes
final stream = doc.changes;
stream.listen((document) {
  // Handle document updates
});

// Automatic subscription management:
// - Subscription starts when first listener added
// - Multiple listeners share same subscription
// - Subscription stops when all listeners cancelled
```

### Transactions

```dart
await odm.runTransaction(() async {
  // All operations automatically use transaction context
  final doc1 = await odm.collection1.doc('id1').get();
  final doc2 = await odm.collection2.doc('id2').get();
  
  await odm.collection1.doc('id1').modify((d) => d.copyWith(field: newValue));
  await odm.collection2.doc('id2').update(($) => [$.field.increment(1)]);
});
```

## Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to transform your Firestore experience?** [Get started](#quick-start) now and build type-safe, maintainable Flutter apps! 🚀