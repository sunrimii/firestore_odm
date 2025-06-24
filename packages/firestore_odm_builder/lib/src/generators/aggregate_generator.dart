import 'package:analyzer/dart/ast/ast.dart';
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
            ..types.add(field.dartType.reference),
        )
        ..body = refer('AggregateField').newInstance([], {
          'name': literalString(field.jsonFieldName),
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
            ..types.add(field.dartType.reference),
        )
        ..body = refer('AggregateFieldSelector').newInstance([], {
          'name': literalString(field.jsonFieldName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate aggregate field selector extension using ModelAnalysis
  static Extension generateAggregateFieldSelectorFromAnalysis(
    ModelAnalysis analysis,
  ) {
    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }

    final typeParameters = analysis.typeParameters;
    final typeParameterNames = typeParameters.map((ref) => ref.symbol).toList();
    final classNameWithTypeParams = analysis.isGeneric ? '$className<${typeParameterNames.join(', ')}>' : className;

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
    final methods = <Method>[];
    for (final field in analysis.fields.values) {
      // Skip document ID field
      if (field.parameterName == analysis.documentIdFieldName) continue;

      final fieldType = field.dartType;

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
