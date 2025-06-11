abstract interface class Upsertable<T> {
  /// Upsert a document using the id field as document ID
  /// Creates new document or updates existing one
  Future<void> upsert(T value);
}
