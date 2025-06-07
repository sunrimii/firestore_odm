import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hero_ai/controllers/hero_controller.dart';

import 'firestore_document.dart';

class FirestoreCollection<T> {
  final CollectionReference<Map<String, dynamic>> ref;
  final T Function(Map<String, dynamic> data) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  final Map<String, FirestoreDocument<T>> _cache = {};

  FirestoreCollection({
    required this.ref,
    required this.fromJson,
    required this.toJson,
  });

  FirestoreDocument<T> doc(String id) {
    return _cache.putIfAbsent(id, () => FirestoreDocument(this, id));
  }
}
