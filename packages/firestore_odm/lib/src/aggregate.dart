import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/aggregatable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/utils.dart';

/// Selector that provides strongly-typed field access for aggregations
class AggregateFieldSelector<T> {
  final List<AggregateOperation> operations = [];

  /// Get count of documents
  int count() {
    final key = 'count_${operations.length}';
    operations.add(CountOperation(key));
    return 0; // Placeholder return value
  }
}

class AggregateConfiguration<T, R> {
  final List<AggregateOperation> operations;
  final R Function(AggregateFieldSelector<T> selector) builder;

  AggregateConfiguration(this.operations, this.builder);
}

abstract class QueryAggregatableHandler {
  static firestore.AggregateQuery applyCount(
    firestore.Query<Map<String, dynamic>> query,
  ) {
    return query.count();
  }

  static AggregateConfiguration<T, R> buildAggregate<T, R extends Record>(
    AggregateBuilder<T, R> builder,
  ) {
    // Create the selector and build the aggregate specification
    final selector = AggregateFieldSelector<T>();
    builder(selector); // Call builder to populate operations

    return AggregateConfiguration(selector.operations, builder);
  }

  static firestore.AggregateQuery applyAggregate<R extends Record>(
    firestore.Query<Map<String, dynamic>> query,
    List<AggregateOperation> operations,
  ) {
    // Build the aggregate query using the operations collected
    final fields = operations.map((op) {
      if (op is CountOperation) {
        return firestore.count();
      } else if (op is SumOperation) {
        return firestore.sum(op.fieldPath);
      } else if (op is AverageOperation) {
        return firestore.average(op.fieldPath);
      } else {
        throw ArgumentError(
          'Unsupported aggregate operation: ${op.runtimeType}',
        );
      }
    }).toList();
    // Create the aggregate query using native Firestore API
    // Firestore supports up to 30 aggregate fields
    if (fields.length > 30) {
      throw ArgumentError(
        'Firestore supports a maximum of 30 aggregate fields, but ${fields.length} were provided.',
      );
    }

    return query.aggregate(
      fields[0],
      fields.length > 1 ? fields[1] : null,
      fields.length > 2 ? fields[2] : null,
      fields.length > 3 ? fields[3] : null,
      fields.length > 4 ? fields[4] : null,
      fields.length > 5 ? fields[5] : null,
      fields.length > 6 ? fields[6] : null,
      fields.length > 7 ? fields[7] : null,
      fields.length > 8 ? fields[8] : null,
      fields.length > 9 ? fields[9] : null,
      fields.length > 10 ? fields[10] : null,
      fields.length > 11 ? fields[11] : null,
      fields.length > 12 ? fields[12] : null,
      fields.length > 13 ? fields[13] : null,
      fields.length > 14 ? fields[14] : null,
      fields.length > 15 ? fields[15] : null,
      fields.length > 16 ? fields[16] : null,
      fields.length > 17 ? fields[17] : null,
      fields.length > 18 ? fields[18] : null,
      fields.length > 19 ? fields[19] : null,
      fields.length > 20 ? fields[20] : null,
      fields.length > 21 ? fields[21] : null,
      fields.length > 22 ? fields[22] : null,
      fields.length > 23 ? fields[23] : null,
      fields.length > 24 ? fields[24] : null,
      fields.length > 25 ? fields[25] : null,
      fields.length > 26 ? fields[26] : null,
      fields.length > 27 ? fields[27] : null,
      fields.length > 28 ? fields[28] : null,
      fields.length > 29 ? fields[29] : null,
    );
  }

  static Future<R> get<T, R>(
    firestore.AggregateQuery query,
    AggregateConfiguration<T, R> configuration,
  ) async {
    return query.get().then((snapshot) {
      // Build the result record from the snapshot
      return _buildResultRecordFromSnapshot(snapshot, configuration);
    });
  }

  static R _buildResultRecordFromSnapshot<T, R>(
    firestore.AggregateQuerySnapshot snapshot,
    AggregateConfiguration<T, R> configuration,
  ) {
    final results = <String, dynamic>{};

    // Use results from native aggregate query
    for (final op in configuration.operations) {
      if (op is CountOperation) {
        results[op.key] = snapshot.count ?? 0;
      } else if (op is SumOperation) {
        results[op.key] = snapshot.getSum(op.fieldPath) ?? 0;
      } else if (op is AverageOperation) {
        results[op.key] = snapshot.getAverage(op.fieldPath) ?? 0.0;
      }
    }

    // Create a dummy record spec to get the structure
    final selector = AggregateFieldSelector<T>();
    final recordSpec = configuration.builder(selector);

    return _buildResultRecord(recordSpec, results, configuration);
  }

  static Stream<R> stream<T, R>(
    firestore.AggregateQuery query,
    ModelConverter<T> _converter,
    String _documentIdField,
    AggregateConfiguration<T, R> configuration,
  ) {
    return lazyBroadcast(
          () => (query.query as firestore.Query<Map<String, dynamic>>)
              .snapshots(),
        )
        .map(
          (snapshot) => processQuerySnapshot(
            snapshot,
            _converter.fromJson,
            _documentIdField,
          ),
        )
        .map(
          (data) => _calculateAggregationsFromSnapshot(
            data,
            configuration.operations,
            _converter.toJson,
          ),
        )
        .map((data) {
          final valueSelector = _AggregateValueSelector<T>(
            data,
            configuration.operations,
          );
          final recordSpec = configuration.builder(valueSelector);
          return _buildResultRecord(recordSpec, data, configuration);
        });
  }

  static R _buildResultRecord<T, R>(
    R template,
    Map<String, dynamic> results,
    AggregateConfiguration<T, R> configuration,
  ) {
    // Create a value selector that returns actual computed results
    final valueSelector = _AggregateValueSelector<T>(
      results,
      configuration.operations,
    );

    // Re-call the builder function with the value selector to get the final record
    return configuration.builder(valueSelector);
  }

  /// Calculate aggregations from snapshot for streaming
  static Map<String, dynamic> _calculateAggregationsFromSnapshot<T>(
    List<T> snapshot,
    List<AggregateOperation> operations,
    Map<String, dynamic> Function(T) toJson,
  ) {
    final results = <String, dynamic>{};

    // Count operations - can use snapshot length
    final countOps = operations.whereType<CountOperation>().toList();
    final count = snapshot.length;
    for (final op in countOps) {
      results[op.key] = count;
    }

    // For sum/average, parse documents manually
    final sumOps = operations.whereType<SumOperation>().toList();
    final avgOps = operations.whereType<AverageOperation>().toList();

    if (sumOps.isNotEmpty || avgOps.isNotEmpty) {
      // Calculate sums
      for (final op in sumOps) {
        results[op.key] = _calculateSum(snapshot, op.fieldPath, toJson);
      }

      // Calculate averages
      for (final op in avgOps) {
        results[op.key] = _calculateAverage(snapshot, op.fieldPath, toJson);
      }
    }

    return results;
  }

  /// Calculate sum for a field path
  static num _calculateSum<T>(
    List<T> documents,
    String fieldPath,
    Map<String, dynamic> Function(T) toJson,
  ) {
    num total = 0;
    for (final doc in documents) {
      final json = toJson(doc);
      final value = _getNestedValue(json, fieldPath);
      if (value is num) {
        total += value;
      }
    }
    return total;
  }

  /// Calculate average for a field path
  static double _calculateAverage<T>(
    List<T> documents,
    String fieldPath,
    Map<String, dynamic> Function(T) toJson,
  ) {
    num total = 0;
    int count = 0;
    for (final doc in documents) {
      final json = toJson(doc);
      final value = _getNestedValue(json, fieldPath);
      if (value is num) {
        total += value;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  /// Get nested value from JSON using dot notation
  static dynamic _getNestedValue(Map<String, dynamic> json, String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

class _AggregateValueSelector<T> extends AggregateFieldSelector<T> {
  final Map<String, dynamic> _results;
  final List<AggregateOperation> _operations;

  _AggregateValueSelector(this._results, this._operations);

  @override
  int count() {
    // Return the actual count result if available
    for (final entry in _results.entries) {
      if (entry.key == 'count' || entry.key.startsWith('count_')) {
        return entry.value as int? ?? 0;
      }
    }
    return 0;
  }
}

/// Strongly-typed aggregate field that knows its numeric type
class TupleAggregateField<T extends num> {
  final String _fieldPath;
  final AggregateFieldSelector _selector;

  const TupleAggregateField(this._fieldPath, this._selector);

  /// Create sum aggregation - returns the correct field type
  T sum() {
    // Check if this is a value selector (second pass) or operation collector (first pass)
    if (_selector is _AggregateValueSelector<dynamic>) {
      final valueSelector = _selector;
      // Find the sum operation for this field and return its result
      final sumOp = valueSelector._operations
          .whereType<SumOperation>()
          .where((op) => op.fieldPath == _fieldPath)
          .firstOrNull;
      if (sumOp != null) {
        final value = valueSelector._results[sumOp.key];
        if (value != null) {
          // Convert from double (Firestore's default numeric type) to the expected type
          if (T == int) {
            return (value as num).toInt() as T;
          } else if (T == double) {
            return (value as num).toDouble() as T;
          } else {
            return value as T;
          }
        }
      }
      return _getDefaultValue();
    } else {
      // First pass: collect operation
      final key = 'sum_${_selector.operations.length}';
      _selector.operations.add(SumOperation(key, _fieldPath));
      return _getDefaultValue();
    }
  }

  /// Create average aggregation - always returns double
  double average() {
    // Check if this is a value selector (second pass) or operation collector (first pass)
    if (_selector is _AggregateValueSelector<dynamic>) {
      final valueSelector = _selector;
      // Find the average operation for this field and return its result
      final avgOp = valueSelector._operations
          .whereType<AverageOperation>()
          .where((op) => op.fieldPath == _fieldPath)
          .firstOrNull;
      if (avgOp != null) {
        final value = valueSelector._results[avgOp.key];
        if (value != null) {
          return (value as num).toDouble();
        }
      }
      return 0.0;
    } else {
      // First pass: collect operation
      final key = 'avg_${_selector.operations.length}';
      _selector.operations.add(AverageOperation(key, _fieldPath));
      return 0.0; // Placeholder
    }
  }

  /// Get default value for the specific numeric type
  T _getDefaultValue() {
    if (T == int) return 0 as T;
    if (T == double) return 0.0 as T;
    if (T == num) return 0 as T;
    throw UnsupportedError('Unsupported numeric type: $T');
  }
}

/// Base class for aggregate operations
abstract class AggregateOperation {
  final String key;
  const AggregateOperation(this.key);
}

/// Count operation
class CountOperation extends AggregateOperation {
  const CountOperation(String key) : super(key);
}

/// Sum operation
class SumOperation extends AggregateOperation {
  final String fieldPath;
  const SumOperation(String key, this.fieldPath) : super(key);
}

/// Average operation
class AverageOperation extends AggregateOperation {
  final String fieldPath;
  const AverageOperation(String key, this.fieldPath) : super(key);
}

class AggregateQuery<S extends FirestoreSchema, T, R>
    implements Gettable<R>, Streamable<R> {
  AggregateQuery(
    this.query,
    this._converter,
    this._documentIdField,
    this._configuration,
  );
  final ModelConverter<T> _converter;
  final String _documentIdField;
  final firestore.AggregateQuery query;
  final AggregateConfiguration<T, R> _configuration;

  /// Executes the aggregate query and returns the result
  Future<R> get() => QueryAggregatableHandler.get(query, _configuration);

  @override
  Stream<R> get stream => QueryAggregatableHandler.stream(
    query,
    _converter,
    _documentIdField,
    _configuration,
  );
}

class AggregateCountQuery implements Gettable<int>, Streamable<int> {
  AggregateCountQuery(this.query);
  final firestore.AggregateQuery query;

  /// Executes the aggregate query and returns the result
  Future<int> get() => query.get().then((snapshot) {
    // Firestore's count query returns a single integer
    return snapshot.count ?? 0;
  });

  @override
  // Returns a stream that emits the count of documents matching the query
  Stream<int> get stream =>
      lazyBroadcast(
        () =>
            (query.query as firestore.Query<Map<String, dynamic>>).snapshots(),
      ).map((snapshot) {
        return snapshot.docs.length;
      });
}
