import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_document.dart';

/// A wrapper around Firestore CollectionReference with type safety and caching
class FirestoreCollection<T> {
  /// The underlying Firestore collection reference
  final CollectionReference<Map<String, dynamic>> ref;

  /// Function to convert JSON data to model instance
  final T Function(Map<String, dynamic> data) fromJson;

  /// Function to convert model instance to JSON data
  final Map<String, dynamic> Function(T value) toJson;

  /// Cache for document instances
  final Map<String, FirestoreDocument<T>> _cache = {};

  /// Creates a new FirestoreCollection instance
  FirestoreCollection({
    required this.ref,
    required this.fromJson,
    required this.toJson,
  });

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  FirestoreDocument<T> doc(String id) {
    return _cache.putIfAbsent(id, () => FirestoreDocument(this, id));
  }
}
