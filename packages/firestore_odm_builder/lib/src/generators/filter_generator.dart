import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes
class FilterGenerator {
  /// Generate the filter builder class code using callable instances
  static void generateFilterSelectorClass(
    StringBuffer buffer,
    String className,
    ConstructorElement2 constructor,
    String rootFilterType,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated FilterSelector for $className');
    buffer.writeln(
      'extension ${className}FilterSelectorExtension on FilterSelector<${className}> {',
    );
    buffer.writeln('');

    // Add document ID filter if there's a document ID field
    if (documentIdField != null) {
      _generateDocumentIdFilterGetter(buffer, documentIdField, rootFilterType);
    }

    // Generate field getters and nested object getters
    for (final param in constructor.formalParameters) {
      final fieldName = param.name3!;
      final fieldType = param.type;

      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isPrimitiveType(fieldType) ||
          TypeAnalyzer.isIterableType(fieldType) ||
          TypeAnalyzer.isMapType(fieldType)) {
        _generateFieldGetter(buffer, fieldName, fieldType, rootFilterType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateNestedFilterGetter(
          buffer,
          fieldName,
          fieldType,
          rootFilterType,
        );
      }
    }

    buffer.writeln('}');
  }

  static void _generateDocumentIdFilterGetter(
    StringBuffer buffer,
    String documentIdField,
    String rootFilterType,
  ) {
    buffer.writeln('  /// Filter by document ID (${documentIdField} field)');
    buffer.writeln(
      '  DocumentIdFieldFilter get $documentIdField =>',
    );
    buffer.writeln(
      '      DocumentIdFieldFilter(name: \'$documentIdField\', parent: this);',
    );
    buffer.writeln('');
  }

  static void _generateNestedFilterGetter(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
    String rootFilterType,
  ) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);

    buffer.writeln('  /// Access nested $fieldName filters');
    buffer.writeln('  FilterSelector<${nestedTypeName}> get $fieldName {');
    buffer.writeln(
      '    return FilterSelector<${nestedTypeName}>(name: \'$fieldName\', parent: this);',
    );
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateFieldGetter(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
    String rootFilterType,
  ) {
    buffer.writeln('  /// Filter by $fieldName');

    // Use appropriate callable filter based on type using TypeChecker
    if (TypeAnalyzer.isStringType(fieldType)) {
      buffer.writeln('  StringFieldFilter get $fieldName =>');
      buffer.writeln(
        '      StringFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isIterableType(fieldType)) {
      final elementTypeName = TypeAnalyzer.getIterableElementTypeName(
        fieldType,
      );
      buffer.writeln(
        '  ArrayFieldFilter get $fieldName =>',
      );
      buffer.writeln(
        '      ArrayFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isMapType(fieldType)) {
      final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
      buffer.writeln(
        '  MapFieldFilter get $fieldName =>',
      );
      buffer.writeln(
        '      MapFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isBoolType(fieldType)) {
      buffer.writeln('  BoolFieldFilter get $fieldName =>');
      buffer.writeln(
        '      BoolFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isDateTimeType(fieldType)) {
      buffer.writeln(
        '  DateTimeFieldFilter get $fieldName =>',
      );
      buffer.writeln(
        '      DateTimeFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      final typeString = fieldType.getDisplayString(withNullability: false);
      buffer.writeln(
        '  NumericFieldFilter get $fieldName =>',
      );
      buffer.writeln(
        '      NumericFieldFilter(name: \'$fieldName\', parent: this);',
      );
    } else {
      // Fallback for other types, treat as string-like
      buffer.writeln('  StringFieldFilter get $fieldName =>');
      buffer.writeln(
        '      StringFieldFilter(name: \'$fieldName\', parent: this);',
      );
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

    // Add document ID filter if there's a document ID field
    if (analysis.documentIdFieldName != null) {
      _generateDocumentIdFilterGetter(buffer, analysis.documentIdFieldName!, className);
    }

    // Generate field getters from analysis
    for (final field in analysis.fields.values) {
      // Skip document ID field as it's handled separately above
      if (field.parameterName == analysis.documentIdFieldName) continue;

      if (TypeAnalyzer.isPrimitiveType(field.dartType) ||
          TypeAnalyzer.isIterableType(field.dartType) ||
          TypeAnalyzer.isMapType(field.dartType)) {
        _generateFieldGetter(buffer, field.parameterName, field.dartType, className);
      } else if (TypeAnalyzer.isCustomClass(field.dartType)) {
        // Generate nested object getter for custom classes - note: rootFilterType stays as className for correct type system
        _generateNestedFilterGetter(
          buffer,
          field.parameterName,
          field.dartType,
          className,  // This is the root filter type, not the nested type
        );
      }
    }

    buffer.writeln('}');
  }
}
