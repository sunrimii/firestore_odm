typedef JsonDeserializer<T> = T Function(Map<String, dynamic>);
typedef JsonSerializer<T> = Map<String, dynamic> Function(T);

class ModelConverter<T> {
  final JsonDeserializer<T> fromJson;
  final JsonSerializer<T> toJson;
  const ModelConverter({required this.fromJson, required this.toJson});
}
