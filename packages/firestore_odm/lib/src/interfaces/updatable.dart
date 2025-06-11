abstract interface class Updatable<T> {
  /// Update an existing document using the id field as document ID
  /// Fails if document doesn't exist
  Future<void> update(T value);
}