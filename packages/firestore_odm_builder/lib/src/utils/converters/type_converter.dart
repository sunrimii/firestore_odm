// ===== Core Converter Interface =====

import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
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
