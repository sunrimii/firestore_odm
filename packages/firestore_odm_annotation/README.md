# Firestore ODM Annotation

Pure annotations for Firestore ODM code generation. This package provides the core annotations used to generate type-safe Firestore ODM code.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  firestore_odm_annotation: ^1.0.0
```

## Usage

This package provides annotations to mark your classes for Firestore ODM code generation:

```dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

@Collection('users')
class User {
  const User({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;
}
```

## Available Annotations

- `@Collection(path)` - Marks a class as a Firestore collection
- `@SubCollection(path)` - Marks a class as a Firestore subcollection  
- `@DocumentId()` - Marks a field as the document ID
- `@FirestoreField(name)` - Maps a field to a different Firestore field name

## Code Generation

To generate the ODM code, you'll also need:

```yaml
dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.0
```

Then run:

```bash
dart run build_runner build
```

## Features

- Type-safe Firestore operations
- Automatic serialization/deserialization
- Query builder support
- Real-time updates
- Subcollection support

## Links

- [Main package: firestore_odm](https://pub.dev/packages/firestore_odm)
- [Code generator: firestore_odm_builder](https://pub.dev/packages/firestore_odm_builder)
- [Documentation](https://pub.dev/documentation/firestore_odm/latest/)
- [GitHub Repository](https://github.com/sylphxltd/firestore_odm)