import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/generators/converter_service.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';
import '../utils/string_helpers.dart';

/// Generator for update builders and related classes using code_builder
class UpdateGenerator {
  /// Generate the update builder extension using pre-analyzed model information
  static Extension? generateUpdateBuilderClass(ModelAnalysis analysis) {
    // Don't generate update builders for types with no updateable fields
    if (analysis.updateableFields.isEmpty) {
      return null;
    }

    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }

    final typeParameters = analysis.typeParameters;

    // Create the target type (UpdateBuilder<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'UpdateBuilder'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = className
              ..types.addAll(typeParameters),
          ),
        ),
    );

    // Generate methods for all updateable fields
    final methods = <Method>[];

    // Generate individual field update methods
    for (final field in analysis.updateableFields) {
      // Skip type parameters (like T, K, V) - only process concrete types
      if (field.dartType is TypeParameterType) {
        continue;
      }

      methods.add(_generateFieldUpdateMethod(field));
    }

    // Create extension
    return Extension(
      (b) => b
        ..name = '${className}UpdateBuilder'
        ..types.addAll(typeParameters)
        ..on = targetType
        ..methods.addAll(methods),
    );
  }


  /// Generate field update method
  static Method _generateFieldUpdateMethod(FieldInfo field) {
    final fieldType = field.dartType;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonFieldName;
    print('Generating update method for field: $fieldName, type: $fieldType, typeRef: ${fieldType.reference}');
    final returnType = TypeAnalyzer.isDateTimeType(fieldType)
        ? TypeReference(
            (b) => b
              ..symbol = 'DateTimeFieldUpdate'
              ..types.add(fieldType.reference),
          )
        : TypeAnalyzer.isDurationType(fieldType)
        ? TypeReference(
            (b) => b
              ..symbol = 'DurationFieldUpdate'
              ..types.add(fieldType.reference),
          )
        : TypeAnalyzer.isNumericType(fieldType)
        ? TypeReference(
            (b) => b
              ..symbol = 'NumericFieldUpdate'
              ..types.add(fieldType.reference),
          )
        : TypeAnalyzer.isMapType(fieldType)
        ? TypeReference(
            (b) => b
              ..symbol = 'MapFieldUpdate'
              ..types.addAll([
                fieldType.reference,
                TypeAnalyzer.getMapKeyType(fieldType).reference,
                TypeAnalyzer.getMapValueType(fieldType).reference,
              ]),
          )
        : TypeAnalyzer.isIterableType(fieldType)
        ? TypeReference(
            (b) => b
              ..symbol = 'ListFieldUpdate'
              ..types.addAll([
                fieldType.reference,
                TypeAnalyzer.getIterableElementType(fieldType)!.reference,
              ]),
          )
        : TypeReference(
            (b) => b
              ..symbol = 'DefaultUpdateBuilder'
              ..types.add(fieldType.reference),
          );
    print('Return type for $fieldName: $returnType (str: ${returnType.accept(DartEmitter(useNullSafetySyntax : true))})');
    final converterService = converterServiceSignal.get();
    final analysis = ModelAnalyzer.analyzeModel(field.dartType, field.element);
    final converter = converterService.get(analysis);

    final bodyExpression = TypeAnalyzer.isDurationType(fieldType)
        ? returnType.newInstance([], {
            'name': literalString(jsonFieldName),
            'parent': refer('this'),
          })
        : returnType.newInstance([], {
            'name': literalString(jsonFieldName),
            'parent': refer('this'),
            'converter': converter.instance,
          });

    return Method(
      (b) => b
        ..docs.add('/// Update $fieldName field')
        ..type = MethodType.getter
        ..name = fieldName
        ..lambda = true
        ..returns = returnType
        ..body = bodyExpression.code,
    );
  }
}
