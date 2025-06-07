import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Main ODM class for managing Firestore transactions and operations
class FirestoreODM {
  final FirebaseFirestore _firestore;

  FirestoreODM([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Default instance of FirestoreODM
  static FirestoreODM get instance => FirestoreODM();

  /// Get the Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Runs a Firestore transaction with automatic success handler management
  ///
  /// The [cb] callback is executed within a transaction context.
  /// Any operations that need to be executed after successful transaction
  /// can be registered using the onSuccess handler available in the zone.
  Future<void> runTransaction(Future<void> Function() cb) async {
    final handlers = <FutureOr<void> Function()>[];

    void onSuccess(void Function() cb) {
      handlers.add(cb);
    }

    await _firestore.runTransaction((transaction) async {
      await runZoned(
        cb,
        zoneValues: {#transaction: transaction, #onSuccess: onSuccess},
      );
    });

    log('running handlers, count: ${handlers.length}');
    for (final handler in handlers) {
      await handler();
    }
  }
}
