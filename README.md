# 🔥 Firestore ODM

A powerful, type-safe Object Document Mapper (ODM) for Firestore with advanced querying and chained update capabilities.

## ✨ Features

- **🔒 Type Safety**: Full compile-time type checking for all operations
- **🔗 Chained Updates**: copyWith-style nested field updates with infinite depth support
- **🔍 Advanced Querying**: Method-chained queries with auto-completion
- **🏗️ Code Generation**: Automatic generation of collection, document, and query classes
- **🎯 Zero Runtime Errors**: Catch errors at compile time, not runtime
- **📱 Multi-Platform**: Works on all Flutter platforms (iOS, Android, Web, Desktop)

## 🚀 Quick Start

### 1. Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm: ^1.0.0
  
dev_dependencies:
  firestore_odm_builder: ^1.0.0
  build_runner: ^2.4.0
```

### 2. Define Your Models

```dart
import 'package:firestore_odm/firestore_odm.dart';
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
    required Profile profile, // Nested object
    @Default(false) bool isPremium,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String bio,
    required String avatar,
    @Default({}) Map<String, String> socialLinks,
    @Default([]) List<String> interests,
    @Default(0) int followers,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

### 3. Generate Code

```bash
dart run build_runner build
```

### 4. Use the ODM

```dart
final odm = FirestoreODM();

// Create user
final user = User(
  id: 'user123',
  name: 'John Doe',
  email: 'john@example.com',
  profile: Profile(
    bio: 'Flutter Developer',
    avatar: 'avatar.jpg',
    socialLinks: {'github': 'johndoe'},
    interests: ['flutter', 'dart'],
    followers: 100,
  ),
  isPremium: true,
  createdAt: DateTime.now(),
);

await odm.users.doc('user123').set(user);
```

## 🔗 Chained Updates (copyWith-style)

The most powerful feature - update nested fields with full type safety:

### Traditional Firestore (❌ Error-Prone)
```dart
// String literals, no type checking, typo-prone
await userDoc.updateFields({
  'profile.bio': 'Updated bio',
  'profile.followers': 200,
  'profile.socialLinks.github': 'new-username',
});
```

### Firestore ODM (✅ Type-Safe)
```dart
// Full type safety, auto-completion, refactoring safe
await userDoc.update.profile(
  bio: 'Updated bio',
  followers: 200,
  socialLinks: {'github': 'new-username'},
);
```

### Multi-Level Nesting Support

```dart
// Supports infinite nesting depth with full type safety
await userDoc.update.profile.story.place.coordinates(
  latitude: 40.7128,
  longitude: -74.0060,
);
```

## 🔍 Advanced Querying

Type-safe queries with method chaining:

```dart
// Query users by age and rating
final topUsers = await odm.users
    .whereAge(isGreaterThan: 18)
    .whereRating(isGreaterThanOrEqualTo: 4.5)
    .whereIsPremium(isEqualTo: true)
    .orderByRating(descending: true)
    .limit(10)
    .get();

// Query with multiple conditions
final activeUsers = await odm.users
    .whereIsActive(isEqualTo: true)
    .whereCreatedAt(isGreaterThan: DateTime.now().subtract(Duration(days: 30)))
    .orderByCreatedAt(descending: true)
    .get();
```

## 📚 Complete Example

```dart
import 'package:firestore_odm/firestore_odm.dart';

void main() async {
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('demo_user');

  // Create user with nested data
  final user = User(
    id: 'demo_user',
    name: 'Demo User',
    email: 'demo@example.com',
    profile: Profile(
      bio: 'Flutter Developer',
      avatar: 'avatar.jpg',
      socialLinks: {'github': 'demo-user'},
      interests: ['flutter', 'dart'],
      followers: 100,
    ),
    isPremium: false,
    createdAt: DateTime.now(),
  );

  // Set document
  await userDoc.set(user);

  // Update top-level fields
  await userDoc.update(name: 'Updated Name', isPremium: true);

  // Update nested profile fields
  await userDoc.update.profile(
    bio: 'Senior Flutter Developer',
    followers: 500,
    socialLinks: {
      'github': 'senior-dev',
      'twitter': '@senior_dev',
      'linkedin': 'senior-developer',
    },
  );

  // Query users
  final premiumUsers = await odm.users
      .whereIsPremium(isEqualTo: true)
      .orderByCreatedAt(descending: true)
      .get();

  print('Found ${premiumUsers.length} premium users');
}
```

## 🏗️ Architecture

### Monorepo Structure

```
firestore_odm/
├── packages/
│   ├── firestore_odm/              # Core runtime library
│   ├── firestore_odm_annotation/   # Annotations for code generation
│   └── firestore_odm_builder/      # Code generator
└── example/                        # Example usage
```

### Generated Classes

For each `@CollectionPath` annotated class, the generator creates:

- **Collection Class**: Type-safe collection operations
- **Document Class**: Type-safe document operations  
- **Query Class**: Type-safe querying with method chaining
- **Update Builder Classes**: Chained update API for nested fields

## 🎯 Benefits

### Type Safety
- ✅ Compile-time validation
- ✅ Auto-completion support
- ✅ Refactoring safe
- ✅ No runtime type errors

### Developer Experience
- ✅ Clean, readable code
- ✅ Reduced boilerplate
- ✅ Intuitive API design
- ✅ Excellent IDE support

### Performance
- ✅ Efficient queries
- ✅ Optimized updates
- ✅ Minimal runtime overhead
- ✅ Tree-shakable code

## 🔧 Advanced Features

### Subcollections

```dart
@freezed
@CollectionPath('users')
@SubcollectionPath<Post>('posts')
class User with _$User {
  // User definition
}

// Access subcollections
final userPosts = await odm.users.doc('user123').posts.get();
```

### Custom Queries

```dart
// Complex filtering
final results = await odm.users
    .whereAge(isGreaterThan: 18, isLessThan: 65)
    .whereRating(whereIn: [4.0, 4.5, 5.0])
    .whereIsActive(isEqualTo: true)
    .orderByRating(descending: true)
    .orderByCreatedAt(descending: true)
    .limit(20)
    .get();
```

### Real-Time Updates

```dart
// Listen to document changes
odm.users.doc('user123').snapshots().listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  }
});

// Listen to collection changes
odm.users.whereIsActive(isEqualTo: true).snapshots().listen((users) {
  print('Active users: ${users.length}');
});
```

## 📖 API Reference

### Collection Operations
- `doc(id)` - Get document reference
- `add(data)` - Add new document
- `get()` - Get all documents
- `snapshots()` - Listen to changes

### Document Operations
- `set(data)` - Set document data
- `update(...)` - Update top-level fields
- `update.field(...)` - Update nested fields (chained)
- `get()` - Get document data
- `delete()` - Delete document
- `snapshots()` - Listen to changes

### Query Operations
- `where{Field}(...)` - Filter by field
- `orderBy{Field}(...)` - Order by field
- `limit(count)` - Limit results
- `startAfter(doc)` - Pagination
- `get()` - Execute query
- `snapshots()` - Listen to query changes

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of [cloud_firestore](https://pub.dev/packages/cloud_firestore)
- Inspired by [Mongoose](https://mongoosejs.com/) for MongoDB
- Uses [freezed](https://pub.dev/packages/freezed) for immutable data classes
- Code generation powered by [source_gen](https://pub.dev/packages/source_gen)

---

Made with ❤️ for the Flutter community