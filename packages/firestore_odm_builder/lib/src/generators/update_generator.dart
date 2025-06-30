import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

class Updater {
  final TypeReference type;
  final Map<String, Expression> arguments;

  const Updater({required this.type, required this.arguments});
}

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
            ..symbol = 'DefaultUpdateBuilder'
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
              ..constant = !type.isGeneric
              ..initializers.addAll([
                ...initializerList,
                refer('super').call([], {
                  'converter': ConverterFactory.instance
                      .getConverter(type, element: type.element)
                      .apply({
                        for (var param in type.element3.typeParameters2)
                          param.name3!: VariableConverter('converter${param.name3!}'),
                      })
                      .toConverterExpr(),
                }).code,
              ]),
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
    final updater = isTypeParameter
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DefaultUpdateBuilder'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'path': literalString(jsonFieldName),
              'converter': converter.toConverterExpr().debug(
                '${{for (var param in field.type.typeParameters) param.name: VariableConverter('_converter${param.name}')}}}',
              ),
            },
          )
        : TypeAnalyzer.isDateTimeType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DateTimeFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {'path': literalString(jsonFieldName)},
          )
        : TypeAnalyzer.isDurationType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DurationFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {'path': literalString(jsonFieldName)},
          )
        : TypeAnalyzer.isNumericType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'NumericFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'path': literalString(jsonFieldName),
              'converter': converter.toConverterExpr(),
            },
          )
        : TypeAnalyzer.isMapType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'MapFieldUpdate'
                ..types.addAll([
                  fieldType.reference,

                  TypeAnalyzer.getMapKeyType(fieldType).reference,
                  TypeAnalyzer.getMapValueType(fieldType).reference,
                ]),
            ),
            arguments: {
              'path': literalString(jsonFieldName),
              'converter': converter.toConverterExpr(),
              'keyConverter': ConverterFactory.instance
                  .getConverter(TypeAnalyzer.getMapKeyType(fieldType))
                  .apply(mapping)
                  .toConverterExpr(),
              'valueConverter': ConverterFactory.instance
                  .getConverter(TypeAnalyzer.getMapValueType(fieldType))
                  .apply(mapping)
                  .toConverterExpr(),
            },
          )
        : TypeAnalyzer.isIterableType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'ListFieldUpdate'
                ..types.addAll([
                  fieldType.reference,
                  TypeAnalyzer.getIterableElementType(fieldType).reference,
                ]), // Use the actual type parameter
            ),
            arguments: {
              'path': literalString(jsonFieldName),
              'converter': converter.toConverterExpr(),
              'elementConverter': ConverterFactory.instance
                  .getConverter(TypeAnalyzer.getIterableElementType(fieldType))
                  .apply(mapping)
                  .toConverterExpr(),
            },
          )
        : isUserType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = '${fieldType.name?.upperFirst()}UpdateBuilder'
                ..types.addAll(fieldType.typeArguments.references),
            ),
            arguments: {'path': literalString(jsonFieldName)},
          )
        : Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DefaultUpdateBuilder'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'path': literalString(jsonFieldName),
              'converter': converter.toConverterExpr().debug(
                '${{for (var param in field.type.typeParameters) param.name: VariableConverter('_converter${param.name}')}}}',
              ),
            },
          );
    final bodyExpression = isGenericType(fieldType)
        ? updater.type.withoutTypeArguments().newInstance([], updater.arguments)
        : updater.type.withoutTypeArguments().constInstance(
            [],
            updater.arguments,
          );

    return Field(
      (b) => b
        ..docs.add('/// Update $fieldName field `${field.type}`')
        // ..type = MethodType.getter
        ..name = fieldName
        ..modifier = FieldModifier.final$
        ..late = isGenericType(fieldType)
        ..type = updater.type
        ..assignment = bodyExpression.code,
      // ..lambda = true
      // ..returns = returnType
      // ..body = bodyExpression.code,
    );
  }

  static bool isGenericType(DartType type) {
    // Check if the type is a TypeParameterType
    return type is TypeParameterType ||
        type is InterfaceType && type.typeArguments.any(isGenericType);
  }
}
