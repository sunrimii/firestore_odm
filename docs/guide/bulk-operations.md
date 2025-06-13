# Bulk Operations

The ODM allows you to perform updates and deletions on multiple documents at once with a single, efficient command. These bulk operations are applied to all documents that match a query.

## Bulk Updates

You can use `patch()`, `modify()`, or `incrementalModify()` on a query to update all matching documents. This is extremely useful for large-scale data migrations or updates.

The syntax is identical to updating a single document, but the operation is applied to every document returned by the query.

```dart
// Give a 100 point bonus to all premium users
await db.users
  .where(($) => $.isPremium(isEqualTo: true))
  .patch(($) => [$.points.increment(100)]);

// Mark all posts in a certain category as archived
await db.posts
  .where(($) => $.category(isEqualTo: 'old-news'))
  .modify((post) => post.copyWith(isArchived: true));

// Reset the 'isActive' flag for all users
await db.users.patch(($) => [$.isActive(false)]);
```

## Bulk Deletes

To delete all documents that match a query, simply chain the `.delete()` method.

**Warning**: This operation is permanent and cannot be undone. Use with caution.

```dart
// Delete all users who have been marked as 'inactive'
await db.users
  .where(($) => $.status(isEqualTo: 'inactive'))
  .delete();

// Clean up posts that were created over a year ago
final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
await db.posts
  .where(($) => $.createdAt(isLessThan: oneYearAgo))
  .delete();