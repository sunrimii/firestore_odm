import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for update builders and related classes using code_builder
class UpdateGenerator {
  /// Generate the update builder extension using pre-analyzed model information
  static Spec? generateUpdateBuilderClass(InterfaceType type) {
    final typeFields = ModelAnalyzer.instance.getFields(type);

    // If there are no fields, we cannot generate an update builder
    if (typeFields.isEmpty) {
      return null;
    }

    final className = type.name!;
    final typeParameters = type.typeParameters.references;

    // Create converter fields for each type parameter
    final converterFields = <Field>[];
    final constructorParams = <Parameter>[];
    final initializerList = <Code>[];

    for (final typeParam in type.typeParameters) {
      final converterName = 'converter${typeParam.name}';
      final converterFieldName = '_${converterName}';
      converterFields.add(
        Field(
          (b) => b
            ..name = converterFieldName
            ..type = TypeReference(
              (b) => b
                ..symbol = 'FirestoreConverter'
                ..types.addAll([typeParam.reference, TypeReferences.dynamic]),
            )
            ..modifier = FieldModifier.final$,
        ),
      );
      constructorParams.add(
        Parameter(
          (b) => b
            ..name = converterName
            ..type = TypeReference(
              (b) => b
                ..symbol = 'FirestoreConverter'
                ..types.addAll([typeParam.reference, TypeReferences.dynamic]),
            )
            ..required = true,
        ),
      );
      initializerList.add(
        refer(converterFieldName).assign(refer(converterName)).code,
      );
    }

    final mapping = {
      for (var param in type.element3.typeParameters2)
        param.name3!: VariableConverter('_converter${param.name3!}'),
    };

    // Generate methods for all updateable fields
    final fields = ModelAnalyzer.instance
        .getFields(type)
        .values
        .map((field) => _generateGenericFieldUpdateMethod(field, mapping));

    return Class(
      (b) => b
        ..name = '${className}UpdateBuilder'
        ..types.addAll(typeParameters)
        ..extend = TypeReference(
          (b) => b
            ..symbol = 'UpdateBuilder'
            ..types.add(
              TypeReference(
                (b) => b
                  ..symbol = className
                  ..types.addAll(typeParameters),
              ),
            ),
        )
        ..fields.addAll(converterFields)
        ..constructors.add(
          Constructor(
            (b) => b
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'path'
                    ..named = true
                    // ..required = true
                    ..toSuper = true,
                ),
                ...constructorParams,
              ])
              ..constant = false
              ..initializers.addAll(initializerList),
          ),
        )
        ..fields.addAll(fields),
    );
  }

  /// Generate field update method for generic types
  static Field _generateGenericFieldUpdateMethod(
    FieldInfo field,
    Map<String, VariableConverter> mapping,
  ) {
    final fieldType = field.type;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonName;
    final converter = ConverterFactory.instance
        .getConverter(field.type, element: field.element)
        .apply(mapping)
        .withNullable(field.isNullable);

    // Check if this field is actually a type parameter (like T)
    final isTypeParameter = fieldType is TypeParameterType;

    // For type parameter fields, we need to use the appropriate converter
    // For concrete type fields (like String), use the standard logic
    final returnType = isTypeParameter
        ? TypeReference(
            (b) => b
              ..symbol = 'DefaultUpdateBuilder'
              ..types.add(fieldType.reference), // Use the actual type parameter
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
        ? returnType.newInstance([], {'path': literalString(jsonFieldName)})
        : returnType.rebuild((b) => b..types.replace([])).newInstance([], {
            'path': literalString(jsonFieldName),
            'converter': converter.toConverterExpr().debug(
              '${{for (var param in field.type.typeParameters) param.name: VariableConverter('_converter${param.name}')}}}',
            ),
          });

    return Field(
      (b) => b
        ..docs.add('/// Update $fieldName field ${field.type}')
        // ..type = MethodType.getter
        ..name = fieldName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = returnType
        ..assignment = bodyExpression.code,
      // ..lambda = true
      // ..returns = returnType
      // ..body = bodyExpression.code,
    );
  }
}
