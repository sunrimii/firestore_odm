import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import '../utils/model_analyzer.dart';
import '../utils/string_helpers.dart';

abstract class Template {
  String toString();
}

class ConverterTemplate implements Template {
  const ConverterTemplate(this.analysis);

  final ModelAnalysis analysis;

  String get className {
    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('Type analysis must have a valid Dart type name');
    }
    return className;
  }

  String get classTypeParametersString {
    final typeParams = List.generate(
      analysis.typeParameters.length,
      (i) => 'T$i, R$i',
    );
    if (typeParams.isEmpty) return '';
    return '<${typeParams.join(', ')}>';
  }

  String get typeParametersString {
    final typeParams = List.generate(
      analysis.typeParameters.length,
      (i) => 'T$i',
    );
    if (typeParams.isEmpty) return '';
    return '<${typeParams.join(', ')}>';
  }

  TypeReference get fromType => analysis.dartType.reference;
  String get toTypeName => switch (analysis.firestoreType) {
    FirestoreType.string => 'String',
    FirestoreType.integer => 'int',
    FirestoreType.double => 'double',
    FirestoreType.boolean => 'bool',
    FirestoreType.timestamp => 'Timestamp',
    FirestoreType.bytes => 'Uint8List',
    FirestoreType.geoPoint => 'GeoPoint',
    FirestoreType.reference => 'DocumentReference',
    FirestoreType.array => 'List<dynamic>',
    FirestoreType.map => 'Map<String, dynamic>',
    FirestoreType.object => 'Map<String, dynamic>',
    FirestoreType.null_ => 'dynamic',
  };
  TypeReference get toType => TypeReference(
    (b) => b
      ..symbol = toTypeName
  );

  static Expression _fromJsonBody(TypeConverter converter, Expression source) {
    switch (converter) {
      case UnderlyingConverter underlyingConverter:
        return underlyingConverter.innerConverter.generateFromFirestore(source);
      case ConverterClassConverter converterClassConverter:
        return converterClassConverter.generateFromFirestore(source);
      case JsonConverter jsonConverter:
        return jsonConverter.handler.fromJson(
          converter.dartType,
          source,
          List.generate(
            converter.elementConverters.length,
            (i) => VariableConverterClassConverter(refer('converter$i')),
          ),
        );
      default:
        throw ArgumentError(
          'Unsupported converter type: ${converter.runtimeType}',
        );
    }
  }

  static Expression _toJsonBody(TypeConverter converter, Expression source) {
    switch (converter) {
      case UnderlyingConverter underlyingConverter:
        return underlyingConverter.innerConverter.generateToFirestore(source);
      case ConverterClassConverter converterClassConverter:
        return converterClassConverter.generateToFirestore(source);
      case JsonConverter jsonConverter:
        return jsonConverter.handler.toJson(
          converter.dartType,
          source,
          List.generate(
            converter.elementConverters.length,
            (i) => VariableConverterClassConverter(refer('converter$i')),
          ),
        );
      default:
        throw ArgumentError(
          'Unsupported converter type: ${converter.runtimeType}',
        );
    }
  }

  Constructor _buildConstructor() {
    return Constructor(
      (b) => b
        ..constant = true
        ..requiredParameters.addAll(
          List.generate(
            analysis.typeParameters.length,
            (i) => Parameter(
              (b) => b
                ..name = 'converter$i'
                ..toThis = true,
            ),
          ),
        ),
    );
  }

  List<Reference> _buildTypeParameters() {
    return List.generate(analysis.typeParameters.length, (i) => refer('T$i'));
  }

  Class toClass() {
    return Class(
      (b) => b
        ..docs.add('/// Generated converter for ${analysis.dartType.element?.name}')
        ..name = '${className}Converter'
        ..types.addAll(_buildTypeParameters()) // 用 types 屬性
        ..implements.add(TypeReference(
          (b) => b
            ..symbol = 'FirestoreConverter'
            ..types.addAll([fromType, refer(toTypeName)]),
        ))
        ..constructors.add(_buildConstructor())
        ..fields.addAll(
          List.generate(
            analysis.typeParameters.length,
            (i) => Field(
              (b) => b
                ..name = 'converter$i'
                ..type = refer('FirestoreConverter<T$i, dynamic>')
                ..modifier = FieldModifier.final$,
            ),
          ),
        )
        ..methods.addAll([
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'fromFirestore'
              ..returns = fromType
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'data'
                    ..type = toType,
                ),
              )
              ..body = _fromJsonBody(analysis.converter, refer('data')).code,
          ),
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'toFirestore'
              ..returns = toType
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'data'
                    ..type = fromType,
                ),
              )
              ..body = _toJsonBody(analysis.converter, refer('data')).asA(toType).code,
          ),
        ]),
    );
  }

  @override
  String toString() {
    return toClass().accept(DartEmitter()).toString();
  }
}

/// Generator for Firestore converters for custom types
class ConverterGenerator {
  static Field generateConverterVariable(
    String name,
    ModelAnalysis analysis,
    TypeConverter converter,
  ) {
    final fromType = analysis.dartType.reference;
    final toTypeName = switch (analysis.firestoreType) {
      FirestoreType.string => 'String',
      FirestoreType.integer => 'int',
      FirestoreType.double => 'double',
      FirestoreType.boolean => 'bool',
      FirestoreType.timestamp => 'Timestamp',
      FirestoreType.bytes => 'Uint8List',
      FirestoreType.geoPoint => 'GeoPoint',
      FirestoreType.reference => 'DocumentReference',
      FirestoreType.array => 'List<dynamic>',
      FirestoreType.map => 'Map<String, dynamic>',
      FirestoreType.object => 'Map<String, dynamic>',
      FirestoreType.null_ => 'dynamic',
    };
    return Field(
      (b) => b
        ..docs.add('/// Converter for $name')
        ..name = '_\$${name.lowerFirst()}Converter'
        ..modifier = FieldModifier.final$
        ..assignment =
            TypeReference(
              (b) => b
                ..symbol = 'DefaultConverter'
                ..types.addAll([fromType, refer(toTypeName)]),
            ).call([], {
              'fromJson': Method(
                (b) => b
                  ..lambda = true
                  ..requiredParameters.add(Parameter((b) => b..name = 'data'))
                  ..body = fromType.property('fromJson').call([
                    refer('data'),
                  ]).code,
              ).closure,
              'toJson': Method(
                (b) => b
                  ..lambda = true
                  ..requiredParameters.add(Parameter((b) => b..name = 'data'))
                  ..body = refer('data').property('toJson').call([]).code,
              ).closure,
            }).code,
    );
  }

  /// Generate converters for custom types discovered through type analysis
  static String generateConvertersForCustomTypes(
    Map<String, ModelAnalysis> typeAnalyses,
  ) {
    final buffer = StringBuffer();
    final seen = <String>{};

    for (final analysis in typeAnalyses.values) {
      final converter = analysis.converter;
      final classname = analysis.dartType.element?.name;
      if (classname == null) continue;
      if (seen.contains(classname)) continue;
      seen.add(classname);

      if (converter is ConverterClassConverter ||
          converter is NullableConverter)
        continue;
      buffer.write(
        ConverterTemplate(analysis).toClass().accept(DartEmitter()).toString(),
      );
      // buffer.write(generateConverterVariable(classname, analysis, converter).accept(DartEmitter()).toString());

      // for (final typeConverter in runAllConverters(converter)) {
      //   if (seen.contains(typeConverter)) continue;

      //   seen.add(typeConverter);

      //   // Skip if the type is primitive or has no converter
      //   if (typeConverter is ConverterClassConverter) continue;

      //   buffer.write(generateConverterVariable(typeConverter).accept(DartEmitter()).toString());

      //   // Generate converter class for this type
      //   // buffer.write(generateConverterVariable(typeAnalysis));
      // }
    }

    return buffer.toString();
  }

  static Iterable<TypeConverter> runAllConverters(
    TypeConverter converter,
  ) sync* {
    yield converter;
    switch (converter) {
      case UnderlyingConverter underlyingConverter:
        yield* runAllConverters(underlyingConverter.innerConverter);
        break;
      case ConverterClassConverter converterClassConverter:
        for (final elementConverter
            in converterClassConverter.parameterConverters) {
          yield* runAllConverters(elementConverter);
        }
        break;
      case JsonConverter jsonConverter:
        for (final elementConverter in jsonConverter.elementConverters) {
          yield* runAllConverters(elementConverter);
        }
        break;
      default:
    }
  }
}
