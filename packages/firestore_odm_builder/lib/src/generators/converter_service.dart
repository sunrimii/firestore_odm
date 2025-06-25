import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_builder/src/generators/generater.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';
import 'package:signals/signals.dart';

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

  TypeReference get fromType =>
      analysis.dartType.element?.reference ??
      TypeReferences.dynamic;
      
  TypeReference get toType => switch (analysis.firestoreType) {
    FirestoreType.string => TypeReferences.string,
    FirestoreType.integer => TypeReferences.int,
    FirestoreType.double => TypeReferences.double,
    FirestoreType.boolean => TypeReferences.bool,
    FirestoreType.timestamp => TypeReferences.timestamp,
    FirestoreType.bytes =>  TypeReferences.bytes,
    FirestoreType.geoPoint => TypeReferences.geoPoint,
    FirestoreType.reference => TypeReferences.documentReference,
    FirestoreType.array => TypeReferences.listOf(TypeReferences.dynamic),
    FirestoreType.map => TypeReferences.mapOf(
      TypeReferences.string,
      TypeReferences.dynamic,
    ),
    FirestoreType.object => TypeReferences.mapOf(
      TypeReferences.string,
      TypeReferences.dynamic,
    ),
  FirestoreType.null_ => TypeReferences.dynamic,
  };

  Expression _fromJsonBody(Expression source) {
    final dartType = analysis.dartType;
    switch (analysis.converter) {
      case UnderlyingConverter converter:
        return converter.innerConverter.generateFromFirestore(source);
      case ConverterClassConverter converter:
        return converter.generateFromFirestore(source);
      case CustomConverter converter:
        final elementConverter =
            dartType is InterfaceType && dartType.typeArguments.isNotEmpty
            ? CustomConverter(dartType.element, {
                for (var i = 0; i < analysis.typeParameters.length; i++)
                  analysis.typeParameters[i]: VariableConverterClassConverter(
                    refer('converter$i'),
                  ),
              })
            : converter;
        return elementConverter.generateFromFirestore(source);
      case JsonConverter converter:
        final elementConverter =
            dartType is InterfaceType && dartType.typeArguments.isNotEmpty
            ? JsonConverter(dartType.element3.reference, [
                for (var i = 0; i < analysis.typeParameters.length; i++)
                  VariableConverterClassConverter(refer('converter$i')),
              ], toType: converter.toType)
            : converter;
        return elementConverter.generateFromFirestore(source);
      default:
        throw ArgumentError(
          'Unsupported converter type: ${analysis.converter.runtimeType}',
        );
    }
  }

  Expression _toJsonBody(Expression source) {
    final dartType = analysis.dartType;
    switch (analysis.converter) {
      case UnderlyingConverter underlyingConverter:
        return underlyingConverter.innerConverter.generateToFirestore(source);
      case ConverterClassConverter converter:
        return converter.generateToFirestore(source);
      case CustomConverter converter:
        final elementConverter =
            dartType is InterfaceType && dartType.typeArguments.isNotEmpty
            ? CustomConverter(dartType.element, {
                for (var i = 0; i < analysis.typeParameters.length; i++)
                  analysis.typeParameters[i]: VariableConverterClassConverter(
                    refer('converter$i'),
                  ),
              })
            : converter;
        return elementConverter.generateToFirestore(source);
      case JsonConverter converter:
        final elementConverter =
            dartType is InterfaceType && dartType.typeArguments.isNotEmpty
            ? JsonConverter(dartType.element3.reference, [
                for (var i = 0; i < analysis.typeParameters.length; i++)
                  VariableConverterClassConverter(refer('converter$i')),
              ], toType: converter.toType)
            : converter;
        final expression = elementConverter.generateToFirestore(source);
        // print(
        //   'Converting $source from ${elementConverter.toType} to ${toType} (check: ${elementConverter.toType != toType})',
        // );
        return elementConverter.toType != toType
            ? expression.asA(toType)
            : expression;
      default:
        throw ArgumentError(
          'Unsupported converter type: ${analysis.converter.runtimeType}',
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

  Class toClass() {
    return Class(
      (b) => b
        ..docs.add(
          '/// Generated converter for ${analysis.dartType.element?.name}, Converter Type: ${analysis.converter.runtimeType}',
        )
        ..name = '${className}Converter'
        ..types.addAll(analysis.typeParameters)
        ..implements.add(
          TypeReference(
            (b) => b
              ..symbol = 'FirestoreConverter'
              ..types.addAll([fromType, toType]),
          ),
        )
        ..constructors.add(_buildConstructor())
        ..fields.addAll(
          analysis.typeParameters.mapIndexedAndLast(
            (i, t, l) => Field(
              (b) => b
                ..name = 'converter${i}'
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'FirestoreConverter'
                    ..types.addAll([t, refer('dynamic')]),
                )
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
              ..body = _fromJsonBody(refer('data')).code,
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
              ..body = _toJsonBody(refer('data')).code,
          ),
        ]),
    );
  }
}

/// Generator for Firestore converters for custom types
class ConverterService extends Generater {
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

  final Map<String, Class> _cache = {};
  final Map<ModelAnalysis, ConverterClassConverter> _converterCache = {};

  ConverterClassConverter get(ModelAnalysis analysis) {
    // built-in converters
    if (analysis.dartType.isDartCoreString ||
        analysis.dartType.isDartCoreInt ||
        analysis.dartType.isDartCoreDouble ||
        analysis.dartType.isDartCoreBool ||
        analysis.dartType.isDartCoreNull) {
      return BuiltInConverter.fromClassName('PrimitiveConverter');
    }

    if (analysis.dartType.isDartCoreList || analysis.dartType.isDartCoreSet) {
      final typeArguments = switch (analysis.dartType) {
        InterfaceType type => type.typeArguments,
        _ => <DartType>[],
      };
      List<TypeConverter> parameterConverters = typeArguments
          .map((t) => get(ModelAnalyzer.analyzeModel(t)))
          .toList();
      return BuiltInConverter.fromClassName(
        'ListConverter',
        parameterConverters,
      );
    }

    if (analysis.dartType.isDartCoreMap) {
      final typeArguments = switch (analysis.dartType) {
        InterfaceType type => type.typeArguments,
        _ => <DartType>[],
      };
      List<TypeConverter> parameterConverters = typeArguments
          .map((t) => get(ModelAnalyzer.analyzeModel(t)))
          .toList();
      return BuiltInConverter.fromClassName(
        'MapConverter',
        parameterConverters,
      );
    }

    if (TypeAnalyzer.isDateTimeType(analysis.dartType)) {
      return BuiltInConverter.fromClassName('DateTimeConverter');
    }

    if (TypeAnalyzer.isDurationType(analysis.dartType)) {
      return BuiltInConverter.fromClassName('DurationConverter');
    }

    if (_converterCache.containsKey(analysis)) {
      return _converterCache[analysis]!;
    }

    print('Generating converter for ${analysis.dartType.getDisplayString()}');
    final converterClass = getConverterClass(analysis);
    final typeArguments = switch (analysis.dartType) {
      InterfaceType type => type.typeArguments,
      _ => <DartType>[],
    };
    final typeConverters = typeArguments
        .map((t) {
          final analysis = ModelAnalyzer.analyzeModel(t);
          return get(analysis);
        })
        .map((c) => c.instance)
        .toList();

    _converterCache[analysis] = ConverterClassConverter(
      TypeReference(
        (b) => b
          ..symbol = converterClass.name
          ..types.addAll(typeArguments.map((t) => t.reference)),
      ).call([...typeConverters]),
    );
    return _converterCache[analysis]!;
  }

  Class getConverterClass(ModelAnalysis analysis) {
    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }
    if (_cache.containsKey(className)) {
      return _cache[className]!;
    }
    final converterClass = ConverterTemplate(analysis).toClass();
    _cache[className] = converterClass;
    print('Writing converter class for $className');
    write(converterClass);
    return converterClass;
  }
}

final converterServiceSignal = signal(ConverterService());
