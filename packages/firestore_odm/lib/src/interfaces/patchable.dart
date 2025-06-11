import 'package:firestore_odm/src/filter_builder.dart';

abstract interface class Patchable<T> {
  /// Patch the document using a strongly-typed update builder
  /// Returns a Future that completes when the patch is applied
  Future<void> patch(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  );
}
