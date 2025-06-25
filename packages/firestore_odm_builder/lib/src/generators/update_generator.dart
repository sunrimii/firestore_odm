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

    // Generate deprecated call method
    methods.add(_generateDeprecatedCallMethod(analysis));

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

  /// Generate the deprecated call method with named parameters
  static Method _generateDeprecatedCallMethod(ModelAnalysis analysis) {
    // Build parameter list
    final parameters = <Parameter>[];
    final bodyStatements = <Code>[];

    // Add initial map declaration
    bodyStatements.add(Code('final data = <String, dynamic>{'));

    for (final field in analysis.updateableFields) {
      // Skip type parameters (like T, K, V) - only process concrete types
      if (field.dartType is TypeParameterType) {
        continue;
      }

      // Make all parameters optional for object merge operations
      final dartTypeString = field.dartType.getDisplayString();
      final optionalType = field.isOptional
          ? dartTypeString
          : '$dartTypeString?';

      parameters.add(
        Parameter(
          (b) => b
            ..name = field.parameterName
            ..type = refer(optionalType)
            ..named = true,
        ),
      );

      final paramName = field.parameterName;
      final jsonFieldName = field.jsonFieldName;

      // Check if field has custom converter
      if (field.converter is! DirectConverter) {
        // Apply converter for toFirestore conversion
        String toFirestoreExpr = field
            .generateToFirestore(refer(field.parameterName))
            .accept(DartEmitter())
            .toString();

        // If the field is optional and the converter already has null check,
        // remove the redundant null check since we already check it in the collection if
        if (field.isOptional &&
            toFirestoreExpr.contains('$paramName == null ? null :')) {
          // Extract the non-null expression by removing the null check pattern
          final pattern = '$paramName == null ? null : ';
          toFirestoreExpr = toFirestoreExpr.replaceFirst(pattern, '');
        }

        bodyStatements.add(
          Code(
            '  if ($paramName != null) \'$jsonFieldName\': $toFirestoreExpr,',
          ),
        );
      } else {
        // Standard assignment without converter
        bodyStatements.add(
          Code('  if ($paramName != null) \'$jsonFieldName\': $paramName,'),
        );
      }
    }

    bodyStatements.add(Code('};'));
    bodyStatements.add(
      Code(
        'return UpdateOperation(\$path, UpdateOperationType.objectMerge, data);',
      ),
    );

    return Method(
      (b) => b
        ..docs.addAll([
          '/// Update with strongly-typed named parameters',
          '///',
          '/// @deprecated This copyWith-style API will be removed in a future major version.',
          '/// Use patch operations instead:',
          '/// ```dart',
          '/// // Instead of: update(name: "John", age: 25)',
          '/// // Use: userDoc.patch((\$) => [\$.name("John"), \$.age(25)])',
          '/// ```',
          '///',
          '/// Note: This API cannot distinguish between "field not specified" and "field set to null",',
          '/// which prevents setting nullable fields to null when they have a current value.',
        ])
        ..annotations.add(
          refer('Deprecated').call([
            literalString(
              'Use patch operations instead. Will be removed in next major version.',
            ),
          ]),
        )
        ..name = 'call'
        ..requiredParameters.addAll(parameters)
        ..returns = refer('UpdateOperation')
        ..body = Block((b) => b..statements.addAll(bodyStatements)),
    );
  }

  /// Generate field update method
  static Method _generateFieldUpdateMethod(FieldInfo field) {
    final fieldType = field.dartType;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonFieldName;

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
