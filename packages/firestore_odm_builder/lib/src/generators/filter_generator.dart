import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes
class FilterGenerator {
  static void _generateDocumentIdFilterGetter(
    StringBuffer buffer,
    String documentIdField,
    FieldInfo field,
  ) {
    buffer.writeln(
      '  /// Filter by document ID (${field.jsonFieldName} field)',
    );
    buffer.writeln('  DocumentIdFieldFilter get ${field.parameterName} =>');
    buffer.writeln(
      '      DocumentIdFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
    );
    buffer.writeln('');
  }

  static void _generateNestedFilterGetter(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    final nestedTypeName = field.dartType.getDisplayString(
      withNullability: false,
    );

    buffer.writeln('  /// Access nested ${field.parameterName} filters');
    buffer.writeln(
      '  FilterSelector<${nestedTypeName}> get ${field.parameterName} {',
    );
    buffer.writeln(
      '    return FilterSelector<${nestedTypeName}>(name: \'${field.jsonFieldName}\', parent: this);',
    );
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateFieldGetter(StringBuffer buffer, FieldInfo field) {
    buffer.writeln('  /// Filter by ${field.parameterName}');

    // Use appropriate callable filter based on type using TypeChecker
    if (TypeAnalyzer.isStringType(field.dartType)) {
      buffer.writeln('  StringFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      StringFieldFilter(name: \'${field.parameterName}\', parent: this);',
      );
    } else if (TypeAnalyzer.isIterableType(field.dartType)) {
      buffer.writeln('  ArrayFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      ArrayFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
      );
    } else if (TypeAnalyzer.isMapType(field.dartType)) {
      buffer.writeln('  MapFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      MapFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
      );
    } else if (TypeAnalyzer.isBoolType(field.dartType)) {
      buffer.writeln('  BoolFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      BoolFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
      );
    } else if (TypeAnalyzer.isDateTimeType(field.dartType)) {
      buffer.writeln('  DateTimeFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      DateTimeFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
      );
    } else if (TypeAnalyzer.isNumericType(field.dartType)) {
      buffer.writeln('  NumericFieldFilter get ${field.parameterName} =>');
      buffer.writeln(
        '      NumericFieldFilter(name: \'${field.jsonFieldName}\', parent: this);',
      );
    } else {
      _generateNestedFilterGetter(buffer, field);
    }
    buffer.writeln('');
  }

  /// Generate filter selector class using ModelAnalysis instead of constructor
  static void generateFilterSelectorClassFromAnalysis(
    StringBuffer buffer,
    ModelAnalysis analysis,
  ) {
    final className = analysis.className;
    buffer.writeln('/// Generated FilterSelector for $className');
    buffer.writeln(
      'extension ${className}FilterSelectorExtension on FilterSelector<${className}> {',
    );
    buffer.writeln('');

    // Generate field getters from analysis
    for (final field in analysis.fields.values) {
      // Skip document ID field as it's handled separately above
      if (field.parameterName == analysis.documentIdFieldName) {
        _generateDocumentIdFilterGetter(
          buffer,
          analysis.documentIdFieldName!,
          field,
        );
      } else {
        _generateFieldGetter(buffer, field);
      }
    }

    buffer.writeln('}');
  }
}
