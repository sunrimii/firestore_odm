import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for order by builders using code_builder
class OrderByGenerator {
  /// Generate OrderBy field selector method
  static Method _generateOrderByFieldSelectorMethod(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Order by ${field.parameterName}')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'OrderByField'
            ..types.add(field.type.reference),
        )
        ..body = refer('OrderByField').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate OrderBy field selector nested getter
  static Method _generateOrderByFieldSelectorNestedGetter(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} for ordering')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'OrderByFieldSelector'
            ..types.add(field.type.reference),
        )
        ..body = refer('OrderByFieldSelector').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
        }).code,
    );
  }

  /// Generate document ID field selector method
  static Method _generateDocumentIdFieldSelector(FieldInfo field) {
    return Method(
      (b) => b
        ..docs.add('/// Order by document ID (${field.parameterName} field)')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'OrderByField'
            ..types.add(refer('String')), // Document ID is always a String
        )
        ..body = refer('OrderByField').newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
          'type': refer('FieldPathType').property('documentId'),
        }).code,
    );
  }

  /// Generate order by selector class using ModelAnalysis
  static Extension generateOrderBySelectorClassFromAnalysis(
    String schemaName,
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
    }
  ) {
    final className = type.element.name;

    final typeParameters = type.typeParameters;

    // Create the target type (OrderByFieldSelector<ClassName<T>>)
    final targetType = TypeReference(
      (b) => b
        ..symbol = 'OrderByFieldSelector'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = className
              ..types.addAll(typeParameters.references),
          ),
        )
        ..url =
            'package:firestore_odm/src/generators/order_by_field_selector.dart',
    );

    // Generate methods for all fields
    final fields = modelAnalyzer.getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      final fieldType = field.type;
      if (field.isDocumentId) {
        // Document ID field
        methods.add(_generateDocumentIdFieldSelector(field));
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Nested custom class field
        methods.add(_generateOrderByFieldSelectorNestedGetter(field));
      } else {
        // Regular field
        methods.add(_generateOrderByFieldSelectorMethod(field));
      }
    }

    // Create extension
    return Extension(
      (b) => b
        ..name = '${schemaName}${className}OrderByFieldSelectorExtension'
        ..types.addAll(typeParameters.references)
        ..on = targetType
        ..docs.add('/// Generated OrderByFieldSelector for `$type`')
        ..methods.addAll(methods),
    );
  }
}
