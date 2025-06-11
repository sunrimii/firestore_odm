import 'package:firestore_odm/src/schema.dart';

abstract interface class Queryable<S extends FirestoreSchema, T> {
  /// Execute the query and return the results
  Future<List<T>> get();

  /// Get a real-time stream of query results
  Stream<List<T>> get stream;
}
