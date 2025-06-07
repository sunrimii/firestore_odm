# Firestore ODM

A type-safe Object Document Mapper (ODM) for Cloud Firestore with code generation support.

## Features

- 🔥 **Type-safe queries** - Strong typing for all field operations
- 🚀 **Code generation** - Automatic generation of collection, query, and document classes
- 📝 **Simple annotations** - Just add `@CollectionPath('collection_name')` to your models
- 🎯 **Intuitive API** - Fluent interface for building complex queries
- 🔍 **Rich query support** - Support for where clauses, ordering, and array operations
- 📦 **Monorepo structure** - Clean separation of concerns

## Package Structure

This project consists of three packages:

- **`firestore_odm_annotation`** - Pure annotations (no Flutter dependencies)
- **`firestore_odm`** - Core ODM classes with Flutter/Firestore integration
- **`firestore_odm_builder`** - Code generator for build_runner

## Installation

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm: ^1.0.0
  # Your other dependencies...

dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.9
  # Your other dev dependencies...
```

## Usage

### 1. Define Your Model

Create a model class with Freezed and add the `@CollectionPath` annotation:

```dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';
part 'user.odm.dart'; // Generated ODM file

@freezed
@CollectionPath('users')
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    required List<String> tags,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Generate Code

Run the code generator:

```bash
dart run build_runner build
```

This generates a `user.odm.dart` file with type-safe collection, query, and document classes.

### 3. Use the Generated ODM

```dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Get the ODM instance
  final odm = FirestoreODM();
  
  // Access the users collection
  final usersCollection = odm.users;
  
  // Type-safe queries
  final adults = await usersCollection
      .whereAge(isGreaterThanOrEqualTo: 18)
      .whereName(startsWith: 'John')
      .orderByCreatedAt(descending: true)
      .limit(10)
      .get();
  
  // Create a new user
  final newUser = User(
    id: 'user123',
    name: 'John Doe',
    email: 'john@example.com',
    age: 25,
    tags: ['developer', 'flutter'],
    createdAt: DateTime.now(),
  );
  
  // Add to Firestore
  await usersCollection.add(newUser);
  
  // Get a specific document
  final userDoc = usersCollection.doc('user123');
  final userData = await userDoc.get();
  
  // Update a document
  await userDoc.update(userData.copyWith(age: 26));
  
  // Delete a document
  await userDoc.delete();
}
```

### 4. Advanced Queries

The generated ODM provides type-safe methods for all field types:

```dart
// String fields
final users = await usersCollection
    .whereName(isEqualTo: 'John')
    .whereEmail(startsWith: 'john@')
    .get();

// Numeric fields
final youngUsers = await usersCollection
    .whereAge(isLessThan: 30)
    .whereAge(isGreaterThan: 18)
    .get();

// Array fields
final developers = await usersCollection
    .whereTags(arrayContains: 'developer')
    .get();

// Date fields
final recentUsers = await usersCollection
    .whereCreatedAt(isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
    .orderByCreatedAt(descending: true)
    .get();

// Complex queries
final complexQuery = await usersCollection
    .whereName(whereIn: ['John', 'Jane', 'Bob'])
    .whereAge(isGreaterThanOrEqualTo: 21)
    .whereTags(arrayContainsAny: ['flutter', 'dart'])
    .orderByCreatedAt(descending: true)
    .limit(50)
    .get();
```

### 5. Real-time Streams

```dart
// Listen to collection changes
usersCollection
    .whereAge(isGreaterThan: 18)
    .snapshots()
    .listen((snapshot) {
  for (final user in snapshot.docs) {
    print('User: ${user.data.name}');
  }
});

// Listen to document changes
usersCollection
    .doc('user123')
    .snapshots()
    .listen((doc) {
  if (doc.exists) {
    print('User updated: ${doc.data.name}');
  }
});
```

## Generated Classes

For each model with `@CollectionPath`, the generator creates:

- **`UserCollection`** - Collection-level operations (add, query, etc.)
- **`UserQuery`** - Type-safe query builder with where/orderBy methods
- **`UserDocument`** - Document-level operations (get, update, delete, etc.)
- **`UserQueryMixin`** - Shared query methods between collection and query classes

## Type Safety

The ODM provides complete type safety:

- ✅ **Field types** - `whereAge(isEqualTo: 25)` only accepts `int`
- ✅ **Array operations** - `whereTags(arrayContains: 'tag')` for List fields
- ✅ **String operations** - `whereName(startsWith: 'prefix')` for String fields
- ✅ **Compile-time errors** - Invalid field names or types cause build errors
- ✅ **IDE support** - Full autocomplete and IntelliSense

## Development

This project uses Melos for monorepo management:

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap

# Run tests
melos test

# Format code
melos format

# Analyze code
melos analyze

# Build example
melos run build:example
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.