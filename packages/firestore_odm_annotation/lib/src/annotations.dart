import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Annotation to mark a class as a Firestore collection or subcollection
///
/// Supports both regular collections and subcollections with wildcard syntax:
/// - Regular collection: `@Collection("users")`
/// - Subcollection: `@Collection("users/*/posts")` where * represents a document ID
///
/// Multiple annotations can be used on the same class to register it in multiple collections:
/// ```dart
/// @Collection('posts')  // Standalone collection
/// @Collection('users/*/posts')  // Subcollection under users
/// class Post with _$Post { ... }
/// ```
@Target({TargetKind.classType})
@immutable
class Collection {
  /// The path to the Firestore collection or subcollection
  ///
  /// Examples:
  /// - `"users"` - Regular collection
  /// - `"users/*/posts"` - Subcollection where * represents the parent document ID
  /// - `"organizations/*/departments/*/employees"` - Nested subcollection
  final String path;

  /// Creates a [Collection] annotation
  const Collection(this.path);
}

/// Annotation to mark a field as the document ID
/// This field will be synchronized with the Firestore document ID
/// but will not be included in the document content.
@Target({TargetKind.field, TargetKind.parameter})
@immutable
class DocumentIdField {
  /// Creates a [DocumentIdField] annotation
  const DocumentIdField();
}
