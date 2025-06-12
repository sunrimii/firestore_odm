class Node {
  final String _name;
  final Node? _parent;
  final List<String> _parts;
  final String _path;

  Node get $root => _parent?.$root ?? this;

  String get $name => _name;

  String get $path => _path;

  List<String> get $parts => _parts;

  Node({String name = '', Node? parent})
    : _name = name,
      _parent = parent,
      _parts = parent != null
          ? (name.isEmpty ? parent._parts : [...parent._parts, name])
          : (name.isEmpty ? const [] : [name]),
      _path = parent != null
          ? (name.isEmpty
              ? parent._path
              : parent._path.isEmpty
                  ? name
                  : '${parent._path}.$name')
          : name;
}
