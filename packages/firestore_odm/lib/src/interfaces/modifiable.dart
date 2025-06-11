typedef ModifierBuilder<T> = T Function(T docData);

abstract interface class Modifiable<T> {
  /// Modify the document using a strongly-typed modifier function
  /// Returns a Future that completes when the modification is applied
  Future<void> modify(ModifierBuilder<T> modifier);

  /// Incremental modify the document with automatic atomic operations
  /// Returns a Future that completes when the incremental modification is applied
  Future<void> incrementalModify(ModifierBuilder<T> modifier);
}

abstract interface class TransactionalModifiable<T> {
  /// Modify the document within a transaction
  /// Returns a Future that completes when the transaction is applied
  void modify(ModifierBuilder<T> modifier);

  /// Incremental modify the document within a transaction
  /// Returns a Future that completes when the incremental modification is applied
  void incrementalModify(ModifierBuilder<T> modifier);
}