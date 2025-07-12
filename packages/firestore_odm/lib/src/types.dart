import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart' as firestore;

sealed class FieldPath {
  Object toFirestore();

  static const FieldPath documentId = DocumentIdFieldPath();

  const factory FieldPath.components([List<String> components]) =
      PathFieldPath;
}

class DocumentIdFieldPath implements FieldPath {
  const DocumentIdFieldPath();

  firestore.FieldPathType toFirestore() => firestore.FieldPathType.documentId;
}

class PathFieldPath implements FieldPath {
  const PathFieldPath([this.components = const []]);

  final List<String> components;

  // it seems that fake firestore does not support firestore.FieldPath in orderby
  // firestore.FieldPath toFirestore() => firestore.FieldPath(components);

  String toFirestore() => path;

  PathFieldPath append(String component) {
    return PathFieldPath([...components, component]);
  } 

  String get path => components.join('.');
}
