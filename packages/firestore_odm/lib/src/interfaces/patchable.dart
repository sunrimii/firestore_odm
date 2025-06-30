import 'package:firestore_odm/src/filter_builder.dart';

/// A typedef for building strongly-typed patch operations.
///
/// This function is used to define a list of [UpdateOperation]s that will be
/// applied to a document.
///
/// [T] represents the type of the model being patched.
// typedef PatchBuilder<T> =
//     List<UpdateOperation> Function(UpdateBuilder<T> patchBuilder);

/// An interface for applying partial updates (patches) to existing documents.
///
/// [T] is the type of the model representing the document data.
abstract interface class Patchable<T> {
  /// Patches the document using a strongly-typed update builder.
  ///
  /// This method allows for updating specific fields of a document without
  /// overwriting the entire document. The [patchBuilder] provides a
  /// [UpdateBuilder] which enables type-safe specification of fields
  /// to be updated, including atomic operations.
  ///
  /// [patchBuilder]: A function that constructs the list of [UpdateOperation]s
  /// to be applied to the document.
  ///
  /// Returns a [Future] that completes when the patch is successfully applied.
  Future<void> patch(List<UpdateOperation> Function(PatchBuilder<T> patchBuilder) patches);
}

/// An interface for applying partial updates (patches) to existing documents
/// within a Firestore transaction.
///
/// [T] is the type of the model representing the document data.
abstract interface class SynchronousPatchable<T> {
  /// Patches the document within an ongoing Firestore transaction using a
  /// strongly-typed update builder.
  ///
  /// This operation is atomic with other operations within the same transaction.
  ///
  /// [patchBuilder]: A function that constructs the list of [UpdateOperation]s
  /// to be applied to the document within the transaction.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void patch(List<UpdateOperation> Function(PatchBuilder<T> patchBuilder) patches);
}
