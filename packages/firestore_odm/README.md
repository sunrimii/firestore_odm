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
await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.add('verified'),
  $.lastLogin.serverTimestamp(),
]);
```

## Key Benefits

- **⚡ 10x Faster Development** - Autocomplete, type safety, and intuitive APIs
- **🛡️ Runtime Error Prevention** - Catch mistakes at compile-time, not in production
- **🎯 Intuitive Queries** - Write complex filters that read like natural language
- **🧠 Smart Builder Pagination** - Revolutionary pagination with zero inconsistency risk
- **🔄 Smart Updates** - Three different update patterns for every use case
- **🔗 Unified Collections** - Single models work across multiple collection paths
- **🏗️ Schema-Based Architecture** - Multiple ODM instances with different structures
- **🧩 Flexible Modeling** - Supports `freezed`, plain Dart classes, and `fast_immutable_collections`
- **📱 Flutter-First** - Built specifically for Flutter development patterns

## 📚 Documentation Index

### 🚀 Getting Started
- [Quick Start](#quick-start) - Installation and basic usage
- [Schema-Based Architecture](#schema-based-architecture) - Multiple ODM instances and collections
- [Installation & Setup](#installation--setup) - Dependencies and code generation

### 🔧 Core Operations
- [Collection Operations](#collection-operations) - [`insert()`](#insert-vs-update-vs-upsert), [`update()`](#insert-vs-update-vs-upsert), [`upsert()`](#insert-vs-update-vs-upsert)
- [Document ID Fields](#-document-id-fields) - Virtual [`@DocumentIdField()`](packages/firestore_odm_annotation/lib/src/annotations.dart) usage
- [Real-time Streams](#-real-time-data-streams) - Live data updates in Flutter UI
- [Bulk Delete Operations](#-bulk-delete-operations) - Query-based and collection-wide delete operations

### 🔍 Query & Filter APIs
- [Type-Safe Querying](#-type-safe-querying) - Complex filters with logical operations
- [Query Operations](#query-operations) - [`where()`](#query-operations), [`orderBy()`](#query-operations), [`limit()`](#query-operations)
- [Smart Builder Pagination](#-smart-builder-pagination-system) - Revolutionary strongly-typed pagination with zero inconsistency risk
- [Aggregate Operations](#-type-safe-aggregate-operations) - [`count()`](packages/firestore_odm/lib/src/count_query.dart), [`sum()`](packages/firestore_odm/lib/src/tuple_aggregate.dart), [`average()`](packages/firestore_odm/lib/src/tuple_aggregate.dart)
- [Map Field Operations](#️-map-field-operations) - Map key access, filtering, and updates

### ✏️ Update Methods
- [Three Update Patterns](#-three-powerful-update-methods) - Array-style, Modify, Incremental Modify
- [Update Operations](#update-operations) - [`patch()`](packages/firestore_odm/lib/src/interfaces/update_operations.dart), [`modify()`](packages/firestore_odm/lib/src/interfaces/document_operations.dart), [`incrementalModify()`](packages/firestore_odm/lib/src/interfaces/document_operations.dart)
- [Collection Bulk Operations](#-collection-bulk-operations) - Bulk modify and incremental modify on entire collections
- [Smart Server Timestamps](#-smart-server-timestamps) - [`FirestoreODM.serverTimestamp`](packages/firestore_odm/lib/src/firestore_odm.dart)

### 🏗️ Advanced Features
- [Multiple Collections & Subcollections](#-multiple-collections--subcollections) - Schema-based collection management
- [Safe Transactions](#-safe-transactions) - ACID guarantees with [`runTransaction()`](packages/firestore_odm/lib/src/firestore_odm.dart)
- [Flexible Data Modeling](#-flexible-data-modeling) - Use `freezed`, plain Dart classes, or `fast_immutable_collections`
- [Feature Completion Status](#feature-completion-status) - What's implemented vs pending

### 📖 Reference & Examples
- [API Reference](#api-reference) - Complete method documentation
- [Testing](#testing) - Integration with [`fake_cloud_firestore`](packages/firestore_odm/lib/firestore_odm.dart)
- [Migration Guide](#migration-from-raw-firestore) - From raw Firestore to ODM
- [Complete Example App](flutter_example/) - Working Flutter application

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
// 1. Array-Style Patches (Explicit atomic operations)
await userDoc.patch(($) => [
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
  .patch(($) => [$.isActive(true)]);         // Bulk array-style patch

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

### 🗑️ Bulk Delete Operations

Delete multiple documents efficiently with query-based operations:

```dart
// Delete all documents matching a query
await odm.users
  .where(($) => $.isActive(isEqualTo: false))
  .delete();

// Delete from ordered query results
await odm.users
  .orderBy(($) => $.rating())
  .limit(10)
  .delete();

// Delete entire collection
await odm.users.delete();

// Delete with complex filters
await odm.users
  .where(($) => $.and(
    $.age(isLessThan: 18),
    $.isActive(isEqualTo: false),
  ))
  .delete();
```

### 🗺️ Map Field Operations

Complete support for Map field access and updates:

```dart
// Map key filtering
final users = await odm.users
  .where(($) => $.settings.key('theme')(isEqualTo: 'dark'))
  .get();

// Nested map key filtering
final users = await odm.users
  .where(($) => $.profile.socialLinks.key('github')(isEqualTo: 'username'))
  .get();

// Map key updates with patch
await userDoc.patch(($) => [
  $.settings.setKey('theme', 'dark'),
  $.profile.socialLinks.setKey('github', 'new-username'),
  $.metadata.removeKey('deprecated_field'),
]);

// Complete map replacement
await userDoc.patch(($) => [
  $.settings({'theme': 'dark', 'language': 'en'}),
]);

// Map operations in bulk queries
await odm.users
  .where(($) => $.settings.key('theme')(isEqualTo: 'light'))
  .patch(($) => [$.settings.setKey('theme', 'dark')]);
```

### 🏗️ Collection Bulk Operations

Perform operations on entire collections efficiently:

```dart
// Bulk modify entire collection
await odm.users.modify((user) => user.copyWith(
  isActive: true,
  updatedAt: DateTime.now(),
));

// Bulk incremental modify with atomic operations
await odm.users.incrementalModify((user) => user.copyWith(
  points: user.points + 10,              // Auto-detects → FieldValue.increment(10)
  tags: [...user.tags, 'bonus'],         // Auto-detects → FieldValue.arrayUnion(['bonus'])
  lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
));

// Collection operations work with aggregations
final stats = await odm.users.aggregate(($) => (
  count: $.count(),
  avgAge: $.age.average(),
)).get();

// Mix collection operations with queries
await odm.users
  .where(($) => $.isActive(isEqualTo: true))
  .modify((user) => user.copyWith(lastActive: DateTime.now()));
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

### 📊 Type-Safe Aggregate Operations

Perform powerful analytics queries with complete type safety and generated field selectors:

```dart
// Simple count operations
final activeUserCount = await odm.users
  .where(($) => $.isActive(isEqualTo: true))
  .count()
  .get();

print('Active users: ${activeUserCount.count}');

// Strongly-typed aggregate operations with generated field selectors
final result = await odm.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),                    // Returns: int
    totalAge: $.age.sum(),              // Returns: int (age field is int)
    avgAge: $.age.average(),            // Returns: double (average always double)
    totalRating: $.rating.sum(),        // Returns: double (rating field is double)
    avgRating: $.rating.average(),      // Returns: double (average always double)
  ))
  .get();

// Perfect type safety - no casting needed!
print('Count: ${result.count}');           // result.count is int
print('Total age: ${result.totalAge}');    // result.totalAge is int
print('Avg age: ${result.avgAge}');        // result.avgAge is double
print('Total rating: ${result.totalRating}'); // result.totalRating is double
print('Avg rating: ${result.avgRating}');  // result.avgRating is double

// Works with nested objects using generated selectors
final nestedStats = await odm.users.aggregate(($) => (
  count: $.count(),
  totalFollowers: $.profile.followers.sum(),  // Generated nested field selector
  avgFollowers: $.profile.followers.average(),
)).get();

// Real-time aggregate streams
StreamBuilder<({int count, int totalAge, double avgRating})>(
  stream: odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .aggregate(($) => (
      count: $.count(),
      totalAge: $.age.sum(),
      avgRating: $.rating.average(),
    ))
    .stream,
  builder: (context, snapshot) {
    final stats = snapshot.data;
    if (stats == null) return Text('Loading stats...');
    
    return Column(children: [
      Text('Active Users: ${stats.count}'),
      Text('Total Age: ${stats.totalAge}'),
      Text('Avg Rating: ${stats.avgRating.toStringAsFixed(1)}'),
    ]);
  },
);
```

**Key Benefits:**
- ✅ **Generated Field Selectors** - No hardcoded field names, full autocomplete
- ✅ **Perfect Type Safety** - `age.sum()` returns `int`, `rating.sum()` returns `double`
- ✅ **Compile-time Validation** - Catch field name typos before runtime
- ✅ **Real-time Streams** - Live aggregate updates in your UI
- ✅ **Query Integration** - Works with all filtering and ordering operations
- ✅ **Nested Object Support** - Generated selectors for nested fields

### 🧠 Smart Builder Pagination System

Our revolutionary Smart Builder approach provides strongly-typed pagination with perfect consistency guarantees:

```dart
// ✨ SAME builder function for orderBy AND object extraction
final builderPattern = ($) => (
  $.profile.followers(true),  // int (descending)
  $.rating(),                 // double (ascending)
  $.name(),                   // String (ascending)
  $.age(true),               // int (descending)
);

// 1. Use builder for orderBy (creates tuple types)
final query = odm.users
  .orderBy(builderPattern)
  .limit(10);

// 2. Use SAME builder for object-based pagination (extracts values)
final paginatedQuery = query
  .startAtObject(userObject)    // Auto-extracts: (1500, 4.7, "Eve", 32)
  .endBeforeObject(otherUser);  // Auto-extracts: (500, 4.2, "David", 28)
```

**🎯 Key Benefits:**
- **Zero Inconsistency Risk** - Same builder ensures perfect field order/type matching
- **Complete Type Safety** - Generic type parameter `O` captures full orderBy tuple
- **Smart Value Extraction** - Automatic object value extraction according to orderBy fields
- **Document ID Support** - Proper handling of `FieldPath.documentId` for document ID ordering

**📋 Complete Pagination API:**
```dart
// Strongly-typed cursor pagination
.startAt(O cursorValues)     // Start at cursor values
.startAfter(O cursorValues)  // Start after cursor values
.endAt(O cursorValues)       // End at cursor values
.endBefore(O cursorValues)   // End before cursor values

// Smart object-based pagination
.startAtObject(T object)     // Auto-extract cursor from object
.startAfterObject(T object)  // Auto-extract cursor from object
.endAtObject(T object)       // Auto-extract cursor from object
.endBeforeObject(T object)   // Auto-extract cursor from object
```

**🔧 Practical Usage:**
```dart
// Multi-field ordering with pagination
final firstPage = await odm.users
  .orderBy(($) => ($.followers(true), $.rating(), $.name()))
  .limit(10)
  .get();

// Next page using object-based pagination
final nextPage = await odm.users
  .orderBy(($) => ($.followers(true), $.rating(), $.name()))
  .startAfterObject(firstPage.last)  // Uses last user object as cursor
  .limit(10)
  .get();

// Or use cursor-based pagination for maximum performance
final cursorValues = (1200, 4.5, "John"); // (followers, rating, name)
final cursorPage = await odm.users
  .orderBy(($) => ($.followers(true), $.rating(), $.name()))
  .startAfter(cursorValues)
  .limit(10)
  .get();
```

###  Real-time Data Streams

```dart
// Live updates in your Flutter UI
class UserProfileWidget extends StatelessWidget {
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: odm.users(userId).stream,
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
await odm.runTransaction((tx) async {
  final sender = await tx.users('user1').get();
  final receiver = await tx.users('user2').get();

  if (sender!.points >= 100) {
    await tx.users('user1').incrementalModify((user) =>
      user.copyWith(points: user.points - 100));

    await tx.users('user2').incrementalModify((user) =>
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

### 🧩 Flexible Data Modeling

While `freezed` is an excellent choice for creating data models, `firestore_odm` is designed to be flexible. You can use plain immutable Dart classes with `json_serializable` or enhance your models with `fast_immutable_collections`.

#### **Plain Dart Classes with `json_serializable`**

You are not required to use `freezed`. If you prefer writing immutable classes by hand, `firestore_odm` works perfectly with classes annotated with `json_serializable`.

This approach gives you full control over your model's implementation while still benefiting from type-safe queries and updates.

**Example `user.dart`:**
```dart
// lib/models/user.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @DocumentIdField()
  final String id;

  final String name;

  @JsonKey(name: 'user_email') // Customize field name in Firestore
  final String email;

  @JsonKey(defaultValue: false) // Provide default values
  final bool isPremium;

  @JsonKey(includeFromJson: false, includeToJson: false) // Ignore field
  final String? internalNotes;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isPremium = false,
    this.internalNotes,
  });

  // Required for json_serializable
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // Required for json_serializable
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Recommended for immutable classes
  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      internalNotes: this.internalNotes, // Does not participate in copyWith
    );
  }
}
```
The workflow remains the same: define your model, include it in your schema, and run `build_runner`. The ODM will generate all the necessary type-safe extensions.

#### **`fast_immutable_collections` Support**

For enhanced performance and truly immutable collections, `firestore_odm` seamlessly supports the [`fast_immutable_collections`](https://pub.dev/packages/fast_immutable_collections) library.

You can use `IList`, `IMap`, and `ISet` directly in your models. The ODM, in conjunction with `json_serializable`, will handle the conversion to and from Firestore-compatible types (`List`, `Map`).

**Example Model with `IList`:**
```dart
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// ... other imports

@freezed
class Product with _$Product {
  const factory Product({
    @DocumentIdField() required String id,
    required String name,
    required IList<String> tags, // Use IList for an immutable list
    required IMap<String, String> attributes, // Use IMap for an immutable map
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
```
This allows you to build robust, high-performance applications by leveraging the benefits of immutable data structures throughout your app.

## Feature Completion Status

Below is a comprehensive overview of all Firestore ODM features and their current implementation status:

| Category | Feature | Status | Description |
|----------|---------|--------|-------------|
| **Core Operations** | Document CRUD | ✅ Complete | Create, read, update, delete documents |
| | Collection Operations | ✅ Complete | [`insert()`](packages/firestore_odm/lib/src/interfaces/collection_operations.dart), [`update()`](packages/firestore_odm/lib/src/interfaces/collection_operations.dart), [`upsert()`](packages/firestore_odm/lib/src/interfaces/collection_operations.dart) |
| | Document ID Fields | ✅ Complete | Virtual [`@DocumentIdField()`](packages/firestore_odm_annotation/lib/src/annotations.dart) with automatic detection |
| | Bulk Delete Operations | ✅ Complete | Query-based and collection-wide delete operations |
| **Querying** | Type-safe Filtering | ✅ Complete | All Firestore operators on primitive and custom types |
| | Nested Object Queries | ✅ Complete | Deep filtering on custom class fields |
| | Array Operations | ✅ Complete | [`arrayContains`](packages/firestore_odm/lib/src/filter_builder.dart), [`arrayContainsAny`](packages/firestore_odm/lib/src/filter_builder.dart), array updates |
| | Map Operations | ✅ Complete | Map field access via [`key()`](packages/firestore_odm/lib/src/filter_builder.dart), individual key filtering and updates |
| | Logical Operations | ✅ Complete | [`and()`](packages/firestore_odm/lib/src/filter_builder.dart), [`or()`](packages/firestore_odm/lib/src/filter_builder.dart) query combinators |
| | Order By & Limits | ✅ Complete | [`orderBy()`](packages/firestore_odm/lib/src/interfaces/query_operations.dart), [`limit()`](packages/firestore_odm/lib/src/interfaces/query_operations.dart) operations |
| | Pagination | ✅ Complete | Smart Builder Pagination with [`startAt()`](packages/firestore_odm/lib/src/pagination.dart), [`startAfter()`](packages/firestore_odm/lib/src/pagination.dart), [`endAt()`](packages/firestore_odm/lib/src/pagination.dart), [`endBefore()`](packages/firestore_odm/lib/src/pagination.dart) |
| **Updates** | Array-style Updates | ✅ Complete | Explicit atomic operations with [`patch()`](packages/firestore_odm/lib/src/interfaces/update_operations.dart) |
| | Modify Updates | ✅ Complete | Immutable diff-based updates with [`modify()`](packages/firestore_odm/lib/src/interfaces/document_operations.dart) |
| | Incremental Modify | ✅ Complete | Automatic atomic detection with [`incrementalModify()`](packages/firestore_odm/lib/src/interfaces/document_operations.dart) |
| | Atomic Operations | ✅ Complete | Increments, server timestamps, mixed operations |
| | Bulk Updates | ✅ Complete | Query-based bulk operations |
| | Map Updates | ✅ Complete | Individual map key updates via [`setKey()`](packages/firestore_odm/lib/src/filter_builder.dart), [`removeKey()`](packages/firestore_odm/lib/src/filter_builder.dart) |
| **Advanced Features** | Aggregate Operations | ✅ Complete | [`count()`](packages/firestore_odm/lib/src/count_query.dart), [`sum()`](packages/firestore_odm/lib/src/tuple_aggregate.dart), [`average()`](packages/firestore_odm/lib/src/tuple_aggregate.dart) with type safety |
| | Real-time Streams | ✅ Complete | Automatic subscription management |
| | Transactions | ✅ Complete | Full transaction support with automatic context detection |
| | Server Timestamps | ✅ Complete | [`FirestoreODM.serverTimestamp`](packages/firestore_odm/lib/src/firestore_odm.dart) constant |
| **Collections** | Multiple Collections | ✅ Complete | Schema-based multiple collection support |
| | Subcollections | ✅ Complete | Fluent API for nested collections |
| | Collection Groups | ✅ Complete | Cross-collection queries |
| **Schema & Architecture** | Schema-based Architecture | ✅ Complete | Multiple ODM instances with different schemas |
| | Code Generation | ✅ Complete | Automatic ODM class generation |
| | Type Safety | ✅ Complete | Compile-time validation throughout |
| **Testing & Dev** | Testing Support | ✅ Complete | Full compatibility with [`fake_cloud_firestore`](packages/firestore_odm/lib/firestore_odm.dart) |
| | Development Tools | ✅ Complete | Build runner integration and error reporting |

### 🎯 Fully Implemented Core Features

✅ **Complete Type Safety** - Compile-time validation throughout entire data layer
✅ **Smart Builder Pagination** - Revolutionary pagination system with zero inconsistency risk
✅ **Three Update Patterns** - Array-style, modify, and incremental modify methods
✅ **Advanced Querying** - Complex logical operations with nested object support
✅ **Real-time Operations** - Automatic subscription management and live updates
✅ **Schema Architecture** - Multiple ODM instances with different collection structures
✅ **Production Ready** - Full transaction support and testing compatibility

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

// Document-level operations
await users.doc('id').update(user);
await users.doc('id').delete();
final user = await users.doc('id').get();

// Collection-level operations (using model's ID field)
await users.insert(user);        // Create new (fails if exists)
await users.update(user);        // Update existing (fails if not exists)
await users.upsert(user);        // Create or update
await users.delete();           // Delete entire collection

// Bulk operations on collections
await users.modify((user) => user.copyWith(isActive: true));
await users.incrementalModify((user) => user.copyWith(points: user.points + 10));

// Advanced document operations
await users.doc('id').modify((user) => user.copyWith(age: 26));
await users.doc('id').incrementalModify((user) => user.copyWith(age: user.age + 1));
```

#### Insert vs Update vs Upsert

**`insert(T value)`** - Type-safe document creation
- ✅ Creates new document using model's ID field
- ✅ Auto-generates unique ID when model ID is empty string
- ❌ Fails if document already exists (when ID is specified)
- 🎯 Perfect for preventing accidental overwrites

**`update(T value)`** - Type-safe document updates
- ✅ Updates existing document using model's ID field
- ❌ Fails if document doesn't exist
- 🎯 Perfect for ensuring you're updating existing data

**`upsert(T value)`** - Flexible create-or-update
- ✅ Creates new document if it doesn't exist
- ✅ Updates document if it already exists
- 🎯 Perfect for idempotent operations

```dart
// Example workflow
final user = User(id: 'alice', name: 'Alice', email: 'alice@example.com');

// First time - create new user with specific ID
await odm.users.insert(user);     // ✅ Success

// Try to insert again
await odm.users.insert(user);     // ❌ Throws StateError: already exists

// Insert with server-generated ID
final autoUser = User(id: '', name: 'Auto User', email: 'auto@example.com');
await odm.users.insert(autoUser); // ✅ Success, Firestore generates unique ID

// Update existing user
final updatedUser = user.copyWith(name: 'Alice Smith');
await odm.users.update(updatedUser); // ✅ Success

// Try to update non-existent user
final newUser = User(id: 'bob', name: 'Bob', email: 'bob@example.com');
await odm.users.update(newUser);     // ❌ Throws StateError: doesn't exist

// Upsert works in both cases
await odm.users.upsert(user);     // ✅ Updates existing
await odm.users.upsert(newUser);  // ✅ Creates new
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

// Map operations
users.where(($) => $.mapField.key('keyName')(isEqualTo: value))
users.where(($) => $.mapField.key('keyName')(isNull: false))
users.where(($) => $.mapField(isEqualTo: {...}))

// Logical operations
users.where(($) => $.and(filter1, filter2, filter3))
users.where(($) => $.or(filter1, filter2, filter3))

// Ordering and limiting
users.orderBy(($) => $.field(descending: true))
users.limit(10)
users.startAfter(document)
users.endBefore(document)

// Delete operations
users.where(($) => $.isActive(isEqualTo: false)).delete()
users.orderBy(($) => $.rating()).limit(10).delete()
users.delete() // Delete entire collection
```

### Update Operations

```dart
// Array-style updates
await doc.patch(($) => [
  $.field(newValue),                    // Direct assignment
  $.nestedObject.field(value),          // Nested updates
  $.arrayField.add(item),               // Array union
  $.arrayField.remove(item),            // Array remove
  $.numericField.increment(5),          // Numeric increment
  $.timestampField.serverTimestamp(),   // Server timestamp
  $.mapField.setKey('key', value),      // Map key update
  $.mapField.removeKey('key'),          // Map key removal
  $.mapField({'key': 'value'}),         // Complete map replacement
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

// Bulk operations work with all update methods
await users.where(($) => $.isActive(isEqualTo: true)).patch(($) => [
  $.lastActive.serverTimestamp(),
]);
await users.modify((user) => user.copyWith(updatedAt: DateTime.now()));
await users.incrementalModify((user) => user.copyWith(points: user.points + 1));
```

### Real-time Streams

```dart
// Document snapshots
final stream = doc.stream;
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
await odm.runTransaction((tx) async {
  // All operations automatically use transaction context
  final doc1 = await tx.collection1.doc('id1').get();
  final doc2 = await tx.collection2.doc('id2').get();
  
  await odm.collection1.doc('id1').modify((d) => d.copyWith(field: newValue));
  odm.collection2.doc('id2').patch(($) => [$.field.increment(1)]);
});
```

## Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to transform your Firestore experience?** [Get started](#quick-start) now and build type-safe, maintainable Flutter apps! 🚀