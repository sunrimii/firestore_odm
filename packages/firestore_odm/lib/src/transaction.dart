import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/existable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';
import 'package:firestore_odm/src/utils.dart';

class TransactionContext<Schema extends FirestoreSchema> {
  final firestore.FirebaseFirestore ref;
  final firestore.Transaction transaction;

  TransactionContext(this.ref, this.transaction);
}

class TransactionCollection<S extends FirestoreSchema, T> {
  final firestore.Transaction _transaction;
  final firestore.CollectionReference<Map<String, dynamic>> query;
  final ModelConverter<T> converter;
  final String documentIdField;

  TransactionCollection({
    required firestore.Transaction transaction,
    required this.query,
    required this.converter,
    this.documentIdField = 'id',
  }) : _transaction = transaction;

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  TransactionDocument<S, T> call(String id) => TransactionDocument(
    _transaction,
    query.doc(id),
    converter,
    documentIdField,
  );
}

class TransactionDocument<S extends FirestoreSchema, T>
    implements
        Gettable<T?>,
        Modifiable<T>,
        TransactionalPatchable<T>,
        Existable,
        TransactionalDeletable {
  final firestore.Transaction _transaction;
  final firestore.DocumentReference<Map<String, dynamic>> ref;
  final ModelConverter<T> converter;
  final String documentIdField;

  TransactionDocument(
    this._transaction,
    this.ref,
    this.converter,
    this.documentIdField,
  );

  @override
  Future<T?> get() async {
    final snapshot = await _transaction.get(ref);
    if (!snapshot.exists) return null;
    return fromFirestoreData(
      converter.fromJson,
      snapshot.data()!,
      documentIdField,
      snapshot.id,
    );
  }

  @override
  Future<void> incrementalModify(T Function(T docData) modifier) async {
    // In transaction: do all reads first, then defer writes
    final snapshot = await _transaction.get(ref);
    final patch = DocumentHandler.processPatch(
      snapshot,
      modifier,
      converter,
      documentIdField,
      computeDiff,
    );
    if (patch.isNotEmpty) {
      _transaction.update(ref, patch);
    }
  }

  @override
  Future<void> modify(T Function(T docData) modifier) async {
    // In transaction: do all reads first, then defer writes
    final snapshot = await _transaction.get(ref);
    final patch = DocumentHandler.processPatch(
      snapshot,
      modifier,
      converter,
      documentIdField,
      computeDiffWithAtomicOperations,
    );
    if (patch.isEmpty) {
      return; // No changes to apply
    }
    _transaction.update(ref, patch);
  }

  @override
  void patch(
    List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder) patchBuilder,
  ) {
    final builder = UpdateBuilder<T>();
    final operations = patchBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    if (!updateMap.isNotEmpty) {
      return; // No updates to apply
    }
    _transaction.update(ref, updateMap);
  }

  @override
  Future<bool> exists() {
    return _transaction.get(ref).then((snapshot) => snapshot.exists);
  }

  @override
  void delete() {
    _transaction.delete(ref);
  }
}
