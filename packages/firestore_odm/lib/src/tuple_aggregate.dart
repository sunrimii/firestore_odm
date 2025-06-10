import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/interfaces/subscribe_operations.dart';
import 'package:firestore_odm/src/services/subscription_service.dart';
import 'model_converter.dart';

/// Typed aggregate query that returns strongly-typed records
class TupleAggregateQuery<T, R extends Record>
    implements SubscribeOperations<R> {
  final Query<Map<String, dynamic>> _query;
  final ModelConverter<T> _converter;
  final R Function(AggregateFieldSelector<T> selector) _builder;

  /// Service for handling real-time subscriptions
  late final QuerySubscriptionService<T> _subscriptionService;

  AggregateQuery? _aggregateQuery;
  List<AggregateOperation>? _operations;

  TupleAggregateQuery(
    this._query,
    this._converter,
    this._builder,
  ) {
    // Initialize the subscription service with the query
    _subscriptionService = QuerySubscriptionService<T>(
      query: _query,
      converter: _converter,
    );
  }

  /// Helper getters for backwards compatibility
  T Function(Map<String, dynamic>) get _fromJson => _converter.fromJson;
  Map<String, dynamic> Function(T) get _toJson => _converter.toJson;

  /// Execute the aggregate query and return strongly-typed record
  Future<R> get() async {
    await _prepareAggregateQuery();

    if (_aggregateQuery != null) {
      // Use native Firestore aggregate API
      final snapshot = await _aggregateQuery!.get();
      return _buildResultRecordFromSnapshot(snapshot);
    } else {
      // Fallback for empty operations
      final selector = AggregateFieldSelector<T>();
      final recordSpec = _builder(selector);
      return _buildResultRecord(recordSpec, {}, []);
    }
  }

  /// Stream of aggregate results that updates when data changes
  Stream<R> get stream => _subscriptionService.stream.asyncMap((snapshot) async {
    // Convert snapshot to aggregate results
    await _prepareAggregateQuery();
    final results = _calculateAggregationsFromSnapshot(snapshot, _operations!);
    return _buildResultRecordFromSnapshot(null, manualResults: results);
  });

  @override
  bool get isSubscribing => _subscriptionService.isSubscribing;

  /// Prepare the aggregate query for execution
  Future<void> _prepareAggregateQuery() async {
    if (_aggregateQuery != null) return;

    // Create the selector and build the aggregate specification
    final selector = AggregateFieldSelector<T>();
    _builder(selector); // Call builder to populate operations

    // Extract aggregate operations from the record
    _operations = selector._operations;

    if (_operations!.isEmpty) return;

    // Build list of AggregateField objects for Firestore native API
    final aggregateFields = _operations!.map((op) {
      if (op is CountOperation) {
        return count();
      } else if (op is SumOperation) {
        return sum(op.fieldPath);
      } else if (op is AverageOperation) {
        return average(op.fieldPath);
      } else {
        throw UnsupportedError('Unsupported aggregate operation: $op');
      }
    }).toList();

    _aggregateQuery = _buildAggregateQuery(aggregateFields);
  }

  /// Build aggregate query with support for up to 30 fields
  AggregateQuery _buildAggregateQuery(List<AggregateField> fields) {
    // Create the aggregate query using native Firestore API
    // Firestore supports up to 30 aggregate fields
    if (fields.length > 30) {
      throw ArgumentError(
        'Firestore supports a maximum of 30 aggregate fields, but ${fields.length} were provided.',
      );
    }

    return _query.aggregate(
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

  /// Calculate aggregations from snapshot for streaming
  Map<String, dynamic> _calculateAggregationsFromSnapshot(
    List<T> snapshot,
    List<AggregateOperation> operations,
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
        results[op.key] = _calculateSum(snapshot, op.fieldPath);
      }

      // Calculate averages
      for (final op in avgOps) {
        results[op.key] = _calculateAverage(snapshot, op.fieldPath);
      }
    }

    return results;
  }

  /// Calculate sum for a field path
  num _calculateSum(List<T> documents, String fieldPath) {
    num total = 0;
    for (final doc in documents) {
      final json = _toJson(doc);
      final value = _getNestedValue(json, fieldPath);
      if (value is num) {
        total += value;
      }
    }
    return total;
  }

  /// Calculate average for a field path
  double _calculateAverage(List<T> documents, String fieldPath) {
    num total = 0;
    int count = 0;
    for (final doc in documents) {
      final json = _toJson(doc);
      final value = _getNestedValue(json, fieldPath);
      if (value is num) {
        total += value;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  /// Get nested value from JSON using dot notation
  dynamic _getNestedValue(Map<String, dynamic> json, String fieldPath) {
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

  /// Build result record from aggregate snapshot
  R _buildResultRecordFromSnapshot(
    AggregateQuerySnapshot? snapshot, {
    Map<String, dynamic>? manualResults,
  }) {
    final results = <String, dynamic>{};

    if (snapshot != null) {
      // Use results from native aggregate query
      for (final op in _operations!) {
        if (op is CountOperation) {
          results[op.key] = snapshot.count ?? 0;
        } else if (op is SumOperation) {
          results[op.key] = snapshot.getSum(op.fieldPath) ?? 0;
        } else if (op is AverageOperation) {
          results[op.key] = snapshot.getAverage(op.fieldPath) ?? 0.0;
        }
      }
    } else if (manualResults != null) {
      // Use manual calculation results for streaming
      results.addAll(manualResults);
    }

    // Create a dummy record spec to get the structure
    final selector = AggregateFieldSelector<T>();
    final recordSpec = _builder(selector);

    return _buildResultRecord(recordSpec, results, _operations!);
  }

  /// Build result record with computed values
  /// Uses dynamic record construction by re-calling the builder function with actual values
  R _buildResultRecord(
    R template,
    Map<String, dynamic> results,
    List<AggregateOperation> operations,
  ) {
    // Create a value selector that returns actual computed results
    final valueSelector = _AggregateValueSelector<T>(results, operations);

    // Re-call the builder function with the value selector to get the final record
    return _builder(valueSelector);
  }
}

/// Selector that provides strongly-typed field access for aggregations
class AggregateFieldSelector<T> {
  final List<AggregateOperation> _operations = [];

  /// Get count of documents
  int count() {
    final key = 'count_${_operations.length}';
    _operations.add(CountOperation(key));
    return 0; // Placeholder return value
  }

  // All field accessors are now code-generated by AggregateGenerator
  // No hardcoded field access needed here
}

// Nested selectors are now code-generated by AggregateGenerator
// No hardcoded nested selectors needed here

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
      final key = 'sum_${_selector._operations.length}';
      _selector._operations.add(SumOperation(key, _fieldPath));
      return _getDefaultValue();
    }
  }

  /// Create average aggregation - always returns double
  double average() {
    // Check if this is a value selector (second pass) or operation collector (first pass)
    if (_selector is _AggregateValueSelector<dynamic>) {
      final valueSelector = _selector as _AggregateValueSelector<dynamic>;
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
      final key = 'avg_${_selector._operations.length}';
      _selector._operations.add(AverageOperation(key, _fieldPath));
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

/// Simple value selector that returns actual computed results
/// This will be extended by generated code to provide field-specific accessors
class _AggregateValueSelector<T> extends AggregateFieldSelector<T> {
  final Map<String, dynamic> _results;
  final List<AggregateOperation> _operations;

  _AggregateValueSelector(this._results, this._operations);

  @override
  int count() {
    // Return the actual count result if available
    for (final entry in _results.entries) {
      if (entry.key.startsWith('count_')) {
        return entry.value as int? ?? 0;
      }
    }
    return 0;
  }
}
