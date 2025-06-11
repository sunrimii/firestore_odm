abstract interface class Modifiable<T> {
  /// Modify the document using a strongly-typed modifier function
  /// Returns a Future that completes when the modification is applied
  Future<void> modify(T Function(T docData) modifier);

  /// Incremental modify the document with automatic atomic operations
  /// Returns a Future that completes when the incremental modification is applied
  Future<void> incrementalModify(T Function(T docData) modifier);
}