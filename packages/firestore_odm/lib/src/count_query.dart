import 'package:cloud_firestore/cloud_firestore.dart';

/// Query for count operations that can be executed with get() or watched for changes
class FirestoreCountQuery {
  final Query<Map<String, dynamic>> _query;

  FirestoreCountQuery(this._query);

  /// Execute the count query and return the result
  Future<int> get() async {
    final countSnapshot = await _query.count().get();
    return countSnapshot.count ?? 0;
  }

  /// Stream of count results that updates when the underlying data changes
  /// Note: Firestore doesn't support real-time count aggregation, so we watch the underlying data
  Stream<int> snapshots() {
    return _query.snapshots().map((snapshot) => snapshot.docs.length);
  }
}