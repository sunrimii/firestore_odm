import 'package:cloud_firestore/cloud_firestore.dart'
    hide FieldPath, FieldValue, Timestamp;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/types.dart';

typedef FilterBuilderFunc<AB extends FilterBuilderNode> =
    AB Function({required FieldPath path});

sealed class FilterOperation {
  Filter toFilter();
}

extension FilterOperationExtension on FilterOperation {
  FilterOperation and(FilterOperation other) {
    return AndOperation([this, other]);
  }

  FilterOperation or(FilterOperation other) {
    return OrOperation([this, other]);
  }

  FilterOperation operator &(FilterOperation other) {
    return and(other);
  }

  FilterOperation operator |(FilterOperation other) {
    return or(other);
  }
}

class AndOperation implements FilterOperation {
  final List<FilterOperation> filters;

  const AndOperation(this.filters);

  @override
  Filter toFilter() => Filter.and(
    filters[0].toFilter(),
    filters[1].toFilter(),
    filters.length > 2 ? filters[2].toFilter() : null,
    filters.length > 3 ? filters[3].toFilter() : null,
    filters.length > 4 ? filters[4].toFilter() : null,
    filters.length > 5 ? filters[5].toFilter() : null,
    filters.length > 6 ? filters[6].toFilter() : null,
    filters.length > 7 ? filters[7].toFilter() : null,
    filters.length > 8 ? filters[8].toFilter() : null,
    filters.length > 9 ? filters[9].toFilter() : null,
    filters.length > 10 ? filters[10].toFilter() : null,
    filters.length > 11 ? filters[11].toFilter() : null,
    filters.length > 12 ? filters[12].toFilter() : null,
    filters.length > 13 ? filters[13].toFilter() : null,
    filters.length > 14 ? filters[14].toFilter() : null,
    filters.length > 15 ? filters[15].toFilter() : null,
    filters.length > 16 ? filters[16].toFilter() : null,
    filters.length > 17 ? filters[17].toFilter() : null,
    filters.length > 18 ? filters[18].toFilter() : null,
    filters.length > 19 ? filters[19].toFilter() : null,
    filters.length > 20 ? filters[20].toFilter() : null,
    filters.length > 21 ? filters[21].toFilter() : null,
    filters.length > 22 ? filters[22].toFilter() : null,
    filters.length > 23 ? filters[23].toFilter() : null,
    filters.length > 24 ? filters[24].toFilter() : null,
    filters.length > 25 ? filters[25].toFilter() : null,
    filters.length > 26 ? filters[26].toFilter() : null,
    filters.length > 27 ? filters[27].toFilter() : null,
    filters.length > 28 ? filters[28].toFilter() : null,
    filters.length > 29 ? filters[29].toFilter() : null,
  );
}

class OrOperation implements FilterOperation {
  final List<FilterOperation> filters;

  const OrOperation(this.filters);

  @override
  Filter toFilter() => Filter.or(
    filters[0].toFilter(),
    filters[1].toFilter(),
    filters.length > 2 ? filters[2].toFilter() : null,
    filters.length > 3 ? filters[3].toFilter() : null,
    filters.length > 4 ? filters[4].toFilter() : null,
    filters.length > 5 ? filters[5].toFilter() : null,
    filters.length > 6 ? filters[6].toFilter() : null,
    filters.length > 7 ? filters[7].toFilter() : null,
    filters.length > 8 ? filters[8].toFilter() : null,
    filters.length > 9 ? filters[9].toFilter() : null,
    filters.length > 10 ? filters[10].toFilter() : null,
    filters.length > 11 ? filters[11].toFilter() : null,
    filters.length > 12 ? filters[12].toFilter() : null,
    filters.length > 13 ? filters[13].toFilter() : null,
    filters.length > 14 ? filters[14].toFilter() : null,
    filters.length > 15 ? filters[15].toFilter() : null,
    filters.length > 16 ? filters[16].toFilter() : null,
    filters.length > 17 ? filters[17].toFilter() : null,
    filters.length > 18 ? filters[18].toFilter() : null,
    filters.length > 19 ? filters[19].toFilter() : null,
    filters.length > 20 ? filters[20].toFilter() : null,
    filters.length > 21 ? filters[21].toFilter() : null,
    filters.length > 22 ? filters[22].toFilter() : null,
    filters.length > 23 ? filters[23].toFilter() : null,
    filters.length > 24 ? filters[24].toFilter() : null,
    filters.length > 25 ? filters[25].toFilter() : null,
    filters.length > 26 ? filters[26].toFilter() : null,
    filters.length > 27 ? filters[27].toFilter() : null,
    filters.length > 28 ? filters[28].toFilter() : null,
    filters.length > 29 ? filters[29].toFilter() : null,
  );
}

class IsEqualToOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsEqualToOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), isEqualTo: value);
}

class IsNotEqualToOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsNotEqualToOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), isNotEqualTo: value);
}

class IsLessThanOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsLessThanOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), isLessThan: value);
}

class IsLessThanOrEqualToOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsLessThanOrEqualToOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), isLessThanOrEqualTo: value);
}

class IsGreaterThanOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsGreaterThanOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), isGreaterThan: value);
}

class IsGreaterThanOrEqualToOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const IsGreaterThanOrEqualToOperation(this.field, this.value);

  @override
  Filter toFilter() =>
      Filter(field.toFirestore(), isGreaterThanOrEqualTo: value);
}

class ArrayContainsOperation<T> implements FilterOperation {
  final FieldPath field;
  final T value;

  const ArrayContainsOperation(this.field, this.value);

  @override
  Filter toFilter() => Filter(field.toFirestore(), arrayContains: value);
}

class ArrayContainsAnyOperation<T> implements FilterOperation {
  final FieldPath field;
  final Iterable<T> values;

  const ArrayContainsAnyOperation(this.field, this.values);

  @override
  Filter toFilter() => Filter(field.toFirestore(), arrayContainsAny: values);
}

class WhereInOperation<T> implements FilterOperation {
  final FieldPath field;
  final List<T> values;

  const WhereInOperation(this.field, this.values);

  @override
  Filter toFilter() => Filter(field.toFirestore(), whereIn: values);
}

class WhereNotInOperation<T> implements FilterOperation {
  final FieldPath field;
  final List<T> values;

  const WhereNotInOperation(this.field, this.values);

  @override
  Filter toFilter() => Filter(field.toFirestore(), whereNotIn: values);
}

mixin class FilterBuilderRoot {
  /// Create OR filter with type safety (supports up to 30 filters)
  OrOperation or(
    FilterOperation filter1,
    FilterOperation filter2, [
    FilterOperation? filter3,
    FilterOperation? filter4,
    FilterOperation? filter5,
    FilterOperation? filter6,
    FilterOperation? filter7,
    FilterOperation? filter8,
    FilterOperation? filter9,
    FilterOperation? filter10,
    FilterOperation? filter11,
    FilterOperation? filter12,
    FilterOperation? filter13,
    FilterOperation? filter14,
    FilterOperation? filter15,
    FilterOperation? filter16,
    FilterOperation? filter17,
    FilterOperation? filter18,
    FilterOperation? filter19,
    FilterOperation? filter20,
    FilterOperation? filter21,
    FilterOperation? filter22,
    FilterOperation? filter23,
    FilterOperation? filter24,
    FilterOperation? filter25,
    FilterOperation? filter26,
    FilterOperation? filter27,
    FilterOperation? filter28,
    FilterOperation? filter29,
    FilterOperation? filter30,
  ]) {
    return OrOperation([
      filter1,
      filter2,
      if (filter3 != null) filter3,
      if (filter4 != null) filter4,
      if (filter5 != null) filter5,
      if (filter6 != null) filter6,
      if (filter7 != null) filter7,
      if (filter8 != null) filter8,
      if (filter9 != null) filter9,
      if (filter10 != null) filter10,
      if (filter11 != null) filter11,
      if (filter12 != null) filter12,
      if (filter13 != null) filter13,
      if (filter14 != null) filter14,
      if (filter15 != null) filter15,
      if (filter16 != null) filter16,
      if (filter17 != null) filter17,
      if (filter18 != null) filter18,
      if (filter19 != null) filter19,
      if (filter20 != null) filter20,
      if (filter21 != null) filter21,
      if (filter22 != null) filter22,
      if (filter23 != null) filter23,
      if (filter24 != null) filter24,
      if (filter25 != null) filter25,
      if (filter26 != null) filter26,
      if (filter27 != null) filter27,
      if (filter28 != null) filter28,
      if (filter29 != null) filter29,
      if (filter30 != null) filter30,
    ]);
  }

  /// Create AND filter with type safety (supports up to 30 filters)
  AndOperation and(
    FilterOperation filter1,
    FilterOperation filter2, [
    FilterOperation? filter3,
    FilterOperation? filter4,
    FilterOperation? filter5,
    FilterOperation? filter6,
    FilterOperation? filter7,
    FilterOperation? filter8,
    FilterOperation? filter9,
    FilterOperation? filter10,
    FilterOperation? filter11,
    FilterOperation? filter12,
    FilterOperation? filter13,
    FilterOperation? filter14,
    FilterOperation? filter15,
    FilterOperation? filter16,
    FilterOperation? filter17,
    FilterOperation? filter18,
    FilterOperation? filter19,
    FilterOperation? filter20,
    FilterOperation? filter21,
    FilterOperation? filter22,
    FilterOperation? filter23,
    FilterOperation? filter24,
    FilterOperation? filter25,
    FilterOperation? filter26,
    FilterOperation? filter27,
    FilterOperation? filter28,
    FilterOperation? filter29,
    FilterOperation? filter30,
  ]) {
    return AndOperation([
      filter1,
      filter2,
      if (filter3 != null) filter3,
      if (filter4 != null) filter4,
      if (filter5 != null) filter5,
      if (filter6 != null) filter6,
      if (filter7 != null) filter7,
      if (filter8 != null) filter8,
      if (filter9 != null) filter9,
      if (filter10 != null) filter10,
      if (filter11 != null) filter11,
      if (filter12 != null) filter12,
      if (filter13 != null) filter13,
      if (filter14 != null) filter14,
      if (filter15 != null) filter15,
      if (filter16 != null) filter16,
      if (filter17 != null) filter17,
      if (filter18 != null) filter18,
      if (filter19 != null) filter19,
      if (filter20 != null) filter20,
      if (filter21 != null) filter21,
      if (filter22 != null) filter22,
      if (filter23 != null) filter23,
      if (filter24 != null) filter24,
      if (filter25 != null) filter25,
      if (filter26 != null) filter26,
      if (filter27 != null) filter27,
      if (filter28 != null) filter28,
      if (filter29 != null) filter29,
      if (filter30 != null) filter30,
    ]);
  }
}


typedef PatchBuilderFunc<T, PB extends PatchBuilder<T, dynamic>> =
    PB Function({String name, PatchBuilder<dynamic, dynamic>? parent});

class PatchBuilder<T, R> extends Node {
  /// Converter function to transform the value before storing in Firestore
  final R Function(T) _toJson;

  /// Create a DefaultUpdateBuilder with optional name, parent and converter
  const PatchBuilder({super.name, super.parent, required R Function(T) toJson})
    : _toJson = toJson;

  UpdateOperation call(T value) {
    // Apply converter if provided, otherwise use the value directly
    final convertedValue = _toJson(value);
    return SetOperation($parts, convertedValue);
  }
}

class FilterBuilderNode extends Node2 {
  /// Create a new FilterBuilderNode
  const FilterBuilderNode({super.path});
}

mixin EqualableMixin<T, J> on FilterBuilderNode {
  J Function(T) get _toJson;

  /// Check if two objects are equal
  IsEqualToOperation isEqualTo(T other) {
    return IsEqualToOperation(path, _toJson(other));
  }

  IsNotEqualToOperation isNotEqualTo(T other) {
    return IsNotEqualToOperation(path, _toJson(other));
  }

  WhereInOperation whereIn(Iterable<T> values) {
    return WhereInOperation(path, values.map(_toJson).toList());
  }

  WhereNotInOperation whereNotIn(Iterable<T> values) {
    return WhereNotInOperation(path, values.map(_toJson).toList());
  }
}

mixin ComparableMixin<T> on FilterBuilderNode {
  num? Function(T) get _toJson;

  /// Check if two objects are equal
  IsLessThanOperation isLessThan(T other) {
    return IsLessThanOperation(path, _toJson(other));
  }

  IsGreaterThanOperation isGreaterThan(T other) {
    return IsGreaterThanOperation(path, _toJson(other));
  }

  IsLessThanOrEqualToOperation isLessThanOrEqualTo(T other) {
    return IsLessThanOrEqualToOperation(path, _toJson(other));
  }

  IsGreaterThanOrEqualToOperation isGreaterThanOrEqualTo(T other) {
    return IsGreaterThanOrEqualToOperation(path, _toJson(other));
  }
}

mixin ArrayFilterableMixin<T, E, JE> on FilterBuilderNode {
  JE Function(E) get _elementToJson;

  /// Check if the array contains a specific value
  ArrayContainsOperation<JE> contains(E value) {
    return ArrayContainsOperation(path, _elementToJson(value));
  }

  /// Check if the array contains any of the specified values
  ArrayContainsAnyOperation<JE> containsAny(Iterable<E> values) {
    return ArrayContainsAnyOperation(path, values.map(_elementToJson).toList());
  }
}

class FilterFieldImpl<T, R> extends FilterField<T, R> {
  FilterFieldImpl({super.path, required super.toJson}) : super._();

  FilterOperation call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
  }) {
    if (isEqualTo != null) {
      return IsEqualToOperation(path, _toJson(isEqualTo as T));
    }
    if (isNotEqualTo != null) {
      return IsNotEqualToOperation(path, _toJson(isNotEqualTo as T));
    }
    if (whereIn != null) {
      return WhereInOperation(
        path,
        (whereIn as Iterable<T>).map(_toJson).toList(),
      );
    }
    if (whereNotIn != null) {
      return WhereNotInOperation(
        path,
        (whereNotIn as Iterable<T>).map(_toJson).toList(),
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class FilterField<T, R> extends FilterBuilderNode
    with EqualableMixin<T, R> {
  factory FilterField({FieldPath? path, required R Function(T) toJson}) =
      FilterFieldImpl<T, R>;

  const FilterField._({super.path, required R Function(T) toJson})
    : _toJson = toJson;

  final R Function(T) _toJson;

  FilterOperation call({T? isEqualTo, T? isNotEqualTo, 
    Iterable<T>? whereIn, Iterable<T>? whereNotIn});
}

class NumericFilterFieldImpl<T> extends NumericFilterField<T> {
  const NumericFilterFieldImpl({super.path, required super.toJson}) : super._();

  FilterOperation call({
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    Iterable<T>? whereIn,
    Iterable<T>? whereNotIn,
  }) {
    if (isEqualTo != null) {
      return IsEqualToOperation(path, _toJson(isEqualTo));
    }
    if (isNotEqualTo != null) {
      return IsNotEqualToOperation(path, _toJson(isNotEqualTo));
    }
    if (isLessThan != null) {
      return IsLessThanOperation(path, _toJson(isLessThan));
    }
    if (isLessThanOrEqualTo != null) {
      return IsLessThanOrEqualToOperation(path, _toJson(isLessThanOrEqualTo));
    }
    if (isGreaterThan != null) {
      return IsGreaterThanOperation(path, _toJson(isGreaterThan));
    }
    if (isGreaterThanOrEqualTo != null) {
      return IsGreaterThanOrEqualToOperation(
        path,
        _toJson(isGreaterThanOrEqualTo),
      );
    }
    if (whereIn != null) {
      return WhereInOperation(path, whereIn.map(_toJson).toList());
    }
    if (whereNotIn != null) {
      return WhereNotInOperation(path, whereNotIn.map(_toJson).toList());
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

abstract class NumericFilterField<T> extends FilterBuilderNode
    with EqualableMixin<T, num?>, ComparableMixin<T> {
  /// Create a numeric field filter
  factory NumericFilterField({
    FieldPath path,
    required num? Function(T) toJson,
  }) = NumericFilterFieldImpl;

  const NumericFilterField._({super.path, required num? Function(T) toJson})
    : _toJson = toJson;

  final num? Function(T) _toJson;

  FilterOperation call({
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    Iterable<T>? whereIn,
    Iterable<T>? whereNotIn,
  });
}

class ArrayFilterFieldImpl<T, E, JE> extends ArrayFilterField<T, E, JE> {
  const ArrayFilterFieldImpl({
    super.path,
    required super.elementToJson,
    required super.toJson,
  }) : super._();

  FilterOperation call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? arrayContains,
    Object? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
  }) {
    if (isEqualTo != null) {
      return IsEqualToOperation(path, _toJson(isEqualTo as T));
    }
    if (isNotEqualTo != null) {
      return IsNotEqualToOperation(path, _toJson(isNotEqualTo as T));
    }
    if (arrayContains != null) {
      return ArrayContainsOperation(path, _elementToJson(arrayContains as E));
    }
    if (arrayContainsAny != null) {
      return ArrayContainsAnyOperation(
        path,
        (arrayContainsAny as Iterable<E>).map(_elementToJson).toList(),
      );
    }
    if (whereIn != null) {
      return WhereInOperation(
        path,
        (whereIn as Iterable<T>).map(_toJson).toList(),
      );
    }
    if (whereNotIn != null) {
      return WhereNotInOperation(
        path,
        (whereNotIn as Iterable<T>).map(_toJson).toList(),
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class ArrayFilterField<T, E, JE> extends FilterBuilderNode
    with EqualableMixin<T, List<JE>?>, ArrayFilterableMixin<T, E, JE> {
  factory ArrayFilterField({
    FieldPath path,
    required JE Function(E) elementToJson,
    required List<JE>? Function(T) toJson,
  }) = ArrayFilterFieldImpl;

  const ArrayFilterField._({
    super.path,
    required JE Function(E) elementToJson,
    required List<JE>? Function(T) toJson,
  }) : _elementToJson = elementToJson,
       _toJson = toJson;

  final JE Function(E) _elementToJson;

  final List<JE>? Function(T) _toJson;

  FilterOperation call({
    T? isEqualTo,
    T? isNotEqualTo,
    E? arrayContains,
    Iterable<E>? arrayContainsAny,
    Iterable<T>? whereIn,
    Iterable<T>? whereNotIn,
  });
}

class MapFilterFieldImpl<T, K, V, JV> extends MapFilterField<T, K, V, JV> {
  const MapFilterFieldImpl({
    super.path,
    required super.toJson,
    required super.keyToJson,
    required super.valueToJson,
  }) : super._();

  FilterOperation call({Object? isEqualTo, Object? isNotEqualTo}) {
    if (isEqualTo != null) {
      return IsEqualToOperation(path, _toJson(isEqualTo as T));
    }
    if (isNotEqualTo != null) {
      return IsNotEqualToOperation(path, _toJson(isNotEqualTo as T));
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// Map field callable filter with key access support
abstract class MapFilterField<T, K, V, JV> extends FilterBuilderNode {
  factory MapFilterField({
    FieldPath path,
    required Map<String, JV> Function(T) toJson,
    required String Function(K) keyToJson,
    required JV Function(V) valueToJson,
  }) = MapFilterFieldImpl<T, K, V, JV>;

  const MapFilterField._({
    super.path,
    required Map<String, JV> Function(T) toJson,
    required String Function(K) keyToJson,
    required JV Function(V) valueToJson,
  }) : _toJson = toJson,
       _keyToJson = keyToJson,
       _valueToJson = valueToJson;

  final Map<String, JV> Function(T) _toJson;
  final String Function(K) _keyToJson;
  final JV Function(V) _valueToJson;

  PathFieldPath get _getPathFieldPath {
    if (path is PathFieldPath) {
      return path as PathFieldPath;
    }
    throw StateError('Path must be a PathFieldPath for MapFieldFilter');
  }

  FilterOperation call({T? isEqualTo, T? isNotEqualTo});

  /// Access a specific key in the map for filtering
  /// Usage: $.profile.socialLinks.key("github")(isEqualTo: "username")
  FilterField<V, JV> key(K mapKey) {
    return FilterField(
      path: _getPathFieldPath.append(_keyToJson(mapKey)),
      toJson: _valueToJson,
    );
  }
}

/// Numeric field callable updater
class NumericFieldUpdate<T extends num?> extends PatchBuilder<T, T> {
  NumericFieldUpdate({required super.name, super.parent})
    : super(toJson: (value) => value);

  /// Increment field value
  UpdateOperation increment(T value) {
    return IncrementOperation(
      $parts,
      value as num, // Ensure value is a num
    );
  }
}

/// List field callable updater
class ListFieldUpdate<T extends Iterable<E>?, E, R>
    extends PatchBuilder<T, List<R>?> {
  ListFieldUpdate({
    required super.name,
    super.parent,
    required R Function(E) elementToJson,
  }) : _elementToJson = elementToJson,
       super(toJson: (value) => value?.map(elementToJson).toList());

  final R Function(E) _elementToJson;

  /// Add element to array
  UpdateOperation add(E value) {
    return ArrayAddAllOperation($parts, [_elementToJson(value)]);
  }

  /// Add multiple elements to array
  UpdateOperation addAll(Iterable<E> values) {
    return ArrayAddAllOperation($parts, values.map(_elementToJson).toList());
  }

  /// Remove element from array
  UpdateOperation remove(E value) {
    return ArrayRemoveAllOperation($parts, [_elementToJson(value)]);
  }

  /// Remove multiple elements from array
  UpdateOperation removeAll(Iterable<E> values) {
    return ArrayRemoveAllOperation($parts, values.map(_elementToJson).toList());
  }
}

/// DateTime field callable updater
class DateTimeFieldUpdate<T extends DateTime?>
    extends PatchBuilder<T, String?> {
  DateTimeFieldUpdate({required super.name, super.parent})
    : super(
        toJson: (value) {
          if (value == null) return null;
          return DateTimeConverter().toJson(value);
        },
      );

  /// Set field to server timestamp
  UpdateOperation serverTimestamp() {
    return ServerTimestampOperation($parts);
  }
}

/// Duration field callable updater
class DurationFieldUpdate<T extends Duration?> extends PatchBuilder<T, int?> {
  DurationFieldUpdate({required super.name, super.parent})
    : super(
        toJson: (value) {
          if (value == null) return null;
          return DurationConverter().toJson(value);
        },
      );

  /// Increment field value by a Duration
  UpdateOperation increment(Duration value) {
    final int milliseconds = const DurationConverter().toJson(value)!;
    return IncrementOperation($parts, milliseconds);
  }
}

class MapFieldUpdate<T, K, V, R> extends PatchBuilder<T, Map<String, R>> {
  MapFieldUpdate({
    required super.name,
    super.parent,
    required super.toJson,
    required String Function(K) keyToJson,
    required R Function(V) valueToJson,
  }) : _keyToJson = keyToJson,
       _valueToJson = valueToJson;

  final String Function(K) _keyToJson;
  final R Function(V) _valueToJson;

  @override
  UpdateOperation call(T value) {
    return MapSetOperation($parts, _toJson(value));
  }

  /// Set a single key-value pair (like map[key] = value)
  /// Usage: $.settings['theme'] = 'dark' → $.settings.set('theme', 'dark')
  UpdateOperation set(K key, V value) {
    final convertedKey = _keyToJson(key);
    final keyPath = [...$parts, convertedKey.toString()];
    return SetOperation<R>(keyPath, _valueToJson(value));
  }

  /// Remove a single key (like map.remove(key))
  /// Usage: $.settings.remove('oldSetting')
  UpdateOperation remove(K key) {
    final convertedKey = _keyToJson(key);
    final keyPath = [...$parts, convertedKey.toString()];
    return DeleteOperation(keyPath);
  }

  /// Add multiple key-value pairs (like map.addAll(other))
  /// Usage: $.settings.addAll({'theme': 'dark', 'language': 'en'})
  UpdateOperation addAll(Map<K, V> entries) {
    final entriesMap = entries.map(
      (key, value) => MapEntry(_keyToJson(key).toString(), _valueToJson(value)),
    );
    return MapPutAllOperation($parts, entriesMap);
  }

  /// Add multiple entries from MapEntry iterable (more flexible)
  /// Usage: $.settings.addEntries([MapEntry('theme', 'dark'), MapEntry('lang', 'en')])
  UpdateOperation addEntries(Iterable<MapEntry<K, V>> entries) {
    final entriesMap = Map.fromEntries(
      entries.map(
        (entry) => MapEntry(
          _keyToJson(entry.key).toString(),
          _valueToJson(entry.value),
        ),
      ),
    );
    return MapPutAllOperation($parts, entriesMap);
  }

  /// Remove multiple keys at once
  /// Usage: $.settings.removeWhere(['oldSetting1', 'oldSetting2'])
  UpdateOperation removeWhere(Iterable<K> keys) {
    final keysList = keys.map((key) => _keyToJson(key)).toList();
    return MapRemoveAllOperation($parts, keysList);
  }

  /// Clear all entries (like map.clear())
  /// Usage: $.settings.clear()
  UpdateOperation clear() {
    return MapClearOperation($parts);
  }

  // ===== Convenience Methods =====

  /// Set multiple keys to the same value
  /// Usage: $.permissions.setAll(['read', 'write'], true)
  UpdateOperation setAll(Iterable<K> keys, V value) {
    final entriesMap = Map.fromIterables(
      keys.map((key) => _keyToJson(key).toString()),
      Iterable.generate(keys.length, (_) => _valueToJson(value)),
    );
    return MapPutAllOperation($parts, entriesMap);
  }
}

/// Map field callable updater with clean, consistent Dart Map-like operations
class DartMapFieldUpdate<T extends Map<K, V>, K, V, R>
    extends MapFieldUpdate<T, K, V, R> {
  DartMapFieldUpdate({
    required super.name,
    super.parent,
    required super.keyToJson,
    required super.valueToJson,
  }) : super(toJson: (value) => mapToJson(value, keyToJson, valueToJson));
}
