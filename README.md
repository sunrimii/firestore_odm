# Firestore ODM for Dart/Flutter

A powerful Object-Document Mapping (ODM) library for Cloud Firestore in Dart and Flutter applications. This library provides type-safe, code-generated access to Firestore with advanced filtering, querying, and update capabilities.

## Features

- 🔥 **Type-safe Firestore operations** - Generated code ensures compile-time safety
- 🎯 **Advanced nested filtering** - Fluent API for complex queries with deep nested field support
- 🔄 **Atomic updates** - Safe field-level updates with conflict resolution
- 📝 **Code generation** - Automatic generation of collections, queries, and filters
- 🆔 **Document ID field support** - Virtual document ID fields with automatic sync and `FieldPath.documentId` support
-  **Fluent API** - Intuitive, chainable method calls
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
    @DocumentIdField() required String id,  // Virtual field synced with document ID
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

## Document ID Field Support

The `@DocumentIdField()` annotation allows you to mark a field as a virtual document ID field. This field is automatically synchronized with the Firestore document ID and provides seamless integration with queries and updates.

### Key Features

- **Virtual Field**: The annotated field doesn't exist in the document content - it's synchronized with the Firestore document ID
- **Automatic Sync**: When reading documents, the field is automatically populated with the document ID
- **Query Support**: Filter and order by document ID using `FieldPath.documentId` internally
- **Upsert Operations**: Use the field value as the document ID for upsert operations

### Basic Usage

```dart
@freezed
@CollectionPath('posts')
class Post with _$Post {
  const factory Post({
    @DocumentIdField() required String id,  // Virtual field synced with document ID
    required String title,
    required String content,
    required String authorId,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### Upsert Operations

```dart
final post = Post(
  id: 'my_custom_id',
  title: 'My Post',
  content: 'Post content...',
  authorId: 'author123',
  tags: ['flutter', 'dart'],
  metadata: {'category': 'tech'},
  createdAt: DateTime.now(),
);

// Upserts to document with ID 'my_custom_id'
await odm.posts.upsert(post);

// The id field is NOT stored in the document content
// It's automatically populated when reading back
final retrievedPost = await odm.posts.doc('my_custom_id').get();
print(retrievedPost?.id); // 'my_custom_id'
```

### Filtering by Document ID

```dart
// Filter by specific document ID
final specificPost = await odm.posts
    .where(($) => $.id(isEqualTo: 'my_custom_id'))
    .get();

// Filter by multiple document IDs
final multiplePosts = await odm.posts
    .where(($) => $.id(whereIn: ['id1', 'id2', 'id3']))
    .get();

// Range queries on document IDs
final postsInRange = await odm.posts
    .where(($) => $.id(isGreaterThan: 'post_a', isLessThan: 'post_z'))
    .get();
```

### Ordering by Document ID

```dart
// Order by document ID ascending
final orderedPosts = await odm.posts
    .orderBy(($) => $.id())
    .get();

// Order by document ID descending
final reversedPosts = await odm.posts
    .orderBy(($) => $.id(descending: true))
    .get();

// Combine with other ordering
final complexOrder = await odm.posts
    .orderBy(($) => $.createdAt(descending: true))
    .orderBy(($) => $.id())
    .get();
```

### Important Notes

- Only **one field per model** can be annotated with `@DocumentIdField()`
- The field **must be of type `String`**
- The field value is **never stored in the document content**
- Empty or null ID values will throw an `ArgumentError` during upsert
- The field is automatically populated when documents are retrieved

## Advanced Filtering with New Where API

### Basic Field Filtering

```dart
// Basic field filtering
final activeUsers = await odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .get();

// Numeric comparisons
final youngUsers = await odm.users
    .where(($) => $.age(isLessThan: 30))
    .get();

// String operations
final johnUsers = await odm.users
    .where(($) => $.name(isEqualTo: 'John Doe'))
    .get();

// Array operations
final developerUsers = await odm.users
    .where(($) => $.tags(arrayContains: 'developer'))
    .get();
```

### Nested Object Filtering

```dart
// Filter by nested profile fields
final popularUsers = await odm.users
    .where(($) => $.profile.followers(isGreaterThan: 100))
    .get();

// Filter by social links
final githubUsers = await odm.users
    .where(($) => $.profile.socialLinks.github(isNotEqualTo: null))
    .get();

// Deep nested filtering
final specificLocationUsers = await odm.users
    .where(($) => $.profile.contact.address.city(isEqualTo: "Hong Kong"))
    .get();
```

### Complex Logical Operations

```dart
// AND operations
final premiumActiveUsers = await odm.users
    .where(($) => $.and(
      $.isActive(isEqualTo: true),
      $.isPremium(isEqualTo: true),
      $.age(isGreaterThan: 18),
    ))
    .get();

// OR operations
final eligibleUsers = await odm.users
    .where(($) => $.or(
      $.isPremium(isEqualTo: true),
      $.rating(isGreaterThanOrEqualTo: 4.0),
    ))
    .get();

// Nested AND/OR combinations
final complexQuery = await odm.users
    .where(($) => $.and(
      $.isActive(isEqualTo: true),
      $.or(
        $.isPremium(isEqualTo: true),
        $.and(
          $.age(isLessThan: 25),
          $.rating(isGreaterThan: 4.0),
        ),
      ),
    ))
    .get();
```

### Real-World Complex Filtering Example

```dart
// Find active users with high engagement
final engagedUsers = await odm.users
    .where(($) => $.and(
      $.age(isGreaterThan: 18),
      $.profile.followers(isGreaterThan: 100),
      $.profile.socialLinks.github(isNotEqualTo: null),
      $.or(
        $.isPremium(isEqualTo: true),
        $.rating(isGreaterThanOrEqualTo: 4.5),
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
await userDoc.update(($) => [
  $.profile.bio('Updated bio'),
  $.profile.followers(150),
]);

// Array operations
await userDoc.update(($) => [
  $.tags.add('expert'),
  $.scores.add(95),
]);

// Numeric increment operations
await userDoc.update(($) => [
  $.age.increment(1),
  $.rating.increment(0.5),
  $.profile.followers.increment(50),
]);

// Server timestamp operations
await userDoc.update(($) => [
  $.lastLogin.serverTimestamp(),
  $.updatedAt.serverTimestamp(),
]);

// Object merge operations
await userDoc.update(($) => [
  $({'name': 'John Smith', 'isPremium': true}),
  $.profile({'bio': 'Senior Developer', 'followers': 200}),
]);

// Mixed operations - The Revolutionary Feature! 🚀
await userDoc.update(($) => [
  // Increments
  $.age.increment(1),
  $.rating.increment(0.5),
  $.profile.followers.increment(50),
  
  // Array operations
  $.tags.add('expert'),
  $.tags.add('verified'),
  
  // Object merges
  $({
    'age': 26, // Can override increments
    'rating': 3.5,
    'isPremium': true,
  }),
  $.profile({
    'followers': 150, // Can override increments
    'bio': 'Full-stack developer',
  }),
  
  // Server timestamps
  $.lastLogin.serverTimestamp(),
]);
```

## RxDB-Style Modify Operations

Firestore ODM also supports RxDB-style modify operations for more advanced update scenarios:

### Basic Modify

The `modify` method computes differences and updates only changed fields:

```dart
// Get a document reference
final userDoc = odm.users.doc('user1');

// Modify operation - only updates changed fields
await userDoc.modify((currentUser) {
  return currentUser.copyWith(
    name: 'Updated Name',
    age: currentUser.age + 1,
    profile: currentUser.profile.copyWith(
      bio: 'Updated bio',
      followers: currentUser.profile.followers + 10,
    ),
  );
});
```

### Incremental Modify with Atomic Operations

The `incrementalModify` method automatically detects and uses Firestore atomic operations where possible:

```dart
// Incremental modify - automatically uses atomic operations
await userDoc.incrementalModify((currentUser) {
  return currentUser.copyWith(
    age: currentUser.age + 1,           // Becomes FieldValue.increment(1)
    rating: currentUser.rating + 0.5,   // Becomes FieldValue.increment(0.5)
    tags: [...currentUser.tags, 'expert'], // Becomes FieldValue.arrayUnion(['expert'])
    profile: currentUser.profile.copyWith(
      followers: currentUser.profile.followers + 50, // Becomes FieldValue.increment(50)
    ),
  );
});

// Remove from arrays atomically
await userDoc.incrementalModify((currentUser) {
  return currentUser.copyWith(
    tags: currentUser.tags.where((tag) => tag != 'beginner').toList(),
    // Becomes FieldValue.arrayRemove(['beginner'])
  );
});

// Mixed atomic operations
await userDoc.incrementalModify((currentUser) {
  return currentUser.copyWith(
    name: 'John Smith',                 // Direct field update
    age: currentUser.age + 2,           // FieldValue.increment(2)
    rating: currentUser.rating - 0.1,   // FieldValue.increment(-0.1)
    tags: [...currentUser.tags, 'verified', 'premium'], // FieldValue.arrayUnion
    scores: [...currentUser.scores, 95, 88], // FieldValue.arrayUnion
    profile: currentUser.profile.copyWith(
      followers: currentUser.profile.followers + 100, // FieldValue.increment(100)
      bio: 'Senior Full-stack Developer', // Direct field update
    ),
  );
});
```

### When to Use Each Method

- **Array-style updates**: Best for explicit, declarative updates with full control
- **`modify`**: Good for complex state transformations where you want only changed fields updated
- **`incrementalModify`**: Perfect for numeric operations, array modifications, and mixed scenarios where atomic operations provide better consistency

```dart
// Array-style: Explicit and declarative
await userDoc.update(($) => [
  $.age.increment(1),
  $.tags.add('expert'),
]);

// Modify: State transformation with diff detection
await userDoc.modify((user) => user.copyWith(
  age: user.age + 1,
  tags: [...user.tags, 'expert'],
));

// Incremental modify: Automatic atomic operations
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,      // Auto-detected as increment
  tags: [...user.tags, 'expert'], // Auto-detected as arrayUnion
));
```

## Transactions

Firestore ODM provides seamless transaction support with automatic context detection. All document operations automatically work within transactions when called inside `runTransaction`.

### Basic Transaction Usage

```dart
final odm = FirestoreODM(firestore);

// Simple transaction
await odm.runTransaction(() async {
  final user = await odm.users.doc('user1').get();
  if (user != null) {
    await odm.users.doc('user1').modify((currentUser) {
      return currentUser.copyWith(
        age: currentUser.age + 1,
        profile: currentUser.profile.copyWith(
          followers: currentUser.profile.followers + 10,
        ),
      );
    });
  }
});
```

### Complex Multi-Document Transactions

```dart
// Transfer followers between users atomically
await odm.runTransaction(() async {
  // Read current state
  final user1 = await odm.users.doc('user1').get();
  final user2 = await odm.users.doc('user2').get();
  
  if (user1 != null && user2 != null) {
    final transferAmount = 50;
    
    // Check if user1 has enough followers
    if (user1.profile.followers >= transferAmount) {
      // Update both users atomically
      await odm.users.doc('user1').incrementalModify((user) {
        return user.copyWith(
          profile: user.profile.copyWith(
            followers: user.profile.followers - transferAmount,
          ),
        );
      });
      
      await odm.users.doc('user2').incrementalModify((user) {
        return user.copyWith(
          profile: user.profile.copyWith(
            followers: user.profile.followers + transferAmount,
          ),
        );
      });
    } else {
      throw Exception('Insufficient followers for transfer');
    }
  }
});
```

### Transaction with Array-Style Updates

```dart
// All update methods work seamlessly in transactions
await odm.runTransaction(() async {
  final user = await odm.users.doc('user1').get();
  
  if (user != null && user.rating < 5.0) {
    // Array-style updates within transaction
    await odm.users.doc('user1').update(($) => [
      $.rating.increment(0.5),
      $.tags.add('verified'),
      $.profile.followers.increment(25),
      $.lastLogin.serverTimestamp(),
    ]);
    
    // Create activity log
    await odm.activities.doc().set(Activity(
      userId: user.id,
      action: 'rating_increased',
      timestamp: DateTime.now(),
    ));
  }
});
```

### Error Handling in Transactions

```dart
try {
  await odm.runTransaction(() async {
    final user = await odm.users.doc('user1').get();
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (user.profile.followers < 100) {
      throw Exception('User must have at least 100 followers');
    }
    
    // Promote user to premium
    await odm.users.doc('user1').modify((currentUser) {
      return currentUser.copyWith(
        isPremium: true,
        rating: math.min(5.0, currentUser.rating + 0.5),
      );
    });
  });
  
  print('User promoted successfully!');
} catch (e) {
  print('Transaction failed: $e');
}
```

### Automatic Transaction Context

All document operations automatically detect transaction context:

```dart
await odm.runTransaction(() async {
  // All these operations happen within the same transaction
  
  // Reading - uses transaction.get()
  final user = await odm.users.doc('user1').get();
  
  // Writing - uses transaction.set()
  await odm.users.doc('user1').set(updatedUser);
  
  // Updating - uses transaction.update()
  await odm.users.doc('user1').update(($) => [
    $.age.increment(1),
  ]);
  
  // Modifying - uses transaction.set() with merge
  await odm.users.doc('user1').modify((user) =>
    user.copyWith(name: 'New Name'));
  
  // Incremental modifying - uses transaction.update()
  await odm.users.doc('user1').incrementalModify((user) =>
    user.copyWith(age: user.age + 1));
  
  // Deleting - uses transaction.delete()
  await odm.users.doc('old_user').delete();
});
```

### Transaction Best Practices

1. **Keep transactions short**: Minimize the time between reads and writes
2. **Read before write**: Always read current state before modifying
3. **Handle conflicts**: Be prepared for transaction retry scenarios
4. **Validate data**: Check constraints before making changes
5. **Use atomic operations**: Prefer `incrementalModify` for numeric/array operations

```dart
// Example: Bank account transfer pattern
await odm.runTransaction(() async {
  // 1. Read current balances
  final fromAccount = await odm.accounts.doc(fromId).get();
  final toAccount = await odm.accounts.doc(toId).get();
  
  // 2. Validate operation
  if (fromAccount == null || toAccount == null) {
    throw Exception('Account not found');
  }
  
  if (fromAccount.balance < amount) {
    throw Exception('Insufficient funds');
  }
  
  // 3. Perform atomic updates
  await odm.accounts.doc(fromId).incrementalModify((account) =>
    account.copyWith(balance: account.balance - amount));
    
  await odm.accounts.doc(toId).incrementalModify((account) =>
    account.copyWith(balance: account.balance + amount));
    
  // 4. Create audit log
  await odm.transactions.doc().set(TransactionLog(
    fromAccount: fromId,
    toAccount: toId,
    amount: amount,
    timestamp: DateTime.now(),
  ));
});
```

## Real-time Data Observation

Firestore ODM provides built-in real-time data observation capabilities with automatic subscription management.

### Basic Document Listening

```dart
// Listen to document changes
final userDoc = odm.users.doc('user1');

final subscription = userDoc.changes.listen((user) {
  if (user != null) {
    print('User updated: ${user.name}, age: ${user.age}');
  } else {
    print('User deleted or does not exist');
  }
});

// Make changes - listener will be triggered automatically
await userDoc.update(($) => [
  $.name('Updated Name'),
  $.age.increment(1),
]);

// Cancel subscription when no longer needed
await subscription.cancel();
```

### Real-time UI Updates with Streams

```dart
// Flutter Widget example
class UserProfileWidget extends StatelessWidget {
  final String userId;
  
  const UserProfileWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    final odm = FirestoreODM(FirebaseFirestore.instance);
    
    return StreamBuilder<User?>(
      stream: odm.users.doc(userId).changes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final user = snapshot.data;
        if (user == null) {
          return Text('User not found');
        }
        
        return Column(
          children: [
            Text('Name: ${user.name}'),
            Text('Age: ${user.age}'),
            Text('Rating: ${user.rating}'),
            Text('Followers: ${user.profile.followers}'),
          ],
        );
      },
    );
  }
}
```

### Multiple Document Observation

```dart
// Observe multiple documents simultaneously
final user1Stream = odm.users.doc('user1').changes;
final user2Stream = odm.users.doc('user2').changes;

// Combine streams
final combinedStream = StreamGroup.merge([user1Stream, user2Stream]);

combinedStream.listen((user) {
  if (user != null) {
    print('Any user updated: ${user.name}');
  }
});

// Or use individual subscriptions
final subscriptions = <StreamSubscription>[];

subscriptions.add(user1Stream.listen((user) {
  print('User 1 updated: ${user?.name}');
}));

subscriptions.add(user2Stream.listen((user) {
  print('User 2 updated: ${user?.name}');
}));

// Cancel all subscriptions
for (final subscription in subscriptions) {
  await subscription.cancel();
}
```

### Automatic Subscription Management

The ODM automatically manages Firestore snapshot subscriptions:

```dart
// Subscription starts when first listener is added
final userDoc = odm.users.doc('user1');
print('Is subscribing: ${userDoc.isSubscribing}'); // false

final subscription1 = userDoc.changes.listen((user) {
  print('Listener 1: ${user?.name}');
});
print('Is subscribing: ${userDoc.isSubscribing}'); // true

// Multiple listeners share the same underlying subscription
final subscription2 = userDoc.changes.listen((user) {
  print('Listener 2: ${user?.name}');
});

// Subscription continues until all listeners are cancelled
await subscription1.cancel();
print('Is subscribing: ${userDoc.isSubscribing}'); // still true

await subscription2.cancel();
print('Is subscribing: ${userDoc.isSubscribing}'); // false
```

### Error Handling in Streams

```dart
final subscription = odm.users.doc('user1').changes.listen(
  (user) {
    // Handle successful data updates
    print('User data: ${user?.name}');
  },
  onError: (error) {
    // Handle stream errors
    print('Stream error: $error');
  },
  onDone: () {
    // Handle stream completion
    print('Stream completed');
  },
);
```

### Real-time Chat/Messaging Example

```dart
// Real-time messaging system
class ChatService {
  final FirestoreODM odm;
  
  ChatService(this.odm);
  
  // Listen to messages in a chat room
  Stream<List<Message>> getMessagesStream(String chatId) {
    return odm.chats.doc(chatId).changes
        .map((chat) => chat?.messages ?? []);
  }
  
  // Send a message and observers will be notified automatically
  Future<void> sendMessage(String chatId, String content, String userId) async {
    await odm.chats.doc(chatId).incrementalModify((chat) {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        userId: userId,
        timestamp: DateTime.now(),
      );
      
      return chat.copyWith(
        messages: [...chat.messages, newMessage],
        lastActivity: DateTime.now(),
      );
    });
  }
}

// Usage in Flutter
StreamBuilder<List<Message>>(
  stream: chatService.getMessagesStream(chatId),
  builder: (context, snapshot) {
    final messages = snapshot.data ?? [];
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Text(message.content),
          subtitle: Text(message.userId),
        );
      },
    );
  },
);
```

### Performance Considerations

1. **Automatic Subscription Sharing**: Multiple listeners on the same document share a single Firestore subscription
2. **Memory Management**: Subscriptions are automatically cancelled when no listeners remain
3. **Efficient Updates**: Only changed documents trigger listener callbacks
4. **Skip Initial**: The stream automatically skips the initial snapshot to avoid duplicate data

```dart
// The stream skips the initial snapshot automatically
final userDoc = odm.users.doc('user1');

// This will NOT trigger for the existing data, only for changes
userDoc.changes.listen((user) {
  print('User changed: ${user?.name}'); // Only called on actual changes
});
```

## Ordering and Limiting

```dart
// Order by field using new orderBy API
final orderedUsers = await odm.users
    .orderBy(($) => $.age(descending: true))
    .limit(10)
    .get();

// Order by nested fields
final popularUsers = await odm.users
    .orderBy(($) => $.rating(descending: true))
    .orderBy(($) => $.createdAt())
    .limit(20)
    .get();

// Order by deeply nested fields
final usersByFollowers = await odm.users
    .orderBy(($) => $.profile.followers(descending: true))
    .limit(15)
    .get();

// Multiple ordering criteria
final complexOrdering = await odm.users
    .orderBy(($) => $.age())
    .orderBy(($) => $.profile.followers(descending: true))
    .orderBy(($) => $.createdAt(descending: true))
    .get();

// Combine filtering and ordering
final topActiveUsers = await odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .orderBy(($) => $.rating(descending: true))
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
final query = users.where(($) => /* conditions */);
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
$.and(filter1, filter2, filter3, ...)  // Up to 30 filters
$.or(filter1, filter2, filter3, ...)   // Up to 30 filters
```

### Update Operations

```dart
// Basic field updates
await doc.update(($) => [
  update.field1(newValue),
  update.field2(anotherValue),
]);

// Nested field updates
await doc.update(($) => [
  update.nestedObject.field(value),
  update.deeply.nested.object.field(anotherValue),
]);

// Array operations
await doc.update(($) => [
  update.arrayField.add(item),
  update.arrayField.remove(item),
]);

// Numeric operations
await doc.update(($) => [
  update.numericField.increment(5),
  update.nestedObject.count.increment(1),
]);

// Server timestamp
await doc.update(($) => [
  update.timestampField.serverTimestamp(),
]);

// Object merge operations
await doc.update(($) => [
  $({'field1': 'value1', 'field2': 'value2'}),
  update.nestedObject({'subField': 'newValue'}),
]);

// Mixed operations in single update
await doc.update(($) => [
  $.name('John'),
  $.age.increment(1),
  $.tags.add('expert'),
  $.profile.followers.increment(10),
  $({'isPremium': true}),
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
        .where(($) => $.and(
          $.isActive(isEqualTo: true),
          $.profile.followers(isGreaterThan: 50),
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