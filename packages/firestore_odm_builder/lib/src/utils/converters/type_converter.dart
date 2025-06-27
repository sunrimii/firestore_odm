// ===== Core Converter Interface =====

import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

sealed class TypeConverter {
  Expression fromFirestore(Expression source);
  Expression toFirestore(Expression source);
}

abstract class HasSpecializedConverter {
  /// Create a specialized version of this converter with type parameters replaced
  TypeConverter specialize(Map<String, TypeConverter> typeArgs);
}

abstract class WithName {
  /// The name of the converter, used for generating code
  String get name;
}

// ===== Converter Implementations =====

/// 1. Direct converter - no conversion needed (primitives)
class DirectConverter implements TypeConverter {
  const DirectConverter();

  @override
  Expression fromFirestore(Expression source) => source;

  @override
  Expression toFirestore(Expression source) => source;
}

/// 2. Variable converter - delegates to a converter variable
class VariableConverter extends DefaultConverter {
  VariableConverter(String variableName) : super(refer(variableName));
}

/// 3. JsonConverter annotation converter
class AnnotationConverter implements TypeConverter, WithName {
  final DartType type;

  String get name => '${type.element3!.name3}AnnotationConverter';

  List<DartType> get typeArgs => type.typeArguments.toList();

  const AnnotationConverter(this.type);

  @override
  Expression fromFirestore(Expression source) {
    return type.reference.call([]).property('fromJson').call([source]);
  }

  @override
  Expression toFirestore(Expression source) {
    return type.reference.call([]).property('toJson').call([source]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnnotationConverter) return false;
    return type == other.type;
  }

  @override
  int get hashCode {
    // Use the type's hash code for equality
    return type.hashCode;
  }
}

/// 4. fromJson/toJson converter (for types with these methods)
/// This converter handles both generic and non-generic types with fromJson/toJson
class JsonMethodConverter
    implements TypeConverter, WithName, HasSpecializedConverter {
  final DartType type;
  final Map<String, TypeConverter> typeParameterMapping;

  String get name => '${type.element3!.name3}JsonConverter';

  const JsonMethodConverter({
    required this.type,
    this.typeParameterMapping = const {},
  });

  TypeConverter _transform(DartType type) {
    final converter = converterFactory.createConverter(type);

    return converter.apply(typeParameterMapping);
  }

  @override
  Expression fromFirestore(Expression source) {
    // Generic: IList<T>.fromJson(data, (e) => converter.fromFirestore(e))
    final converterLambdas = switch (type) {
      InterfaceType typeParameterType =>
        typeParameterType.typeArguments
            .map(_transform)
            .map(
              (converter) => Method(
                (b) => b
                  ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                  ..body = converter.fromJsonExpr(refer('e')).code
                  ..lambda = true,
              ).closure,
            )
            .toList(),
      _ => [],
    };
    return type.element3!.reference.property('fromJson').call([
      source,
      ...converterLambdas,
    ]);
  }

  @override
  Expression toFirestore(Expression source) {
    // Generic: IList<T>.toJson(data, (e) => converter.toFirestore(e))
    final converterLambdas = switch (type) {
      InterfaceType typeParameterType =>
        typeParameterType.typeArguments
            .map(_transform)
            .map(
              (converter) => Method(
                (b) => b
                  ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                  ..body = converter.toJsonExpr(refer('e')).code
                  ..lambda = true,
              ).closure,
            )
            .toList(),
      _ => [],
    };
    return source.property('toJson').call([...converterLambdas]);
  }

  /// Create a specialized version with concrete converters
  JsonMethodConverter specialize(Map<String, TypeConverter> typeArgs) {
    return JsonMethodConverter(
      type: type,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

/// 5. Custom model converter (our own converter for models)
class ModelConverter
    implements TypeConverter, WithName, HasSpecializedConverter {
  final InterfaceType type;
  final Map<String, FieldInfo> fields;
  final Map<String, TypeConverter> typeParameterMapping;

  String get name => '${type.element.name}ModelConverter';
  List<DartType> get typeArgs => type.typeArguments.toList();

  const ModelConverter({
    required this.type,
    required this.fields,
    this.typeParameterMapping = const {},
  });

  TypeConverter _transform(DartType fieldType, Element? element) {
    final converter = converterFactory.createConverter(
      fieldType,
      element: element,
    );
    return converter.apply(typeParameterMapping);
  }

  @override
  Expression fromFirestore(Expression source) {
    return type.reference.withoutNullability().newInstance(
      [],
      Map.fromEntries(
        fields.values.map(
          (field) => MapEntry(
            field.parameterName,
            _transform(field.type, field.element)
                .withNullable(field.isNullable)
                .fromJsonExpr(source.index(literalString(field.jsonName))),
          ),
        ),
      ),
    );
  }

  @override
  Expression toFirestore(Expression source) {
    return literalMap(
      Map.fromEntries(
        fields.values.map(
          (field) => MapEntry(
            field.jsonName,
            _transform(field.type, field.element)
                .withNullable(field.isNullable)
                .toJsonExpr(source.property(field.parameterName)),
          ),
        ),
      ),
    );
  }

  /// Create a specialized version with type parameters replaced
  ModelConverter specialize(Map<String, TypeConverter> typeArgs) {
    return ModelConverter(
      type: type,
      fields: fields,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

// 6. Default converter
class DefaultConverter implements TypeConverter {
  final Expression _expression;

  const DefaultConverter(this._expression);

  @override
  Expression fromFirestore(Expression source) {
    return _expression.property('fromJson').call([source]);
  }

  @override
  Expression toFirestore(Expression source) {
    return _expression.property('toJson').call([source]);
  }
}

class SpecializedDefaultConverter extends DefaultConverter
    implements HasSpecializedConverter {
  SpecializedDefaultConverter(
    this.expression, {
    this.typeParameterMapping = const {},
  }) : super(
         expression((DartType type) {
           final converter = converterFactory.createConverter(type);

           return switch (converter) {
             TypeParameterPlaceholder type
                 when typeParameterMapping.containsKey(type.name) =>
               typeParameterMapping[type.name]!,
             // If the converter is a specialized converter, we need to specialize it
             // with the type parameters of the field's Dart type
             HasSpecializedConverter specializedConverter =>
               specializedConverter.specialize(typeParameterMapping),
             // Otherwise, use the converter as is
             _ => converter,
           };
         }),
       );

  final Expression Function(TypeConverter Function(DartType)) expression;
  final Map<String, TypeConverter> typeParameterMapping;

  @override
  TypeConverter specialize(Map<String, TypeConverter> typeArgs) {
    return SpecializedDefaultConverter(
      expression,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

class NullableConverter implements TypeConverter {
  final TypeConverter inner;

  const NullableConverter(this.inner);

  @override
  Expression fromFirestore(Expression source) {
    return source
        .equalTo(literalNull)
        .conditional(literalNull, inner.fromFirestore(source.nullChecked));
  }

  @override
  Expression toFirestore(Expression source) {
    return source
        .equalTo(literalNull)
        .conditional(literalNull, inner.toFirestore(source.nullChecked));
  }
}

// ===== Helper Classes =====

/// Placeholder for generic type parameters
class TypeParameterPlaceholder
    implements TypeConverter, HasSpecializedConverter {
  final String name;
  final Map<String, TypeConverter> typeParameterMapping;

  const TypeParameterPlaceholder(
    this.name, {
    this.typeParameterMapping = const {},
  });

  @override
  Expression fromFirestore(Expression source) {
    if (typeParameterMapping.containsKey(name)) {
      // Use the mapped converter if available
      return typeParameterMapping[name]!.fromFirestore(source);
    }
    // Fallback to using the raw data as-is for unresolved type parameters
    print(
      'Warning: Using fallback for unresolved type parameter $name, typeParameterMapping: $typeParameterMapping',
    );
    return source;
  }

  @override
  Expression toFirestore(Expression source) {
    if (typeParameterMapping.containsKey(name)) {
      // Use the mapped converter if available
      return typeParameterMapping[name]!.toFirestore(source);
    }
    // Fallback to using the raw data as-is for unresolved type parameters
    print('Warning: Using fallback for unresolved type parameter $name');
    return source;
  }

  @override
  TypeConverter specialize(Map<String, TypeConverter> typeArgs) {
    return TypeParameterPlaceholder(
      name,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

class FieldInfo {
  final String parameterName;
  final String jsonName;
  final DartType type;
  final Element element;
  // final TypeConverter converter;
  final bool isNullable;

  const FieldInfo({
    required this.parameterName,
    required this.jsonName,
    required this.type,
    required this.element,
    // required this.converter,
    required this.isNullable,
  });
}

// ===== Converter Factory =====

class ConverterFactory {
  final Map<(DartType, Element?), TypeConverter> _converterCache = {};
  final List<Spec> _modelConverters = [];

  /// Create a converter for the given type, optionally using the provided element
  TypeConverter createConverter(DartType type, {Element? element}) =>
      _converterCache.putIfAbsent((
        type,
        element,
      ), () => _createConverter(type, element: element));

  /// Analyze a type and create appropriate converter
  TypeConverter _createConverter(DartType type, {Element? element}) {
    // 2. Check for type parameters
    if (type is TypeParameterType) {
      return TypeParameterPlaceholder(type.element.name);
    }

    // 3. Check for @JsonConverter annotation
    final annotation = _findJsonConverterAnnotation(element);
    if (annotation != null) {
      final fromType =
          annotation.getMethod2('fromJson')?.returnType.reference ??
          TypeReferences.dynamic;
      final toType =
          annotation.getMethod2('toJson')?.returnType.reference ??
          TypeReferences.dynamic;
      final converter = AnnotationConverter(annotation);
      _generateConverter(converter, fromType: fromType, toType: toType);
      return converter;
    }

    // 4. Check for fromJson/toJson methods
    if (_hasJsonMethods(type) && type is InterfaceType) {
      // Check if it's a generic type by counting converter parameters
      final actualToType = type.getMethod2('toJson')?.returnType.reference;
      final toType =
          TypeChecker.fromRuntime(Iterable).isAssignableFromType(type)
          ? TypeReferences.listOf(TypeReferences.dynamic)
          : TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);
      _generateInterfaceConverter(
        type.element,
        toType: toType,
        cast: actualToType != toType,
      );

      // with fromJson/toJson
      return JsonMethodConverter(
        type: type,
        typeParameterMapping: {
          for (final t in type.element3.typeParameters2)
            t.name3!: VariableConverter('converter${t.name3}'),
        },
      );
    }

    // 1. Check for primitives
    if (_isPrimitive(type)) {
      return const DirectConverter();
    }

    // built-in converters for common types
    const mapper = {
      DateTime: 'DateTimeConverter',
      Duration: 'DurationConverter',
      List: 'ListConverter',
      Set: 'SetConverter',
      Map: 'MapConverter',
      Iterable: 'IterableConverter',
    };

    for (final entry in mapper.entries) {
      if (TypeChecker.fromRuntime(entry.key).isAssignableFromType(type)) {
        return SpecializedDefaultConverter(
          (transform) =>
              TypeReference(
                (b) => b
                  ..symbol = entry.value
                  ..url = 'package:firestore_odm/firestore_odm.dart'
                  ..types.addAll(type.typeArguments.map((t) => t.reference)),
              ).call(
                type.typeArguments
                    .map(transform)
                    .map((x) => x.toConverterExpr())
                    .toList(),
              ),
          typeParameterMapping: {
            for (final t in type.typeParameters)
              t.name: VariableConverter('converter${t.name}'),
          },
        );
      }
    }

    // 5. Create custom model converter
    if (type is InterfaceType) {
      return _createModelConverter(type);
    }

    throw UnimplementedError('No converter for type: $type');
  }

  bool _isPrimitive(DartType type) {
    final name = type.element?.name;
    return const {
      'String',
      'int',
      'double',
      'bool',
      'num',
      'dynamic',
      'Object',
    }.contains(name);
  }

  InterfaceType? _findJsonConverterAnnotation(Element? element) {
    if (element == null) return null;
    final annotation = TypeChecker.fromRuntime(
      JsonConverter,
    ).firstAnnotationOf(element);
    if (annotation == null) return null;
    if (annotation.type is! InterfaceType) return null;
    return annotation.type as InterfaceType;
  }

  bool _hasJsonMethods(DartType type) {
    if (type is! InterfaceType) return false;

    final element = type.element;
    // Check if type has fromJson factory and toJson method
    final fromJson =
        element.constructors.where((c) => c.name == 'fromJson').firstOrNull ??
        element.methods
            .where((m) => m.isStatic && m.name == 'fromJson')
            .firstOrNull;
    final toJson = element.methods.where((m) => m.name == 'toJson').firstOrNull;

    return fromJson != null && toJson != null;
  }

  ModelConverter _createModelConverter(InterfaceType type) {
    final constructor = type.constructors
        .where((c) => c.name.isEmpty)
        .firstOrNull;

    // Analyze fields and create model converter
    final fields = <String, FieldInfo>{};

    if (constructor != null) {
      // Simplified field analysis
      for (final parameter in constructor.parameters) {
        if (parameter.isStatic) continue;

        var jsonName = parameter.name;
        // check JsonKey annotation for custom names
        if (parameter.metadata.isNotEmpty) {
          final jsonKey = TypeChecker.fromRuntime(
            JsonKey,
          ).firstAnnotationOfExact(parameter);
          if (jsonKey != null) {
            final reader = ConstantReader(jsonKey);

            jsonName =
                reader.read('name').literalValue as String? ?? parameter.name;

            final includeFromJson =
                reader.read('includeFromJson').literalValue as bool? ?? true;
            final includeToJson =
                reader.read('includeToJson').literalValue as bool? ?? true;
            if (!includeFromJson || !includeToJson) {
              continue;
            }
          }
        }

        fields[parameter.name] = FieldInfo(
          parameterName: parameter.name,
          jsonName: jsonName,
          type: parameter.type,
          element: parameter,
          // converter: createConverter(field.type, element: field),
          isNullable:
              parameter.type.nullabilitySuffix == NullabilitySuffix.question,
        );
      }
    }

    // print(
    //   'Creating ModelConverter for ${type.element.name} with fields: ${fields.keys.join(', ')}',
    // );
    _generateInterfaceConverter(type.element);
    return ModelConverter(
      type: type,
      fields: fields,
      typeParameterMapping: {
        for (final t in type.element3.typeParameters2)
          t.name3!: VariableConverter('converter${t.name3}'),
      },
    );
  }

  List<Spec> get specs {
    // Return all model converter specs
    return _modelConverters;
  }

  final Set<TypeConverter> _generated = {};
  final Set<InterfaceElement> _generated2 = {};

  void _generateInterfaceConverter(
    InterfaceElement element, {
    TypeReference? toType,
    bool cast = false,
  }) {
    if (_generated2.contains(element)) {
      // Already generated for this element
      return;
    }

    _generated2.add(element);

    final converter = createConverter(element.thisType, element: element);
    _generateConverter(
      converter,
      typeParameters: element.typeParameters.map((x) => x.reference),
      fromType: element.reference,
      toType: toType,
      cast: cast,
    );
  }

  void _generateConverter(
    TypeConverter converter, {
    Iterable<TypeReference> typeParameters = const [],
    TypeReference? fromType,
    TypeReference? toType,
    bool cast = false,
    Iterable<String> docs = const [],
  }) {
    if (_generated.contains(converter)) {
      // Already generated for this element
      return;
    }

    _generated.add(converter);

    if (converter is! WithName) {
      throw ArgumentError(
        'Converter must implement WithName to generate model converter',
      );
    }

    final fromTypeResult =
        fromType ??
        TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);
    final toTypeResult =
        toType ??
        TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);

    _modelConverters.add(
      Class(
        (b) => b
          ..docs.addAll(docs)
          ..name = (converter as WithName).name
          ..types.addAll(typeParameters)
          ..implements.add(
            TypeReference(
              (b) => b
                ..symbol = 'FirestoreConverter'
                ..types.addAll([fromTypeResult, toTypeResult]),
            ),
          )
          ..fields.addAll(
            typeParameters.map(
              (t) => Field(
                (b) => b
                  ..name = 'converter${t.symbol}'
                  ..type = TypeReference(
                    (b) => b
                      ..symbol = 'FirestoreConverter'
                      ..types.addAll([t, TypeReferences.dynamic]),
                  )
                  ..modifier = FieldModifier.final$,
              ),
            ),
          )
          ..constructors.add(
            Constructor(
              (b) => b
                ..constant = false
                ..optionalParameters.addAll(
                  typeParameters.map(
                    (t) => Parameter(
                      (b) => b
                        ..required = true
                        ..named = true
                        ..name = 'converter${t.symbol}'
                        ..toThis = true,
                    ),
                  ),
                ),
            ),
          )
          ..methods.addAll([
            Method(
              (b) => b
                ..name = 'fromJson'
                ..annotations.add(refer('override'))
                ..returns = fromTypeResult
                ..requiredParameters.add(Parameter((b) => b..name = 'data'))
                ..body = converter.fromFirestore(refer('data')).code,
            ),
            Method(
              (b) => b
                ..name = 'toJson'
                ..annotations.add(refer('override'))
                ..returns = toTypeResult
                ..requiredParameters.add(Parameter((b) => b..name = 'value'))
                ..body = (cast
                    ? converter
                          .toFirestore(refer('value'))
                          .asA(toTypeResult)
                          .code
                    : converter.toFirestore(refer('value')).code),
            ),
          ]),
      ),
    );
  }
}

final converterFactory = ConverterFactory();

extension TypeConverterExtensions on TypeConverter {
  Expression fromJsonExpr(source) {
    return switch (this) {
      DefaultConverter defaultConverter =>
        defaultConverter.toConverterExpr().property('fromJson').call([source]),
      AnnotationConverter annotationConverter =>
        TypeReference(
              (b) => b
                ..symbol = annotationConverter.name
                ..url = 'package:firestore_odm/firestore_odm.dart',
            )
            .call([], switch (annotationConverter.type) {
              InterfaceType(:final typeArguments, :final element3) =>
                Map.fromIterables(
                  element3.typeParameters2.map((t) => 'converter${t.name3}'),
                  typeArguments
                      .map((t) => converterFactory.createConverter(t))
                      .map(
                        (c) => c.apply(
                          Map.fromIterables(
                            element3.typeParameters2.map(
                              (t) => 'converter${t.name3}',
                            ),
                            typeArguments.map(
                              (t) => converterFactory.createConverter(t),
                            ),
                          ),
                        ),
                      )
                      .map((c) => c.toConverterExpr()),
                ),
              _ => {},
            })
            .property('fromJson')
            .call([source]),
      JsonMethodConverter jsonMethodConverter =>
        TypeReference(
              (b) => b
                ..symbol = jsonMethodConverter.name
                ..url = 'package:firestore_odm/firestore_odm.dart'
                ..types.addAll(
                  jsonMethodConverter.type.typeArguments.map(
                    (t) => t.reference,
                  ),
                ),
            )
            .call([], switch (jsonMethodConverter.type) {
              InterfaceType(:final typeArguments, :final element3) =>
                Map.fromIterables(
                  element3.typeParameters2.map((t) => 'converter${t.name3}'),
                  typeArguments.map(
                    (t) => converterFactory
                        .createConverter(t)
                        .apply(jsonMethodConverter.typeParameterMapping)
                        .toConverterExpr(),
                  ),
                ),
              _ => {},
            })
            .property('fromJson')
            .call([source]),
      ModelConverter modelConverter => TypeReference(
        (b) => b
          ..symbol = modelConverter.name
          ..types.addAll(
            modelConverter.type.typeArguments.map((t) => t.reference),
          ),
      ).newInstance([]).property('fromJson').call([source]),
      _ => fromFirestore(source),
    };
  }

  Expression toJsonExpr(source) {
    return switch (this) {
      DefaultConverter defaultConverter =>
        defaultConverter._expression.property('toJson').call([source]),
      AnnotationConverter annotationConverter =>
        TypeReference(
              (b) => b
                ..symbol = annotationConverter.name
                ..url = 'package:firestore_odm/firestore_odm.dart',
            )
            .call([], switch (annotationConverter.type) {
              InterfaceType(:final typeArguments, :final element3) =>
                Map.fromIterables(
                  element3.typeParameters2.map((t) => 'converter${t.name3}'),
                  typeArguments
                      .map((t) => converterFactory.createConverter(t))
                      .map((c) => c.toConverterExpr()),
                ),
              _ => {},
            })
            .property('toJson')
            .call([source]),
      JsonMethodConverter jsonMethodConverter =>
        TypeReference(
              (b) => b
                ..symbol = jsonMethodConverter.name
                ..url = 'package:firestore_odm/firestore_odm.dart'
                ..types.addAll(
                  jsonMethodConverter.type.typeArguments.map(
                    (t) => t.reference,
                  ),
                ),
            )
            .call([], switch (jsonMethodConverter.type) {
              InterfaceType(:final typeArguments, :final element3) =>
                Map.fromIterables(
                  element3.typeParameters2.map((t) => 'converter${t.name3}'),
                  typeArguments
                      .map((t) => converterFactory.createConverter(t))
                      .map((c) => c.toConverterExpr()),
                ),
              _ => {},
            })
            .property('toJson')
            .call([source]),
      ModelConverter modelConverter => TypeReference(
        (b) => b
          ..symbol = modelConverter.name
          ..types.addAll(
            modelConverter.type.typeArguments.map((t) => t.reference),
          ),
      ).newInstance([]).property('toJson').call([source]),
      _ => toFirestore(source),
    };
  }

  Expression toConverterExpr() {
    switch (this) {
      case DirectConverter _:
        return refer('PrimitiveConverter').call([]);
      case DefaultConverter defaultConverter:
        return defaultConverter._expression;
      case AnnotationConverter annotationConverter:
        return TypeReference(
          (b) => b
            ..symbol = annotationConverter.name
            ..url = 'package:firestore_odm/firestore_odm.dart',
        ).call([], switch (annotationConverter.type) {
          InterfaceType(:final typeArguments, :final element3) =>
            Map.fromIterables(
              element3.typeParameters2.map((t) => 'converter${t.name3}'),
              typeArguments
                  .map((t) => converterFactory.createConverter(t))
                  .map((c) => c.toConverterExpr()),
            ),
          _ => {},
        });
      case JsonMethodConverter jsonMethodConverter:
        return TypeReference(
          (b) => b
            ..symbol = jsonMethodConverter.name
            ..url = 'package:firestore_odm/firestore_odm.dart',
        ).call([], switch (jsonMethodConverter.type) {
          InterfaceType(:final typeArguments, :final element3) =>
            Map.fromIterables(
              element3.typeParameters2.map((t) => 'converter${t.name3}'),
              typeArguments.map(
                (t) => converterFactory.createConverter(t).toConverterExpr(),
              ),
            ),
          _ => {},
        });
      case ModelConverter modelConverter:
        return TypeReference(
          (b) => b
            ..symbol = modelConverter.name
            ..types.addAll(
              modelConverter.type.typeArguments.map((t) => t.reference),
            ),
        ).newInstance(
          [],
          Map.fromIterables(
            modelConverter.type.element3.typeParameters2.map(
              (e) => 'converter${e.name3!}',
            ),
            modelConverter.type.typeArguments.map((type) {
              final converter = converterFactory.createConverter(type);
              return converter.toConverterExpr();
            }),
          ),
        );
      // case TypeParameterPlaceholder typeParameterPlaceholder:
      //   // For type parameters, we return a placeholder converter
      //   return refer('converter${typeParameterPlaceholder.name}');
      case NullableConverter nullableConverter:
        return TypeReference(
          (b) => b..symbol = 'NullableConverter',
        ).call([nullableConverter.inner.toConverterExpr()]);
      default:
        return TypeReference(
          (b) => b..symbol = 'FirestoreConverter',
        ).property('create').call([], {
          'fromJson': Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'data'))
              ..body = fromFirestore(refer('data')).code,
          ).closure,
          'toJson': Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'data'))
              ..body = toFirestore(refer('data')).code,
          ).closure,
        });
    }
  }

  TypeConverter withNullable(bool nullable) {
    return nullable ? NullableConverter(this) : this;
  }

  TypeConverter apply(Map<String, TypeConverter> typeArgs) {
    return switch (this) {
      TypeParameterPlaceholder type when typeArgs.containsKey(type.name) =>
        typeArgs[type.name]!,
      // If the converter is a specialized converter, we need to specialize it
      // with the type parameters of the field's Dart type
      HasSpecializedConverter specializedConverter =>
        specializedConverter.specialize(typeArgs),
      // Otherwise, use the converter as is
      _ => this,
    };
  }
}
