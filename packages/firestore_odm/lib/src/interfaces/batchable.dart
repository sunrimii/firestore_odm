import 'package:firestore_odm/src/filter_builder.dart';

/// Defines interfaces for batch operations that are performed synchronously and
/// queued for later execution as a single atomic write.
abstract interface class BatchInsertable<T> {
  /// Queues an insert operation for a document in batch mode.
  ///
  /// The document will be inserted if it does not already exist.
  ///
  /// [value]: The data of the document to be inserted.
  void insert(T value);
}

abstract interface class BatchUpdatable<T> {
  /// Queues an update operation for an existing document in batch mode.
  ///
  /// The document must already exist for this operation to succeed.
  ///
  /// [value]: The new data to update the document with.
  void update(T value);
}

abstract interface class BatchUpsertable<T> {
  /// Queues an upsert operation for a document in batch mode.
  ///
  /// If the document does not exist, it will be created. If it already exists,
  /// its data will be updated.
  ///
  /// [value]: The data of the document to be upserted.
  void upsert(T value);
}

abstract interface class BatchDeletable {
  /// Queues a delete operation for a document in batch mode.
  ///
  /// The document will be deleted from the collection.
  void delete();
}

abstract interface class BatchPatchable<T> {
  /// Queues a patch operation for an existing document in batch mode.
  ///
  /// A patch operation updates specific fields of a document without replacing
  /// the entire document.
  ///
  /// [patchBuilder]: A function that provides an [UpdateBuilder] to specify
  /// the fields to be patched.
  void patch(List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder) patchBuilder);
}