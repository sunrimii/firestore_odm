# What is Firestore ODM?

This project is a type-safe Object Document Mapper (ODM) for [Cloud Firestore](https://firebase.google.com/docs/firestore) on Dart and Flutter. It's designed from the ground up to solve the common frustrations of working with Firestore in a type-safe language, allowing you to build amazing apps faster and with fewer runtime errors.

## Why We Built This

If you've worked with the standard `cloud_firestore` package, you know the pain:

-   **No Type Safety**: You refer to fields using strings (`'isActive'`, `'profile.followers'`), which the compiler can't check. A simple typo can lead to a runtime error that's hard to find.
-   **Manual Serialization**: You have to manually convert `DocumentSnapshot` objects to your data models and back again, which is tedious and error-prone.
-   **Complex Queries**: Writing complex queries with nested logic can be difficult and hard to read.
-   **Incomplete Solutions**: Other ODMs for Flutter are often incomplete or not actively maintained.

We wanted a solution that provides:
✅ Complete, end-to-end type safety.
✅ Intuitive, readable, and chainable APIs.
✅ Automatic, seamless serialization.
✅ Powerful features that solve real-world problems.
✅ Active maintenance and a focus on the Flutter ecosystem.

## Firestore ODM vs Standard cloud_firestore

Here's a detailed comparison showing how Firestore ODM solves the fundamental problems of the standard `cloud_firestore` package:

### Type Safety: Strong Types vs Dynamic Maps

**Standard cloud_firestore:**
```dart
// Everything is Map<String, dynamic> - no type safety
DocumentSnapshot doc = await FirebaseFirestore.instance
  .collection('users')
  .doc('user123')
  .get();

Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
String name = data?['name']; // Runtime error if field doesn't exist
int age = data?['profile']['age']; // Nested access is fragile
```

**Firestore ODM:**
```dart
// Strongly typed throughout - compile-time safety
User? user = await db.users('user123').get();
String name = user.name; // IDE autocomplete, compile-time checking
int age = user.profile.age; // Type-safe nested access
```

### Query Building: String-Based vs Type-Safe

**Standard cloud_firestore:**
```dart
// String-based field paths - typos cause runtime errors
final query = FirebaseFirestore.instance
  .collection('users')
  .where('isActive', isEqualTo: true)
  .where('profile.followers', isGreaterThan: 100)
  .where('age', isLessThan: 30);
```

**Firestore ODM:**
```dart
// Type-safe query builder with IDE support
final query = db.users.where(($) => $.and(
  $.isActive(isEqualTo: true),
  $.profile.followers(isGreaterThan: 100),
  $.age(isLessThan: 30),
));
```

### Data Updates: Manual Maps vs Smart Operations

**Standard cloud_firestore:**
```dart
// Manual map construction - error-prone
await userDoc.update({
  'profile.followers': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['verified']),
  'lastLogin': FieldValue.serverTimestamp(),
  'profile.settings.theme': 'dark', // Nested updates are complex
});
```

**Firestore ODM:**
```dart
// Three different update strategies for different needs:

// 1. Patch - Atomic operations
await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.add('verified'),
  $.lastLogin.serverTimestamp(),
]);

// 2. Modify - Simple diff-based updates
await userDoc.modify((user) => user.copyWith(
  isActive: false,
  profile: user.profile.copyWith(theme: 'dark'),
));

// 3. IncrementalModify - Smart diff with atomic operations
await userDoc.incrementalModify((user) => user.copyWith(
  profile: user.profile.copyWith(followers: user.profile.followers + 1),
));
```

### Aggregations: Limited vs Comprehensive

**Standard cloud_firestore:**
```dart
// Basic aggregations only
AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance
  .collection('users')
  .count()
  .get();
int count = snapshot.count;

// No streaming aggregations
// No complex aggregations like sum/average
```

**Firestore ODM:**
```dart
// Comprehensive aggregations with streaming support
final result = await db.users.aggregate(($) => (
  count: $.count(),
  averageAge: $.age.average(),
  totalFollowers: $.profile.followers.sum(),
)).get();

// Real-time streaming aggregations (unique feature!)
db.users.aggregate(($) => (count: $.count())).stream.listen((result) {
  print('Live count: ${result.count}');
});
```

### Pagination: Error-Prone vs Smart Builder

**Standard cloud_firestore:**
```dart
// Manual cursor management - inconsistency risks
Query query = FirebaseFirestore.instance
  .collection('users')
  .orderBy('createdAt')
  .limit(10);

// Next page requires manual cursor extraction
QuerySnapshot snapshot = await query.get();
DocumentSnapshot lastDoc = snapshot.docs.last;
Query nextQuery = query.startAfterDocument(lastDoc);
```

**Firestore ODM:**
```dart
// Smart Builder pagination - zero inconsistency risk
final page1 = await db.users
  .orderBy(($) => $.createdAt)
  .limit(10)
  .get();

// Smart Builder automatically handles cursors
final page2 = await db.users
  .orderBy(($) => $.createdAt)
  .limit(10)
  .startAfterObject(page1.last) // Type-safe cursor
  .get();
```

### Transactions: Manual vs Automatic

**Standard cloud_firestore:**
```dart
// Manual read-before-write ordering
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // Must manually ensure all reads happen before writes
  DocumentSnapshot userDoc = await transaction.get(userRef);
  DocumentSnapshot postDoc = await transaction.get(postRef);
  
  // Then perform writes
  transaction.update(userRef, {'postCount': userDoc.data()['postCount'] + 1});
  transaction.set(postRef, postData);
});
```

**Firestore ODM:**
```dart
// Automatic deferred writes - handles read-before-write automatically
await db.runTransaction((tx) async {
  final user = await tx.users('user123').get();
  final post = Post(title: 'New Post', authorId: user.id);
  
  // Writes are automatically deferred until the end
  await tx.users('user123').modify((u) => u.copyWith(postCount: u.postCount + 1));
  await tx.posts.insert(post);
});
```

### Code Generation: None vs Highly Optimized

**Standard cloud_firestore:**
- No code generation
- All operations happen at runtime
- Manual serialization required
- No compile-time optimizations

**Firestore ODM:**
- **Lightning-fast code generation** using callables and Dart extensions
- **Minimal generated code** - highly optimized output
- **Model reusability** - same model works in collections and subcollections without code duplication
- **Zero runtime overhead** - all magic happens at compile time

### Summary

| Feature | Standard cloud_firestore | Firestore ODM |
|---------|-------------------------|---------------|
| **Type Safety** | ❌ Map<String, dynamic> everywhere | ✅ Strong types throughout |
| **Query Building** | ❌ String-based, error-prone | ✅ Type-safe with IDE support |
| **Data Updates** | ❌ Manual map construction | ✅ Three smart update strategies |
| **Aggregations** | ❌ Basic count only | ✅ Comprehensive + streaming |
| **Pagination** | ❌ Manual, inconsistency risks | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Code Generation** | ❌ None | ✅ Highly optimized, minimal output |
| **Model Reusability** | ❌ N/A | ✅ Same model, multiple collections |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |
| **Developer Experience** | ❌ Frustrating | ✅ Productive and enjoyable |

Firestore ODM transforms Firestore from a source of frustration into a powerful, type-safe database layer that enhances your Flutter development experience.
## Optimized Code Generation

Firestore ODM is built with performance and efficiency in mind:

- **Lightning Fast Builds**: Highly optimized code generation using callables and Dart extensions ensures minimal build times
- **Minimal Generated Code**: Smart generation produces compact, efficient output without bloating your project
- **Model Reusability**: The same model works seamlessly in both collections and subcollections without duplicating generated code
- **Zero Runtime Overhead**: All the magic happens at compile time, so your app runs at full speed

The generated code is designed to be as minimal and efficient as possible, leveraging Dart's advanced features to provide maximum functionality with minimum footprint.
This ODM is the result. It makes working with Firestore feel natural and productive in Dart, turning it into a joy instead of a chore.