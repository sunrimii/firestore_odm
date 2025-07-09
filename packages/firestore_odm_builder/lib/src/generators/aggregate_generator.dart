import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';
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
          'context': refer('\$context'),
        }).code,
    );
  }

  /// Generate nested custom type accessor for aggregate field selector
  static Method _generateNestedCustomTypeAccessor(FieldInfo field) {
    final nestedTypeRef = field.type is TypeParameterType
        ? TypeReference((b) => b..symbol = '\$${field.type.element3!.name3}')
        : TypeReference(
            (b) => b
              ..symbol = '${field.type.element3!.name3}AggregateFieldSelector'
              ..types.addAll(field.type.typeArguments.map((e) => e.reference)),
          );
    final initializerTypeRef = field.type is TypeParameterType
        ? refer('_builderFunc${field.type.element3!.name3!.camelCase()}')
        : nestedTypeRef;
    return Method(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} aggregate fields')
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

  /// Generate aggregate field selector extension using ModelAnalysis
  static Extension? generateAggregateFieldSelectorFromAnalysis(
    String schemaName,
    InterfaceType type,
  ) {
    final fields = getFields(type);
    if (fields.isEmpty) {
      return null;
    }
    final className = type.element.name;

    final typeParameters = type.typeParameters.references;
    final typeParameterNames = type.typeParameters
        .map((ref) => ref.name)
        .toList();
    final classNameWithTypeParams = type.isGeneric
        ? '$className<${typeParameterNames.join(', ')}>'
        : className;

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
        ..name = '${schemaName}${className}AggregateFieldSelectorExtension'
        ..types.addAll(typeParameters)
        ..on = targetType
        ..docs.add(
          '/// Generated AggregateFieldSelector for $classNameWithTypeParams',
        )
        ..methods.addAll(methods),
    );
  }

  static List<Spec> generateClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate OrderByFieldSelector class
    specs.add(generateAggregateClass(type));

    specs.add(generateAggregateRootClass(type));

    return specs;
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

  static Class generateAggregateRootClass(InterfaceType type) {
    final className = type.element3.name3;
    final builders = computeNeededBuilders(type: type.element3.thisType);
    return Class(
      (b) => b
        ..name = '${className}AggregateBuilderRoot'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('AggregateFieldNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = '${className}AggregateFieldSelector'
            ..types.addAll(
              type.element3.typeParameters2.expand(
                (t) => [
                  t.reference,
                  if (builders.contains(t))
                    TypeReference((b) => b..symbol = '\$${t.name3}'),
                ],
              ),
            ),
        )
        ..docs.add('/// Generated AggregateFieldSelector for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for AggregateFieldSelector')
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'context'
                    ..toSuper = true
                    ..required = true
                    ..named = true,
                ),
                for (final typeParam in computeNeededBuilders(
                  type: type.element3.thisType,
                ))
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..toSuper = true
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (b) => b
                    ..name = 'name'
                    ..toSuper = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'parent'
                    ..toSuper = true,
                ),
              ]),
          ),
        )
        ..mixins.add(refer('AggregateRootMixin'))
        ..implements.add(refer('AggregateBuilderRoot')),
    );
  }

  static Class generateAggregateClass(InterfaceType type) {
    final className = type.element3.name3;

    final builders = computeNeededBuilders(type: type);

    // Generate methods for all aggregatable fields
    final methods = <Method>[];
    for (final field in getFields(type).values) {
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

    return Class(
      (b) => b
        ..name = '${className}AggregateFieldSelector'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('AggregateFieldNode'),
                ),
            ],
          ),
        )
        ..extend = refer('AggregateFieldNode')
        ..docs.add('/// Generated AggregateFieldSelector for `$type`')
        ..constructors.addAll([
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for AggregateFieldSelector')
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
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'AggregateBuilderFunc'
                          ..types.add(refer('\$${typeParam.name3}')),
                      )
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (b) => b
                    ..name = 'name'
                    ..toSuper = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'parent'
                    ..toSuper = true,
                ),
              ])
              ..initializers.addAll([
                for (final typeParam in builders)
                  refer('_builderFunc${typeParam.name3!.camelCase()}')
                      .assign(
                        refer('builderFunc${typeParam.name3!.camelCase()}'),
                      )
                      .code,
              ]),
          ),
        ])
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_builderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'AggregateBuilderFunc'
                    ..types.add(refer('\$${typeParam.name3}')),
                ),
            ),
        ])
        ..methods.addAll(methods),
    );
  }

  static TypeReference getBuilderType({
    required DartType type,
    bool isRoot = false,
  }) {
    if (type is! InterfaceType || !TypeAnalyzer.isCustomClass(type)) {
      if (!TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
        return TypeReference((b) => b..symbol = 'Never');
      }
      return TypeReference(
        (b) => b
          ..symbol = 'AggregateField'
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
        ..symbol = isRoot
            ? '${type.element3.name3}AggregateBuilderRoot'
            : '${type.element3.name3}AggregateFieldSelector'
        ..types.addAll(
          map.entries.expand(
            (t) => [
              t.value.reference,
              if (builders.contains(t.key)) getBuilderType(type: t.value),
            ],
          ),
        ),
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
              'builderFunc${entry.key.name3!.camelCase()}',
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
                  ..body = getBuilderInstanceExpression(
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

  static Expression getBuilderInstanceExpression({
    required DartType type,
    required Expression context,
    Expression? name,
    Expression? parent,
    bool isRoot = false,
  }) {
    if (!isUserType(type) &&
        !TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
      return refer(
        'throw UnsupportedError',
      ).call([literalString('Unsupported type for aggregation')]);
    }
    return getBuilderType(type: type, isRoot: isRoot).newInstance([], {
      'context': context,
      if (name != null) 'name': name,
      if (parent != null) 'parent': parent,
      if (type is InterfaceType)
        ...getConstructorBuildersParameters(type: type),
    });
  }
}
