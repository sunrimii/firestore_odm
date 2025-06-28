extension StringUtils on String {
  String lowerFirst() => isEmpty ? this : this[0].toLowerCase() + substring(1);

  String upperFirst() => isEmpty ? this : this[0].toUpperCase() + substring(1);

  String camelCase() {
    if (isEmpty) return this;
    final parts = split('_');
    return parts
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : '')
        .join('');
  }
}
