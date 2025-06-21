/// A typedef for defining a function that modifies a document's data.
///
/// This function takes the current document data of type [T] and returns
/// the modified document data of the same type [T].
typedef ModifierBuilder<T> = T Function(T docData);

/// An interface for modifying existing documents in Firestore.
///
/// [T] is the type of the model representing the document data.
abstract interface class Modifiable<T> {
  /// Modifies the document using a strongly-typed modifier function.
  ///
  /// This method performs a read operation to get the current document data,
  /// applies the [modifier] function to it, and then performs an update
  /// operation with the modified data.
  ///
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but it is convenient when you need to read the current state of a document
  /// before updating it.
  ///
  /// Note: Firestore uses last-write-wins semantics. This read-modify-write
  /// operation is NOT transactional by default and may be subject to race
  /// conditions if multiple clients try to modify the same document concurrently.
  /// For transactional updates, use [TransactionalModifiable.modify].
  ///
  /// [atomic]: When `true` (default), the system automatically detects and uses
  /// Firestore's atomic operations like `FieldValue.increment()`,
  /// `FieldValue.arrayUnion()`, and `FieldValue.arrayRemove()` where possible.
  /// When `false`, it performs simple field updates without atomic operations.
  ///
  /// [modifier]: A function that takes the current document data and returns
  /// the modified document data.
  ///
  /// Returns a [Future] that completes when the modification is successfully applied.
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true});

  /// @deprecated Use [modify] with the `atomic` parameter instead.
  /// This method will be removed in a future version.
  ///
  /// Migrate your code to use: `modify(modifier, atomic: true)`
  @Deprecated('Use modify(atomic: true) instead. This method will be removed in a future version.')
  Future<void> incrementalModify(ModifierBuilder<T> modifier);
}

/// An interface for modifying existing documents within a Firestore transaction.
///
/// [T] is the type of the model representing the document data.
abstract interface class TransactionalModifiable<T> {
  /// Modifies the document within an ongoing Firestore transaction.
  ///
  /// This method performs a read operation to get the current document data
  /// within the transaction, applies the [modifier] function to it, and then
  /// performs an update operation with the modified data, all within the
  /// same atomic transaction.
  ///
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but it is convenient when you need to read the current state before writing
  /// and ensure atomicity.
  ///
  /// [atomic]: When `true` (default), the system automatically detects and uses
  /// Firestore's atomic operations like `FieldValue.increment()`,
  /// `FieldValue.arrayUnion()`, and `FieldValue.arrayRemove()` where possible.
  /// When `false`, it performs simple field updates without atomic operations.
  ///
  /// [modifier]: A function that takes the current document data and returns
  /// the modified document data.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void modify(ModifierBuilder<T> modifier, {bool atomic = true});

  /// @deprecated Use [modify] with the `atomic` parameter instead.
  /// This method will be removed in a future version.
  ///
  /// Migrate your code to use: `modify(modifier, atomic: true)`
  @Deprecated('Use modify(atomic: true) instead. This method will be removed in a future version.')
  void incrementalModify(ModifierBuilder<T> modifier);
}
