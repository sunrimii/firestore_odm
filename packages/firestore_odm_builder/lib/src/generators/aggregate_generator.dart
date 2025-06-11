import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';

/// Generator for aggregate field selectors
class AggregateGenerator {
  /// Generate the aggregate field selector extension code
  static void generateAggregateFieldSelectorClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated AggregateFieldSelector for $className');
    buffer.writeln(
      'extension ${className}AggregateFieldSelectorExtension on AggregateFieldSelector<${className}> {',
    );
    buffer.writeln('');

    // Generate field accessors for all numeric fields
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isNumericType(fieldType)) {
        _generateNumericFieldAccessor(buffer, fieldName, fieldType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object accessor for custom classes
        _generateNestedAggregateAccessor(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate numeric field accessor for aggregation
  static void _generateNumericFieldAccessor(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    // Determine the Dart type for the field
    final dartType = _getDartTypeForAggregateField(fieldType);

    buffer.writeln('  /// $fieldName field for aggregation');
    buffer.writeln(
      '  TupleAggregateField<$dartType> get $fieldName => TupleAggregateField<$dartType>(\'$fieldName\', this);',
    );
    buffer.writeln('');
  }

  /// Generate nested object accessor for custom classes
  static void _generateNestedAggregateAccessor(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final className = _getClassNameFromType(fieldType);
    buffer.writeln('  /// $fieldName nested object for aggregation');
    buffer.writeln(
      '  ${className}NestedAggregateSelector get $fieldName => ${className}NestedAggregateSelector(\'$fieldName\', this);',
    );
    buffer.writeln('');
  }

  /// Generate nested aggregate selector class for custom objects
  static void generateNestedAggregateSelector(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated nested aggregate selector for $className');
    buffer.writeln('class ${className}NestedAggregateSelector {');
    buffer.writeln('  final String _basePath;');
    buffer.writeln('  final AggregateFieldSelector _parent;');
    buffer.writeln('');
    buffer.writeln(
      '  const ${className}NestedAggregateSelector(this._basePath, this._parent);',
    );
    buffer.writeln('');

    // Generate nested field accessors
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isNumericType(fieldType)) {
        _generateNestedNumericFieldAccessor(buffer, fieldName, fieldType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object accessor for further nesting
        _generateDeeplyNestedAggregateAccessor(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate nested numeric field accessor
  static void _generateNestedNumericFieldAccessor(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    // Determine the Dart type for the field
    final dartType = _getDartTypeForAggregateField(fieldType);

    buffer.writeln('  /// $fieldName field for aggregation');
    buffer.writeln(
      '  TupleAggregateField<$dartType> get $fieldName => TupleAggregateField<$dartType>(\'\$_basePath.$fieldName\', _parent);',
    );
    buffer.writeln('');
  }

  /// Generate deeply nested object accessor
  static void _generateDeeplyNestedAggregateAccessor(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final className = _getClassNameFromType(fieldType);
    buffer.writeln('  /// $fieldName nested object for aggregation');
    buffer.writeln(
      '  ${className}NestedAggregateSelector get $fieldName => ${className}NestedAggregateSelector(\'\$_basePath.$fieldName\', _parent);',
    );
    buffer.writeln('');
  }

  /// Get the appropriate Dart type for aggregate field
  static String _getDartTypeForAggregateField(DartType fieldType) {
    // Use TypeAnalyzer instead of string comparison
    if (TypeAnalyzer.isIntType(fieldType)) {
      return 'int';
    } else if (TypeAnalyzer.isDoubleType(fieldType)) {
      return 'double';
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      return 'num';
    } else {
      return 'num'; // Fallback for numeric-like types
    }
  }

  /// Extract class name from DartType
  static String _getClassNameFromType(DartType type) {
    return type.getDisplayString(withNullability: false);
  }

  /// Generate nested aggregate selector classes for all nested custom types
  static void generateNestedAggregateSelectors(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String? documentIdField,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      if (TypeAnalyzer.isCustomClass(fieldType)) {
        final element = fieldType.element;
        if (element is ClassElement) {
          final typeName = element.name;

          // Avoid processing the same type multiple times
          if (processedTypes.contains(typeName)) continue;
          processedTypes.add(typeName);

          final nestedConstructor = element.unnamedConstructor;
          if (nestedConstructor != null) {
            buffer.writeln('');
            generateNestedAggregateSelector(
              buffer,
              typeName,
              nestedConstructor,
              documentIdField,
            );

            // Recursively generate for deeply nested types
            generateNestedAggregateSelectors(
              buffer,
              nestedConstructor,
              processedTypes,
              documentIdField,
            );
          }
        }
      }
    }
  }
}
