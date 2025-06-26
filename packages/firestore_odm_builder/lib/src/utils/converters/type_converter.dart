// ===== Core Converter Interface =====

import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

abstract class TypeConverter {
  Expression fromFirestore(Expression source);
  Expression toFirestore(Expression source);
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
class VariableConverter implements TypeConverter {
  final String variableName;

  const VariableConverter(this.variableName);

  @override
  Expression fromFirestore(Expression source) {
    return refer(variableName).property('fromFirestore').call([source]);
  }

  @override
  Expression toFirestore(Expression source) {
    return refer(variableName).property('toFirestore').call([source]);
  }
}

/// 3. JsonConverter annotation converter
class AnnotationConverter implements TypeConverter {
  final TypeReference converterType;

  const AnnotationConverter(this.converterType);

  @override
  Expression fromFirestore(Expression source) {
    return converterType.call([]).property('fromJson').call([source]);
  }

  @override
  Expression toFirestore(Expression source) {
    return converterType.call([]).property('toJson').call([source]);
  }
}

/// 4. fromJson/toJson converter (for types with these methods)
/// This converter handles both generic and non-generic types with fromJson/toJson
class JsonMethodConverter implements TypeConverter {
  final TypeReference type;
  final List<TypeConverter> typeArgConverters;
  final bool isGeneric;

  JsonMethodConverter({required this.type, this.typeArgConverters = const []})
    : isGeneric = typeArgConverters.isNotEmpty;

  @override
  Expression fromFirestore(Expression source) {
    if (!isGeneric) {
      // Non-generic: User.fromJson(data)
      return type.property('fromJson').call([source]);
    }

    // Generic: IList<T>.fromJson(data, (e) => converter.fromFirestore(e))
    final converterLambdas = typeArgConverters
        .map(
          (converter) => Method(
            (b) => b
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'e'
                    ..type = TypeReferences.dynamic,
                ),
              )
              ..body = converter.fromFirestore(refer('e')).code
              ..lambda = true,
          ).closure,
        )
        .toList();

    return type.property('fromJson').call([source, ...converterLambdas]);
  }

  @override
  Expression toFirestore(Expression source) {
    if (!isGeneric) {
      // Non-generic: value.toJson()
      return source.property('toJson').call([]);
    }

    // Generic: value.toJson((e) => converter.toFirestore(e))
    final converterLambdas = typeArgConverters
        .map(
          (converter) => Method(
            (b) => b
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = converter.toFirestore(refer('e')).code
              ..lambda = true,
          ).closure,
        )
        .toList();

    return source.property('toJson').call(converterLambdas);
  }

  /// Create a specialized version with concrete converters
  JsonMethodConverter specialize(Map<String, TypeConverter> typeArgs) {
    final specialized = <TypeConverter>[];

    for (final converter in typeArgConverters) {
      if (converter is TypeParameterPlaceholder) {
        final replacement = typeArgs[converter.name];
        specialized.add(replacement ?? converter);
      } else {
        specialized.add(converter);
      }
    }

    return JsonMethodConverter(type: type, typeArgConverters: specialized);
  }
}

/// 5. Custom model converter (our own converter for models)
class ModelConverter implements TypeConverter {
  final InterfaceType type;
  final Map<String, FieldInfo> fields;
  final Map<String, TypeConverter> typeParameterMapping;

  const ModelConverter({
    required this.type,
    required this.fields,
    this.typeParameterMapping = const {},
  });

  TypeConverter _resolveFieldConverter(FieldInfo field) {
    final converter = converterFactory.createConverter(
      field.type,
      element: field.element,
    );

    // If it's a type parameter, check if we have a mapping
    if (converter is TypeParameterPlaceholder) {
      final mapped = typeParameterMapping[converter.name];
      if (mapped != null) return mapped;
      // Fallback to variable converter
      return VariableConverter('converter${converter.name}');
    }

    return converter;
  }

  Expression _handleNullable(
    FieldInfo field,
    Expression expression,
    Expression Function(Expression) transform,
  ) {
    if (field.isNullable) {
      return expression
          .equalTo(literalNull)
          .conditional(literalNull, transform(expression.nullChecked));
    }
    return transform(expression);
  }

  @override
  Expression fromFirestore(Expression source) {
    return type.reference.withoutNullability().newInstance(
      [],
      Map.fromEntries(
        fields.values.map(
          (field) => MapEntry(
            field.parameterName,
            _handleNullable(
              field,
              source.index(literalString(field.jsonName)),
              (expr) => _resolveFieldConverter(field).fromFirestore(expr),
            ),
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
            _handleNullable(
              field,
              source.property(field.parameterName),
              (expr) => _resolveFieldConverter(field).toFirestore(expr),
            ),
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
  final Expression type;

  const DefaultConverter(this.type);

  @override
  Expression fromFirestore(Expression source) {
    return type.property('fromJson').call([source]);
  }

  @override
  Expression toFirestore(Expression source) {
    return type.property('toJson').call([source]);
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
class TypeParameterPlaceholder implements TypeConverter {
  final String name;

  const TypeParameterPlaceholder(this.name);

  @override
  Expression fromFirestore(Expression source) {
    // This should be replaced by actual converter
    throw StateError('TypeParameterPlaceholder should be replaced before use');
  }

  @override
  Expression toFirestore(Expression source) {
    // This should be replaced by actual converter
    throw StateError('TypeParameterPlaceholder should be replaced before use');
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

  /// Create a converter for the given type, optionally using the provided element
  TypeConverter createConverter(DartType type, {Element? element}) {
    // Check cache first
    final key = (type, element);
    if (_converterCache.containsKey(key)) {
      return _converterCache[key]!;
    }

    // Create new converter
    final converter = _createConverter(type, element: element);

    // Cache it
    _converterCache[key] = converter;

    return converter;
  }

  static Expression createConverterExpression(TypeConverter converter) {
    switch (converter) {
      case DirectConverter _:
        return refer('PrimitiveConverter').call([]);
      default:
        return TypeReference(
          (b) => b..symbol = 'FirestoreConverter',
        ).property('create').call([], {
          'fromJson': Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'data'))
              ..body = converter.fromFirestore(refer('data')).code,
          ).closure,
          'toJson': Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'data'))
              ..body = converter.toFirestore(refer('data')).code,
          ).closure,
        });
    }
  }

  /// Analyze a type and create appropriate converter
  TypeConverter _createConverter(DartType type, {Element? element}) {
    // 2. Check for type parameters
    if (type is TypeParameterType) {
      return TypeParameterPlaceholder(type.element.name);
    }

    // 3. Check for @JsonConverter annotation
    final annotation = _findJsonConverterAnnotation(element);
    if (annotation != null) {
      return AnnotationConverter(annotation);
    }

    // 4. Check for fromJson/toJson methods
    if (_hasJsonMethods(type)) {
      if (type is InterfaceType) {
        // Check if it's a generic type by counting converter parameters
        final converterParamCount = _countFromJsonConverterParams(type);

        if (converterParamCount > 0) {
          // Generic type like IList<T> or IMap<K,V>
          final typeArgs = type.typeArguments
              .map((t) => createConverter(t))
              .toList();

          return JsonMethodConverter(
            type: TypeReference(
              (b) => b
                ..symbol = type.element.name
                ..types.addAll(type.typeArguments.map((p) => p.reference)),
            ),
            typeArgConverters: typeArgs,
          );
        }
      }

      // Non-generic type with fromJson/toJson
      return JsonMethodConverter(
        type: type.reference,
        typeArgConverters: const [],
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
        final typeArgs = type is ParameterizedType
            ? type.typeArguments.toList()
            : const <DartType>[];
        return DefaultConverter(
          TypeReference(
            (b) => b
              ..symbol = entry.value
              ..url = 'package:firestore_odm/firestore_odm.dart'
              ..types.addAll(typeArgs.map((t) => t.reference)),
          ).call(
            typeArgs
                .map((arg) => createConverter(arg, element: element))
                .map(createConverterExpression)
                .toList(),
          ),
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

  TypeReference? _findJsonConverterAnnotation(Element? element) {
    for (final annotation in element?.metadata ?? []) {
      final annotationType = annotation.computeConstantValue()?.type;
      if (annotationType is InterfaceType) {
        final classElement = annotationType.element;

        // Check all interfaces and superclasses
        for (final interface in classElement.allSupertypes) {
          final interfaceName = interface.element.name;
          if (interfaceName == 'JsonConverter') {
            return classElement.reference;
          }
        }
      }
    }
    return null;
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

  int _countFromJsonConverterParams(InterfaceType type) {
    final fromJson = type.element.constructors
        .where((c) => c.name == 'fromJson')
        .firstOrNull;

    if (fromJson == null) return 0;

    // Count parameters after the first one (which is the JSON data)
    return fromJson.parameters.length - 1;
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

            jsonName = reader.read('name').literalValue as String? ?? parameter.name;

            final includeFromJson = reader.read('includeFromJson').literalValue as bool? ?? true;
            final includeToJson = reader.read('includeToJson').literalValue as bool? ?? true;
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

    print(
      'Creating ModelConverter for ${type.element.name} with fields: ${fields.keys.join(', ')}',
    );

    return ModelConverter(type: type, fields: fields);
  }
}

final converterFactory = ConverterFactory();
