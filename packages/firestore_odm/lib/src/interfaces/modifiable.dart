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
}
