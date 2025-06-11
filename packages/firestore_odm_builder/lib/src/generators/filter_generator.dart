import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';

/// Generator for filter builders and filter classes
class FilterGenerator {
  /// Generate the filter builder class code using callable instances
  static void generateFilterSelectorClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
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
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isPrimitiveType(fieldType)) {
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
      '  DocumentIdFieldFilter<$rootFilterType> get $documentIdField =>',
    );
    buffer.writeln(
      '      DocumentIdFieldFilter<$rootFilterType>(\'$documentIdField\', prefix);',
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
      '    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';',
    );
    buffer.writeln(
      '    return FilterSelector<${nestedTypeName}>(prefix: nestedPrefix);',
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
    final typeString = fieldType.getDisplayString(withNullability: false);

    buffer.writeln('  /// Filter by $fieldName');

    // Use appropriate callable filter based on type
    if (typeString == 'String') {
      buffer.writeln('  StringFieldFilter<$rootFilterType> get $fieldName =>');
      buffer.writeln(
        '      StringFieldFilter<$rootFilterType>(\'$fieldName\', prefix);',
      );
    } else if (TypeAnalyzer.isListType(fieldType)) {
      final elementType = TypeAnalyzer.getListElementType(fieldType);
      buffer.writeln(
        '  ArrayFieldFilter<$rootFilterType, $elementType> get $fieldName =>',
      );
      buffer.writeln(
        '      ArrayFieldFilter<$rootFilterType, $elementType>(\'$fieldName\', prefix);',
      );
    } else if (typeString == 'bool') {
      buffer.writeln('  BoolFieldFilter<$rootFilterType> get $fieldName =>');
      buffer.writeln(
        '      BoolFieldFilter<$rootFilterType>(\'$fieldName\', prefix);',
      );
    } else if (typeString == 'DateTime') {
      buffer.writeln(
        '  DateTimeFieldFilter<$rootFilterType> get $fieldName =>',
      );
      buffer.writeln(
        '      DateTimeFieldFilter<$rootFilterType>(\'$fieldName\', prefix);',
      );
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      buffer.writeln(
        '  NumericFieldFilter<$rootFilterType, $typeString> get $fieldName =>',
      );
      buffer.writeln(
        '      NumericFieldFilter<$rootFilterType, $typeString>(\'$fieldName\', prefix);',
      );
    } else {
      // Fallback for other types, treat as string-like
      buffer.writeln('  StringFieldFilter<$rootFilterType> get $fieldName =>');
      buffer.writeln(
        '      StringFieldFilter<$rootFilterType>(\'$fieldName\', prefix);',
      );
    }
    buffer.writeln('');
  }

  /// Generate nested filter builder classes
  static void generateNestedFilterSelectorClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootFilterType,
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
            generateFilterSelectorClass(
              buffer,
              typeName,
              nestedConstructor,
              rootFilterType,
              null,
            );

            // Recursively generate for deeply nested types
            generateNestedFilterSelectorClasses(
              buffer,
              nestedConstructor,
              processedTypes,
              rootFilterType,
            );
          }
        }
      }
    }
  }
}
