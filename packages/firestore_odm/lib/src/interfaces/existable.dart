abstract interface class Existable<T> {
  /// Checks if the document exists in Firestore
  Future<bool> exists();
}
