import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

class ConverterFactory {
  static final ConverterFactory instance = ConverterFactory._internal();

  ConverterFactory._internal();

  final Map<(DartType, Element?), TypeConverter> _baseConverterCache = {};
  final List<Spec> _modelConverters = [];

  /// Create a converter for the given type, optionally using the provided element
  TypeConverter getConverter(
    DartType type, {
    Element? element,
    bool raw = false,
  }) {
    final baseConverter = _baseConverterCache.putIfAbsent(
      (type, element),
      () => _tryConvertToDefaultConverter(
        _createConverter(type, element: element),
      ),
    );
    return raw ? baseConverter : _tryConvertToDefaultConverter(baseConverter);
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
    if (type is InterfaceType && _hasJsonMethods(type)) {
      return JsonMethodConverter(type: type);
    }

    // 1. Check for primitives
    if (isPrimitive(type)) {
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
          (typeParameterMapping) =>
              TypeReference(
                    (b) => b
                      ..symbol = entry.value
                      ..url = 'package:firestore_odm/firestore_odm.dart'
                      ..types.addAll(
                        type.typeArguments.map((t) => t.reference),
                      ),
                  )
                  .call(
                    type.typeArguments
                        .map(
                          (t) => getConverter(
                            t,
                          ).apply(typeParameterMapping).toConverterExpr(),
                        )
                        .toList(),
                  )
                  .debug('${typeParameterMapping}'),
        );
      }
    }

    // 5. Create custom model converter
    if (type is InterfaceType) {
      return ModelConverter(type: type);
    }

    throw UnimplementedError('No converter for type: $type');
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

  bool _hasJsonMethods(InterfaceType type) {
    // Check if type has fromJson factory and toJson method
    final fromJson = type.lookUpConstructor2(
      'fromJson',
      type.element3.library2,
    );
    final toJson = type.lookUpMethod3('toJson', type.element3.library2);

    return fromJson != null && toJson != null;
  }

  List<Spec> get specs {
    // Return all model converter specs
    return _modelConverters;
  }

  TypeConverter _tryConvertToDefaultConverter(TypeConverter converter) {
    return switch (converter) {
      DefaultConverter defaultConverter => defaultConverter,
      NullableConverter nullableConverter => NullableConverter(
        _tryConvertToDefaultConverter(nullableConverter.inner),
      ),
      WithName withName => _toDefaultConverter(withName),
      _ => converter,
    };
  }

  final Set<String> _generated3 = {};
  DefaultConverter _toDefaultConverter(WithName converter) {
    if (!_generated3.contains(converter.name)) {
      final baseConverter = converter.baseConverter;
      _generateConverter(
        baseConverter.apply(
          Map.fromIterables(
            baseConverter.type.element3.typeParameters2.map((e) => e.name3!),
            baseConverter.type.element3.typeParameters2.map(
              (e) => VariableConverter('converter${e.name3!}'),
            ),
          ),
        ),
        typeParameters: baseConverter.type.element3.typeParameters2.references,
        fromType: baseConverter.fromType,
        toType: baseConverter.expectType,
        cast: baseConverter.toType != baseConverter.expectType,
        docs: ['//Generated converter for `${baseConverter.type}`'],
      );
      _generated3.add(baseConverter.name);
    }
    return SpecializedDefaultConverter((typeParameterMapping) {
      final type = TypeReference(
        (b) => b
          ..symbol = (converter).name
          ..types.addAll(converter.type.typeArguments.map((v) => v.reference)),
      );
      final namedArguments = Map.fromIterables(
        converter.type.element3.typeParameters2.map(
          (e) => 'converter${e.name3!}',
        ),
        converter.type.typeArguments.map(
          (e) => getConverter(e).apply(typeParameterMapping).toConverterExpr(),
        ),
      );
      final isConst = !converter.type.typeArguments.any(
        (t) => t is TypeParameterType,
      );
      return isConst
          ? type.constInstance([], namedArguments)
          : type
                .newInstance([], namedArguments)
                .debug('${typeParameterMapping}');
    });
  }

  final Set<TypeConverter> _generated = {};

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
          ..name = converter.name
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
                ..constant = true
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
                ..requiredParameters.add(
                  Parameter(
                    (b) => b
                      ..name = 'data'
                      ..type = toTypeResult,
                  ),
                )
                ..body = converter.fromFirestore(refer('data')).code,
            ),
            Method(
              (b) => b
                ..name = 'toJson'
                ..annotations.add(refer('override'))
                ..returns = toTypeResult
                ..requiredParameters.add(
                  Parameter(
                    (b) => b
                      ..name = 'value'
                      ..type = fromTypeResult,
                  ),
                )
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
