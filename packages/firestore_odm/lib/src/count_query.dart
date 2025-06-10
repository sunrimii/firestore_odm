import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/subscribe_operations.dart';

/// Query for count operations that can be executed with get() or watched for changes
class FirestoreCountQuery implements SubscribeOperations<int> {
  final Query<Map<String, dynamic>> _query;

  late final QuerySubscriptionService<int> _subscriptionService;

  FirestoreCountQuery(this._query) {
    // Initialize the subscription service if needed
    _subscriptionService = QuerySubscriptionService<int>(
      query: _query,
      converter: ModelConverter<int>(
        fromMap: (data) => 0,
        toMap: (value) => {'count': value},
      ),
    );
  }

  /// Execute the count query and return the result
  Future<int> get() async {
    final countSnapshot = await _query.count().get();
    return countSnapshot.count ?? 0;
  }

  /// Stream of count results that updates when the underlying data changes
  /// Note: Firestore doesn't support real-time count aggregation, so we watch the underlying data
  @override
  Stream<int> get stream => _subscriptionService.stream.map((data) => data.length);
  
  @override
  bool get isSubscribing => _subscriptionService.isSubscribing;
}