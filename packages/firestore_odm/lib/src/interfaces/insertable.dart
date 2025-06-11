abstract interface class Insertable<T> {
  /// Insert a new document using the id field as document ID
  /// Fails if document already exists
  Future<void> insert(T value);
}
