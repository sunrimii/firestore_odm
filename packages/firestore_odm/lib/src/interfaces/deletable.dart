/// Interface for deleting a single document.
abstract interface class Deletable {
  /// Deletes the document from Firestore.
  ///
  /// This operation is performed directly on the document reference and is
  /// not part of a transaction.
  ///
  /// Returns a [Future] that completes when the deletion is successfully applied.
  Future<void> delete();
}


/// Interface for deleting a single document within a Firestore transaction.
abstract interface class SynchronousDeletable {
  /// Deletes the document from Firestore within an ongoing transaction.
  ///
  /// This operation is performed on the document reference as part of a
  /// transaction. The transaction must be committed to apply the deletion.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void delete();
}