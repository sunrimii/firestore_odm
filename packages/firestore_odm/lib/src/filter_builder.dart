import 'package:cloud_firestore/cloud_firestore.dart'
    show FieldPath, FieldValue, Timestamp;
import 'package:firestore_odm/src/field_selecter.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/types.dart';

typedef FilterBuilderFunc<AB extends FilterBuilderNode> =
    AB Function({String name, FilterBuilderNode? parent});

/// Filter types
enum FilterType { field, and, or }

/// Firestore operators
enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
}

/// Universal filter class that can represent any filter type
class FirestoreFilter {
  final FilterType type;

  // For field filters
  final Object? field;
  final FilterOperator? operator;
  final dynamic value;

  // For logical filters (AND/OR)
  final List<FirestoreFilter>? filters;

  const FirestoreFilter._({
    required this.type,
    this.field,
    this.operator,
    this.value,
    this.filters,
  });

  /// Default constructor for generated classes
  const FirestoreFilter() : this._(type: FilterType.field);

  /// Create a field filter
  const FirestoreFilter.field({
    required Object field,
    required FilterOperator operator,
    required dynamic value,
  }) : this._(
         type: FilterType.field,
         field: field,
         operator: operator,
         value: value,
       );

  /// Create an AND filter
  const FirestoreFilter.and(List<FirestoreFilter> filters)
    : this._(type: FilterType.and, filters: filters);

  /// Create an OR filter
  const FirestoreFilter.or(List<FirestoreFilter> filters)
    : this._(type: FilterType.or, filters: filters);

  /// Create a filter from another FirestoreFilter (copy constructor)
  FirestoreFilter.fromFilter(FirestoreFilter other)
    : this._(
        type: other.type,
        field: other.field,
        operator: other.operator,
        value: other.value,
        filters: other.filters,
      );

  FirestoreFilter and(FirestoreFilter other) {
    return FirestoreFilter.and([...?filters, other]);
  }

  FirestoreFilter or(FirestoreFilter other) {
    return FirestoreFilter.or([...?filters, other]);
  }
}

/// Base filter builder class using Node-based architecture
class FilterBuilderNode extends Node {
  /// Create a FilterSelector with optional name and parent for nested objects
  const FilterBuilderNode({super.name, super.parent});
}

abstract class FilterBuilderRoot {
  factory FilterBuilderRoot() = _FilterBuilderRootImpl;

  /// Create OR filter with type safety (supports up to 30 filters)
  FirestoreFilter or(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]);

  /// Create AND filter with type safety (supports up to 30 filters)
  FirestoreFilter and(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]);
}

mixin FilterBuilderRootMixin on FilterBuilderNode implements FilterBuilderRoot {
  /// Create OR filter with type safety (supports up to 30 filters)
  FirestoreFilter or(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]) {
    final allFilters = <FirestoreFilter>[filter1, filter2];
    if (filter3 != null) allFilters.add(filter3);
    if (filter4 != null) allFilters.add(filter4);
    if (filter5 != null) allFilters.add(filter5);
    if (filter6 != null) allFilters.add(filter6);
    if (filter7 != null) allFilters.add(filter7);
    if (filter8 != null) allFilters.add(filter8);
    if (filter9 != null) allFilters.add(filter9);
    if (filter10 != null) allFilters.add(filter10);
    if (filter11 != null) allFilters.add(filter11);
    if (filter12 != null) allFilters.add(filter12);
    if (filter13 != null) allFilters.add(filter13);
    if (filter14 != null) allFilters.add(filter14);
    if (filter15 != null) allFilters.add(filter15);
    if (filter16 != null) allFilters.add(filter16);
    if (filter17 != null) allFilters.add(filter17);
    if (filter18 != null) allFilters.add(filter18);
    if (filter19 != null) allFilters.add(filter19);
    if (filter20 != null) allFilters.add(filter20);
    if (filter21 != null) allFilters.add(filter21);
    if (filter22 != null) allFilters.add(filter22);
    if (filter23 != null) allFilters.add(filter23);
    if (filter24 != null) allFilters.add(filter24);
    if (filter25 != null) allFilters.add(filter25);
    if (filter26 != null) allFilters.add(filter26);
    if (filter27 != null) allFilters.add(filter27);
    if (filter28 != null) allFilters.add(filter28);
    if (filter29 != null) allFilters.add(filter29);
    if (filter30 != null) allFilters.add(filter30);
    return FirestoreFilter.or(allFilters);
  }

  /// Create AND filter with type safety (supports up to 30 filters)
  FirestoreFilter and(
    FirestoreFilter filter1,
    FirestoreFilter filter2, [
    FirestoreFilter? filter3,
    FirestoreFilter? filter4,
    FirestoreFilter? filter5,
    FirestoreFilter? filter6,
    FirestoreFilter? filter7,
    FirestoreFilter? filter8,
    FirestoreFilter? filter9,
    FirestoreFilter? filter10,
    FirestoreFilter? filter11,
    FirestoreFilter? filter12,
    FirestoreFilter? filter13,
    FirestoreFilter? filter14,
    FirestoreFilter? filter15,
    FirestoreFilter? filter16,
    FirestoreFilter? filter17,
    FirestoreFilter? filter18,
    FirestoreFilter? filter19,
    FirestoreFilter? filter20,
    FirestoreFilter? filter21,
    FirestoreFilter? filter22,
    FirestoreFilter? filter23,
    FirestoreFilter? filter24,
    FirestoreFilter? filter25,
    FirestoreFilter? filter26,
    FirestoreFilter? filter27,
    FirestoreFilter? filter28,
    FirestoreFilter? filter29,
    FirestoreFilter? filter30,
  ]) {
    final allFilters = <FirestoreFilter>[filter1, filter2];
    if (filter3 != null) allFilters.add(filter3);
    if (filter4 != null) allFilters.add(filter4);
    if (filter5 != null) allFilters.add(filter5);
    if (filter6 != null) allFilters.add(filter6);
    if (filter7 != null) allFilters.add(filter7);
    if (filter8 != null) allFilters.add(filter8);
    if (filter9 != null) allFilters.add(filter9);
    if (filter10 != null) allFilters.add(filter10);
    if (filter11 != null) allFilters.add(filter11);
    if (filter12 != null) allFilters.add(filter12);
    if (filter13 != null) allFilters.add(filter13);
    if (filter14 != null) allFilters.add(filter14);
    if (filter15 != null) allFilters.add(filter15);
    if (filter16 != null) allFilters.add(filter16);
    if (filter17 != null) allFilters.add(filter17);
    if (filter18 != null) allFilters.add(filter18);
    if (filter19 != null) allFilters.add(filter19);
    if (filter20 != null) allFilters.add(filter20);
    if (filter21 != null) allFilters.add(filter21);
    if (filter22 != null) allFilters.add(filter22);
    if (filter23 != null) allFilters.add(filter23);
    if (filter24 != null) allFilters.add(filter24);
    if (filter25 != null) allFilters.add(filter25);
    if (filter26 != null) allFilters.add(filter26);
    if (filter27 != null) allFilters.add(filter27);
    if (filter28 != null) allFilters.add(filter28);
    if (filter29 != null) allFilters.add(filter29);
    if (filter30 != null) allFilters.add(filter30);
    return FirestoreFilter.and(allFilters);
  }
}

class _FilterBuilderRootImpl extends FilterBuilderNode
    with FilterBuilderRootMixin {
  const _FilterBuilderRootImpl();
}


typedef PatchBuilderFunc<T, PB extends PatchBuilder<T, dynamic>> =
    PB Function({
      String name,
      PatchBuilder<dynamic, dynamic>? parent,
    });

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

class FieldNameOrDocumentId {
  final String? fieldName;
  final FieldPathType documentId = FieldPathType.documentId;

  const FieldNameOrDocumentId._({this.fieldName});

  /// Create a FieldNameOrDocumentId with a field name
  const FieldNameOrDocumentId.field(String fieldName)
    : this._(fieldName: fieldName);

  /// Create a FieldNameOrDocumentId for document ID
  const FieldNameOrDocumentId.documentId() : this._();

  bool get isDocumentId => fieldName == null;
  bool get isFieldName => fieldName != null;

  dynamic get value => fieldName ?? documentId.toFirestore();

  @override
  String toString() => fieldName ?? documentId.toFirestore().toString();
}

class NoValue {
  /// Represents a special value indicating no value is provided
  const NoValue();

  @override
  String toString() => 'NoValue';
}

/// Callable filter instances using Node-based architecture
/// Base callable filter class
abstract class CallableFilter extends FilterBuilderNode {
  final FieldPathType? _type;
  const CallableFilter({super.name, super.parent, FieldPathType? type})
    : _type = type;

  FirestoreFilter _process(FilterOperator operator, dynamic value) {
    return FirestoreFilter.field(
      field: _type?.toFirestore() ?? FieldPath($parts),
      operator: operator,
      value: value,
    );
  }
}

class FilterFieldImpl<T> extends CallableFilter implements FilterField<T> {
  FilterFieldImpl({super.name = '', super.parent, super.type});

  FirestoreFilter call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? whereIn,
    Object? whereNotIn,
    Object? isNull,
  }) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    if (isLessThan != null) {
      return _process(FilterOperator.isLessThan, isLessThan);
    }
    if (isLessThanOrEqualTo != null) {
      return _process(FilterOperator.isLessThanOrEqualTo, isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) {
      return _process(FilterOperator.isGreaterThan, isGreaterThan);
    }
    if (isGreaterThanOrEqualTo != null) {
      return _process(
        FilterOperator.isGreaterThanOrEqualTo,
        isGreaterThanOrEqualTo,
      );
    }
    if (whereIn != null) {
      return _process(FilterOperator.whereIn, whereIn);
    }
    if (whereNotIn != null) {
      return _process(FilterOperator.whereNotIn, whereNotIn);
    }
    if (isNull != null) {
      return _process(
        isNull as bool ? FilterOperator.isEqualTo : FilterOperator.isNotEqualTo,
        null,
      );
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class FilterField<T> implements CallableFilter {
  factory FilterField({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = FilterFieldImpl;

  FirestoreFilter call({
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    List<T>? whereIn,
    List<T>? whereNotIn,
    bool? isNull,
  });
}

class BoolFieldFilterImpl extends CallableFilter implements BoolFieldFilter {
  const BoolFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({Object? isEqualTo, Object? isNotEqualTo}) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class BoolFieldFilter implements CallableFilter {
  factory BoolFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = BoolFieldFilterImpl;

  FirestoreFilter call({bool? isEqualTo, bool? isNotEqualTo});
}

class ArrayFieldFilterImpl<T> extends CallableFilter
    implements ArrayFieldFilter<T> {
  const ArrayFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? arrayContains,
    Object? arrayContainsAny,
  }) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    if (arrayContains != null) {
      return _process(FilterOperator.arrayContains, arrayContains);
    }
    if (arrayContainsAny != null) {
      return _process(FilterOperator.arrayContainsAny, arrayContainsAny);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }
}

/// String field callable filter
abstract class ArrayFieldFilter<T> implements CallableFilter {
  factory ArrayFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = ArrayFieldFilterImpl;

  FirestoreFilter call({
    List<T>? isEqualTo,
    List<T>? isNotEqualTo,
    T? arrayContains,
    List<T>? arrayContainsAny,
  });
}

class MapFieldFilterImpl<K, V> extends CallableFilter
    implements MapFieldFilter<K, V> {
  const MapFieldFilterImpl({super.name, super.parent, super.type});

  FirestoreFilter call({Map<K, V>? isEqualTo, Map<K, V>? isNotEqualTo}) {
    if (isEqualTo != null) {
      return _process(FilterOperator.isEqualTo, isEqualTo);
    }
    if (isNotEqualTo != null) {
      return _process(FilterOperator.isNotEqualTo, isNotEqualTo);
    }
    throw ArgumentError('At least one filter condition must be provided');
  }

  FilterField<V> key(K mapKey) {
    return FilterField<V>(name: mapKey.toString(), parent: this);
  }
}

/// Map field callable filter with key access support
abstract class MapFieldFilter<K, V> extends CallableFilter {
  factory MapFieldFilter({
    String name,
    FilterBuilderNode? parent,
    FieldPathType? type,
  }) = MapFieldFilterImpl<K, V>;

  FirestoreFilter call({Map<K, V>? isEqualTo, Map<K, V>? isNotEqualTo});

  /// Access a specific key in the map for filtering
  /// Usage: $.profile.socialLinks.key("github")(isEqualTo: "username")
  FilterField<V> key(K mapKey);
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
