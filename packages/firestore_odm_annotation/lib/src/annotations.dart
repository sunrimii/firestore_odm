import 'package:meta/meta.dart';

/// Annotation to mark a class as a Firestore collection
@immutable
class CollectionPath {
  /// The path to the Firestore collection
  final String path;

  /// Creates a [CollectionPath] annotation
  const CollectionPath(this.path);
}

/// Annotation to mark a field as a subcollection
@immutable
class SubcollectionPath {
  /// The path to the subcollection
  final String path;

  /// Creates a [SubcollectionPath] annotation
  const SubcollectionPath(this.path);
}
