import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'firestore_collection.dart';

/// Abstract base class for type-safe Firestore queries
abstract class FirestoreQuery<T> {
  /// The collection this query operates on
  final FirestoreCollection<T> collection;

  /// The underlying Firestore query
  @protected
  final Query<Map<String, dynamic>> query;

  /// Creates a new FirestoreQuery instance
  FirestoreQuery(this.collection, this.query);

  /// Limits the number of results returned
  FirestoreQuery<T> limit(int limit) {
    return newInstance(query.limit(limit));
  }

  /// Limits the number of results returned from the end
  FirestoreQuery<T> limitToLast(int limit) {
    return newInstance(query.limitToLast(limit));
  }

  /// Executes the query and returns the results
  Future<List<T>> get() async {
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add document ID to the data
      return collection.fromJson(data);
    }).toList();
  }

  /// Creates a new instance of the query with the given Firestore query
  @protected
  FirestoreQuery<T> newInstance(Query<Map<String, dynamic>> query);
}
