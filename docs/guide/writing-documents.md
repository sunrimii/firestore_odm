# Writing & Updating Documents

This guide covers all the ways to create, update, and delete single documents. For information on updating multiple documents at once, see the [Bulk Operations](./bulk-operations) guide.

## Creating Documents

-   **`insert(T value)`**: Adds a new document to a collection. The document ID is taken from the `@DocumentIdField()` in your model. This method will fail if a document with that ID already exists.
-   **`upsert(T value)`**: Adds a new document or completely overwrites an existing one with the same ID. This is useful when you don't need to worry about whether the document exists.

```dart
// Assumes 'id' is the @DocumentIdField in the User model.

// Fails if 'john-doe' already exists
await db.users.insert(User(id: 'john-doe', name: 'John', ...));

// Creates a new document or overwrites the existing one
await db.users.upsert(User(id: 'jane-doe', name: 'Jane', ...));
```

## Updating a Document

The ODM provides three powerful and flexible methods for updating a single document.

### `patch()` (For Atomic Updates)

The `patch()` method is for making specific, atomic updates. This is the most efficient method for operations like incrementing a number, adding/removing elements from an array, or setting a server timestamp. It gives you a builder with methods for each field.

```dart
final userDoc = db.users('jane-doe');

await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.add('active'), // Atomically adds 'active' to the 'tags' array
  $.lastLogin.serverTimestamp(),
  $.name('Jane Smith'), // Also supports simple field sets
]);
```

### `incrementalModify()` (Recommended)

This is the "smartest" update method. It compares the current state of your document with the new state you provide and automatically uses atomic operations where possible. This gives you the convenience of working with model objects while still getting the performance benefits of atomic writes.

```dart
await userDoc.incrementalModify((user) => user.copyWith(
  // This will be converted to a FieldValue.increment(1) operation
  age: user.age + 1,

  // This will be converted to a FieldValue.arrayUnion(['new-tag'])
  tags: [...user.tags, 'new-tag'],

  // This will just be a normal field update
  name: 'Jane Smith',
));
```

### `modify()`

This method also compares the current and new states of the document, but it performs simple field updates without converting them to atomic operations. It's useful for straightforward data changes where you don't need atomic behavior.

```dart
await userDoc.modify((user) => user.copyWith(
  name: 'Jane Smith',
  isPremium: true,
));
```

### `update()`

The `update()` method performs a full overwrite of an existing document. The entire object you provide will replace the one in Firestore. This method will fail if the document does not already exist.

```dart
// The user document MUST exist for this to succeed.
await userDoc.update(User(id: 'jane-doe', name: 'Jane Smith', ...));
```

## Deleting a Document

To delete a single document, use the `.delete()` method on a document reference.

```dart
await db.users('jane-doe').delete();