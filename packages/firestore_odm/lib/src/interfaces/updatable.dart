import 'dart:async';

/// An interface for updating existing documents in a Firestore collection.
///
/// [T] is the type of the model that will be used for the update.
abstract interface class Updatable<T> {
  /// Updates an existing document in the collection.
  ///
  /// The document to be updated is identified by its `id` field within
  /// the provided [value]. If a document with the specified ID does not
  /// exist, this operation will fail.
  ///
  /// [value]: The data to update the document with. The `id` field of this
  /// object is used to locate the document.
  ///
  /// Returns a [FutureOr] that completes when the document has been successfully
  /// updated.
  FutureOr<void> update(T value);
}
