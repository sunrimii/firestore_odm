# Firestore ODM

Type-safe Firestore ODM with code generation support. Generate type-safe Firestore operations with annotations.

## 📚 Quick Navigation

### 🚀 Getting Started
- [Installation](#installation) - Add dependencies to your project
- [Quick Start](#quick-start) - Define models and generate code
- [Collection Operations](#collection-operations) - Basic CRUD operations

### 📋 API Reference
- [Insert Operations](#insert-operations) - [`insert()`](#insert-operations) with ID management
- [Update Operations](#update-operations) - [`updateDocument()`](#update-operations), [`upsert()`](#upsert-operations)
- [Features Overview](#features) - Complete feature list and limitations

### 📖 Full Documentation
- [Complete Feature Guide](../../README.md) - Detailed examples and advanced usage
- [API Reference](https://pub.dev/documentation/firestore_odm/latest/) - Generated API docs
- [GitHub Repository](https://github.com/sylphxltd/firestore_odm) - Source code and issues

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm: ^1.0.0
  
dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.0
```

## Quick Start

1. Define your model with annotations:

```dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

@Collection('users')
class User {
  const User({required this.name, required this.email});
  final String name;
  final String email;
}
```

2. Generate code:

```bash
dart run build_runner build
```

3. Use type-safe operations:

```dart
// Insert (create new document, fails if exists)
await usersCollection.insert(User(id: 'user1', name: 'John', email: 'john@example.com'));

// Update (fails if document doesn't exist)
await usersCollection.updateDocument(User(id: 'user1', name: 'John Doe', email: 'john.doe@example.com'));

// Upsert (create or update)
await usersCollection.upsert(User(id: 'user3', name: 'Bob', email: 'bob@example.com'));

// Query
final users = await usersCollection.where((user) => user.name.isEqualTo('John')).get();

// Real-time updates
usersCollection.snapshots().listen((snapshot) {
  for (final user in snapshot.docs) {
    print('User: ${user.data.name}');
  }
});
```

## Collection Operations

### Insert Operations

**`insert(T value)`** - Creates a new document using the model's ID field
- Fails if document already exists (when ID is specified)
- If ID is empty string, server generates a unique ID automatically
- Requires the model to have a non-null ID field

```dart
// Insert with specific ID
final user = User(id: 'user123', name: 'John', email: 'john@example.com');
await usersCollection.insert(user);

// Insert with server-generated ID
final user2 = User(id: '', name: 'Jane', email: 'jane@example.com');
await usersCollection.insert(user2); // Firestore generates unique ID
```

### Update Operations

**`updateDocument(T value)`** - Updates an existing document using the model's ID field
- Fails if document doesn't exist
- Completely replaces the document data

```dart
final updatedUser = User(id: 'user123', name: 'John Doe', email: 'john.doe@example.com');
await usersCollection.updateDocument(updatedUser);
```

**`upsert(T value)`** - Creates or updates a document
- Uses the model's ID field as document ID
- Creates if document doesn't exist, updates if it does

```dart
final user = User(id: 'user123', name: 'John', email: 'john@example.com');
await usersCollection.upsert(user); // Works whether user123 exists or not
```

## Features

### ✅ Fully Implemented
- **Type-safe Operations** - Complete compile-time validation
- **Document ID Fields** - Virtual `@DocumentIdField()` with automatic detection
- **Advanced Querying** - Complex filters, nested objects, logical operations
- **Three Update Methods** - Array-style, modify, and incremental modify
- **Real-time Streams** - Automatic subscription management
- **Aggregate Operations** - Type-safe `count()`, `sum()`, `average()` with generated selectors
- **Transactions** - Full ACID transaction support
- **Schema Architecture** - Multiple ODM instances with different collection structures
- **Subcollections** - Fluent API for nested collections
- **Testing Support** - Full compatibility with `fake_cloud_firestore`

### ❌ Current Limitations
- **Map Field Access** - Direct access to map fields like `profile.socialLinks.github`
- **Pagination** - Enhanced cursor-based pagination helpers need improvement

### 🚧 Workarounds Available
```dart
// Map field filtering - use map-level operations
await users.where(($) => $.profile.socialLinks(isNotEqualTo: null)).get();

// Complex map updates - replace entire map
await userDoc.update(($) => [$.profile.socialLinks({'github': 'username'})]);
```

## Documentation

- [Complete Feature Guide](../../README.md) - Full documentation with examples
- [API Reference](https://pub.dev/documentation/firestore_odm/latest/)
- [GitHub Repository](https://github.com/sylphxltd/firestore_odm)