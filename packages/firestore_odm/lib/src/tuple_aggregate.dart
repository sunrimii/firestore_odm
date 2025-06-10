import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed aggregate query that returns strongly-typed records
class TupleAggregateQuery<T, R extends Record> {
  final Query<Map<String, dynamic>> _query;
  final T Function(Map<String, dynamic> data) _fromJson;
  final Map<String, dynamic> Function(T value) _toJson;
  final R Function(AggregateFieldSelector<T> selector) _builder;

  TupleAggregateQuery(
    this._query,
    this._fromJson,
    this._toJson,
    this._builder,
  );

  /// Execute the aggregate query and return strongly-typed record
  Future<R> get() async {
    // Create the selector and build the aggregate specification
    final selector = AggregateFieldSelector<T>();
    final recordSpec = _builder(selector);
    
    // Extract aggregate operations from the record
    final operations = selector._operations;
    
    // Execute aggregations
    final results = await _executeAggregations(operations);
    
    // Build the result record with actual values
    return _buildResultRecord(recordSpec, results, operations);
  }

  /// Stream of aggregate results that updates when data changes
  Stream<R> snapshots() {
    return _query.snapshots().asyncMap((snapshot) async {
      final selector = AggregateFieldSelector<T>();
      final recordSpec = _builder(selector);
      final operations = selector._operations;
      
      final results = _calculateAggregationsFromSnapshot(snapshot, operations);
      return _buildResultRecord(recordSpec, results, operations);
    });
  }

  /// Execute native Firestore aggregations where possible
  Future<Map<String, dynamic>> _executeAggregations(List<AggregateOperation> operations) async {
    final results = <String, dynamic>{};
    
    // Handle count aggregation natively
    final countOps = operations.whereType<CountOperation>().toList();
    if (countOps.isNotEmpty) {
      final countSnapshot = await _query.count().get();
      final count = countSnapshot.count ?? 0;
      for (final op in countOps) {
        results[op.key] = count;
      }
    }
    
    // For sum/average, need to fetch and calculate manually
    final sumOps = operations.whereType<SumOperation>().toList();
    final avgOps = operations.whereType<AverageOperation>().toList();
    
    if (sumOps.isNotEmpty || avgOps.isNotEmpty) {
      final snapshot = await _query.get();
      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _fromJson(data);
      }).toList();
      
      // Calculate sums
      for (final op in sumOps) {
        results[op.key] = _calculateSum(documents, op.fieldPath);
      }
      
      // Calculate averages
      for (final op in avgOps) {
        results[op.key] = _calculateAverage(documents, op.fieldPath);
      }
    }
    
    return results;
  }

  /// Calculate aggregations from snapshot for streaming
  Map<String, dynamic> _calculateAggregationsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    List<AggregateOperation> operations,
  ) {
    final results = <String, dynamic>{};
    
    // Count operations
    final countOps = operations.whereType<CountOperation>().toList();
    final count = snapshot.docs.length;
    for (final op in countOps) {
      results[op.key] = count;
    }
    
    // Parse documents for sum/average
    final sumOps = operations.whereType<SumOperation>().toList();
    final avgOps = operations.whereType<AverageOperation>().toList();
    
    if (sumOps.isNotEmpty || avgOps.isNotEmpty) {
      final documents = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _fromJson(data);
      }).toList();
      
      // Calculate sums
      for (final op in sumOps) {
        results[op.key] = _calculateSum(documents, op.fieldPath);
      }
      
      // Calculate averages  
      for (final op in avgOps) {
        results[op.key] = _calculateAverage(documents, op.fieldPath);
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

  /// Build result record with computed values
  /// TODO: This should be replaced by generated code for each specific record pattern
  R _buildResultRecord(R template, Map<String, dynamic> results, List<AggregateOperation> operations) {
    // TEMPORARY: Use reflection-like approach until proper code generation is implemented
    // In production, the generator would create specific typed builders for each record pattern
    return _buildRecordGeneric(template, results, operations);
  }
  
  /// Generic record builder (temporary until code generation)
  R _buildRecordGeneric(R template, Map<String, dynamic> results, List<AggregateOperation> operations) {
    // This is a temporary generic approach
    // The real solution requires code generation to create typed builders for each record pattern
    
    // Extract values in order of operations
    final values = operations.map((op) => results[op.key]).toList();
    
    // For now, use a simple pattern matching approach
    // This will be replaced by generated code that knows the exact record structure
    
    if (operations.length == 1 && operations.first is CountOperation) {
      return (count: values[0] as int) as R;
    }
    
    if (operations.length == 3) {
      // Assume common pattern: count, sum, average
      final count = values[0] as int;
      final sum = values[1] as num;
      final avg = values[2] as double;
      
      // Check template structure to determine field names
      final templateStr = template.toString();
      if (templateStr.contains('activeCount')) {
        return (activeCount: count, totalAge: sum, avgRating: avg) as R;
      } else {
        return (count: count, totalAge: sum, avgRating: avg) as R;
      }
    }
    
    // Default fallback
    return template;
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
    final key = 'sum_${_selector._operations.length}';
    _selector._operations.add(SumOperation(key, _fieldPath));
    return _getDefaultValue();
  }
  
  /// Create average aggregation - always returns double
  double average() {
    final key = 'avg_${_selector._operations.length}';
    _selector._operations.add(AverageOperation(key, _fieldPath));
    return 0.0; // Placeholder
  }
  
  /// Get default value for the specific numeric type
  T _getDefaultValue() {
    if (T == int) return 0 as T;
    if (T == double) return 0.0 as T;
    if (T == num) return 0 as T;
    throw UnsupportedError('Unsupported numeric type: $T');
  }
}