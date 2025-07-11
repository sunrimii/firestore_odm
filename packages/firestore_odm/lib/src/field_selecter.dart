import 'package:firestore_odm/firestore_odm.dart';

class Node {
  final String _name;
  final Node? _parent;

  Node get $root => _parent?.$root ?? this;

  String get $name => _name;

  String get $path {
    if (_parent == null) return _name;
    if (_name.isEmpty) return _parent.$path;
    return _parent.$path.isEmpty ? _name : '${_parent.$path}.$_name';
  }

  List<String> get $parts {
    if (_parent == null) {
      return _name.isEmpty ? const <String>[] : <String>[_name];
    }
    if (_name.isEmpty) return _parent.$parts;
    return [..._parent.$parts, _name];
  }

  const Node({String name = '', Node? parent}) : _name = name, _parent = parent;
}

class Node2 {
  const Node2({FieldPath? path}) :
    path = path ?? const FieldPath.components([]);

  final FieldPath path;
}
