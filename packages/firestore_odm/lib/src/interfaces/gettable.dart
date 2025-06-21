/// An interface for retrieving document data.
///
/// [T] is the type of the model representing the document data.
abstract interface class Gettable<T> {
  /// Retrieves the document data from Firestore.
  ///
  /// This method attempts to get the document data from an ongoing transaction
  /// if available. Otherwise, it fetches the data from the Firestore cache
  /// or directly from Firestore, depending on the current settings and network availability.
  ///
  /// Returns a [Future] that resolves to an instance of [T] if the document exists,
  /// or `null` if the document does not exist.
  Future<T?> get();
}
