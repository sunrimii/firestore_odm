class ModelConverter<T> {
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  ModelConverter({required this.fromMap, required this.toMap});

  T fromJson(Map<String, dynamic> json) => fromMap(json);

  Map<String, dynamic> toJson(T model) => toMap(model);
}
