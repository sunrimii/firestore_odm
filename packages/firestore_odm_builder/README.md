# Firestore ODM Builder

Code generator for Firestore ODM annotations. Generates type-safe Firestore operations from annotated classes.

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

This package automatically generates code when you use the annotations from `firestore_odm_annotation`:

```dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

@Collection('users')
class User {
  const User({required this.name, required this.email});
  final String name;
  final String email;
}
```

Run the code generator:

```bash
dart run build_runner build
```

This generates type-safe collection references, query builders, and serialization code.

## Generated Features

- Collection references (`usersCollection`)
- Type-safe query builders
- Automatic serialization/deserialization
- Real-time snapshot support
- Transaction and batch operations

## Links

- [Main package: firestore_odm](https://pub.dev/packages/firestore_odm)
- [Annotations: firestore_odm_annotation](https://pub.dev/packages/firestore_odm_annotation)
- [GitHub Repository](https://github.com/sylphxltd/firestore_odm)