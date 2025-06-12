import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/interfaces/orderable.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/orderby.dart';
import 'package:firestore_odm/src/recordHelper.dart';

abstract class QueryPaginationHandler {
  static List<dynamic> build<R extends Record>(R cursorValues) {
    return cursorValues.toList();
  }

  /// Smart value extraction using the SAME builder function as orderBy
  /// This ensures perfect consistency and type safety
  static List<dynamic> buildValuesFromObject<T, O extends Record>(
    T object,
    ModelConverter<T> converter,
    OrderByBuilder<T, O> orderByBuilder,
    String documentIdFieldName,
  ) {
    // Convert object to Map for extraction
    final objectMap = converter.toJson(object);

    // Create extraction-mode selector with the same object
    final extractionSelector = RootOrderByFieldExtractor<T>(objectMap);

    // Reuse the SAME builder function to extract values!
    // This guarantees perfect consistency with orderBy
    orderByBuilder(extractionSelector);

    return extractionSelector.extractedValues;
  }

  static firestore.Query<R> applyStartAt<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.startAt(cursorValues);
  }

  static firestore.Query<R> applyStartAfter<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.startAfter(cursorValues);
  }

  static firestore.Query<R> applyEndAt<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.endAt(cursorValues);
  }

  static firestore.Query<R> applyEndBefore<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.endBefore(cursorValues);
  }
}
