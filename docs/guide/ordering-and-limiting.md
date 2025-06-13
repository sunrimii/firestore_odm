# Ordering & Limiting Data

## Sorting with `orderBy()`

The `.orderBy()` method sorts the results of your query. You can sort by multiple fields in ascending or descending order.

The `orderBy` method takes a builder function that returns a [Record](https://dart.dev/language/records) (or "tuple"). This ensures that the sorting criteria are strongly typed.

```dart
// Get users, sorted by follower count (highest first), then by name (A-Z)
final sortedUsers = await db.users
  .orderBy(($) => (
    $.profile.followers(descending: true),
    $.name(), // ascending is the default
  ))
  .get();
```

> **Important**: If you use a range filter (`<`, `<=`, `>`, `>=`) on a field, your first `orderBy()` clause must be on the same field.

## Limiting Results

-   **`limit(int count)`**: Restricts the query to return only the first `count` documents from the beginning of the sorted results.
-   **`limitToLast(int count)`**: Restricts the query to return only the last `count` documents from the end of the sorted results. Note that this requires an `orderBy()` clause and will reverse the order of the results.

```dart
// Get the top 10 most popular users
final top10 = await db.users
  .orderBy(($) => $.profile.followers(descending: true))
  .limit(10)
  .get();