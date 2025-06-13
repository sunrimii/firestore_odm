# Reading Documents

This guide covers all the ways to read a single document's data.

## Fetching a Document Once

To get a document by its ID, use the `.get()` method on a document reference. This performs a single read from the database.

If the document does not exist, the result will be `null`.

```dart
// Get a reference to a specific document
final userDoc = db.users('jane-doe');

// Fetch the data
// Returns a Future<User?>
final user = await userDoc.get();

if (user != null) {
  print('User found: ${user.name}');
} else {
  print('User not found.');
}
```

## Subscribing to a Document (Real-time)

To listen for real-time changes to a document, use the `.stream` property. This returns a `Stream` that emits a new value every time the document's data changes on the server.

This is essential for building reactive user interfaces that update automatically.

```dart
// Returns a Stream<User?>
final userStream = db.users('jane-doe').stream;

final subscription = userStream.listen((user) {
  if (user != null) {
    // This code will run every time the 'jane-doe' document is updated
    print('User data updated: ${user.name}');
  } else {
    print('User was deleted.');
  }
});

// In a real app (e.g., a Flutter widget), you would cancel the subscription
// when it's no longer needed to prevent memory leaks.
// subscription.cancel();
```

## Checking for Existence

If you only need to know if a document exists and don't need its data, use `.exists()`. This is more efficient than fetching the entire document as it only downloads a minimal amount of data.

```dart
// Returns a Future<bool>
final bool userExists = await db.users('jane-doe').exists();

if (userExists) {
  print('The user jane-doe exists!');
}