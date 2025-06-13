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

## 📚 Documentation

📖 **[Complete Documentation](https://sylphxltd.github.io/firestore_odm/)** - Comprehensive guides, examples, and API reference

## 📚 Documentation

📖 **[Complete Documentation](https://sylphxltd.github.io/firestore_odm/)** - Comprehensive guides, examples, and API reference

## 📚 Table of Contents

- [🚀 Getting Started](#-getting-started)
  - [1. Installation](#1-installation)
  - [2. Define Your Model](#2-define-your-model)
  - [3. Define Your Schema](#3-define-your-schema)
  - [4. Generate Code](#4-generate-code)
  - [5. Start Using](#5-start-using)
- [🌟 Core Concepts](#-core-concepts)
  - [Schema-Based Architecture](#schema-based-architecture)
  - [Flexible Data Modeling](#flexible-data-modeling)
  - [Type-Safe Everything](#type-safe-everything)
- [✨ Key Features](#-key-features)
  - [🔍 Type-Safe Queries](#-type-safe-queries)
  - [🔄 Powerful Updates](#-powerful-updates)
  - [🧠 Smart Pagination](#-smart-pagination)
  - [📊 Aggregate Operations](#-aggregate-operations)
  - [🔗 Subcollections](#-subcollections)
  - [🏦 Transactions](#-transactions)
- [🧪 Testing](#-testing)
- [📄 API Reference](#-api-reference)
- [🤝 Contributing](#-contributing)

---

## 🚀 Getting Started

Get up and running with Firestore ODM in five simple steps.

### 1. Installation

Add the necessary dependencies to your `pubspec.yaml`:

```yaml
# pubspec.yaml
dependencies:
  cloud_firestore: ^4.0.0 # Or your desired version
  firestore_odm: ^1.0.0
  firestore_odm_annotation: ^1.0.0
  # One of: freezed_annotation, json_annotation
  freezed_annotation: ^2.0.0

dev_dependencies:
  build_runner: ^2.0.0
  firestore_odm_builder: ^1.0.0
  # One of: freezed, json_serializable
  freezed: ^2.0.0
  json_serializable: ^6.0.0
```

### 2. Define Your Model

Create your data model using `freezed` or a plain Dart class with `json_serializable`.

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
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 3. Define Your Schema

Group your collections into a schema. This is the single source of truth for your database structure.

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

part 'schema.odm.dart';

@Schema()
@Collection<User>("users")
final appSchema = _$AppSchema;
```

> **Note:** The `@Schema()` annotation is crucial for the generator to correctly process your collections.

### 4. Generate Code

Run the `build_runner` to generate the required ODM code:

```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs
```

### 5. Start Using

Initialize the ODM and start performing type-safe operations.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(appSchema, firestore: firestore);

  // Create a user
  await odm.users.insert(User(id: 'jane', name: 'Jane Smith', email: 'jane@example.com'));

  // Get a user
  final user = await odm.users('jane').get();
  print(user?.name); // Prints "Jane Smith"

  // Query users
  final smiths = await odm.users.where((_) => _.name(isEqualTo: 'Jane Smith')).get();
  print('Found ${smiths.length} users named Jane Smith');
}
```

## 🌟 Core Concepts

### Schema-Based Architecture

The schema is the heart of the ODM. By defining all your collections in one place, you get:
- **Compile-time validation** of collection paths and model relationships.
- **Automatic parent-child detection** for subcollections.
- **No manual model imports** needed for nested types.
- The ability to have **multiple, separate ODM instances** for different parts of your app.

```dart
// Define multiple collections and subcollections in one place
@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
@Collection<Post>("users/*/posts") // User subcollection
final appSchema = _$AppSchema;
```

### Flexible Data Modeling

`firestore_odm` is unopinionated about how you create your models.

- **`freezed` (Recommended):** The examples use `freezed` for its concise and robust immutable classes.
- **`json_serializable`:** Use plain, hand-written Dart classes with the `json_serializable` package. This gives you full control.
- **`fast_immutable_collections`:** Integrate for high-performance, truly immutable lists (`IList`), maps (`IMap`), and sets (`ISet`).

```dart
// Example model with fast_immutable_collections
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
// ...

@freezed
class Product with _$Product {
  const factory Product({
    @DocumentIdField() required String id,
    required String name,
    required IList<String> tags, // Immutable list
  }) = _Product;
  // ...
}
```

### Type-Safe Everything

Every API in `firestore_odm` is designed to be type-safe. From queries to updates, the Dart compiler becomes your best defense against common database errors.

- ✅ **Queries:** `odm.users.where((_) => _.age(isGreaterThan: 18))`
- ✅ **Updates:** `odm.users('id').patch((_) => [_.age.increment(1)])`
- ✅ **Pagination:** `odm.users.orderBy((_) => _.age()).startAfterObject(lastUser)`
- ✅ **Aggregates:** `odm.users.aggregate((_) => _.age.average())`

Say goodbye to `string-based` field names and runtime errors.

## ✨ Key Features

### 🔍 Type-Safe Queries

Write complex, readable queries that are validated at compile-time.

```dart
// Complex logical query
final engagedUsers = await odm.users
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.or(
      $.tags(arrayContains: 'premium'),
      $.profile.followers(isGreaterThan: 1000),
    ),
  ))
  .get();

// Map field query
final darkThemeUsers = await odm.users
  .where(($) => $.settings.key('theme')(isEqualTo: 'dark'))
  .get();
```

### 🔄 Powerful Updates

Choose the update pattern that best fits your needs. All methods support both single-document and bulk updates.

- **`patch()` (Array-Style):** For explicit, atomic operations.
- **`modify()`:** For immutable, diff-based updates using `copyWith`.
- **`incrementalModify()` (Recommended):** Automatically detects and applies atomic operations like `FieldValue.increment()` and `FieldValue.arrayUnion()`.

```dart
// 1. patch() - Explicit and atomic
await userDoc.patch(($) => [
  $.name('John Smith'),
  $.age.increment(1),
  $.tags.add('verified'),
]);

// 2. incrementalModify() - Smart and convenient
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,              // Auto-detects -> FieldValue.increment(1)
  tags: [...user.tags, 'expert'], // Auto-detects -> FieldValue.arrayUnion()
));

// 3. Bulk update an entire query
await odm.users
  .where(($) => $.isActive(isEqualTo: false))
  .patch(($) => [$.isActive(true)]);
```

### 🧠 Smart Pagination

Our revolutionary "Smart Builder" provides strongly-typed pagination with zero risk of inconsistency. The same builder function is used for both ordering and cursor creation.

```dart
// Define the ordering and cursor fields ONCE
final builder = ($) => ($.followers(true), $.name()); // Order by followers (desc), then name (asc)

// 1. Get the first page
final firstPage = await odm.users.orderBy(builder).limit(10).get();

// 2. Get the next page with perfect type-safety
if (firstPage.isNotEmpty) {
  final nextPage = await odm.users
    .orderBy(builder)
    .startAfterObject(firstPage.last) // Auto-extracts cursor from the last user object
    .limit(10)
    .get();
}
```

### 📊 Aggregate Operations

Perform `count`, `sum`, and `average` aggregations with full type-safety and real-time stream support.

```dart
// Get aggregate data for active users
final stats = await odm.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),              // Returns int
    avgAge: $.age.average(),       // Returns double
    totalPoints: $.points.sum(),   // Returns int (or double if points is double)
  ))
  .get();

print('Active users: ${stats.count}');
print('Average age: ${stats.avgAge}');

// Also available as a stream: .aggregate(...).stream
```

### 🔗 Subcollections

Define and access subcollections with a fluent, type-safe API.

```dart
// 1. Define in schema
@Schema()
@Collection<User>("users")
@Collection<Post>("users/*/posts") // Subcollection of users
final appSchema = _$AppSchema;

// 2. Access with type-safety
final userPosts = odm.users('jane').posts;

// 3. Perform operations
await userPosts.insert(Post(id: 'post1', title: 'My First Post'));
final allPosts = await userPosts.get();
```

### 🏦 Transactions

Run atomic, multi-document operations with ACID guarantees. The transaction context is automatically passed to all ODM operations within the callback.

```dart
await odm.runTransaction((tx) async {
  final sender = await tx.users('user1').get();
  final receiver = await tx.users('user2').get();

  if (sender!.balance >= 100) {
    // All operations inside this block are part of the transaction
    await tx.users('user1').patch(($) => [$.balance.increment(-100)]);
    await tx.users('user2').patch(($) => [$.balance.increment(100)]);
  }
});
```

## 🧪 Testing

The ODM integrates perfectly with `package:fake_cloud_firestore` for fast and reliable unit/widget testing.

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
// ... your imports

void main() {
  test('user queries work correctly', () async {
    final firestore = FakeFirebaseFirestore();
    final odm = FirestoreODM(appSchema, firestore: firestore);

    await odm.users.insert(User(id: 'test', name: 'Test User', email: '...'));

    final result = await odm.users('test').get();
    expect(result?.name, 'Test User');
  });
}
```

## 📄 API Reference

For a detailed look at all available methods, please explore the generated code and the source files linked below.

- **[Collection Operations](#-powerful-updates):** `insert`, `update`, `upsert`, `patch`, `modify`, `delete`.
- **[Query Operations](#-type-safe-queries):** `where`, `orderBy`, `limit`, `startAt`, `endBefore`.
- **[Document Operations:** `get`, `stream`, `delete`, `patch`, `modify`.

## 🤝 Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to transform your Firestore experience?** [Get started](#-getting-started) now and build type-safe, maintainable Flutter apps! 🚀