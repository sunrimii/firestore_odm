import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';
import '../utils/string_helpers.dart';

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
      final paramName = field.parameterName;
      final jsonFieldName = field.jsonFieldName;
      
      // Check if field has custom toFirestore expression (JsonConverter)
      if (field.customToFirestoreExpression != null) {
        // Apply JsonConverter for toFirestore conversion
        final toFirestoreExpr = field.customToFirestoreExpression!
            .replaceAll('\$source', paramName);
        buffer.writeln(
          '    if ($paramName != null) data[\'$jsonFieldName\'] = $toFirestoreExpr;',
        );
      } else {
        // Standard assignment without converter
        buffer.writeln(
          '    if ($paramName != null) data[\'$jsonFieldName\'] = $paramName;',
        );
      }
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
    
    // Generate custom UpdateBuilder classes for fields with converters
    generateConverterUpdateBuilders(buffer, analysis);
  }

  /// Generate custom UpdateBuilder classes for fields with converters
  static void generateConverterUpdateBuilders(
    StringBuffer buffer,
    ModelAnalysis analysis,
  ) {
    final className = analysis.className;
    
    // Find fields with converters
    final converterFields = analysis.updateableFields
        .where((field) => field.customToFirestoreExpression != null)
        .toList();
    
    for (final field in converterFields) {
      final fieldName = field.parameterName;
      final fieldType = field.dartType.getDisplayString();
      final converterExpr = field.customToFirestoreExpression!;
      
      if (TypeAnalyzer.isMapType(field.dartType)) {
        // Generate custom MapFieldUpdate for map fields with converters
        final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(field.dartType);
        
        buffer.writeln('/// Custom MapFieldUpdate for ${fieldName} field with converter');
        buffer.writeln('class _${className}${StringHelpers.capitalize(fieldName)}MapFieldUpdate extends MapFieldUpdate<$fieldType, $keyType, $valueType> {');
        buffer.writeln('  _${className}${StringHelpers.capitalize(fieldName)}MapFieldUpdate({super.name, super.parent});');
        buffer.writeln('');
        buffer.writeln('  @override');
        buffer.writeln('  UpdateOperation call($fieldType value) {');
        
        // Apply converter
        final convertedExpr = converterExpr.replaceAll('\$source', 'value');
        buffer.writeln('    final convertedValue = $convertedExpr;');
        buffer.writeln('    return UpdateOperation(\$path, UpdateOperationType.set, convertedValue);');
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('');
      } else if (TypeAnalyzer.isIterableType(field.dartType)) {
        // Generate custom ListFieldUpdate for iterable fields with converters
        final elementTypeName = TypeAnalyzer.getIterableElementTypeName(field.dartType);
        
        buffer.writeln('/// Custom ListFieldUpdate for ${fieldName} field with converter');
        buffer.writeln('class _${className}${StringHelpers.capitalize(fieldName)}ListFieldUpdate extends ListFieldUpdate<$fieldType, $elementTypeName> {');
        buffer.writeln('  _${className}${StringHelpers.capitalize(fieldName)}ListFieldUpdate({super.name, super.parent});');
        buffer.writeln('');
        buffer.writeln('  @override');
        buffer.writeln('  UpdateOperation call($fieldType value) {');
        
        // Apply converter
        final convertedExpr = converterExpr.replaceAll('\$source', 'value');
        buffer.writeln('    final convertedValue = $convertedExpr;');
        buffer.writeln('    return UpdateOperation(\$path, UpdateOperationType.set, convertedValue);');
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('');
      } else {
        // Generate custom UpdateBuilder for non-iterable fields with converters
        buffer.writeln('/// Custom UpdateBuilder for ${fieldName} field with converter');
        buffer.writeln('class _${className}${StringHelpers.capitalize(fieldName)}UpdateBuilder extends DefaultUpdateBuilder<$fieldType> {');
        buffer.writeln('  _${className}${StringHelpers.capitalize(fieldName)}UpdateBuilder({super.name, super.parent});');
        buffer.writeln('');
        buffer.writeln('  @override');
        buffer.writeln('  UpdateOperation call($fieldType value) {');
        
        // Apply converter
        final convertedExpr = converterExpr.replaceAll('\$source', 'value');
        buffer.writeln('    final convertedValue = $convertedExpr;');
        buffer.writeln('    return UpdateOperation(\$path, UpdateOperationType.set, convertedValue);');
        buffer.writeln('  }');
        buffer.writeln('}');
        buffer.writeln('');
      }
    }
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

    // Check if field has converter (any type of converter)
    if (field.customToFirestoreExpression != null) {
      // Generate custom UpdateBuilder for fields with converters
      if (TypeAnalyzer.isMapType(fieldType)) {
        // Map types with converters
        final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
        buffer.writeln(
          '  _${className}${StringHelpers.capitalize(fieldName)}MapFieldUpdate get $fieldName => _${className}${StringHelpers.capitalize(fieldName)}MapFieldUpdate(name: \'$jsonFieldName\', parent: this);',
        );
      } else if (TypeAnalyzer.isIterableType(fieldType)) {
        // Iterable types with converters
        final elementTypeName = TypeAnalyzer.getIterableElementTypeName(fieldType);
        buffer.writeln(
          '  _${className}${StringHelpers.capitalize(fieldName)}ListFieldUpdate get $fieldName => _${className}${StringHelpers.capitalize(fieldName)}ListFieldUpdate(name: \'$jsonFieldName\', parent: this);',
        );
      } else {
        // Other types with converters
        buffer.writeln(
          '  _${className}${StringHelpers.capitalize(fieldName)}UpdateBuilder get $fieldName => _${className}${StringHelpers.capitalize(fieldName)}UpdateBuilder(name: \'$jsonFieldName\', parent: this);',
        );
      }
    } else if (TypeAnalyzer.isMapType(fieldType)) {
      final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
      buffer.writeln(
        '  MapFieldUpdate<$fieldType, $keyType, $valueType> get $fieldName => MapFieldUpdate(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isIterableType(fieldType)) {
      final elementTypeName = TypeAnalyzer.getIterableElementTypeName(
        fieldType,
      );
      buffer.writeln(
        '  ListFieldUpdate<$fieldType, $elementTypeName> get $fieldName => ListFieldUpdate(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isDateTimeType(fieldType)) {
      buffer.writeln(
        '  DateTimeFieldUpdate<$fieldType> get $fieldName => DateTimeFieldUpdate(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isDurationType(fieldType)) {
      buffer.writeln(
        '  DurationFieldUpdate<$fieldType> get $fieldName => DurationFieldUpdate(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      buffer.writeln(
        '  NumericFieldUpdate<$fieldType> get $fieldName => NumericFieldUpdate(name: \'$jsonFieldName\', parent: this);',
      );
    } else if (TypeAnalyzer.isCustomClass(fieldType)) {
      // Generate nested UpdateBuilder for custom class types
      buffer.writeln(
        '  UpdateBuilder<$fieldType> get $fieldName => UpdateBuilder(name: \'$jsonFieldName\', parent: this);',
      );
    } else {
      buffer.writeln(
        '  DefaultUpdateBuilder<$fieldType> get $fieldName => DefaultUpdateBuilder(name: \'$jsonFieldName\', parent: this);',
      );
    }
    buffer.writeln('');
  }
}
