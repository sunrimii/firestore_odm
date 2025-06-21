/// Interface for strongly-typed pagination operations.
///
/// This interface provides methods to define boundary conditions for queries
/// based on document field values, enabling efficient cursor-based pagination.
///
/// [T] represents the type of the model for the documents being paginated.
/// [O] represents the record/tuple of `orderBy` field types, which dictates
/// the structure of the `cursorValues` used for pagination.
abstract interface class Paginatable<T, O> {
  /// Starts the pagination at the given [cursorValues].
  ///
  /// The query will return documents starting from the document that exactly
  /// matches the provided [cursorValues]. These values must correspond to
  /// the fields and order defined in the `orderBy` clause.
  ///
  /// [cursorValues]: A record/tuple of values corresponding to the `orderBy` fields.
  Paginatable<T, O> startAt(O cursorValues);

  /// Starts the pagination after the given [cursorValues].
  ///
  /// The query will return documents strictly after the document that matches
  /// the provided [cursorValues]. These values must correspond to the fields
  /// and order defined in the `orderBy` clause.
  ///
  /// [cursorValues]: A record/tuple of values corresponding to the `orderBy` fields.
  Paginatable<T, O> startAfter(O cursorValues);

  /// Ends the pagination at the given [cursorValues].
  ///
  /// The query will return documents up to and including the document that
  /// exactly matches the provided [cursorValues]. These values must correspond
  /// to the fields and order defined in the `orderBy` clause.
  ///
  /// [cursorValues]: A record/tuple of values corresponding to the `orderBy` fields.
  Paginatable<T, O> endAt(O cursorValues);

  /// Ends the pagination before the given [cursorValues].
  ///
  /// The query will return documents strictly before the document that matches
  /// the provided [cursorValues]. These values must correspond to the fields
  /// and order defined in the `orderBy` clause.
  ///
  /// [cursorValues]: A record/tuple of values corresponding to the `orderBy` fields.
  Paginatable<T, O> endBefore(O cursorValues);

  /// Starts the pagination at the document represented by the given [object].
  ///
  /// This method automatically extracts the necessary cursor values from the
  /// [object] based on the currently defined `orderBy` configuration.
  ///
  /// [object]: The document object whose field values will be used as the starting cursor.
  Paginatable<T, O> startAtObject(T object);

  /// Starts the pagination after the document represented by the given [object].
  ///
  /// This method automatically extracts the necessary cursor values from the
  /// [object] based on the currently defined `orderBy` configuration.
  ///
  /// [object]: The document object whose field values will be used as the cursor.
  Paginatable<T, O> startAfterObject(T object);

  /// Ends the pagination at the document represented by the given [object].
  ///
  /// This method automatically extracts the necessary cursor values from the
  /// [object] based on the currently defined `orderBy` configuration.
  ///
  /// [object]: The document object whose field values will be used as the ending cursor.
  Paginatable<T, O> endAtObject(T object);

  /// Ends the pagination before the document represented by the given [object].
  ///
  /// This method automatically extracts the necessary cursor values from the
  /// [object] based on the currently defined `orderBy` configuration.
  ///
  /// [object]: The document object whose field values will be used as the cursor.
  Paginatable<T, O> endBeforeObject(T object);
}
