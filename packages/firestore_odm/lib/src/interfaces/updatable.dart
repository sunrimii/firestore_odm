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
  /// Returns a [Future] that completes when the document has been successfully
  /// updated.
  Future<void> update(T value);
}

/// An interface for updating existing documents within a Firestore transaction.
///  
/// [T] is the type of the model that will be used for the update.
abstract interface class SynchronousUpdatable<T> {
  /// Updates an existing document within an ongoing Firestore transaction.
  ///
  /// The document to be updated is identified by its `id` field within
  /// the provided [value]. If a document with the specified ID does not
  /// exist, this operation will fail.
  ///
  /// [value]: The data to update the document with. The `id` field of this
  /// object is used to locate the document.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void update(T value);
}