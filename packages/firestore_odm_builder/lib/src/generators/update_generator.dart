import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
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

    buffer.writeln(
      'extension ${NameUtil.getName(analysis.dartType, postfix: 'UpdateBuilder')} on UpdateBuilder<${NameUtil.getName(analysis.dartType)}> {',
    );
    buffer.writeln('');

    // Generate strongly-typed named parameter update method
    buffer.writeln('  /// Update with strongly-typed named parameters');
    buffer.writeln('  ///');
    buffer.writeln('  /// @deprecated This copyWith-style API will be removed in a future major version.');
    buffer.writeln('  /// Use patch operations instead:');
    buffer.writeln('  /// ```dart');
    buffer.writeln('  /// // Instead of: update(name: "John", age: 25)');
    buffer.writeln('  /// // Use: userDoc.patch((\$) => [\$.name("John"), \$.age(25)])');
    buffer.writeln('  /// ```');
    buffer.writeln('  ///');
    buffer.writeln('  /// Note: This API cannot distinguish between "field not specified" and "field set to null",');
    buffer.writeln('  /// which prevents setting nullable fields to null when they have a current value.');
    buffer.writeln('  @Deprecated(\'Use patch operations instead. Will be removed in next major version.\')');
    buffer.writeln('  UpdateOperation call({');

    // Generate named parameters for all updateable fields with proper types
    for (final field in analysis.updateableFields) {
      // Skip type parameters (like T, K, V) - only process concrete types
      if (field.dartType is TypeParameterType) {
        continue;
      }
      
      // Make all parameters optional for object merge operations
      final dartTypeString = field.dartType.getDisplayString();
      // If the type is already nullable, use it as-is, otherwise make it nullable
      final optionalType = field.isOptional
          ? dartTypeString
          : '$dartTypeString?';
      buffer.writeln('    $optionalType ${field.parameterName},');
    }

    buffer.writeln('  }) {');
    buffer.writeln('    final data = <String, dynamic>{');

    // Generate field assignments using JSON field names from analysis
    for (final field in analysis.updateableFields) {
      // Skip type parameters (like T, K, V) - only process concrete types
      if (field.dartType is TypeParameterType) {
        continue;
      }
      
      final paramName = field.parameterName;
      final jsonFieldName = field.jsonFieldName;
      
      // Check if field has custom converter
      if (field.converter is! DirectConverter) {
        // Apply converter for toFirestore conversion
        String toFirestoreExpr = field.generateToFirestore(refer(field.parameterName)).accept(DartEmitter()).toString();

        // If the field is optional and the converter already has null check,
        // remove the redundant null check since we already check it in the collection if
        if (field.isOptional && toFirestoreExpr.contains('$paramName == null ? null :')) {
          // Extract the non-null expression by removing the null check pattern
          final pattern = '$paramName == null ? null : ';
          toFirestoreExpr = toFirestoreExpr.replaceFirst(pattern, '');
        }
        
        buffer.writeln(
          '      if ($paramName != null) \'$jsonFieldName\': $toFirestoreExpr,',
        );
      } else {
        // Standard assignment without converter
        buffer.writeln(
          '      if ($paramName != null) \'$jsonFieldName\': $paramName,',
        );
      }
    }

    buffer.writeln('    };');
    buffer.writeln(
      '    return UpdateOperation(\$path, UpdateOperationType.objectMerge, data);',
    );
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate individual field update methods
    for (final field in analysis.updateableFields) {
      // Skip type parameters (like T, K, V) - only process concrete types
      if (field.dartType is TypeParameterType) {
        continue;
      }
      
      _generateFieldUpdateMethod(buffer, field);
    }

    buffer.writeln('}');
    buffer.writeln('');
    
    // No longer need to generate custom UpdateBuilder classes - using converter parameter instead
  }


  static void _generateFieldUpdateMethod(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    final fieldType = field.dartType;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonFieldName;

    // Generate field getter that returns a callable update instance
    buffer.writeln('  /// Update $fieldName field');

    // Check field type first - DateTime/Duration/Numeric should always use their specialized UpdateBuilders
    if (TypeAnalyzer.isDateTimeType(fieldType)) {
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
    } else if (field.converter is! DirectConverter) {
      // Generate custom UpdateBuilder for fields with converters (non-DateTime/Duration/Numeric)
      if (TypeAnalyzer.isMapType(fieldType)) {
        // Map types with converters - use MapFieldUpdate with converter
        final (keyType, valueType) = TypeAnalyzer.getMapTypeNames(fieldType);
        final fieldTypeString = fieldType.getDisplayString();
        final converterExpr = field.generateToFirestore(refer('value')).accept(DartEmitter()).toString();
        buffer.writeln(
          '  MapFieldUpdate<$fieldTypeString, $keyType, $valueType> get $fieldName => MapFieldUpdate<$fieldTypeString, $keyType, $valueType>(name: \'$jsonFieldName\', parent: this, converter: (value) => $converterExpr);',
        );
      } else if (TypeAnalyzer.isIterableType(fieldType)) {
        // Iterable types with converters - use ListFieldUpdate with converter
        final elementTypeName = TypeAnalyzer.getIterableElementTypeName(fieldType);
        final fieldTypeString = fieldType.getDisplayString();
        final converterExpr = field.generateToFirestore(refer('value')).accept(DartEmitter()).toString();
        buffer.writeln(
          '  ListFieldUpdate<$fieldTypeString, $elementTypeName> get $fieldName => ListFieldUpdate<$fieldTypeString, $elementTypeName>(name: \'$jsonFieldName\', parent: this, converter: (value) => $converterExpr);',
        );
      } else {
        // Other types with converters - use DefaultUpdateBuilder with converter
        final fieldTypeString = fieldType.getDisplayString();
        final converterExpr = field.generateToFirestore(refer('value')).accept(DartEmitter()).toString();
        buffer.writeln(
          '  DefaultUpdateBuilder<$fieldTypeString> get $fieldName => DefaultUpdateBuilder<$fieldTypeString>(name: \'$jsonFieldName\', parent: this, converter: (value) => $converterExpr);',
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
