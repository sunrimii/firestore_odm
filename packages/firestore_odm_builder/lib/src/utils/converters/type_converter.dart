// ===== Core Converter Interface =====

import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

sealed class TypeConverter {
  // TypeReference fromType = TypeReferences.dynamic;
  // TypeReference toType = TypeReferences.dynamic;
  Expression fromFirestore(Expression source);
  Expression toFirestore(Expression source);
}

abstract class MaybeGeneric {
  Map<String, TypeConverter> get typeParameterMapping;

  /// Apply the type arguments to the converter
  TypeConverter apply(Map<String, TypeConverter> typeArgs);
}

abstract class WithName implements TypeConverter {
  /// The name of the converter, used for generating code
  String get name;
  InterfaceType get type;
  WithName get baseConverter;
  // List<DartType> get typeArguments;
  // List<TypeParameterElement> get typeParameters;
  TypeReference get fromType;
  TypeReference get toType;
  TypeReference get expectType;
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
  final InterfaceType type;

  String get name => '_\$${type.element3.name3}AnnotationConverter';
  WithName get baseConverter => AnnotationConverter(type.element.thisType);

  List<TypeParameterElement> get typeParameters => [];
  List<DartType> get typeArguments => [];

  TypeReference get fromType =>
      type.getMethod2('fromJson')!.returnType.reference;

  TypeReference get toType => type.getMethod2('toJson')!.returnType.reference;
  TypeReference get expectType => toType;

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
class JsonMethodConverter implements TypeConverter, WithName, MaybeGeneric {
  final InterfaceType type;
  final Map<String, TypeConverter> typeParameterMapping;
  WithName get baseConverter => JsonMethodConverter(type: type);

  String get name => '_\$${type.element3.name3}JsonConverter';

  List<DartType> get typeArguments => type.typeArguments.toList();

  List<TypeParameterElement> get typeParameters => type.typeParameters;

  TypeReference get fromType => type.element3.reference;

  TypeReference get toType =>
      type.lookUpMethod3('toJson', type.element3.library2)?.returnType.reference ??
      TypeReferences.dynamic;

  TypeReference get expectType => 
      TypeChecker.fromRuntime(Iterable).isAssignableFromType(type)
      ? TypeReferences.listOf(TypeReferences.dynamic)
      : TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);

  const JsonMethodConverter({
    required this.type,
    this.typeParameterMapping = const {},
  });

  TypeConverter _transform(DartType type) {
    return ConverterFactory.instance
        .getConverter(type)
        .apply(typeParameterMapping);
  }

  @override
  Expression fromFirestore(Expression source) {
    // Generic: IList<T>.fromJson(data, (e) => converter.fromFirestore(e))
    final converterLambdas = type.typeArguments
        .map(_transform)
        .map(
          (converter) => Method(
            (b) => b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = converter.fromFirestore(refer('e')).code
              ..lambda = true,
          ).closure,
        );
    return type.element3.reference.property('fromJson').call([
      source,
      ...converterLambdas,
    ]);
  }

  @override
  Expression toFirestore(Expression source) {
    // Generic: IList<T>.toJson(data, (e) => converter.toFirestore(e))
    final converterLambdas = type.typeArguments
        .map(_transform)
        .map(
          (converter) => Method(
            (b) => b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = converter.toFirestore(refer('e')).code
              ..lambda = true,
          ).closure,
        );
    return source.property('toJson').call([...converterLambdas]);
  }

  /// Create a specialized version with concrete converters
  JsonMethodConverter apply(Map<String, TypeConverter> typeArgs) {
    return JsonMethodConverter(
      type: type.element.thisType,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

/// 5. Custom model converter (our own converter for models)
class ModelConverter implements TypeConverter, WithName, MaybeGeneric {
  final InterfaceType type;
  final Map<String, TypeConverter> typeParameterMapping;

  String get name => '_\$${type.element.name}ModelConverter';
  WithName get baseConverter => ModelConverter(
    type: type.element3.thisType,
    typeParameterMapping: typeParameterMapping,
  );
  List<TypeParameterElement> get typeParameters => type.typeParameters;

  TypeReference get fromType => type.element3.reference;
  TypeReference get toType =>
      TypeChecker.fromRuntime(Iterable).isAssignableFromType(type)
      ? TypeReferences.listOf(TypeReferences.dynamic)
      : TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);

  TypeReference get expectType => toType;

  List<DartType> get typeArguments => type.typeArguments.toList();

  ModelConverter({required this.type, this.typeParameterMapping = const {}});

  TypeConverter _transform(DartType fieldType, Element? element) {
    return ConverterFactory.instance
        .getConverter(fieldType, element: element)
        .apply(typeParameterMapping);
  }

  late final Map<String, FieldInfo> fields = ModelAnalyzer.instance.getFields(
    type,
  );

  @override
  Expression fromFirestore(Expression source) {
    return type.reference.withoutNullability().newInstance(
      [],
      Map.fromEntries(
        fields.values.map((field) {
          return MapEntry(
            field.parameterName,
            _transform(field.type, field.element)
                .withNullable(field.isNullable)
                .fromFirestore(source.index(literalString(field.jsonName)))
                .asA(field.type.reference),
          );
        }),
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
                .toFirestore(source.property(field.parameterName)),
          ),
        ),
      ),
    );
  }

  /// Create a specialized version with type parameters replaced
  ModelConverter apply(Map<String, TypeConverter> typeArgs) {
    return ModelConverter(
      type: type.element3.thisType,
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
    implements MaybeGeneric {
  SpecializedDefaultConverter(
    this.expressionFunc, {
    this.typeParameterMapping = const {},
  }) : super(expressionFunc(typeParameterMapping));

  final Expression Function(Map<String, TypeConverter>) expressionFunc;
  final Map<String, TypeConverter> typeParameterMapping;

  @override
  TypeConverter apply(Map<String, TypeConverter> typeArgs) {
    return SpecializedDefaultConverter(
      expressionFunc,
      typeParameterMapping: typeArgs,
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
class TypeParameterPlaceholder implements TypeConverter, MaybeGeneric {
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
    return refer(
      '/* Unresolved type parameter */ ${source.accept(DartEmitter())}',
    );
  }

  @override
  Expression toFirestore(Expression source) {
    if (typeParameterMapping.containsKey(name)) {
      // Use the mapped converter if available
      return typeParameterMapping[name]!.toFirestore(source);
    }
    // Fallback to using the raw data as-is for unresolved type parameters
    print('Warning: Using fallback for unresolved type parameter $name');
    return refer(
      '/* Unresolved type parameter */ ${source.accept(DartEmitter())}',
    );
  }

  @override
  TypeConverter apply(Map<String, TypeConverter> typeArgs) {
    return TypeParameterPlaceholder(
      name,
      typeParameterMapping: {...typeParameterMapping, ...typeArgs},
    );
  }
}

final converterFactory = ConverterFactory.instance;

extension TypeConverterExtensions on TypeConverter {
  Expression toConverterExpr() {
    switch (this) {
      case DirectConverter _:
        return refer('PrimitiveConverter').constInstance([]);
      case DefaultConverter defaultConverter:
        return defaultConverter._expression;
      case NullableConverter nullableConverter:
        return TypeReference(
          (b) => b..symbol = 'NullableConverter',
        ).call([nullableConverter.inner.toConverterExpr()]);

      case TypeParameterPlaceholder typeParam:
        return refer(
          'null as dynamic /* Unresolved type parameter ${typeParam.name} */',
        );
      case WithName converter:
        return converter
            .apply(
              Map.fromIterables(
                converter.type.element3.typeParameters2.map((e) => e.name3!),
                converter.type.typeArguments.map(
                  (e) => converterFactory.getConverter(e),
                ),
              ),
            )
            .toConverterExpr();
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

  TypeConverter apply([Map<String, TypeConverter> typeArgs = const {}]) {
    return switch (this) {
      TypeParameterPlaceholder type when typeArgs.containsKey(type.name) =>
        typeArgs[type.name]!,
      // If the converter is a specialized converter, we need to specialize it
      // with the type parameters of the field's Dart type
      MaybeGeneric specializedConverter => specializedConverter.apply({
        ...specializedConverter.typeParameterMapping,
        ...typeArgs,
      }),
      // Otherwise, use the converter as is
      _ => this,
    };
  }
}
