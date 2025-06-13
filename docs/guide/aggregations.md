# Aggregations

The ODM provides a type-safe API for performing server-side aggregations, allowing you to efficiently calculate values like `count`, `sum`, and `average` across a set of documents without needing to download all the data to the client.

## `count()`

The simplest aggregation is `.count()`, which returns the number of documents matching your query.

```dart
// Get the total number of users
final userCount = await db.users.count().get();

// Get the number of active users
final activeUserCount = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .count()
  .get();

print('There are $activeUserCount active users.');
```

## `aggregate()`

For more complex aggregations, use the `.aggregate()` method. It allows you to perform multiple calculations (`sum`, `average`, and `count`) in a single request. The result is returned as a strongly-typed Record.

```dart
// Get multiple stats for active users in one go
final stats = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    // You can name the fields whatever you want
    totalUsers: $.count(),
    averageAge: $.age.average(),
    totalFollowers: $.profile.followers.sum(),
  ))
  .get();

print('Total active users: ${stats.totalUsers}');
print('Average age of active users: ${stats.averageAge}');
print('Combined followers of all active users: ${stats.totalFollowers}');
```

## Streaming Aggregations (A Unique Feature)

A powerful and unique feature of this ODM is the ability to create **real-time subscriptions to aggregation results**. While Firestore does not support this natively, our ODM implements this on the client-side for you.

When you call `.stream` on an `aggregate()` or `count()` query, the ODM:
1.  Creates a real-time subscription to the underlying query.
2.  Whenever the query results change, it efficiently recalculates the aggregations on the client.
3.  It then emits the new aggregation results on the stream.

This allows you to build reactive UIs that display live-updating stats.

```dart
// Create a stream that emits the latest stats whenever the data changes
final statsStream = db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),
    avgAge: $.age.average(),
  ))
  .stream;

// Listen to the stream and update your UI
statsStream.listen((stats) {
  print('Live active user count: ${stats.count}');
  print('Live average age: ${stats.avgAge}');
});