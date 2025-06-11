abstract interface class Gettable<T> {
  /// Gets the document data
  /// Uses transactions when available, otherwise fetches from cache or Firestore
  Future<T?> get();
}
