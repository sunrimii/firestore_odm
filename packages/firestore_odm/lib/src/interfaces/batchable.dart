import 'package:firestore_odm/src/filter_builder.dart';

/// Interfaces for batch operations that are synchronous and queued for later execution

abstract interface class BatchInsertable<T> {
  /// Insert a document in batch mode (queued for later execution)
  void insert(T value);
}

abstract interface class BatchUpdatable<T> {
  /// Update a document in batch mode (queued for later execution)
  void update(T value);
}

abstract interface class BatchUpsertable<T> {
  /// Upsert a document in batch mode (queued for later execution)
  void upsert(T value);
}

abstract interface class BatchDeletable {
  /// Delete a document in batch mode (queued for later execution)
  void delete();
}

abstract interface class BatchPatchable<T> {
  /// Patch a document in batch mode (queued for later execution)
  void patch(List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder) patchBuilder);
}