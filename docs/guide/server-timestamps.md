# Server Timestamps

In distributed systems, relying on the client's clock can lead to inconsistencies. Firestore provides a `FieldValue.serverTimestamp()` to ensure that timestamps are generated consistently on Google's servers. This ODM provides a convenient and type-safe way to use this feature.

## The `FirestoreODM.serverTimestamp` Constant

The ODM exposes a special static constant, `FirestoreODM.serverTimestamp`. You should use this constant whenever you want to set a server-generated timestamp on a `DateTime` field.

This constant acts as a **sentinel value**. When you use it in an update operation, the ODM's internal logic detects this special value and replaces it with the actual `FieldValue.serverTimestamp()` before sending the data to Firestore.

## Usage with `modify` and `incrementalModify`

When using `modify` or `incrementalModify`, assign `FirestoreODM.serverTimestamp` directly to your `DateTime` field within the `copyWith` method.

```dart
final userDoc = odm.users('jane-doe');

// The ODM will detect the special constant and convert it
// to a proper server timestamp.
await userDoc.modify((user) => user.copyWith(
  lastLogin: FirestoreODM.serverTimestamp,
));
```

## Usage with `patch`

When using the `patch` method, you get access to a dedicated `.serverTimestamp()` method on any `DateTime` field. This is the recommended way to set server timestamps within a patch operation as it's more explicit.

```dart
final userDoc = odm.users('jane-doe');

// The .serverTimestamp() method directly creates the correct update operation.
await userDoc.patch(($) => [
  $.lastLogin.serverTimestamp(),
  $.profile.lastActivity.serverTimestamp(),
]);
```

By providing these two mechanisms, the ODM ensures you can easily and safely use server-generated timestamps, whether you prefer working with model objects (`modify`) or explicit update operations (`patch`).