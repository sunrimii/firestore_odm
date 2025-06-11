/// Interface defining subscription/real-time operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class Streamable<T> {
  /// Stream of document changes for real-time updates
  Stream<T?> get stream;
}
