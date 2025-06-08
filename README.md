# Firestore ODM for Dart/Flutter

**Stop fighting with Firestore queries. Start building amazing apps.**

Transform your Firestore development experience with type-safe, intuitive database operations that feel natural and productive. No more wrestling with field strings, runtime errors, or complex update logic.

## Why Choose Firestore ODM?

### ✅ **Before vs After**

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

### 🚀 **Key Benefits**

- **⚡ 10x Faster Development** - Autocomplete, type safety, and intuitive APIs
- **🛡️ Runtime Error Prevention** - Catch mistakes at compile-time, not in production
- **🎯 Intuitive Queries** - Write complex filters that read like natural language
- **🔄 Smart Updates** - Atomic operations, conflict resolution, and optimistic updates
- **🔗 Unified Collections** - Single models work across multiple collection paths
- **📱 Flutter-First** - Built specifically for Flutter development patterns

## Quick Start

### 1. Add to Your Project

```bash
# Add dependencies
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
part 'user.odm.dart'; // This will be generated

@freezed
@Collection('users')
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

### 3. Generate Code & Start Using

```bash
# Generate the ODM code
dart run build_runner build

# Now you're ready to use it!
```

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(firestore);

  // Create users effortlessly
  await odm.users.doc('john').set(User(
    id: 'john',
    name: 'John Doe',
    email: 'john@example.com',
    age: 25,
    isActive: true,
    tags: ['developer', 'flutter'],
  ));

  // Or use upsert with document ID field
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

## Common Use Cases

### 🔍 **Smart Filtering Made Simple**

```dart
// Find your target users with readable queries
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
```

### ⚡ **Lightning-Fast Updates**

```dart
// Single operation, multiple changes
await userDoc.update(($) => [
  $.name('John Smith'),           // Direct update
  $.age.increment(1),             // Atomic increment
  $.tags.add('verified'),         // Array addition
  $.lastLogin.serverTimestamp(),  // Server timestamp
]);

// Or use familiar copyWith pattern with smart atomic detection
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,              // Becomes increment(1)
  tags: [...user.tags, 'expert'], // Becomes arrayUnion(['expert'])
));
```

### 🔄 **Real-time Data Streams**

```dart
// Live updates in your Flutter UI
class UserProfileWidget extends StatelessWidget {
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: odm.users.doc(userId).changes,
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

### 🏦 **Safe Transactions**

```dart
// Multi-document operations with ACID guarantees
await odm.runTransaction(() async {
  final sender = await odm.users.doc('user1').get();
  final receiver = await odm.users.doc('user2').get();
  
  if (sender!.points >= 100) {
    await odm.users.doc('user1').incrementalModify((user) =>
      user.copyWith(points: user.points - 100));
      
    await odm.users.doc('user2').incrementalModify((user) =>
      user.copyWith(points: user.points + 100));
  }
});
```

## Advanced Features

<details>
<summary><strong>🎯 Document ID Fields</strong></summary>

```dart
@freezed
@Collection('posts')
class Post with _$Post {
  const factory Post({
    @DocumentIdField() required String id, // Virtual field, auto-synced
    required String title,
    required String content,
  }) = _Post;
  
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

// Use document ID in queries
final specificPosts = await odm.posts
  .where(($) => $.id(whereIn: ['post1', 'post2', 'post3']))
  .get();

// Order by document ID
final orderedPosts = await odm.posts
  .orderBy(($) => $.id())
  .get();
```
</details>

<details>
<summary><strong>🏗️ Complex Nested Objects</strong></summary>

```dart
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String bio,
    required Map<String, String> socialLinks,
    required Address address,
  }) = _Profile;
  
  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

// Query nested fields naturally
final users = await odm.users
  .where(($) => $.and(
    $.profile.bio(isNotEqualTo: null),
    $.profile.followers(isGreaterThan: 100),
  ))
  .get();

// Update nested fields easily
await userDoc.update(($) => [
  $.profile.bio('Updated bio'),
  $.profile.followers.increment(10),
]);
```
</details>

<details>
<summary><strong>🔥 Multiple Update Patterns</strong></summary>

```dart
// Choose your style:

// 1. Array-style (explicit operations)
await userDoc.update(($) => [
  $.age.increment(1),
  $.tags.add('expert'),
]);

// 2. Modify (diff-based updates)
await userDoc.modify((user) => user.copyWith(
  age: user.age + 1,
  tags: [...user.tags, 'expert'],
));

// 3. Incremental modify (automatic atomic operations)
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,      // Auto-detects increment
  tags: [...user.tags, 'expert'], // Auto-detects arrayUnion
));
```
</details>

<details>
<summary><strong>🏗️ Multiple Collections & Subcollections</strong></summary>

```dart
// 🆕 NEW: Use a single model for multiple collection paths!
@freezed
@Collection('posts')           // Top-level posts collection
@Collection('users/*/posts')   // User subcollection posts
class SharedPost with _$SharedPost {
  const factory SharedPost({
    @DocumentIdField() required String id,
    required String title,
    required String content,
    required int likes,
    required DateTime createdAt,
  }) = _SharedPost;
  
  factory SharedPost.fromJson(Map<String, dynamic> json) => _$SharedPostFromJson(json);
}

// ✨ Access BOTH collections with the same model:

// 1. Top-level posts collection
await odm.posts.upsert(SharedPost(
  id: 'global1',
  title: 'Global Post',
  content: 'Visible to everyone!',
  likes: 42,
  createdAt: DateTime.now(),
));

// 2. User-specific subcollection
await odm.users('alice').posts.upsert(SharedPost(
  id: 'personal1',
  title: 'Alice\'s Personal Post',
  content: 'Just for me!',
  likes: 5,
  createdAt: DateTime.now(),
));

// Query both collections independently
final globalPosts = await odm.posts
  .where(($) => $.likes(isGreaterThan: 10))
  .get();

final alicePosts = await odm.users('alice').posts
  .where(($) => $.title(contains: 'Personal'))
  .get();

// 🔥 Supports unlimited nesting levels
@Collection('organizations/*/departments/*/teams/*/projects')
class Project with _$Project { /* ... */ }

// Access deeply nested collections
final teamProjects = odm.organizations('acme')
  .departments('engineering')
  .teams('mobile')
  .projects;

// Access deeply nested collections
final employees = odm.organizations('org1').departments('dept1').employees;
```
</details>

## Current Limitations

While Firestore ODM provides powerful type-safe operations, some advanced features are not yet implemented:

### 🚧 **Not Yet Supported**

- **Map Field Access**: Direct access to map fields like `profile.socialLinks.github` is not supported
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

### 🎯 **Fully Supported Features**

✅ **Document ID Fields** - Virtual `@DocumentIdField()` with `FieldPath.documentId` support
✅ **Type-safe Filtering** - All Firestore operators on primitive and custom types
✅ **Nested Object Queries** - Deep filtering on custom class fields
✅ **Array Operations** - `arrayContains`, `arrayContainsAny`, `arrayUnion`, `arrayRemove`
✅ **Atomic Updates** - Increments, server timestamps, and mixed operation arrays
✅ **Real-time Streams** - Automatic subscription management with `changes` stream
✅ **Transactions** - Full transaction support with automatic context detection
✅ **RxDB-style Operations** - `modify()` and `incrementalModify()` with atomic detection
✅ **Upsert Operations** - Document creation/updates using Document ID fields
✅ **Subcollection Support** - Fluent API for nested collection access with wildcard syntax
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

void main() {
  test('user queries work perfectly', () async {
    final firestore = FakeFirebaseFirestore();
    final odm = FirestoreODM(firestore);
    
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

## Migration Guide

Coming from raw Firestore? Here's how to upgrade:

<details>
<summary><strong>🔄 Common Migration Patterns</strong></summary>

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
</details>

## Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to transform your Firestore experience?** [Get started](#quick-start) now and see the difference! 🚀

---

## API Reference

<details>
<summary><strong>Complete API Documentation</strong></summary>

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
  $(field1: 'value1', field2: 'value2'), // Object merge
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

// Automatic subscription management
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

</details>