typedef ModifierBuilder<T> = T Function(T docData);

abstract interface class Modifiable<T> {
  /// Modify the document using a strongly-typed modifier function.
  ///
  /// This method performs a read operation followed by an update operation.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// Note: Firestore uses last-write-wins semantics. This read-modify-write
  /// operation is NOT transactional and may be subject to race conditions.
  /// For transactional updates, use transactions.
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// Returns a Future that completes when the modification is applied.
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true});

  /// @deprecated Use [modify] with atomic parameter instead.
  /// This method will be removed in a future version.
  ///
  /// Migrate to: `modify(modifier, atomic: true)`
  @Deprecated('Use modify(atomic: true) instead. This method will be removed in a future version.')
  Future<void> incrementalModify(ModifierBuilder<T> modifier);
}

abstract interface class TransactionalModifiable<T> {
  /// Modify the document within a transaction.
  ///
  /// This method performs a read operation followed by an update operation within a transaction.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// Returns a Future that completes when the transaction is applied.
  void modify(ModifierBuilder<T> modifier, {bool atomic = true});

  /// @deprecated Use [modify] with atomic parameter instead.
  /// This method will be removed in a future version.
  ///
  /// Migrate to: `modify(modifier, atomic: true)`
  @Deprecated('Use modify(atomic: true) instead. This method will be removed in a future version.')
  void incrementalModify(ModifierBuilder<T> modifier);
}
