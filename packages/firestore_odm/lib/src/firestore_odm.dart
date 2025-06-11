import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/transaction.dart';
import 'schema.dart';

/// Internal variable to store the current server timestamp constant
DateTime _currentServerTimestamp = DateTime.fromMillisecondsSinceEpoch(
  -8640000000000000,
);

/// Main ODM class for managing Firestore transactions and operations
class FirestoreODM<T extends FirestoreSchema> {
  final FirebaseFirestore _firestore;

  /// **Special constant for server timestamps**
  ///
  /// Use this constant in your DateTime fields when you want to set server timestamp.
  /// The system will automatically replace this with FieldValue.serverTimestamp().
  ///
  /// Value: DateTime.fromMillisecondsSinceEpoch(-8640000000000000) (an impossible timestamp that cannot be accidentally used)
  ///
  /// Example:
  /// ```dart
  /// await userDoc.modify((user) => user.copyWith(
  ///   lastLogin: FirestoreODM.serverTimestamp, // Becomes server timestamp
  /// ));
  /// ```
  static DateTime get serverTimestamp => _currentServerTimestamp;

  /// The schema instance for type safety
  final T schema;

  /// Create ODM instance with schema
  ///
  /// Example:
  /// ```dart
  /// final odm = FirestoreODM(schema, firestore: firestore);
  /// ```
  FirestoreODM(this.schema, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Runs a Firestore transaction with automatic success handler management
  ///
  /// The [cb] callback is executed within a transaction context.
  /// Any operations that need to be executed after successful transaction
  /// can be registered using the onSuccess handler available in the zone.
  Future<void> runTransaction(Future<void> Function(TransactionContext<T>) cb) async {
    _firestore.runTransaction((transaction) async {
      final context = TransactionContext<T>(_firestore, transaction);
      await cb(context);
    });
  }
}
