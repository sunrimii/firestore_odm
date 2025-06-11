abstract interface class Deletable<T> {
  /// Deletes the document using a strongly-typed delete function
  /// Returns a Future that completes when the deletion is applied
  Future<void> delete();
}
