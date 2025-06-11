abstract interface class Modifiable<T> {
  /// Modify the document using a strongly-typed modifier function
  /// Returns a Future that completes when the modification is applied
  Future<void> modify(T Function(T docData) modifier);

  /// Incremental modify the document with automatic atomic operations
  /// Returns a Future that completes when the incremental modification is applied
  Future<void> incrementalModify(T Function(T docData) modifier);
}

abstract interface class TransactionalModifiable<T> {
  /// Modify the document within a transaction
  /// Returns a Future that completes when the transaction is applied
  void modify(T Function(T docData) modifier);

  /// Incremental modify the document within a transaction
  /// Returns a Future that completes when the incremental modification is applied
  void incrementalModify(T Function(T docData) modifier);
}