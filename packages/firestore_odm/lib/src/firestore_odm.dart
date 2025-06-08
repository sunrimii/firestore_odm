import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update_operations_mixin.dart';

/// Internal variable to store the current server timestamp constant
DateTime _currentServerTimestamp = DateTime.utc(1900, 1, 1, 0, 0, 10);

/// Main ODM class for managing Firestore transactions and operations
class FirestoreODM {
  final FirebaseFirestore _firestore;
  final DateTime _specialTimestamp;

  /// **Special constant for server timestamps**
  ///
  /// Use this constant in your DateTime fields when you want to set server timestamp.
  /// The system will automatically replace this with FieldValue.serverTimestamp().
  ///
  /// Default: January 1, 1900 at 00:00:10 UTC (a time rarely used in real applications)
  ///
  /// Example:
  /// ```dart
  /// await userDoc.modify((user) => user.copyWith(
  ///   lastLogin: FirestoreODM.serverTimestamp, // Becomes server timestamp
  /// ));
  /// ```
  static DateTime get serverTimestamp => _currentServerTimestamp;

  /// Create ODM with optional custom server timestamp
  ///
  /// Example:
  /// ```dart
  /// final odm = FirestoreODM(
  ///   firestore: firestore,
  ///   serverTimestamp: DateTime.utc(1900, 1, 1, 0, 0, 20),
  /// );
  /// ```
  FirestoreODM({
    FirebaseFirestore? firestore,
    DateTime? serverTimestamp,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _specialTimestamp = serverTimestamp ?? _currentServerTimestamp;

  /// Get the special timestamp for this ODM instance
  DateTime get specialTimestamp => _specialTimestamp;

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
