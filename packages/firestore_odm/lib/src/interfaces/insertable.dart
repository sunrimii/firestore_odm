/// An interface for inserting new documents into a Firestore collection.
///
/// [T] is the type of the model that will be inserted.
abstract interface class Insertable<T> {
  /// Inserts a new document into the collection.
  ///
  /// The document's ID will be determined by the `id` field within the
  /// provided [value]. If a document with the same ID already exists in the
  /// collection, this operation will fail.
  ///
  /// [value]: The data of the document to be inserted.
  ///
  /// Returns a [Future] that completes when the document has been successfully inserted.
  Future<void> insert(T value);
}


/// An interface for inserting new documents within a Firestore transaction.
/// 
/// [T] is the type of the model that will be inserted.
abstract interface class SynchronousInsertable<T> {
  /// Inserts a new document within an ongoing Firestore transaction.
  ///
  /// The document's ID will be determined by the `id` field within the
  /// provided [value]. If a document with the same ID already exists in the
  /// collection, this operation will fail.
  ///
  /// [value]: The data of the document to be inserted.
  ///
  /// This method does not return a [Future] directly, as the transaction's
  /// completion (`transaction.commit()`) handles the overall result.
  void insert(T value);
}