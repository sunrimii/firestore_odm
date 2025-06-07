import 'package:meta/meta_meta.dart';
// export 'package:hero_ai/odm/firestore_odm.dart';
// export 'package:hero_ai/odm/firestore_collection.dart';
// export 'package:hero_ai/odm/firestore_document.dart';
// export 'package:cloud_firestore/cloud_firestore.dart';

@Target({TargetKind.parameter})
class Unique {
  const Unique();
}

@Target({TargetKind.classType})
class CollectionPath {
  final String path;
  const CollectionPath(this.path);
}

@Target({TargetKind.classType})
class SubcollectionPath<T> {
  final String path;
  const SubcollectionPath(this.path);
}
