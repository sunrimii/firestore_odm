/// Interface for checking the existence of a document.
abstract interface class Existable {
  /// Checks if the document associated with this reference currently exists in Firestore.
  ///
  /// Returns a [Future] that resolves to `true` if the document exists,
  /// and `false` otherwise.
  Future<bool> exists();
}
