/// Interface for strongly-typed pagination operations
/// The generic type O represents the tuple of orderBy field types
abstract interface class PaginationOperations<T, O> {
  /// Start pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  PaginationOperations<T, O> startAt(O cursorValues);

  /// Start pagination after the given cursor values
  /// The cursor values must match the orderBy tuple type O
  PaginationOperations<T, O> startAfter(O cursorValues);

  /// End pagination at the given cursor values
  /// The cursor values must match the orderBy tuple type O
  PaginationOperations<T, O> endAt(O cursorValues);

  /// End pagination before the given cursor values
  /// The cursor values must match the orderBy tuple type O
  PaginationOperations<T, O> endBefore(O cursorValues);

  /// Start pagination at the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  PaginationOperations<T, O> startAtObject(T object);

  /// Start pagination after the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  PaginationOperations<T, O> startAfterObject(T object);

  /// End pagination at the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  PaginationOperations<T, O> endAtObject(T object);

  /// End pagination before the given object
  /// Automatically extracts cursor values based on current orderBy configuration
  PaginationOperations<T, O> endBeforeObject(T object);
}

/// Specialized pagination operations when no orderBy has been applied
abstract interface class EmptyPaginationOperations<T> {
  /// Cannot use pagination without orderBy - call orderBy() first
  Never startAt(dynamic cursorValues);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never startAfter(dynamic cursorValues);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never endAt(dynamic cursorValues);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never endBefore(dynamic cursorValues);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never startAtObject(T object);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never startAfterObject(T object);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never endAtObject(T object);
  
  /// Cannot use pagination without orderBy - call orderBy() first
  Never endBeforeObject(T object);
}