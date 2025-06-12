import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for aggregate field selectors
class AggregateGenerator {
  /// Generate the aggregate field selector extension using ModelAnalysis
  static void generateAggregateFieldSelectorFromAnalysis(
    StringBuffer buffer,
    ModelAnalysis analysis,
  ) {
    final className = analysis.className;
    buffer.writeln('/// Generated AggregateFieldSelector for $className');
    buffer.writeln(
      'extension ${className}AggregateFieldSelectorExtension on AggregateFieldSelector<${className}> {',
    );
    buffer.writeln('');

    // Generate field accessors for all numeric fields from analysis
    for (final field in analysis.fields.values) {
      // Skip document ID field
      if (field.parameterName == analysis.documentIdFieldName) continue;

      if (TypeAnalyzer.isNumericType(field.dartType)) {
        _generateNumericFieldAccessor(buffer, field);
      } else if (TypeAnalyzer.isCustomClass(field.dartType)) {
        // Generate nested custom type accessor
        _generateNestedCustomTypeAccessor(buffer, field);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate numeric field accessor for aggregation
  static void _generateNumericFieldAccessor(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    buffer.writeln('  /// ${field.parameterName} field for aggregation');
    buffer.writeln(
      '  AggregateField<${field.dartType}> get ${field.parameterName} => AggregateField(name: \'${field.jsonFieldName}\', parent: this);',
    );
    buffer.writeln('');
  }

  /// Generate nested custom type accessor for aggregate field selector
  static void _generateNestedCustomTypeAccessor(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    buffer.writeln(
      '  /// Access nested ${field.parameterName} aggregate fields',
    );
    buffer.writeln(
      '  AggregateFieldSelector<${field.dartType}> get ${field.parameterName} => AggregateFieldSelector(name: \'${field.jsonFieldName}\', parent: this);',
    );
    buffer.writeln('');
  }
}
