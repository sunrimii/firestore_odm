/// Interface defining update operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class UpdateOperations<T> {
  /// RxDB-style modify without atomic operations
  /// Only computes differences and updates changed fields
  Future<void> modify(T Function(T docData) modifier);
  
  /// RxDB-style incremental modify with automatic atomic operations
  /// Automatically detects and uses Firestore atomic operations where possible
  Future<void> incrementalModify(T Function(T docData) modifier);
}