import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';
import '../utils/string_helpers.dart';

/// Generator for update builders and related classes
class UpdateGenerator {
  /// Generate the update builder class code
  static void generateUpdateBuilderClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootUpdateType,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated UpdateBuilder for $className');
    buffer.writeln(
      'extension ${className}UpdateBuilder on UpdateBuilder<${className}> {',
    );
    buffer.writeln('');

    // Generate strongly-typed named parameter update method
    buffer.writeln('  /// Update with strongly-typed named parameters');
    buffer.writeln('  UpdateOperation call({');

    // Generate named parameters for all fields except document ID
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field
      if (fieldName == documentIdField) continue;

      // Make all parameters optional for object merge operations
      final baseType = fieldType.getDisplayString(withNullability: false);
      final optionalType = fieldType.isDartCoreNull ? baseType : '$baseType?';
      buffer.writeln('    $optionalType $fieldName,');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    final data = <String, dynamic>{};');

    // Generate assignments for provided parameters
    for (final param in constructor.parameters) {
      final fieldName = param.name;

      // Skip document ID field
      if (fieldName == documentIdField) continue;

      buffer.writeln(
        '    if ($fieldName != null) data[\'$fieldName\'] = $fieldName;',
      );
    }

    buffer.writeln(
      '    return UpdateOperation(prefix, UpdateOperationType.objectMerge, data);',
    );
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate field methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip document ID field
      if (fieldName == documentIdField) continue;

      if (TypeAnalyzer.isPrimitiveType(fieldType) ||
          TypeAnalyzer.isComparableType(fieldType) ||
          TypeAnalyzer.isMapType(fieldType)) {
        _generateUpdateFieldMethod(buffer, className, fieldName, fieldType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateUpdateNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  static void _generateUpdateFieldMethod(
    StringBuffer buffer,
    String className,
    String fieldName,
    DartType fieldType,
  ) {
    final typeString = fieldType.getDisplayString(withNullability: false);

    // Generate field getter that returns a callable update instance
    buffer.writeln('  /// Update $fieldName field');

    if (TypeAnalyzer.isIterableType(fieldType)) {
      final elementTypeName = TypeAnalyzer.getIterableElementTypeName(
        fieldType,
      );
      buffer.writeln(
        '  ListFieldUpdate<$className, $elementTypeName> get $fieldName => ListFieldUpdate<$className, $elementTypeName>(\'$fieldName\', prefix);',
      );
    } else if (TypeAnalyzer.isMapType(fieldType)) {
      final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
      buffer.writeln(
        '  MapFieldUpdate<$className, $keyType, $valueType> get $fieldName => MapFieldUpdate<$className, $keyType, $valueType>(\'$fieldName\', prefix);',
      );
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      buffer.writeln(
        '  NumericFieldUpdate<$className, $typeString> get $fieldName => NumericFieldUpdate<$className, $typeString>(\'$fieldName\', prefix);',
      );
    } else if (TypeAnalyzer.isDateTimeType(fieldType)) {
      buffer.writeln(
        '  DateTimeFieldUpdate<$className> get $fieldName => DateTimeFieldUpdate<$className>(\'$fieldName\', prefix);',
      );
    } else if (typeString == 'bool') {
      buffer.writeln(
        '  BoolFieldUpdate<$className> get $fieldName => BoolFieldUpdate<$className>(\'$fieldName\', prefix);',
      );
    } else if (typeString == 'String') {
      buffer.writeln(
        '  StringFieldUpdate<$className> get $fieldName => StringFieldUpdate<$className>(\'$fieldName\', prefix);',
      );
    } else {
      // Other types - generic updater
      buffer.writeln(
        '  GenericFieldUpdate<$className, $typeString> get $fieldName => GenericFieldUpdate<$className, $typeString>(\'$fieldName\', prefix);',
      );
    }
    buffer.writeln('');
  }

  static void _generateUpdateNestedGetter(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    buffer.writeln('  /// Access nested $fieldName for updates');
    buffer.writeln(
      '  ${StringHelpers.capitalize(fieldName)}NestedUpdater get $fieldName => ${StringHelpers.capitalize(fieldName)}NestedUpdater(prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\');',
    );
    buffer.writeln('');
  }

  /// Generate nested updater class
  static void generateNestedUpdaterClass(
    StringBuffer buffer,
    String fieldName,
    DartType fieldType,
  ) {
    final capitalizedFieldName = StringHelpers.capitalize(fieldName);

    // Get the constructor for this nested type
    final element = fieldType.element;
    if (element is! ClassElement) return;

    final constructor = element.unnamedConstructor;
    if (constructor == null) return;

    buffer.writeln('class ${capitalizedFieldName}NestedUpdater {');
    buffer.writeln('  final String prefix;');
    buffer.writeln('  ${capitalizedFieldName}NestedUpdater(this.prefix);');
    buffer.writeln('');
    buffer.writeln('  /// Update with strongly-typed named parameters');
    buffer.writeln('  UpdateOperation call({');

    // Get document ID field for this nested type
    final nestedDocumentIdField = TypeAnalyzer.getDocumentIdField(constructor);

    // Generate all field update methods directly on this nested updater
    for (final param in constructor.parameters) {
      final paramFieldName = param.name;
      final paramType = param.type;

      // Skip document ID field
      if (paramFieldName == nestedDocumentIdField) continue;

      // Make all parameters optional for object merge operations
      final baseType = paramType.getDisplayString(withNullability: false);
      final optionalType = paramType.isDartCoreNull ? baseType : '$baseType?';
      buffer.writeln('    $optionalType $paramFieldName,');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    final data = <String, dynamic>{};');

    // Generate assignments for provided parameters
    for (final param in constructor.parameters) {
      final paramFieldName = param.name;

      // Skip document ID field
      if (paramFieldName == nestedDocumentIdField) continue;

      buffer.writeln(
        '    if ($paramFieldName != null) data[\'$paramFieldName\'] = $paramFieldName;',
      );
    }

    buffer.writeln(
      '    return UpdateOperation(prefix, UpdateOperationType.objectMerge, data);',
    );
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate all field update methods directly on this nested updater
    for (final param in constructor.parameters) {
      final paramFieldName = param.name;
      final paramType = param.type;

      // Skip document ID field
      if (paramFieldName == nestedDocumentIdField) continue;

      if (TypeAnalyzer.isStringType(paramType)) {
        buffer.writeln('  /// Update $paramFieldName field');
        buffer.writeln('  /// Set $paramFieldName value');
        buffer.writeln(
          '  UpdateOperation $paramFieldName(${paramType.getDisplayString(withNullability: true)} value) {',
        );
        buffer.writeln(
          '    final fieldPath = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln(
          '    return UpdateOperation(fieldPath, UpdateOperationType.set, value);',
        );
        buffer.writeln('  }');
        buffer.writeln('');
      } else if (TypeAnalyzer.isNumericType(paramType)) {
        final numericType = paramType.getDisplayString(withNullability: false);
        buffer.writeln('  /// Update $paramFieldName field');
        buffer.writeln(
          '  NumericFieldBuilder<$numericType> get $paramFieldName {',
        );
        buffer.writeln(
          '    final fieldPath = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln(
          '    return NumericFieldBuilder<$numericType>(fieldPath);',
        );
        buffer.writeln('  }');
        buffer.writeln('');
      } else if (TypeAnalyzer.isBoolType(paramType)) {
        buffer.writeln('  /// Update $paramFieldName field');
        buffer.writeln('  /// Set $paramFieldName value');
        buffer.writeln(
          '  UpdateOperation $paramFieldName(${paramType.getDisplayString(withNullability: true)} value) {',
        );
        buffer.writeln(
          '    final fieldPath = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln(
          '    return UpdateOperation(fieldPath, UpdateOperationType.set, value);',
        );
        buffer.writeln('  }');
        buffer.writeln('');
      } else if (TypeAnalyzer.isDateTimeType(paramType)) {
        buffer.writeln('  /// Update $paramFieldName field');
        buffer.writeln('  DateTimeFieldBuilder get $paramFieldName {');
        buffer.writeln(
          '    final fieldPath = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln('    return DateTimeFieldBuilder(fieldPath);');
        buffer.writeln('  }');
        buffer.writeln('');
      } else if (TypeAnalyzer.isIterableType(paramType)) {
        final elementTypeName = TypeAnalyzer.getIterableElementTypeName(
          paramType,
        );
        buffer.writeln('  /// Update $paramFieldName field');
        buffer.writeln(
          '  ListFieldBuilder<$elementTypeName> get $paramFieldName {',
        );
        buffer.writeln(
          '    final fieldPath = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln(
          '    return ListFieldBuilder<$elementTypeName>(fieldPath);',
        );
        buffer.writeln('  }');
        buffer.writeln('');
      } else if (TypeAnalyzer.isCustomClass(paramType)) {
        // Nested custom class - create accessor
        final nestedUpdaterClassName =
            '${StringHelpers.capitalize(paramFieldName)}NestedUpdater';
        buffer.writeln('  /// Access nested $paramFieldName for updates');
        buffer.writeln('  $nestedUpdaterClassName get $paramFieldName {');
        buffer.writeln(
          '    final nestedPrefix = prefix.isEmpty ? \'$paramFieldName\' : \'\$prefix.$paramFieldName\';',
        );
        buffer.writeln('    return $nestedUpdaterClassName(nestedPrefix);');
        buffer.writeln('  }');
        buffer.writeln('');
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate nested update builder classes
  static void generateNestedUpdateBuilderClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootUpdateType,
  ) {
    // Get document ID field for this constructor
    final documentIdField = TypeAnalyzer.getDocumentIdField(constructor);

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
          generateUpdateBuilderClass(
            buffer,
            nestedClassName,
            nestedConstructor,
            rootUpdateType,
            null,
          );

          // Recursively generate builders for nested classes
          generateNestedUpdateBuilderClasses(
            buffer,
            nestedConstructor,
            processedTypes,
            rootUpdateType,
          );
        }
      }
    }
  }

  /// Generate all nested updater classes
  static void generateAllNestedUpdaterClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
  ) {
    // Get document ID field for this constructor
    final documentIdField = TypeAnalyzer.getDocumentIdField(constructor);

    for (final param in constructor.parameters) {
      final fieldType = param.type;
      final fieldName = param.name;

      // Skip the document ID field and built-in types
      if (fieldName == documentIdField ||
          TypeAnalyzer.isBuiltInType(fieldType)) {
        continue;
      }

      if (TypeAnalyzer.isCustomClass(fieldType)) {
        final nestedTypeName = fieldType.getDisplayString(
          withNullability: false,
        );

        // Avoid processing the same type multiple times
        if (processedTypes.contains(nestedTypeName)) continue;
        processedTypes.add(nestedTypeName);

        // Generate the nested updater class for this field
        generateNestedUpdaterClass(buffer, fieldName, fieldType);

        // Recursively generate for deeper nested types
        if (fieldType.element is ClassElement) {
          final nestedClass = fieldType.element as ClassElement;
          final nestedConstructor = nestedClass.unnamedConstructor;
          if (nestedConstructor != null) {
            generateAllNestedUpdaterClasses(
              buffer,
              nestedConstructor,
              processedTypes,
            );
          }
        }
      }
    }
  }

  /// Generate base update classes (placeholder for now)
  static void generateBaseUpdateClasses(StringBuffer buffer) {
    // Base classes are now provided by the core package
    // Only need to generate specific update builders for each model
  }
}
