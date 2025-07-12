import 'package:firestore_odm/firestore_odm.dart';

class Node2 {
  const Node2({this.field = const FieldPath.components([])});

  PathFieldPath get path => field as PathFieldPath;

  final FieldPath field;
}
