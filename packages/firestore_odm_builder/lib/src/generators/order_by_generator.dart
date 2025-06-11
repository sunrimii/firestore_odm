import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';

/// Generator for order by builders
class OrderByGenerator {
  /// Generate the order by builder class code
  static void generateOrderBySelectorClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootOrderByType,
    String? documentIdField,
  ) {
    // Generate both old OrderBySelector extensions (for backward compatibility)
    buffer.writeln('/// Generated OrderBySelector for $className');
    buffer.writeln(
      'extension ${className}OrderBySelectorExtension on OrderBySelector<${className}> {',
    );

    // Add document ID order method if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Order by document ID (${documentIdField} field)');
      buffer.writeln(
        '  DocumentIdOrderBy<$rootOrderByType> get $documentIdField => DocumentIdOrderBy<$rootOrderByType>(\'$documentIdField\', prefix);',
      );
      buffer.writeln('');
    }

    // Generate field getters for old pattern
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isPrimitiveType(fieldType) ||
          TypeAnalyzer.isComparableType(fieldType)) {
        _generateOrderByFieldMethod(buffer, rootOrderByType, fieldName);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateOrderByNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');

    // Generate new OrderByFieldSelector extensions (for new tuple syntax)
    buffer.writeln('/// Generated OrderByFieldSelector for $className');
    buffer.writeln(
      'extension ${className}OrderByFieldSelectorExtension on OrderByFieldSelector<${className}> {',
    );

    // Add document ID order method if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Order by document ID (${documentIdField} field)');
      buffer.writeln(
        '  String $documentIdField([bool descending = false]) => addField(FieldPath.documentId, descending, String);',
      );
      buffer.writeln('');
    }

    // Generate field methods for new pattern
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isPrimitiveType(fieldType) ||
          TypeAnalyzer.isComparableType(fieldType)) {
        _generateOrderByFieldSelectorMethod(buffer, fieldName, fieldType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateOrderByFieldSelectorNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  static void _generateOrderByFieldMethod(
    StringBuffer buffer,
    String rootOrderByType,
    String fieldName,
  ) {
    buffer.writeln('  /// Order by $fieldName');
    buffer.writeln(
      '  FieldOrderBy<$rootOrderByType> get $fieldName => FieldOrderBy<$rootOrderByType>(\'$fieldName\', prefix);',
    );
    buffer.writeln('');
  }

  static void _generateOrderByNestedGetter(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    buffer.writeln('  /// Access nested $fieldName for ordering');
    buffer.writeln(
      '  OrderBySelector<$nestedTypeName> get $fieldName => OrderByHelper.createOrderBySelector(\'$fieldName\', prefix: prefix);',
    );
    buffer.writeln('');
  }

  static void _generateOrderByFieldSelectorMethod(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final dartTypeName = _getDartTypeName(fieldType);
    buffer.writeln('  /// Order by $fieldName');
    buffer.writeln(
      '  $dartTypeName $fieldName([bool descending = false]) => addField(\'$fieldName\', descending, $dartTypeName);',
    );
    buffer.writeln('');
  }

  static void _generateOrderByFieldSelectorNestedGetter(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    buffer.writeln('  /// Access nested $fieldName for ordering');
    buffer.writeln(
      '  OrderByFieldSelector<$nestedTypeName> get $fieldName => OrderByFieldSelector<$nestedTypeName>(prefix: \'$fieldName.\', parentFields: fields, isExtractionMode: isExtractionMode, sourceObject: sourceObject);',
    );
    buffer.writeln('');
  }

  static String _getDartTypeName(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    switch (typeName) {
      case 'int':
      case 'double':
      case 'String':
      case 'bool':
      case 'DateTime':
        return typeName;
      default:
        return 'dynamic'; // For custom types, we'll use dynamic for now
    }
  }

  /// Generate nested order by builder classes
  static void generateNestedOrderBySelectorClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootOrderByType,
    String? documentIdField,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      // Skip the document ID field and built-in types
      if (param.name == documentIdField ||
          TypeAnalyzer.isBuiltInType(fieldType)) {
        continue;
      }

      final nestedClassName = fieldType.getDisplayString(
        withNullability: false,
      );

      // Avoid generating duplicate builders
      if (processedTypes.contains(nestedClassName)) {
        continue;
      }
      processedTypes.add(nestedClassName);

      // Try to get the constructor of the nested class
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;

        if (nestedConstructor != null) {
          generateOrderBySelectorClass(
            buffer,
            nestedClassName,
            nestedConstructor,
            rootOrderByType,
            null,
          );

          // Recursively generate builders for nested classes
          generateNestedOrderBySelectorClasses(
            buffer,
            nestedConstructor,
            processedTypes,
            rootOrderByType,
            null,
          );
        }
      }
    }
  }
}
