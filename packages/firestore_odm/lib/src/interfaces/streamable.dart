/// An interface defining capabilities for real-time data streaming and subscriptions.
///
/// This interface is part of an "Interface + Composition" architecture, allowing
/// different data access objects to expose real-time update streams.
///
/// [T] is the type of the model representing the data being streamed.
abstract interface class Streamable<T> {
  /// Provides a real-time [Stream] of document changes.
  ///
  /// This getter returns a [Stream] that emits a new value of type [T]
  /// whenever the underlying document data changes in Firestore. If the document
  /// ceases to exist, it will emit `null`. This is ideal for building reactive
  /// UI components that require immediate updates.
  ///
  /// Returns a [Stream] of [T?] for real-time updates.
  Stream<T?> get stream;
}
