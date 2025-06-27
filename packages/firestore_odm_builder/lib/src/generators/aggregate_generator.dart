import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for aggregate field selectors using code_builder
class AggregateGenerator {
  /// Generate numeric field accessor method for aggregation
  static Method _generateNumericFieldAccessor(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// ${field.parameterName} field for aggregation')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'AggregateField'
            ..types.add(field.type.reference),
        )
        ..body = refer('AggregateField').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate nested custom type accessor for aggregate field selector
  static Method _generateNestedCustomTypeAccessor(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} aggregate fields')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'AggregateFieldSelector'
            ..types.add(field.type.reference),
        )
        ..body = refer('AggregateFieldSelector').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate aggregate field selector extension using ModelAnalysis
  static Extension generateAggregateFieldSelectorFromAnalysis(
    InterfaceType type,
  ) {
    final className = type.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }

    final typeParameters = type.typeParameters.references;
    final typeParameterNames = type.typeParameters.map((ref) => ref.name).toList();
    final classNameWithTypeParams = type.isGeneric ? '$className<${typeParameterNames.join(', ')}>' : className;

    // Create the target type (AggregateFieldSelector<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'AggregateFieldSelector'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = className
              ..types.addAll(typeParameters),
          ),
        ),
    );

    // Generate methods for all aggregatable fields
    final fields = ModelAnalyzer.instance.getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      // Skip document ID field
      if (field.isDocumentId) continue;

      final fieldType = field.type;

      if (TypeAnalyzer.isNumericType(fieldType)) {
        // Numeric field for aggregation
        methods.add(_generateNumericFieldAccessor(field));
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Nested custom class field
        methods.add(_generateNestedCustomTypeAccessor(field));
      }
    }

    // Create extension
    return Extension(
      (b) => b
        ..name = '${className}AggregateFieldSelectorExtension'
        ..types.addAll(typeParameters)
        ..on = targetType
        ..docs.add(
          '/// Generated AggregateFieldSelector for $classNameWithTypeParams',
        )
        ..methods.addAll(methods),
    );
  }
}
