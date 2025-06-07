import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_collection.dart';

abstract class FirestoreQuery<T> {
  final FirestoreCollection<T> collection;

  @protected
  final Query<Map<String, dynamic>> query;

  FirestoreQuery(this.collection, this.query);

  FirestoreQuery<T> limit(int limit) {
    return newInstance(query.limit(limit));
  }

  FirestoreQuery<T> limitToLast(int limit) {
    return newInstance(query.limitToLast(limit));
  }

  Future<List<T>> get() async {
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => collection.fromJson(doc.data())).toList();
  }

  @protected
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query);
}
