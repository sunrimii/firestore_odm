import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';

/// Generator for order by builders
class OrderByGenerator {
  /// Generate the order by builder class code
  static void generateOrderByBuilderClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootOrderByType,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated OrderByBuilder for $className');
    buffer.writeln('class ${className}OrderByBuilder extends OrderByBuilder {');
    buffer.writeln('  ${className}OrderByBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Add document ID order method if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Order by document ID (${documentIdField} field)');
      buffer.writeln('  OrderByField $documentIdField({bool descending = false}) => orderByField(FieldPath.documentId, descending: descending);');
      buffer.writeln('');
    }

    // Generate field methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;
      
      if (TypeAnalyzer.isPrimitiveType(fieldType) || TypeAnalyzer.isComparableType(fieldType)) {
        _generateOrderByFieldMethod(buffer, className, fieldName);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateOrderByNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  static void _generateOrderByFieldMethod(StringBuffer buffer, String className, String fieldName) {
    buffer.writeln('  /// Order by $fieldName');
    buffer.writeln('  OrderByField $fieldName({bool descending = false}) => orderByField(\'$fieldName\', descending: descending);');
    buffer.writeln('');
  }

  static void _generateOrderByNestedGetter(StringBuffer buffer, String fieldName, DartType fieldType) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    buffer.writeln('  /// Access nested $fieldName for ordering');
    buffer.writeln('  ${nestedTypeName}OrderByBuilder get $fieldName {');
    buffer.writeln('    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return ${nestedTypeName}OrderByBuilder(prefix: nestedPrefix);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  /// Generate nested order by builder classes
  static void generateNestedOrderByBuilderClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootOrderByType,
    String? documentIdField,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      // Skip the document ID field and built-in types
      if (param.name == documentIdField || TypeAnalyzer.isBuiltInType(fieldType)) {
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
          generateOrderByBuilderClass(buffer, nestedClassName, nestedConstructor, rootOrderByType, null);

          // Recursively generate builders for nested classes
          generateNestedOrderByBuilderClasses(
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