import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/generators/converter_service.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart' hide FieldInfo;
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

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
    
    // Check if field has a JsonConverter that changes the type
    final expectedType = field.firestoreType;

    final converter = converterFactory.createConverter(field.dartType, element: field.element);
    // if (field.parameterName == 'tags') {
    //   print('Field $fieldName: expected type: $expectedType, original converter: ${analysis.converter}, converter type: ${converter}, converter: ${converter.toType} changed: ${expectedType.rebuild((b) => b..isNullable = null) != converter.toType.rebuild((b) => b..isNullable = null)}');
    // }
    final returnType = false
        ? TypeReference(
            (b) => b
              ..symbol = 'DefaultUpdateBuilder'
              ..types.add(fieldType.reference),
          )
        : TypeAnalyzer.isDateTimeType(fieldType)
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

    final bodyExpression = returnType.symbol == 'DurationFieldUpdate'
        ? returnType.newInstance([], {
            'name': literalString(jsonFieldName),
            'parent': refer('this'),
          })
        : returnType.newInstance([], {
            'name': literalString(jsonFieldName),
            'parent': refer('this'),
            'toJson': Method(
              (b) => b
                ..lambda = true
                // ..returns = TypeReference((b) => b..symbol = 'FirestoreConverter')
                ..requiredParameters.add(Parameter((b) => b
                  ..name = 'data'
                  ))
                ..body = field.dartType.nullabilitySuffix == NullabilitySuffix.question
                    ? refer('data').equalTo(literalNull).conditional(literalNull, converter.toFirestore(refer('data'))).code
                    : converter.toFirestore(refer('data')).code,
            ).closure,
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
