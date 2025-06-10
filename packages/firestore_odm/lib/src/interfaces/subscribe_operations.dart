/// Interface defining subscription/real-time operation capabilities
/// Part of the Interface + Composition architecture
abstract interface class SubscribeOperations<T> {
  /// Stream of document changes for real-time updates
  Stream<T?> get snapshots;

  /// Whether this instance is currently subscribed to real-time updates
  bool get isSubscribing;
}
