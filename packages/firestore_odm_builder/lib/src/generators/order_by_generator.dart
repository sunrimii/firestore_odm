import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for order by builders using code_builder
class OrderByGenerator {
  /// Generate OrderBy field selector method
  static Method _generateOrderByFieldSelectorMethod(FieldInfo field) {
    final constructorArgs = <String, Expression>{
      'name': literalString(field.jsonName),
      'parent': refer('this'),
      'context': refer('\$context'),
    };

    // Add type parameter for document ID fields
    if (field.isDocumentId) {
      constructorArgs['type'] = refer('FieldPath.documentId');
    }

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
        ..body = refer('OrderByField').newInstance([], constructorArgs).code,
    );
  }

  /// Generate OrderBy field selector nested getter
  static Method _generateOrderByFieldSelectorNestedGetter(FieldInfo field) {
    final nestedTypeRef = field.type is TypeParameterType
        ? TypeReference((b) => b..symbol = '\$${field.type.element3!.name3}')
        : TypeReference(
            (b) => b
              ..symbol = '${field.type.element3!.name3}OrderByBuilder'
              ..types.addAll(field.type.typeArguments.map((e) => e.reference)),
          );
    final initializerTypeRef = field.type is TypeParameterType
        ? refer('_orderByBuilderFunc${field.type.element3!.name3!.camelCase()}')
        : nestedTypeRef;
    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} for ordering')
        ..type = MethodType.getter
        ..name = field.parameterName
        ..lambda = true
        ..returns = nestedTypeRef
        ..body = initializerTypeRef.newInstance([], {
          'name': literalString(field.jsonName),
          'parent': refer('this'),
          'context': refer('\$context'),
        }).code,
    );
  }

  /// Generate order by selector class using ModelAnalysis
  static Extension generateOrderBySelectorClassFromAnalysis(
    String schemaName,
    InterfaceType type,
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
    final fields = getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      final fieldType = field.type;
      if (TypeAnalyzer.isCustomClass(fieldType)) {
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

  static Map<TypeParameterElement2, InterfaceType> matchedBuilders({
    required InterfaceType type,
  }) {
    final builders = computeNeededBuilders(type: type);
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    return Map.fromEntries(
      map.entries
          .where((entry) => builders.contains(entry.key))
          .whereType<MapEntry<TypeParameterElement2, InterfaceType>>(),
    );
  }

  static Map<String, Expression> getConstructorBuildersParameters({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);

    return Map.fromEntries(
      map.entries
          .where((entry) => builders.contains(entry.key))
          .map(
            (entry) => MapEntry(
              'orderByBuilderFunc${entry.key.name3!.camelCase()}',
              Method(
                (b) => b
                  ..lambda = true
                  ..optionalParameters.addAll([
                    Parameter(
                      (b) => b
                        ..name = 'context'
                        ..required = true
                        ..named = true,
                    ),
                    Parameter(
                      (b) => b
                        ..name = 'name'
                        ..defaultTo = literalString('').code
                        ..named = true,
                    ),
                    Parameter(
                      (b) => b
                        ..name = 'parent'
                        ..named = true,
                    ),
                  ])
                  ..body = getOrderByBuilderInstanceExpression(
                    type: entry.value,
                    context: refer('context'),
                    name: refer('name'),
                    parent: refer('parent'),
                  ).code,
              ).closure,
            ),
          ),
    );
  }

  static Set<TypeParameterElement2> computeNeededBuilders({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.typeArguments,
      type.element3.typeParameters2,
    );
    final fields = getFields(type);
    final fieldTypes = fields.values.map((field) => field.type).toSet();
    return fieldTypes.map((fieldType) => map[fieldType]).nonNulls.toSet();
  }

  static Class generateOrderByClass(InterfaceType type) {
    final fields = getFields(type);
    final methods = <Method>[];
    final builders = computeNeededBuilders(type: type);
    for (final field in fields.values) {
      final fieldType = field.type;
      if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Nested custom class field
        methods.add(_generateOrderByFieldSelectorNestedGetter(field));
      } else {
        // Regular field
        methods.add(_generateOrderByFieldSelectorMethod(field));
      }
    }

    final className = type.element.name;

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}OrderByBuilder'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('OrderByFieldNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference((b) => b..symbol = 'OrderByFieldNode')
        ..docs.add('/// Generated OrderByBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for OrderByBuilder')
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'context'
                    ..toSuper = true
                    ..required = true
                    ..named = true,
                ),
                for (final typeParam in builders)
                  Parameter(
                    (b) => b
                      ..name =
                          'orderByBuilderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'OrderByBuilderFunc'
                          ..types.add(refer('\$${typeParam.name3}')),
                      )
                      ..named = true
                      ..required = true,
                  ),
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
              ])
              ..initializers.addAll([
                for (final typeParam in builders)
                  refer('_orderByBuilderFunc${typeParam.name3!.camelCase()}')
                      .assign(
                        refer(
                          'orderByBuilderFunc${typeParam.name3!.camelCase()}',
                        ),
                      )
                      .code,
              ]),
          ),
        )
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_orderByBuilderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'OrderByBuilderFunc'
                    ..types.add(refer('\$${typeParam.name3}')),
                ),
            ),
        ])
        ..methods.addAll(methods),
    );
  }

  static List<Spec> generateOrderByClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate OrderByFieldSelector class
    specs.add(generateOrderByClass(type));

    return specs;
  }

  static TypeReference getOrderByBuilderType({required DartType type}) {
    if (type is! InterfaceType || !TypeAnalyzer.isCustomClass(type)) {
      return TypeReference(
        (b) => b
          ..symbol = 'OrderByField'
          ..types.add(type.reference),
      );
    }
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);
    return TypeReference(
      (b) => b
        ..symbol = '${type.element3.name3}OrderByBuilder'
        ..types.addAll(
          map.entries.expand(
            (t) => [
              t.value.reference,
              if (builders.contains(t.key))
                getOrderByBuilderType(type: t.value),
            ],
          ),
        ),
    );
  }

  static Expression getOrderByBuilderInstanceExpression({
    required DartType type,
    required Expression context,
    Expression? name,
    Expression? parent,
  }) {
    if (type is! InterfaceType) {
      return TypeReference(
        (b) => b
          ..symbol = 'OrderByField'
          ..types.add(type.reference),
      ).newInstance([], {
        'context': context,
        if (name != null) 'name': name,
        if (parent != null) 'parent': parent,
      });
    }
    return getOrderByBuilderType(type: type).newInstance([], {
      'context': context,
      if (name != null) 'name': name,
      if (parent != null) 'parent': parent,
      ...getConstructorBuildersParameters(type: type),
    });
  }
}
