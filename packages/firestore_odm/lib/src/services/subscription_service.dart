import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/data_processor.dart';

/// Service class that encapsulates all subscription/real-time operations logic
/// Follows composition over inheritance pattern
class SubscriptionService<T> {
  /// The document reference to subscribe to
  final DocumentReference<Map<String, dynamic>>? documentRef;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data) fromJson;

  /// Stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// Stream controller for broadcasting document changes
  final StreamController<T?> _controller = StreamController.broadcast();

  final String documentIdField;

  /// Creates a new SubscriptionService instance
  SubscriptionService({
    required this.documentRef,
    required this.fromJson,
    required this.documentIdField,
  }) {
    _setupSubscription();
  }

  /// Stream of document changes
  Stream<T?> get stream => _controller.stream;

  /// Whether this document is currently subscribed to real-time updates
  bool get isSubscribing => _subscription != null;

  /// Setup the subscription lifecycle
  void _setupSubscription() {
    if (documentRef == null) return;

    _controller.onListen = () {
      log('Starting subscription to document changes');
      _subscription = documentRef!
          .snapshots()
          .skip(1)
          .listen(
            (event) {
              log('Document data changed: ${event.data()}');
              final data = event.data();
              _controller.add(_fromJson(data));
            },
            onError: (error) {
              log('Subscription error: $error');
              _controller.addError(error);
            },
          );
    };

    _controller.onCancel = () {
      log('Cancelling subscription to document changes');
      _subscription?.cancel();
      _subscription = null;
    };
  }

  /// Converts JSON data to model instance, adding the document ID
  T? _fromJson(Map<String, dynamic>? data) {
    if (data == null || documentRef == null) return null;
    // Add document ID to the data
    final processedData = FirestoreDataProcessor.processFirestoreData(
      data,
      documentIdField: documentIdField,
      documentId: documentRef!.id,
    );
    return fromJson(processedData);
  }

  /// Start listening to real-time updates manually
  void startListening() {
    if (documentRef == null || _subscription != null) return;

    log('Manually starting subscription to document changes');
    _subscription = documentRef!.snapshots().listen(
      (event) {
        log('Document data changed: ${event.data()}');
        final data = event.data();
        _controller.add(_fromJson(data));
      },
      onError: (error) {
        log('Subscription error: $error');
        _controller.addError(error);
      },
    );
  }

  /// Stop listening to real-time updates manually
  void stopListening() {
    log('Manually stopping subscription to document changes');
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose of resources when the service is no longer needed
  void dispose() {
    log('Disposing SubscriptionService');
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }

  /// Create a new service instance for a different document
  SubscriptionService<T> withDocumentRef(
    DocumentReference<Map<String, dynamic>> newDocumentRef,
  ) {
    return SubscriptionService<T>(
      documentRef: newDocumentRef,
      fromJson: fromJson,
      documentIdField: documentIdField,
    );
  }

  /// Create a service instance for query-based subscriptions
  static QuerySubscriptionService<T> forQuery<T>({
    required Query<Map<String, dynamic>> query,
    required T Function(Map<String, dynamic> data, [String? documentId])
    fromJson,
  }) {
    return QuerySubscriptionService<T>(query: query, fromJson: fromJson);
  }
}

/// Specialized subscription service for query-based real-time updates
class QuerySubscriptionService<T> {
  /// The query to subscribe to
  final Query<Map<String, dynamic>> query;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data, [String? documentId]) fromJson;

  /// Stream subscription for real-time query updates
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _querySubscription;

  /// Stream controller for broadcasting query changes
  final StreamController<List<T>> _queryController =
      StreamController.broadcast();

  QuerySubscriptionService({required this.query, required this.fromJson}) {
    _setupQuerySubscription();
  }

  Stream<List<T>> get changes => _queryController.stream;

  bool get isSubscribing => _querySubscription != null;

  /// Setup the query subscription lifecycle
  void _setupQuerySubscription() {
    _queryController.onListen = () {
      log('Starting subscription to query changes');
      _querySubscription = query.snapshots().listen(
        (snapshot) {
          log('Query data changed: ${snapshot.docs.length} documents');
          final results = snapshot.docs
              .map((doc) {
                final data = doc.data();
                return fromJson(data, doc.id);
              })
              .cast<T>()
              .toList();
          _queryController.add(results);
        },
        onError: (error) {
          log('Query subscription error: $error');
          _queryController.addError(error);
        },
      );
    };

    _queryController.onCancel = () {
      log('Cancelling subscription to query changes');
      _querySubscription?.cancel();
      _querySubscription = null;
    };
  }

  void startListening() {
    if (_querySubscription != null) return;

    log('Manually starting subscription to query changes');
    _querySubscription = query.snapshots().listen(
      (snapshot) {
        log('Query data changed: ${snapshot.docs.length} documents');
        final results = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return fromJson(data, doc.id);
            })
            .cast<T>()
            .toList();
        _queryController.add(results);
      },
      onError: (error) {
        log('Query subscription error: $error');
        _queryController.addError(error);
      },
    );
  }

  void stopListening() {
    log('Manually stopping subscription to query changes');
    _querySubscription?.cancel();
    _querySubscription = null;
  }

  void dispose() {
    log('Disposing QuerySubscriptionService');
    _querySubscription?.cancel();
    _querySubscription = null;
    _queryController.close();
  }
}
