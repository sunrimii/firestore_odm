abstract interface class Existable {
  /// Checks if the document exists in Firestore
  Future<bool> exists();
}
