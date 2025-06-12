import 'package:cloud_firestore_platform_interface/src/field_path_type.dart'
    as fs;

enum FieldPathType {
  documentId(fs.FieldPathType.documentId);

  const FieldPathType(this._firestoreType);

  final fs.FieldPathType _firestoreType;

  fs.FieldPathType toFirestore() => _firestoreType;

  @override
  String toString() => 'FieldPathType($_firestoreType)';
}
