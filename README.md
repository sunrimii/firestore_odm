# Firestore ODM for Dart/Flutter

A powerful Object-Document Mapping (ODM) library for Cloud Firestore in Dart and Flutter applications. This library provides type-safe, code-generated access to Firestore with advanced filtering, querying, and update capabilities.

## Features

- 🔥 **Type-safe Firestore operations** - Generated code ensures compile-time safety
- 🎯 **Advanced filtering** - Fluent API for complex queries with nested field support
- 🔄 **Atomic updates** - Safe field-level updates with conflict resolution
- 📝 **Code generation** - Automatic generation of collections, queries, and filters
- 🎨 **Fluent API** - Intuitive, chainable method calls
- 🧪 **Test-friendly** - Works seamlessly with `fake_cloud_firestore`

## Architecture

This project is organized as a monorepo with separate packages:

```
packages/
├── firestore_odm/              # Core runtime library
├── firestore_odm_annotation/   # Annotations for code generation
└── firestore_odm_builder/      # Code generator (dev dependency)
```

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm: ^1.0.0
  firestore_odm_annotation: ^1.0.0

dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.7
```

## Quick Start

### 1. Define Your Models

```dart
// lib/models/user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';
part 'user.odm.dart';

@freezed
@FirestoreDocument(collection: 'users')
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    required Profile profile,
    required bool isActive,
    required bool isPremium,
    @Default([]) List<String> tags,
    @Default([]) List<int> scores,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String bio,
    required String avatar,
    required Map<String, String> socialLinks,
    required List<String> interests,
    required int followers,
    DateTime? lastActive,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

### 2. Generate Code

```bash
dart run build_runner build
```

### 3. Initialize and Use

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final users = UserCollection(firestore);

  // Create a user
  final user = User(
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    age: 25,
    profile: Profile(
      bio: 'Software developer',
      avatar: 'avatar.jpg',
      socialLinks: {'github': 'johndoe'},
      interests: ['coding', 'gaming'],
      followers: 100,
    ),
    isActive: true,
    isPremium: false,
    tags: ['developer', 'flutter'],
    createdAt: DateTime.now(),
  );

  await users.doc(user.id).set(user);
}
```

## Advanced Usage

### Filtering and Querying

```dart
// Basic field filtering
final activeUsers = await users
    .where((filter) => filter.isActive(isEqualTo: true))
    .get();

// Numeric comparisons
final youngUsers = await users
    .where((filter) => filter.age(isLessThan: 30))
    .get();

// String operations
final johnUsers = await users
    .where((filter) => filter.name(contains: 'John'))
    .get();

// Array operations
final developerUsers = await users
    .where((filter) => filter.tags(arrayContains: 'developer'))
    .get();

// Multiple conditions
final premiumActiveUsers = await users
    .where((filter) => filter.isActive(isEqualTo: true))
    .where((filter) => filter.isPremium(isEqualTo: true))
    .get();

// Logical operations
final complexQuery = await users
    .where((filter) => filter.or(
      filter.age(isLessThan: 25),
      filter.isPremium(isEqualTo: true),
    ))
    .get();
```

### Atomic Updates

```dart
// Get a document reference
final userDoc = users.doc('user1');

// Atomic field updates
await userDoc.update
    .name('New Name')
    .age(26)
    .isActive(false)
    .apply();

// Nested field updates
await userDoc.update
    .profile.bio('Updated bio')
    .profile.followers(150)
    .apply();

// Array operations
await userDoc.update
    .tags.add('expert')
    .scores.add(95)
    .apply();
```

### Ordering and Limiting

```dart
// Order by field
final orderedUsers = await users
    .orderByAge(descending: true)
    .limit(10)
    .get();

// Multiple ordering
final complexOrder = await users
    .orderByAge()
    .orderByName()
    .get();
```

## Generated Code Structure

For each `@FirestoreDocument` class, the generator creates:

- **Collection class** (`UserCollection`) - Entry point for queries
- **Query class** (`UserQuery`) - Chainable query builder
- **Filter class** (`UserFilter`) - Type-safe filtering
- **Update builder** (`UserUpdateBuilder`) - Atomic updates
- **Document extensions** - Convenient update methods

## API Reference

### Collection Operations

```dart
final users = UserCollection(firestore);

// Document operations
await users.doc('id').set(user);
await users.doc('id').update(updates);
await users.doc('id').delete();
final user = await users.doc('id').get();

// Query operations
final query = users.where((filter) => /* conditions */);
final results = await query.get();
```

### Filter Operations

```dart
// Equality
filter.field(isEqualTo: value)
filter.field(isNotEqualTo: value)

// Comparisons (numbers, strings, dates)
filter.field(isLessThan: value)
filter.field(isLessThanOrEqualTo: value)
filter.field(isGreaterThan: value)
filter.field(isGreaterThanOrEqualTo: value)

// Arrays
filter.field(whereIn: [values])
filter.field(whereNotIn: [values])

// Array fields
filter.arrayField(arrayContains: value)
filter.arrayField(arrayContainsAny: [values])

// Null checks
filter.field(isNull: true)

// String operations
filter.stringField(contains: 'substring')

// Logical operations
filter.or(filter1, filter2, ...)
filter.and(filter1, filter2, ...)
```

### Update Operations

```dart
// Basic field updates
await doc.update
    .field1(newValue)
    .field2(anotherValue)
    .apply();

// Nested field updates
await doc.update
    .nestedObject.field(value)
    .apply();

// Array operations
await doc.update
    .arrayField.add(item)
    .arrayField.remove(item)
    .apply();
```

## Testing

The library works seamlessly with `fake_cloud_firestore` for testing:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  test('user operations', () async {
    final firestore = FakeFirebaseFirestore();
    final users = UserCollection(firestore);
    
    // Your test code here
  });
}
```

## Examples

See the `flutter_example/` directory for a complete working example with:

- Model definitions
- CRUD operations
- Advanced filtering
- Atomic updates
- Comprehensive tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.