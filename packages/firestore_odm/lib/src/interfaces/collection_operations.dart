/// Interface defining collection-level operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class CollectionOperations<T> {
  /// Insert a new document using the id field as document ID
  /// Fails if document already exists
  Future<void> insert(T value);

  /// Update an existing document using the id field as document ID
  /// Fails if document doesn't exist
  Future<void> updateDocument(T value);

  /// Upsert a document using the id field as document ID
  /// Creates new document or updates existing one
  Future<void> upsert(T value);
}