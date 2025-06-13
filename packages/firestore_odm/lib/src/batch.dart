import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/batchable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/types.dart';
import 'package:firestore_odm/src/utils.dart';

/// Batch field for type-safe batch operations
class BatchField<T> extends Node {
  BatchField({super.name, super.parent, this.type});
  final FieldPathType? type;

  /// Insert operation
  void insert(T value) {
    switch($root) {
      case RootBatchFieldSelector selector:
        selector._operations.add(
          BatchInsertOperation(
            fieldPath: type?.toFirestore() ?? $path,
            value: value,
          ),
        );
      default:
        throw StateError('Invalid root type for BatchField: ${$root}');
    }
  }

  /// Update operation
  void update(T value) {
    switch($root) {
      case RootBatchFieldSelector selector:
        selector._operations.add(
          BatchUpdateOperation(
            fieldPath: type?.toFirestore() ?? $path,
            value: value,
          ),
        );
      default:
        throw StateError('Invalid root type for BatchField: ${$root}');
    }
  }

  /// Delete operation
  void delete() {
    switch($root) {
      case RootBatchFieldSelector selector:
        selector._operations.add(
          BatchDeleteOperation(
            fieldPath: type?.toFirestore() ?? $path,
          ),
        );
      default:
        throw StateError('Invalid root type for BatchField: ${$root}');
    }
  }
}

/// Base class for batch field selectors
class BatchFieldSelector<T> extends Node {
  BatchFieldSelector({super.name, super.parent});
}

/// Root batch field selector that manages batch operations
class RootBatchFieldSelector<T> extends BatchFieldSelector<T> {
  RootBatchFieldSelector();
  
  final List<BatchOperation> _operations = [];
}

/// Base class for batch operations
abstract class BatchOperation {
  final dynamic fieldPath;
  
  const BatchOperation({required this.fieldPath});
}

/// Insert operation
class BatchInsertOperation extends BatchOperation {
  final dynamic value;
  
  const BatchInsertOperation({
    required super.fieldPath,
    required this.value,
  });
}

/// Update operation
class BatchUpdateOperation extends BatchOperation {
  final dynamic value;
  
  const BatchUpdateOperation({
    required super.fieldPath,
    required this.value,
  });
}

/// Delete operation
class BatchDeleteOperation extends BatchOperation {
  const BatchDeleteOperation({required super.fieldPath});
}

/// Builder function type for batch operations
typedef BatchBuilderFunction<T> = void Function(BatchFieldSelector<T> selector);

/// Configuration for batch operations
class BatchConfiguration<T> {
  final List<BatchOperation> operations;
  final BatchBuilderFunction<T> builder;

  const BatchConfiguration(this.operations, this.builder);

  @override
  String toString() => 'BatchConfiguration(${operations.length} operations)';
}

/// Context for managing batch operations
class BatchContext<S extends FirestoreSchema> {
  final firestore.FirebaseFirestore _firestore;
  final firestore.WriteBatch _batch;

  BatchContext(this._firestore) : _batch = _firestore.batch();

  /// Access to the Firestore instance
  firestore.FirebaseFirestore get firestoreInstance => _firestore;

  /// Commits the batch
  Future<void> commit() async {
    await _batch.commit();
  }
}

/// Batch document for handling document-level batch operations
class BatchDocument<S extends FirestoreSchema, T> 
    implements BatchDeletable, BatchPatchable<T> {
  final BatchContext<S> _context;
  final firestore.DocumentReference<Map<String, dynamic>> _ref;
  final ModelConverter<T> _converter;
  final String _documentIdField;

  BatchDocument(
    this._context,
    this._ref,
    this._converter,
    this._documentIdField,
  );

  /// Access to the document reference for subcollection operations
  firestore.DocumentReference<Map<String, dynamic>> get ref => _ref;

  /// Access to the batch context for subcollection operations
  BatchContext<S> get context => _context;

  @override
  void delete() {
    _context._batch.delete(_ref);
  }

  @override
  void patch(List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder) patchBuilder) {
    final builder = UpdateBuilder<T>();
    final operations = patchBuilder(builder);
    final updateMap = UpdateBuilder.operationsToMap(operations);
    
    if (updateMap.isEmpty) {
      return; // No updates to apply
    }

    _context._batch.update(_ref, updateMap);
  }
}

/// Batch collection for handling collection-level batch operations
class BatchCollection<S extends FirestoreSchema, T> 
    implements BatchInsertable<T>, BatchUpdatable<T>, BatchUpsertable<T> {
  final BatchContext<S> _context;
  final firestore.CollectionReference<Map<String, dynamic>> _collection;
  final ModelConverter<T> _converter;
  final String _documentIdField;

  BatchCollection({
    required firestore.CollectionReference<Map<String, dynamic>> collection,
    required ModelConverter<T> converter,
    required String documentIdField,
    required BatchContext<S> context,
  }) : _collection = collection,
       _converter = converter,
       _documentIdField = documentIdField,
       _context = context;

  /// Gets a document reference for batch operations
  BatchDocument<S, T> call(String id) => BatchDocument(
    _context,
    _collection.doc(id),
    _converter,
    _documentIdField,
  );

  @override
  void insert(T value) {
    final (data, documentId) = processObject(
      _converter.toJson,
      value,
      documentIdField: _documentIdField,
    );

    // If ID is the auto-generated constant, let Firestore generate a unique ID
    if (documentId == kAutoGeneratedIdValue) {
      final docRef = _collection.doc();
      _context._batch.set(docRef, data);
    } else if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty. Use FirestoreODM.autoGeneratedId for auto-generated IDs.',
      );
    } else {
      final docRef = _collection.doc(documentId);
      _context._batch.set(docRef, data);
    }
  }

  @override
  void update(T value) {
    final (data, documentId) = processObject(
      _converter.toJson,
      value,
      documentIdField: _documentIdField,
    );

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty for batch update operation',
      );
    }

    final docRef = _collection.doc(documentId);
    _context._batch.set(docRef, data);
  }

  @override
  void upsert(T value) {
    final (data, documentId) = processObject(
      _converter.toJson,
      value,
      documentIdField: _documentIdField,
    );

    // Auto-generated IDs don't make sense for upsert operations
    if (documentId == kAutoGeneratedIdValue) {
      throw ArgumentError(
        'Auto-generated IDs cannot be used with upsert operations. '
        'Upsert requires a specific document ID to check for existing documents. '
        'Use insert() for auto-generated IDs or provide a specific ID for upsert.',
      );
    }

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty for batch upsert operation.',
      );
    }

    final docRef = _collection.doc(documentId);
    _context._batch.set(docRef, data, firestore.SetOptions(merge: true));
  }
}

/// Handler for batch operations using the Node-based architecture
abstract class BatchHandler {
  /// Build batch configuration using the Node-based selector pattern
  static BatchConfiguration<T> buildBatch<T>(
    BatchBuilderFunction<T> batchBuilder,
  ) {
    final selector = RootBatchFieldSelector<T>();
    
    // Call the batch builder to populate the selector
    batchBuilder(selector);
    
    return BatchConfiguration(selector._operations, batchBuilder);
  }

  /// Apply batch operations to a Firestore batch
  static void applyBatch<T>(
    firestore.WriteBatch batch,
    BatchConfiguration<T> config,
    firestore.CollectionReference<Map<String, dynamic>> collection,
    ModelConverter<T> converter,
    String documentIdField,
  ) {
    for (final operation in config.operations) {
      switch (operation) {
        case BatchInsertOperation insertOp:
          final (data, docId) = processObject(
            (value) => converter.toJson(value as T),
            insertOp.value,
            documentIdField: documentIdField,
          );
          final docRef = docId == kAutoGeneratedIdValue
              ? collection.doc()
              : collection.doc(docId);
          batch.set(docRef, data);
          
        case BatchUpdateOperation updateOp:
          final (data, docId) = processObject(
            (value) => converter.toJson(value as T),
            updateOp.value,
            documentIdField: documentIdField,
          );
          if (docId.isEmpty) {
            throw ArgumentError('Document ID required for update operation');
          }
          final docRef = collection.doc(docId);
          batch.set(docRef, data);
          
        case BatchDeleteOperation deleteOp:
          // For delete operations, we need the document ID from the field path
          final docRef = collection.doc(deleteOp.fieldPath.toString());
          batch.delete(docRef);
      }
    }
  }
}