import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/existable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';
import 'package:firestore_odm/src/utils.dart';

class TransactionContext<Schema extends FirestoreSchema> {
  final firestore.FirebaseFirestore ref;
  final firestore.Transaction transaction;
  final Map<String, firestore.DocumentSnapshot<Map<String, dynamic>>>
  _documentCache = {};
  final List<Function()> _deferredWrites = [];

  TransactionContext(this.ref, this.transaction);

  /// Cache a document snapshot for reuse within the transaction
  void _cacheDocument(
    firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    _documentCache[snapshot.reference.path] = snapshot;
  }

  /// Get a cached document snapshot if available
  firestore.DocumentSnapshot<Map<String, dynamic>>? _getCachedDocument(
    firestore.DocumentReference<Map<String, dynamic>> ref,
  ) {
    return _documentCache[ref.path];
  }

  /// Add a deferred write operation
  void _addDeferredWrite(Function() writeOperation) {
    _deferredWrites.add(writeOperation);
  }

  /// Execute all deferred writes
  void executeDeferredWrites() {
    for (final write in _deferredWrites) {
      write();
    }
    _deferredWrites.clear();
  }
}

class TransactionCollection<S extends FirestoreSchema, T> {
  final firestore.Transaction _transaction;
  final firestore.CollectionReference<Map<String, dynamic>> query;
  final FirestoreConverter<T, Map<String, dynamic>> converter;
  final String documentIdField;
  final TransactionContext<S> _context;

  TransactionCollection({
    required firestore.Transaction transaction,
    required this.query,
    required this.converter,
    required TransactionContext<S> context,
    required this.documentIdField,
  }) : _transaction = transaction,
       _context = context;

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  TransactionDocument<S, T> call(String id) => TransactionDocument(
    _transaction,
    query.doc(id),
    converter,
    documentIdField,
    _context,
  );
}

class TransactionDocument<S extends FirestoreSchema, T>
    implements
        Gettable<T?>,
        Modifiable<T>,
        SynchronousPatchable<T>,
        Existable,
        SynchronousDeletable {
  final firestore.Transaction _transaction;
  final firestore.DocumentReference<Map<String, dynamic>> ref;
  final FirestoreConverter<T, Map<String, dynamic>> converter;
  final String documentIdField;
  final TransactionContext<S> _context;

  TransactionDocument(
    this._transaction,
    this.ref,
    this.converter,
    this.documentIdField,
    this._context,
  );

  @override
  Future<T?> get() async {
    final snapshot = await _transaction.get(ref);
    // Cache the snapshot for future use in this transaction
    _context._cacheDocument(snapshot);
    if (!snapshot.exists) return null;
    return fromFirestoreData(
      converter.fromJson,
      snapshot.data()!,
      documentIdField,
      snapshot.id,
    );
  }

  /// Get a document snapshot, reading if not cached
  Future<firestore.DocumentSnapshot<Map<String, dynamic>>>
  _getSnapshot() async {
    final cached = _context._getCachedDocument(ref);
    if (cached != null) {
      return cached;
    }
    final snapshot = await _transaction.get(ref);
    _context._cacheDocument(snapshot);
    return snapshot;
  }

  /// Modify a document within a transaction using diff-based updates.
  ///
  /// This method performs a read operation followed by an update operation within a transaction.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// **Important Notes:**
  /// - **Transactions**: This operation is transactional and handles read-before-write correctly
  /// - **Deferred Writes**: Write operations are automatically deferred until transaction commit
  /// - **Performance**: Additional read operation impacts performance compared to [patch]
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// **Example:**
  /// ```dart
  /// await db.runTransaction((tx) async {
  ///   // With atomic operations (default)
  ///   await tx.users('user1').modify((user) => user.copyWith(
  ///     balance: user.balance - 100, // Auto-detects -> FieldValue.increment(-100)
  ///   ));
  ///
  ///   // Without atomic operations
  ///   await tx.users('user2').modify((user) => user.copyWith(
  ///     status: 'processed',
  ///   ), atomic: false);
  /// });
  /// ```
  @override
  Future<void> modify(T Function(T docData) modifier, {bool atomic = true}) async {
    // Read the document and prepare the write operation
    final snapshot = await _getSnapshot();
    final patch = DocumentHandler.processPatch(
      snapshot,
      modifier,
      converter.toJson,
      converter.fromJson,
      documentIdField,
      atomic ? computeDiffWithAtomicOperations : computeDiff,
    );
    if (patch.isNotEmpty) {
      // Defer the write operation
      _context._addDeferredWrite(() => _transaction.update(ref, patch));
    }
  }

  @override
  void patch(
    List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder) patchBuilder,
  ) {
    final builder = UpdateBuilder<T>();
    final operations = patchBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    if (updateMap.isNotEmpty) {
      // Defer the write operation
      _context._addDeferredWrite(() => _transaction.update(ref, updateMap));
    }
  }

  @override
  Future<bool> exists() async {
    final snapshot = await _getSnapshot();
    return snapshot.exists;
  }

  @override
  void delete() {
    // Defer the delete operation
    _context._addDeferredWrite(() => _transaction.delete(ref));
  }
}
