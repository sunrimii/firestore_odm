import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for update builders and related classes
class UpdateGenerator {
  /// Generate the update builder class code using pre-analyzed model information
  static void generateUpdateBuilderClass(
    StringBuffer buffer,
    ModelAnalysis analysis,
  ) {
    // Don't generate update builders for types with no updateable fields
    if (analysis.updateableFields.isEmpty) {
      return;
    }

    final className = analysis.className;

    buffer.writeln('/// Generated UpdateBuilder for $className');
    buffer.writeln(
      'extension ${className}UpdateBuilder on UpdateBuilder<${className}> {',
    );
    buffer.writeln('');

    // Generate strongly-typed named parameter update method
    buffer.writeln('  /// Update with strongly-typed named parameters');
    buffer.writeln('  UpdateOperation call({');

    // Generate named parameters for all updateable fields
    for (final field in analysis.updateableFields) {
      // Make all parameters optional for object merge operations
      final dartTypeString = field.dartType.getDisplayString();
      // If the type is already nullable, use it as-is, otherwise make it nullable
      final optionalType = field.isNullable
          ? dartTypeString
          : '$dartTypeString?';
      buffer.writeln('    $optionalType ${field.parameterName},');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    final data = <String, dynamic>{};');

    // Generate field assignments using JSON field names from analysis
    for (final field in analysis.updateableFields) {
      buffer.writeln(
        '    if (${field.parameterName} != null) data[\'${field.jsonFieldName}\'] = ${field.parameterName};',
      );
    }

    buffer.writeln(
      '    return UpdateOperation(\$path, UpdateOperationType.objectMerge, data);',
    );
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate individual field update methods
    for (final field in analysis.updateableFields) {
      _generateFieldUpdateMethod(buffer, className, field);
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  static void _generateFieldUpdateMethod(
    StringBuffer buffer,
    String className,
    FieldInfo field,
  ) {
    final fieldType = field.dartType;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonFieldName;

    // Generate field getter that returns a callable update instance
    buffer.writeln('  /// Update $fieldName field');

    if (TypeAnalyzer.isMapType(fieldType)) {
      final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
      buffer.writeln(
        '  MapFieldUpdate<$className, $keyType, $valueType> get $fieldName => MapFieldUpdate<$className, $keyType, $valueType>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isIterableType(fieldType)) {
      final elementTypeName = TypeAnalyzer.getIterableElementTypeName(
        fieldType,
      );
      buffer.writeln(
        '  ListFieldUpdate<$className, $elementTypeName> get $fieldName => ListFieldUpdate<$className, $elementTypeName>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isStringType(fieldType)) {
      buffer.writeln(
        '  StringFieldUpdate<$className> get $fieldName => StringFieldUpdate<$className>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isBoolType(fieldType)) {
      buffer.writeln(
        '  BoolFieldUpdate<$className> get $fieldName => BoolFieldUpdate<$className>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isDateTimeType(fieldType)) {
      buffer.writeln(
        '  DateTimeFieldUpdate<$className> get $fieldName => DateTimeFieldUpdate<$className>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      final typeString = fieldType.getDisplayString();
      buffer.writeln(
        '  NumericFieldUpdate<$className, $typeString> get $fieldName => NumericFieldUpdate<$className, $typeString>(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isCustomClass(fieldType)) {
      // Generate nested UpdateBuilder for custom class types
      final typeString = fieldType.getDisplayString();
      buffer.writeln(
        '  UpdateBuilder<$typeString> get $fieldName => UpdateBuilder<$typeString>(name: \'$jsonFieldName\', parent: this);',
      );
    } else {
      final typeString = fieldType.getDisplayString();
      buffer.writeln(
        '  GenericFieldUpdate<$className, $typeString> get $fieldName => GenericFieldUpdate<$className, $typeString>(name: \'$jsonFieldName\', parent: this);',
      );
    }
    buffer.writeln('');
  }
}
