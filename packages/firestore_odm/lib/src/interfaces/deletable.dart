abstract interface class Deletable {
  /// Deletes the document using a strongly-typed delete function
  /// Returns a Future that completes when the deletion is applied
  Future<void> delete();
}

abstract interface class TransactionalDeletable {
  /// Deletes the document within a transaction
  /// Returns a Future that completes when the deletion is applied
  void delete();
}