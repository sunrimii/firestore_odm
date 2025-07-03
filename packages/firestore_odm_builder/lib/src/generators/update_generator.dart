import 'dart:convert';

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
  static Spec? generateUpdateBuilderClass(
    String schemaName,
    InterfaceType type, {
      required ModelAnalyzer modelAnalyzer,
      required ConverterFactory converterFactory,
    }
  ) {
    final typeFields = modelAnalyzer.getFields(type);

    final baseTypeFields = modelAnalyzer.getFields(
      type.element.thisType,
    );

    // If there are no fields, we cannot generate an update builder
    if (typeFields.isEmpty) {
      return null;
    }

    final className = type.name!;
    final typeArguments = type.typeArguments.references;

    // Generate methods for all updateable fields
    final methods = modelAnalyzer
        .getFields(type)
        .values
        .where((f) => isOpenGeneric(baseTypeFields[f.parameterName]!.type))
        .map((field) => _generateGenericFieldUpdateMethod(field, {}, converterFactory: converterFactory));

    if (methods.isEmpty) {
      return null; // No methods to generate
    }

    return Extension(
      (b) => b
        ..name =
            '${schemaName}${className}PatchBuilder' +
            Object.hashAll(typeArguments).abs().toRadixString(36).upperFirst()
        ..on = TypeReference(
          (b) => b
            ..symbol = 'PatchBuilder'
            ..types.add(
              TypeReference(
                (b) => b
                  ..symbol = className
                  ..types.addAll(typeArguments),
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate the update builder extension using pre-analyzed model information
  static Spec? generateGenericUpdateBuilderClass(
    String schemaName,
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
    required ConverterFactory converterFactory,
    }
  ) {
    final typeFields = modelAnalyzer.getFields(type);

    // If there are no fields, we cannot generate an update builder
    if (typeFields.isEmpty) {
      return null;
    }

    final className = type.name!;
    final typeParameters = type.element3.typeParameters2.references;

    // Generate methods for all updateable fields
    final methods = modelAnalyzer
        .getFields(type)
        .values
        .where((f) => !isOpenGeneric(f.type))
        .map((field) => _generateGenericFieldUpdateMethod(field, {}, converterFactory: converterFactory));

    if (methods.isEmpty) {
      return null; // No methods to generate
    }

    return Extension(
      (b) => b
        ..name = '${schemaName}${className}PatchBuilder'
        ..types.addAll(typeParameters)
        ..on = TypeReference(
          (b) => b
            ..symbol = 'PatchBuilder'
            ..types.add(
              TypeReference(
                (b) => b
                  ..symbol = className
                  ..types.addAll(typeParameters),
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  static bool isOpenGeneric(DartType type) {
    // Check if there are unbound type parameters
    return _containsTypeParameters(type);
  }

  static bool isClosedGeneric(DartType type) {
    // Is generic but has no unbound type parameters
    if (type is ParameterizedType) {
      return type.typeArguments.isNotEmpty && !_containsTypeParameters(type);
    }
    return false;
  }

  static bool _containsTypeParameters(DartType type) {
    if (type is TypeParameterType) {
      return true;
    }

    if (type is ParameterizedType) {
      return type.typeArguments.any(_containsTypeParameters);
    }

    return false;
  }

  /// Generate field update method for generic types
  static Method _generateGenericFieldUpdateMethod(
    FieldInfo field,
    Map<String, VariableConverter> mapping, {
    required ConverterFactory converterFactory,
    }
  ) {
    final fieldType = field.type;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonName;
    final converter = converterFactory
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
                ..symbol = 'PatchBuilder'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
              'converter': converter.toConverterExpr(),
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
            arguments: {
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
            },
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
            arguments: {
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
            },
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
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
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
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
              'converter': converter.toConverterExpr(),
              'keyConverter': converterFactory
                  .getConverter(TypeAnalyzer.getMapKeyType(fieldType))
                  .apply(mapping)
                  .toConverterExpr(),
              'valueConverter': converterFactory
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
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
              'converter': converter.toConverterExpr(),
              'elementConverter': converterFactory
                  .getConverter(TypeAnalyzer.getIterableElementType(fieldType))
                  .apply(mapping)
                  .toConverterExpr(),
            },
          )
        : Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'PatchBuilder'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'name': literalString(jsonFieldName),
              'parent': refer('this'),
              'converter': converter.toConverterExpr(),
            },
          );
    final bodyExpression = updater.type.withoutTypeArguments().newInstance(
      [],
      updater.arguments,
    );

    return Method(
      (b) => b
        ..docs.add('/// Update $fieldName field `${field.type}`')
        ..annotations.add(
          refer(
            'pragma',
            'package:firestore_odm/src/annotations.dart',
          ).call([literalString('vm:prefer-inline')]),
        )
        ..name = fieldName
        ..type = MethodType.getter
        ..lambda = true
        ..returns = updater.type
        ..body = bodyExpression.code,
    );
  }
}
