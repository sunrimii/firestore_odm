import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/transaction.dart';
import 'package:firestore_odm/src/batch.dart';
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
  /// All write operations are deferred until after all reads complete.
  Future<void> runTransaction(
    Future<void> Function(TransactionContext<T>) cb,
  ) async {
    return await _firestore.runTransaction((transaction) async {
      final context = TransactionContext<T>(_firestore, transaction);

      // Execute the callback (collects reads and defers writes)
      await cb(context);

      // Execute all deferred writes after reads are complete
      context.executeDeferredWrites();
    });
  }

  /// Runs a batch write operation with automatic batching
  ///
  /// The [cb] callback is executed within a batch context.
  /// All write operations are queued and committed at the end.
  ///
  /// Example:
  /// ```dart
  /// await odm.runBatch((batch) {
  ///   batch.users.insert(user1);
  ///   batch.users.insert(user2);
  ///   batch.users('user3').delete();
  /// });
  /// ```
  Future<void> runBatch(
    void Function(BatchContext<T>) cb,
  ) async {
    final context = BatchContext<T>(_firestore);
    
    // Execute the callback (queues all write operations)
    cb(context);
    
    // Commit all queued operations
    await context.commit();
  }

  /// Creates a batch context for manual batch operations
  ///
  /// This allows for manual control over when to commit the batch.
  /// Remember to call [BatchContext.commit] when you're done.
  ///
  /// Example:
  /// ```dart
  /// final batch = odm.batch();
  /// batch.users.insert(user1);
  /// batch.users.insert(user2);
  /// batch.users('user3').delete();
  /// await batch.commit();
  /// ```
  BatchContext<T> batch() {
    return BatchContext<T>(_firestore);
  }
}
