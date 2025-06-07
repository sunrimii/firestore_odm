# Firestore ODM

A powerful Object-Document Mapping (ODM) library for Cloud Firestore in Flutter/Dart applications. This library provides type-safe, reactive access to Firestore with automatic code generation.

## Features

- 🔥 **Type-safe Firestore operations** - Full type safety with compile-time checks
- 🚀 **Automatic code generation** - Generate collection and document classes from annotations
- 📱 **Reactive streams** - Real-time updates with automatic subscription management
- 🔄 **Optimistic updates** - Efficient partial updates with automatic diff computation
- 🏗️ **Transaction support** - Built-in transaction handling for atomic operations
- 📦 **Monorepo structure** - Separate packages for annotations and code generation

## Packages

This monorepo contains two packages:

### `firestore_odm_annotation`
Runtime annotations and base classes for the ODM. Add this to your app's dependencies.

### `firestore_odm_builder`
Code generator for creating ODM classes. Add this to your app's dev_dependencies.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm_annotation: ^1.0.0
  cloud_firestore: ^5.4.4
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.9
  freezed: ^2.5.7
  json_serializable: ^6.8.0
```

## Usage

### 1. Define your model with annotations

```dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';
part 'user.odm.dart'; // Generated ODM code

@freezed
@CollectionPath('users')
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    @Default([]) List<String> tags,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Generate code

Run the code generator:

```bash
dart run build_runner build
```

### 3. Use the generated ODM

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user.dart';

void main() async {
  await Firebase.initializeApp();
  
  // Access the generated collection
  final usersCollection = UserCollection();
  
  // Create a new user
  final newUser = User(
    id: 'user123',
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
  );
  
  // Save to Firestore
  await usersCollection.doc('user123').set(newUser);
  
  // Get a user
  final user = await usersCollection.doc('user123').get();
  print('User: ${user?.name}');
  
  // Listen to real-time updates
  usersCollection.doc('user123').changes.listen((user) {
    print('User updated: ${user?.name}');
  });
  
  // Update user
  await usersCollection.doc('user123').update((user) => user.copyWith(
    age: user.age + 1,
  ));
  
  // Query users
  final activeUsers = await usersCollection
      .where('isActive', isEqualTo: true)
      .get();
  
  // Stream query results
  usersCollection
      .where('age', isGreaterThan: 18)
      .snapshots()
      .listen((users) {
    print('Adult users: ${users.length}');
  });
}
```

## Advanced Features

### Subcollections

```dart
@freezed
@SubcollectionPath('users/{userId}/posts')
class Post with _$Post {
  const factory Post({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### Transactions

```dart
await runFirestoreTransaction(() async {
  final user = await usersCollection.doc('user123').get();
  if (user != null) {
    await usersCollection.doc('user123').update((u) => u.copyWith(
      age: u.age + 1,
    ));
  }
});
```

### Custom Queries

```dart
// Complex queries
final results = await usersCollection
    .where('age', isGreaterThan: 18)
    .where('isActive', isEqualTo: true)
    .orderBy('name')
    .limit(10)
    .get();

// Real-time queries
usersCollection
    .where('tags', arrayContains: 'flutter')
    .snapshots()
    .listen((users) {
  // Handle real-time updates
});
```

## Architecture

The ODM follows a clean architecture pattern:

- **Annotations**: Define collection paths and document structure
- **Generated Code**: Type-safe collection and document classes
- **Runtime Classes**: Base classes for collections, documents, and queries
- **Reactive Streams**: Automatic subscription management and real-time updates

## Development

This project uses Melos for monorepo management:

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap

# Run tests
melos run test

# Analyze code
melos run analyze

# Format code
melos run format
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run `melos run analyze` and `melos run test`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.