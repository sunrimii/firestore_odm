import 'package:meta/meta_meta.dart';

/// Annotation to mark a parameter as unique
@Target({TargetKind.parameter})
class Unique {
  const Unique();
}

/// Annotation to specify the Firestore collection path for a model class
@Target({TargetKind.classType})
class CollectionPath {
  /// The Firestore collection path
  final String path;

  const CollectionPath(this.path);
}

/// Annotation to specify a subcollection path with its type
@Target({TargetKind.classType})
class SubcollectionPath<T> {
  /// The subcollection path
  final String path;

  const SubcollectionPath(this.path);
}
