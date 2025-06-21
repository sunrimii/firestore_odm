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

/// Interface for deleting a single document within a transaction.
abstract interface class TransactionalDeletable {
  /// Deletes the document within an ongoing Firestore transaction.
  ///
  /// This operation is atomic with other operations within the same transaction.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void delete();
}
