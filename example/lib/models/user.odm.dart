// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// FirestoreGenerator
// **************************************************************************

mixin UserQueryMixin {
  FirestoreCollection<User> get collection;
  Query<Map<String, dynamic>> get query;

  UserQuery whereDocumentId({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      FieldPath.documentId,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByDocumentId({bool descending = false}) {
    return UserQuery(
      collection,
      query.orderBy(FieldPath.documentId, descending: descending),
    );
  }

  UserQuery whereId({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      'id',
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderById({bool descending = false}) {
    return UserQuery(collection, query.orderBy('id', descending: descending));
  }

  UserQuery whereName({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      'name',
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByName({bool descending = false}) {
    return UserQuery(collection, query.orderBy('name', descending: descending));
  }

  UserQuery whereEmail({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      'email',
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByEmail({bool descending = false}) {
    return UserQuery(
      collection,
      query.orderBy('email', descending: descending),
    );
  }

  UserQuery whereAge({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      'age',
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByAge({bool descending = false}) {
    return UserQuery(collection, query.orderBy('age', descending: descending));
  }

  UserQuery whereTags({
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
  }) {
    Query<Map<String, dynamic>> newQuery = query;
    if (arrayContains != null) {
      newQuery = newQuery.where('tags', arrayContains: arrayContains);
    }
    if (arrayContainsAny != null) {
      newQuery = newQuery.where('tags', arrayContainsAny: arrayContainsAny);
    }
    if (whereIn != null) {
      newQuery = newQuery.where('tags', whereIn: whereIn);
    }
    if (whereNotIn != null) {
      newQuery = newQuery.where('tags', whereNotIn: whereNotIn);
    }
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByTags({bool descending = false}) {
    return UserQuery(collection, query.orderBy('tags', descending: descending));
  }

  UserQuery whereCreatedAt({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    Query<Map<String, dynamic>> newQuery = query.where(
      'createdAt',
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
    return UserQuery(collection, newQuery);
  }

  UserQuery orderByCreatedAt({bool descending = false}) {
    return UserQuery(
      collection,
      query.orderBy('createdAt', descending: descending),
    );
  }
}

class UserCollection extends FirestoreCollection<User> with UserQueryMixin {
  UserCollection()
    : super(
        ref: FirebaseFirestore.instance.collection('users'),
        fromJson: (data) => User.fromJson(data),
        toJson: (value) => value.toJson(),
      );

  @override
  Query<Map<String, dynamic>> get query => ref;

  @override
  FirestoreCollection<User> get collection => this;
}

class UserQuery extends FirestoreQuery<User> with UserQueryMixin {
  UserQuery(this.collection, Query<Map<String, dynamic>> query)
    : super(collection, query);

  @override
  final FirestoreCollection<User> collection;

  @override
  Query<Map<String, dynamic>> get query => super.query;

  @override
  FirestoreQuery<User> newInstance(Query<Map<String, dynamic>> query) {
    return UserQuery(collection, query);
  }
}
