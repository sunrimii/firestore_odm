import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart'
    hide FieldInfo;
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for update builders and related classes using code_builder
class UpdateGenerator {
  /// Generate the update builder extension using pre-analyzed model information
  static Spec? generateUpdateBuilderClass(ModelAnalysis analysis) {
    // Don't generate update builders for types with no updateable fields
    if (analysis.updateableFields.isEmpty) {
      return null;
    }

    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }

    final typeParameters = analysis.typeParameters;
    return _generateGenericUpdateBuilderClass(
      analysis,
      className,
      typeParameters,
    );
  }

  // /// Generate extension for non-generic types
  // static Extension _generateExtensionUpdateBuilder(
  //   ModelAnalysis analysis,
  //   String className,
  //   List<TypeReference> typeParameters,
  // ) {
  //   // Create the target type (UpdateBuilder<ClassName>)
  //   final targetType = TypeReference(
  //     (b) => b
  //       ..symbol = 'UpdateBuilder'
  //       ..types.add(
  //         TypeReference(
  //           (b) => b
  //             ..symbol = className
  //             ..types.addAll(typeParameters),
  //         ),
  //       ),
  //   );

  //   // Generate methods for all updateable fields
  //   final methods = <Method>[];
  //   for (final field in analysis.updateableFields) {
  //     methods.add(_generateFieldUpdateMethod(field));
  //   }

  //   return Extension(
  //     (b) => b
  //       ..name = '${className}UpdateBuilder'
  //       ..on = targetType
  //       ..methods.addAll(methods),
  //   );
  // }

  /// Generate class for generic types that accepts converters
  static Class _generateGenericUpdateBuilderClass(
    ModelAnalysis analysis,
    String className,
    List<TypeReference> typeParameters,
  ) {
    // Create converter fields for each type parameter
    final converterFields = <Field>[];
    final constructorParams = <Parameter>[];
    final initializerList = <Code>[];

    for (final typeParam in typeParameters) {
      final converterName = 'converter${typeParam.symbol}';
      final converterFieldName = '_${converterName}';
      converterFields.add(
        Field(
          (b) => b
            ..name = converterFieldName
            ..type = TypeReference(
              (b) => b
                ..symbol = 'FirestoreConverter'
                ..types.addAll([typeParam, TypeReferences.dynamic]),
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
                ..types.addAll([typeParam, TypeReferences.dynamic]),
            )
            ..required = true,
        ),
      );
      initializerList.add(
        refer(converterFieldName).assign(refer(converterName)).code,
      );
    }

    // Generate methods for all updateable fields
    final fields = <Field>[];
    for (final field in analysis.updateableFields) {
      fields.add(_generateGenericFieldUpdateMethod(field));
    }

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
  ) {
    final fieldType = field.dartType;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonFieldName;
    final converter = converterFactory.createConverter(
      field.dartType,
      element: field.element,
    );

    final specializedConverter = switch(converter) {
      TypeParameterPlaceholder type => VariableConverter('_converter${type.name}'),
      // If the converter is a specialized converter, we need to specialize it
      // with the type parameters of the field's Dart type
      HasSpecializedConverter specializedConverter => specializedConverter.specialize({
            for (var param in field.dartType .typeParameters)
              param.name: VariableConverter('_converter${param.name}')
          }),
      // Otherwise, use the converter as is
      _ => converter,
    };
    
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
            'converter': specializedConverter
                .withNullable(
                  field.dartType.nullabilitySuffix ==
                      NullabilitySuffix.question,
                )
                .toConverterExpr(),
          });

    return Field(
      (b) => b
        ..docs.add('/// Update $fieldName field ${field.dartType}')
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
