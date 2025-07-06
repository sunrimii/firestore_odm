import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes using code_builder
class FilterGenerator {
  /// Generate document ID filter getter method
  static Method _generateDocumentIdFilterGetter(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Filter by document ID (${field.jsonName} field)')
        ..annotations.add(
          refer('pragma').call([literalString('vm:prefer-inline')]),
        )
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = refer('DocumentIdFieldFilter')
        ..body = refer('DocumentIdFieldFilter').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate nested filter getter method
  static Method _generateNestedFilterGetter(FieldInfo field) {
    final nestedTypeName = field.type.getDisplayString(withNullability: false);

    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} filters')
        ..annotations.add(
          refer('pragma').call([literalString('vm:prefer-inline')]),
        )
        ..type = MethodType.getter
        ..name = field.parameterName
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'FilterSelector'
            ..types.add(refer(nestedTypeName)),
        )
        ..body = refer('FilterSelector').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate field getter method based on field type
  static Method _generateFieldGetter(FieldInfo field) {
    final String filterType;
    final String fieldName;

    // Determine the appropriate filter type based on field type
    if (TypeAnalyzer.isStringType(field.type)) {
      filterType = 'StringFieldFilter';
      fieldName =
          field.parameterName; // Note: using parameterName for string type
    } else if (TypeAnalyzer.isMapType(field.type)) {
      filterType = 'MapFieldFilter';
      fieldName = field.jsonName;
    } else if (TypeAnalyzer.isIterableType(field.type)) {
      filterType = 'ArrayFieldFilter';
      fieldName = field.jsonName;
    } else if (TypeAnalyzer.isBoolType(field.type)) {
      filterType = 'BoolFieldFilter';
      fieldName = field.jsonName;
    } else if (TypeAnalyzer.isDateTimeType(field.type)) {
      filterType = 'DateTimeFieldFilter';
      fieldName = field.jsonName;
    } else if (TypeAnalyzer.isNumericType(field.type)) {
      filterType = 'NumericFieldFilter';
      fieldName = field.jsonName;
    } else {
      // For nested types, return the nested filter getter
      return _generateNestedFilterGetter(field);
    }

    return Method(
      (b) => b
        ..docs.add('/// Filter by ${field.parameterName}')
        ..type = MethodType.getter
        ..annotations.add(
          refer('pragma').call([literalString('vm:prefer-inline')]),
        )
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
    String schemaName,
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
  }) {
    final className = type.element.name;

    final typeParameters = type.typeParameters;

    // Create the target type (FilterSelector<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'FilterSelector'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = className
              ..types.addAll(typeParameters.references),
          ),
        ),
    );

    // Generate methods for all fields
    final fields = modelAnalyzer.getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
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
        ..name = '${schemaName}${className}FilterSelectorExtension'
        ..types.addAll(typeParameters.references)
        ..on = targetType
        ..docs.add('/// Generated FilterSelector for `$type`')
        ..methods.addAll(methods),
    );
  }

  static Class generateFilterSelectorClass(
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
  }) {
    final className = type.element.name;

    final typeParameters = type.typeParameters;

    // Create the target type (FilterSelector<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'FilterSelector'
        ..types.add(type.reference),
    );

    // Generate methods for all fields
    final fields = modelAnalyzer.getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      if (field.isDocumentId) {
        // Document ID field
        methods.add(_generateDocumentIdFilterGetter(field));
      } else {
        // Regular field
        methods.add(_generateFieldGetter(field));
      }
    }

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}FilterBuilder'
        ..types.addAll(typeParameters.references)
        ..extend = targetType
        ..docs.add('/// Generated FilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..docs.add('/// Creates a filter selector for `$className`')
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'name'
                    ..toSuper = true
                    ..named = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'parent'
                    ..toSuper = true
                    ..named = true,
                ),
              ]),
          ),
        )
        ..methods.addAll(methods),
    );
  }

  static Class generateRootFilterSelectorClass(
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
  }) {
    final className = type.element.name;

    final typeParameters = type.typeParameters;

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}RootFilterBuilder'
        ..types.addAll(typeParameters.references)
        ..extend = TypeReference(
          (b) => b
            ..symbol = '${className}FilterBuilder'
            ..types.addAll(typeParameters.references),
        )
        ..mixins.add(refer('RootFilterMixin'))
        ..implements.add(
          TypeReference(
            (b) => b
              ..symbol = 'RootFilterSelector'
              ..types.add(type.reference),
          ),
        )
        ..docs.add('/// Generated RootFilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..docs.add('/// Creates a root filter selector for `$className`'),
          ),
        ),
    );
  }

  static List<Spec> generateFilterSelectorClasses(
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
  }) {
    final specs = <Spec>[];

    // Generate FilterSelector class
    specs.add(generateFilterSelectorClass(type, modelAnalyzer: modelAnalyzer));

    // Generate RootFilterSelector class
    specs.add(
      generateRootFilterSelectorClass(type, modelAnalyzer: modelAnalyzer),
    );

    return specs;
  }

  static TypeReference getFilterBuilderType(InterfaceType type) {
    return TypeReference(
      (b) => b
        ..symbol = type.element.name + 'FilterBuilder'
        ..types.addAll(type.typeArguments.map((t) => t.reference)),
    );
  }

  static Expression getFilterBuilderInstanceExpression(InterfaceType type) {
    return getFilterBuilderType(type).constInstance([]);
  }

  static TypeReference getRootFilterBuilderType(InterfaceType type) {
    return TypeReference(
      (b) => b
        ..symbol = type.element.name + 'RootFilterBuilder'
        ..types.addAll(type.typeArguments.map((t) => t.reference)),
    );
  }

  static Expression getRootFilterBuilderInstanceExpression(InterfaceType type) {
    return getRootFilterBuilderType(type).constInstance([]);
  }
}
