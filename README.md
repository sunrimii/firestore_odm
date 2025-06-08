# Firestore ODM for Dart/Flutter

A powerful Object-Document Mapping (ODM) library for Cloud Firestore in Dart and Flutter applications. This library provides type-safe, code-generated access to Firestore with advanced filtering, querying, and update capabilities.

## Features

- 🔥 **Type-safe Firestore operations** - Generated code ensures compile-time safety
- 🎯 **Advanced nested filtering** - Fluent API for complex queries with deep nested field support
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
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';
part 'user.odm.dart';

@freezed
@CollectionPath('users')
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    required Profile profile,
    required bool isActive,
    required bool isPremium,
    required double rating,
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
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(firestore);

  // Create a user
  final user = User(
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    age: 25,
    profile: Profile(
      bio: 'Software developer',
      avatar: 'avatar.jpg',
      socialLinks: {'github': 'johndoe', 'twitter': 'john_dev'},
      interests: ['coding', 'gaming'],
      followers: 100,
    ),
    isActive: true,
    isPremium: false,
    rating: 4.5,
    tags: ['developer', 'flutter'],
    createdAt: DateTime.now(),
  );

  await odm.users.doc(user.id).set(user);
}
```

## Advanced Filtering with New Where API

### Basic Field Filtering

```dart
// Basic field filtering
final activeUsers = await odm.users
    .where((filter) => filter.isActive(isEqualTo: true))
    .get();

// Numeric comparisons
final youngUsers = await odm.users
    .where((filter) => filter.age(isLessThan: 30))
    .get();

// String operations
final johnUsers = await odm.users
    .where((filter) => filter.name(isEqualTo: 'John Doe'))
    .get();

// Array operations
final developerUsers = await odm.users
    .where((filter) => filter.tags(arrayContains: 'developer'))
    .get();
```

### Nested Object Filtering

```dart
// Filter by nested profile fields
final popularUsers = await odm.users
    .where((filter) => filter.profile.followers(isGreaterThan: 100))
    .get();

// Filter by social links
final githubUsers = await odm.users
    .where((filter) => filter.profile.socialLinks.github(isNotEqualTo: null))
    .get();

// Deep nested filtering
final specificLocationUsers = await odm.users
    .where((filter) => filter.profile.contact.address.city(isEqualTo: "Hong Kong"))
    .get();
```

### Complex Logical Operations

```dart
// AND operations
final premiumActiveUsers = await odm.users
    .where((filter) => filter.and(
      filter.isActive(isEqualTo: true),
      filter.isPremium(isEqualTo: true),
      filter.age(isGreaterThan: 18),
    ))
    .get();

// OR operations
final eligibleUsers = await odm.users
    .where((filter) => filter.or(
      filter.isPremium(isEqualTo: true),
      filter.rating(isGreaterThanOrEqualTo: 4.0),
    ))
    .get();

// Nested AND/OR combinations
final complexQuery = await odm.users
    .where((filter) => filter.and(
      filter.isActive(isEqualTo: true),
      filter.or(
        filter.isPremium(isEqualTo: true),
        filter.and(
          filter.age(isLessThan: 25),
          filter.rating(isGreaterThan: 4.0),
        ),
      ),
    ))
    .get();
```

### Real-World Complex Filtering Example

```dart
// Find active users with high engagement
final engagedUsers = await odm.users
    .where((filter) => filter.and(
      filter.age(isGreaterThan: 18),
      filter.profile.followers(isGreaterThan: 100),
      filter.profile.socialLinks.github(isNotEqualTo: null),
      filter.or(
        filter.isPremium(isEqualTo: true),
        filter.rating(isGreaterThanOrEqualTo: 4.5),
      ),
    ))
    .get();
```

## Array-Style Updates

Firestore ODM supports powerful array-style update operations that allow you to combine multiple update types in a single operation.

```dart
// Get a document reference
final userDoc = odm.users.doc('user1');

// Basic field updates
await userDoc.update(($) => [
  $.name('New Name'),
  $.age(26),
  $.isActive(false),
]);

// Nested field updates
await userDoc.update((update) => [
  update.profile.bio('Updated bio'),
  update.profile.followers(150),
]);

// Array operations
await userDoc.update((update) => [
  update.tags.add('expert'),
  update.scores.add(95),
]);

// Numeric increment operations
await userDoc.update((update) => [
  update.age.increment(1),
  update.rating.increment(0.5),
  update.profile.followers.increment(50),
]);

// Server timestamp operations
await userDoc.update((update) => [
  update.lastLogin.serverTimestamp(),
  update.updatedAt.serverTimestamp(),
]);

// Object merge operations
await userDoc.update((update) => [
  update({'name': 'John Smith', 'isPremium': true}),
  update.profile({'bio': 'Senior Developer', 'followers': 200}),
]);

// Mixed operations - The Revolutionary Feature! 🚀
await userDoc.update((update) => [
  // Increments
  update.age.increment(1),
  update.rating.increment(0.5),
  update.profile.followers.increment(50),
  
  // Array operations
  update.tags.add('expert'),
  update.tags.add('verified'),
  
  // Object merges
  update({
    'age': 26, // Can override increments
    'rating': 3.5,
    'isPremium': true,
  }),
  update.profile({
    'followers': 150, // Can override increments
    'bio': 'Full-stack developer',
  }),
  
  // Server timestamps
  update.lastLogin.serverTimestamp(),
]);
```

## Ordering and Limiting

```dart
// Order by field
final orderedUsers = await odm.users
    .orderByAge(descending: true)
    .limit(10)
    .get();

// Order by nested fields
final popularUsers = await odm.users
    .orderByRating(descending: true)
    .orderByCreatedAt()
    .limit(20)
    .get();

// Combine filtering and ordering
final topActiveUsers = await odm.users
    .where((filter) => filter.isActive(isEqualTo: true))
    .orderByRating(descending: true)
    .limit(10)
    .get();
```

## Generated Code Structure

For each `@CollectionPath` class, the generator creates:

- **Collection class** (`UserCollection`) - Entry point for queries
- **Query class** (`UserQuery`) - Chainable query builder  
- **Filter class** (`UserFilter`) - Type-safe filtering
- **FilterBuilder class** (`UserFilterBuilder`) - Filter construction
- **Document extensions** - Convenient update methods

## API Reference

### Collection Operations

```dart
final users = odm.users;

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
// Basic equality
filter.field(isEqualTo: value)
filter.field(isNotEqualTo: value)

// Numeric comparisons
filter.field(isLessThan: value)
filter.field(isLessThanOrEqualTo: value)
filter.field(isGreaterThan: value)
filter.field(isGreaterThanOrEqualTo: value)

// Array membership
filter.field(whereIn: [values])
filter.field(whereNotIn: [values])

// Array field operations
filter.arrayField(arrayContains: value)
filter.arrayField(arrayContainsAny: [values])

// Null checks
filter.field(isNull: true)

// Nested object filtering
filter.nestedObject.field(isEqualTo: value)
filter.deeply.nested.object.field(isGreaterThan: value)

// Logical operations
filter.and(filter1, filter2, filter3, ...)  // Up to 30 filters
filter.or(filter1, filter2, filter3, ...)   // Up to 30 filters
```

### Update Operations

```dart
// Basic field updates
await doc.update((update) => [
  update.field1(newValue),
  update.field2(anotherValue),
]);

// Nested field updates
await doc.update((update) => [
  update.nestedObject.field(value),
  update.deeply.nested.object.field(anotherValue),
]);

// Array operations
await doc.update((update) => [
  update.arrayField.add(item),
  update.arrayField.remove(item),
]);

// Numeric operations
await doc.update((update) => [
  update.numericField.increment(5),
  update.nestedObject.count.increment(1),
]);

// Server timestamp
await doc.update((update) => [
  update.timestampField.serverTimestamp(),
]);

// Object merge operations
await doc.update((update) => [
  update({'field1': 'value1', 'field2': 'value2'}),
  update.nestedObject({'subField': 'newValue'}),
]);

// Mixed operations in single update
await doc.update((update) => [
  update.name('John'),
  update.age.increment(1),
  update.tags.add('expert'),
  update.profile.followers.increment(10),
  update({'isPremium': true}),
  update.lastUpdated.serverTimestamp(),
]);
```

## Testing

The library works seamlessly with `fake_cloud_firestore` for testing:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';

void main() {
  test('user operations', () async {
    final firestore = FakeFirebaseFirestore();
    final odm = FirestoreODM(firestore);
    
    // Test complex filtering
    final results = await odm.users
        .where((filter) => filter.and(
          filter.isActive(isEqualTo: true),
          filter.profile.followers(isGreaterThan: 50),
        ))
        .get();
    
    expect(results.length, 0); // Initially empty
  });
}
```

## Examples

See the `flutter_example/` directory for a complete working example with:

- Model definitions with nested objects
- CRUD operations
- Advanced filtering with complex nested queries
- Atomic updates
- Comprehensive test suite (69 tests, 100% passing)

## Performance Features

- **Type-safe code generation** - Zero runtime reflection
- **Optimized query construction** - Minimal object allocation
- **Efficient nested field access** - Direct field path generation
- **Compile-time validation** - Catch errors before runtime

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