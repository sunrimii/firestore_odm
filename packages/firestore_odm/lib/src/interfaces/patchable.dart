import 'package:firestore_odm/src/filter_builder.dart';

abstract interface class Patchable<T> {
  /// Patch the document using a strongly-typed update builder
  /// Returns a Future that completes when the patch is applied
  Future<void> patch(
    List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder)
    patchBuilder,
  );
}


abstract interface class TransactionalPatchable<T> {
  /// Patch the document within a transaction using a strongly-typed update builder
  /// Returns a Future that completes when the patch is applied
  void patch(
    List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder)
    patchBuilder,
  );
}