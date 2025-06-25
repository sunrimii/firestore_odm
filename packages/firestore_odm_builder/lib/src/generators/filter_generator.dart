import 'package:code_builder/code_builder.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes using code_builder
class FilterGenerator {
  /// Generate document ID filter getter method
  static Method _generateDocumentIdFilterGetter(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Filter by document ID (${field.jsonFieldName} field)')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = refer('DocumentIdFieldFilter')
        ..body = refer('DocumentIdFieldFilter').newInstance([], {
          'name': literalString(field.jsonFieldName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate nested filter getter method
  static Method _generateNestedFilterGetter(FieldInfo field) {
    final nestedTypeName = field.dartType.getDisplayString(
      withNullability: false,
    );

    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} filters')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'FilterSelector'
            ..types.add(refer(nestedTypeName)),
        )
        ..body = refer('FilterSelector').newInstance([], {
          'name': literalString(field.jsonFieldName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate field getter method based on field type
  static Method _generateFieldGetter(FieldInfo field) {
    final String filterType;
    final String fieldName;

    // Determine the appropriate filter type based on field type
    if (TypeAnalyzer.isStringType(field.dartType)) {
      filterType = 'StringFieldFilter';
      fieldName =
          field.parameterName; // Note: using parameterName for string type
    } else if (TypeAnalyzer.isMapType(field.dartType)) {
      filterType = 'MapFieldFilter';
      fieldName = field.jsonFieldName;
    } else if (TypeAnalyzer.isIterableType(field.dartType)) {
      filterType = 'ArrayFieldFilter';
      fieldName = field.jsonFieldName;
    } else if (TypeAnalyzer.isBoolType(field.dartType)) {
      filterType = 'BoolFieldFilter';
      fieldName = field.jsonFieldName;
    } else if (TypeAnalyzer.isDateTimeType(field.dartType)) {
      filterType = 'DateTimeFieldFilter';
      fieldName = field.jsonFieldName;
    } else if (TypeAnalyzer.isNumericType(field.dartType)) {
      filterType = 'NumericFieldFilter';
      fieldName = field.jsonFieldName;
    } else {
      // For nested types, return the nested filter getter
      return _generateNestedFilterGetter(field);
    }

    return Method(
      (b) => b
        ..docs.add('/// Filter by ${field.parameterName}')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = refer(filterType)
        ..body = refer(filterType).newInstance([], {
          'name': literalString(fieldName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate filter selector extension using ModelAnalysis
  static Extension generateFilterSelectorClassFromAnalysis(
    ModelAnalysis analysis,
  ) {
    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }

    final isGeneric = analysis.isGeneric;
    final typeParameters = analysis.typeParameters;
    final typeParameterNames = typeParameters.map((ref) => ref.symbol).toList();
    final classNameWithTypeParams = isGeneric
        ? '$className<${typeParameterNames.join(', ')}>'
        : className;

    // Create the target type (FilterSelector<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'FilterSelector'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = className
              ..types.addAll(typeParameters),
          ),
        ),
    );

    // Generate methods for all fields
    final methods = <Method>[];
    for (final field in analysis.fields.values) {
      if (field.isDocumentId) {
        // Document ID field
        methods.add(_generateDocumentIdFilterGetter(field));
      } else {
        // Regular field
        methods.add(_generateFieldGetter(field));
      }
    }

    // Create extension
    return Extension(
      (b) => b
        ..name = '${className}FilterSelectorExtension'
        ..types.addAll(typeParameters)
        ..on = targetType
        ..docs.add('/// Generated FilterSelector for $classNameWithTypeParams')
        ..methods.addAll(methods),
    );
  }
}
