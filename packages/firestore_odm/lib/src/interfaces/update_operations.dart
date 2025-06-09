import 'package:firestore_odm/src/filter_builder.dart';

/// Interface defining update operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class UpdateOperations<T> {
  /// Update using array-style update operations with type-safe builder
  Future<void> update(
    List<UpdateOperation> Function(UpdateBuilder<T> updateBuilder)
    updateBuilder,
  );

  /// RxDB-style modify without atomic operations
  /// Only computes differences and updates changed fields
  Future<void> modify(T Function(T docData) modifier);

  /// RxDB-style incremental modify with automatic atomic operations
  /// Automatically detects and uses Firestore atomic operations where possible
  Future<void> incrementalModify(T Function(T docData) modifier);
}
