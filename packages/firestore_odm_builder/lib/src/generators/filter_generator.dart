import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes using code_builder
class FilterGenerator {
  /// Generate field getter method based on field type
  static Method _generateFieldGetter({required FieldInfo field}) {
    final typeRef = field.type is TypeParameterType
        ? TypeReference((b) => b..symbol = '\$${field.type.element3!.name3}')
        : getBuilderType(type: field.type);
    final initializerTypeRef = field.type is TypeParameterType
        ? refer('_builderFunc${field.type.element3!.name3!.camelCase()}')
        : typeRef;

    final String fieldName = field.jsonName;

    return Method(
      (b) => b
        ..docs.add('/// Filter by ${field.parameterName}')
        ..type = MethodType.getter
        ..annotations.add(
          refer('pragma').call([literalString('vm:prefer-inline')]),
        )
        ..name = field.parameterName
        ..lambda = true
        ..returns = typeRef
        ..body = initializerTypeRef.newInstance([], {
          'name': literalString(fieldName),
          'parent': refer('this'),
          if (field.isDocumentId) 'type': refer('FieldPathType.documentId'),
        }).code,
    );
  }

  /// Generate filter selector extension using ModelAnalysis
  static Extension generateFilterSelectorClassFromAnalysis(
    String schemaName,
    InterfaceType type,
  ) {
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
    final fields = getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      // Regular field
      methods.add(_generateFieldGetter(field: field));
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

  static Class generateFilterSelectorClass(InterfaceType type) {
    final className = type.element.name;

    final builders = computeNeededBuilders(type: type);

    // Generate methods for all fields
    final fields = getFields(type);
    final methods = <Method>[];
    for (final field in fields.values) {
      // Regular field
      methods.add(_generateFieldGetter(field: field));
    }

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}FilterBuilder'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('FilterBuilderNode'),
                ),
            ],
          ),
        )
        ..extend = refer('FilterBuilderNode')
        ..docs.add('/// Generated FilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..docs.add('/// Creates a filter selector for `$className`')
              ..optionalParameters.addAll([
                for (final typeParam in builders)
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'FilterBuilderFunc'
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
                  refer('_builderFunc${typeParam.name3!.camelCase()}')
                      .assign(
                        refer('builderFunc${typeParam.name3!.camelCase()}'),
                      )
                      .code,
              ]),
          ),
        )
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_builderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'FilterBuilderFunc'
                    ..types.add(refer('\$${typeParam.name3}')),
                ),
            ),
        ])
        ..methods.addAll(methods),
    );
  }

  static Class generateRootFilterSelectorClass(InterfaceType type) {
    final className = type.element3.name3;
    final builders = computeNeededBuilders(type: type.element3.thisType);
    // Create extension
    return Class(
      (b) => b
        ..name = '${className}FilterBuilderRoot'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('FilterBuilderNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = '${className}FilterBuilder'
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
        ..mixins.add(refer('FilterBuilderRootMixin'))
        ..implements.add(refer('FilterBuilderRoot'))
        ..docs.add('/// Generated RootFilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..docs.add('/// Creates a root filter selector for `$className`')
              ..optionalParameters.addAll([
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
              ]),
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

  static List<Spec> generateClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate FilterSelector class
    specs.add(generateFilterSelectorClass(type));

    // Generate RootFilterSelector class
    specs.add(generateRootFilterSelectorClass(type));

    return specs;
  }

  static TypeReference getBuilderType({
    required DartType type,
    bool isRoot = false,
  }) {
    if (TypeAnalyzer.isMapType(type)) {
      return TypeReference(
        (b) => b
          ..symbol = 'MapFieldFilter'
          ..types.add(type.typeArguments.first.reference)
          ..types.add(type.typeArguments.last.reference),
      );
    }

    if (TypeAnalyzer.isIterableType(type)) {
      return TypeReference(
        (b) => b
          ..symbol = 'ArrayFieldFilter'
          ..types.add(type.typeArguments.first.reference),
      );
    }

    if (TypeAnalyzer.isBoolType(type)) {
      return TypeReference((b) => b..symbol = 'BoolFieldFilter');
    }

    if (type is InterfaceType && TypeAnalyzer.isCustomClass(type)) {
      final map = Map.fromIterables(
        type.element3.typeParameters2,
        type.typeArguments,
      );
      final builders = computeNeededBuilders(type: type.element3.thisType);
      return TypeReference(
        (b) => b
          ..symbol = isRoot
              ? '${type.element3.name3}FilterBuilderRoot'
              : '${type.element3.name3}FilterBuilder'
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

    return TypeReference(
      (b) => b
        ..symbol = 'FilterField'
        ..types.add(type.reference),
    );
  }

  static Expression getFilterBuilderInstanceExpression({
    required DartType type,
    bool isRoot = false,
  }) {
    return getBuilderType(type: type, isRoot: isRoot).constInstance([]);
  }

  static TypeReference getRootFilterBuilderType(InterfaceType type) {
    return TypeReference(
      (b) => b
        ..symbol = type.element.name + 'FilterBuilderRoot'
        ..types.addAll(type.typeArguments.map((t) => t.reference)),
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
    Expression? name,
    Expression? parent,
    bool isRoot = false,
  }) {
    return getBuilderType(type: type, isRoot: isRoot).newInstance([], {
      if (name != null) 'name': name,
      if (parent != null) 'parent': parent,
      if (type is InterfaceType)
        ...getConstructorBuildersParameters(type: type),
    });
  }
}
