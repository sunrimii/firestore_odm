# Firestore ODM

Type-safe Firestore ODM with code generation support. Generate type-safe Firestore operations with annotations.

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
// Create
await usersCollection.add(User(name: 'John', email: 'john@example.com'));

// Query
final users = await usersCollection.where((user) => user.name.isEqualTo('John')).get();

// Real-time updates
usersCollection.snapshots().listen((snapshot) {
  for (final user in snapshot.docs) {
    print('User: ${user.data.name}');
  }
});
```

## Features

- ✅ Type-safe Firestore operations
- ✅ Automatic serialization/deserialization  
- ✅ Query builder with IntelliSense
- ✅ Real-time updates
- ✅ Subcollection support
- ✅ Transaction support
- ✅ Batch operations

## Documentation

- [API Reference](https://pub.dev/documentation/firestore_odm/latest/)
- [GitHub Repository](https://github.com/sylphxltd/firestore_odm)