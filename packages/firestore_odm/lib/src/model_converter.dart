import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonDeserializer<T> = T Function(Map<String, dynamic>);
typedef JsonSerializer<T> = Map<String, dynamic> Function(T);

class ModelConverter<T> {
  final JsonDeserializer<T> fromJson;
  final JsonSerializer<T> toJson;
  const ModelConverter({required this.fromJson, required this.toJson});
}



abstract interface class FirestoreConverter<T, F> {
  T fromFirestore(F data);
  F toFirestore(T data);
}


class DateTimeConverter implements FirestoreConverter<DateTime, Timestamp> {
  @override
  DateTime fromFirestore(Timestamp data) => data.toDate();

  @override
  Timestamp toFirestore(DateTime data) => Timestamp.fromDate(data);
}


class DurationConverter implements FirestoreConverter<Duration, int> {
  @override
  Duration fromFirestore(int data) => Duration(milliseconds: data);

  @override
  int toFirestore(Duration data) => data.inMilliseconds;
}