import 'update_operations.dart';
import 'subscribe_operations.dart';

/// Interface defining document operation capabilities
/// Combines update and subscription operations for documents
/// Part of the Interface + Composition architecture
abstract interface class DocumentOperations<T>
    implements UpdateOperations<T>, SubscribeOperations<T> {
  
  /// Gets the document data
  /// Uses transactions when available, otherwise fetches from cache or Firestore
  Future<T?> get();
  
  /// Sets the document data
  /// Uses transactions when available for atomic operations
  Future<void> set(T state);
  
  /// Deletes the document
  Future<void> delete();
  
  /// Checks if the document exists in Firestore
  Future<bool> exists();
  
  /// Gets the document or creates it with the provided factory function
  Future<T> getOrCreate(T Function() create);
}