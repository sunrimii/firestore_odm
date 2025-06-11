/// Interface for strongly-typed pagination operations
/// The generic type O represents the tuple of orderBy field types
abstract interface class Paginatable<T, O> {
  /// Start pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  Paginatable<T, O> startAt(O cursorValues);

  /// Start pagination after the given cursor values
  /// The cursor values must match the orderBy tuple type O
  Paginatable<T, O> startAfter(O cursorValues);

  /// End pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  Paginatable<T, O> endAt(O cursorValues);

  /// End pagination before the given cursor values
  /// The cursor values must match the orderBy tuple type O
  Paginatable<T, O> endBefore(O cursorValues);

  /// Start pagination at the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  Paginatable<T, O> startAtObject(T object);

  /// Start pagination after the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  Paginatable<T, O> startAfterObject(T object);

  /// End pagination at the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  Paginatable<T, O> endAtObject(T object);

  /// End pagination before the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  Paginatable<T, O> endBeforeObject(T object);
}
