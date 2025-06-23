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

  String get fromTypeName => '${className}${typeParametersString}';
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

  List<Field> _buildFields() {
    return List.generate(
      analysis.typeParameters.length,
      (i) => Field(
        (b) => b
          ..name = 'converter$i'
          ..type = refer('FirestoreConverter<T$i, dynamic>')
          ..modifier = FieldModifier.final$,
      ),
    );
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

  List<Method> _buildMethods() {
    return [_buildFromFirestoreMethod(), _buildToFirestoreMethod()];
  }

  Method _buildFromFirestoreMethod() {
    return Method(
      (b) => b
        ..name = 'fromFirestore'
        ..annotations.add(refer('override'))
        ..returns = refer(fromTypeName)
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'data'
              ..type = refer(toTypeName),
          ),
        )
        ..body = analysis.converter
            .generateFromFirestore(refer('data'))
            .returned
            .statement,
    );
  }

  Method _buildToFirestoreMethod() {
    return Method(
      (b) => b
        ..name = 'toFirestore'
        ..annotations.add(refer('override'))
        ..returns = refer(toTypeName)
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'data'
              ..type = refer(fromTypeName),
          ),
        )
        ..body = analysis.converter
            .generateToFirestore(refer('data'))
            .returned
            .statement,
    );
  }

  List<Reference> _buildTypeParameters() {
    return List.generate(analysis.typeParameters.length, (i) => refer('T$i'));
  }

  
  Class toClass() {
    return Class(
      (b) => b
        ..name = '${className}Converter'
        ..types.addAll(_buildTypeParameters()) // 用 types 屬性
        ..implements.add(
          refer('FirestoreConverter<$fromTypeName, $toTypeName>'),
        )
        ..docs.add('/// Generated converter for $className')
        ..fields.addAll(_buildFields())
        ..constructors.add(_buildConstructor())
        ..methods.addAll(_buildMethods()),
    );
  }

  @override
  String toString() {
    return toClass().accept(DartEmitter()).toString();
  }
}

/// Generator for Firestore converters for custom types
class ConverterGenerator {
  /// Generate converters for custom types discovered through type analysis
  static String generateConvertersForCustomTypes(
    Map<String, ModelAnalysis> typeAnalyses,
  ) {
    final buffer = StringBuffer();
    final seen = <TypeConverter>{};

    for (final typeAnalysis in typeAnalyses.values) {
      final converter = typeAnalysis.converter;
      for (final typeConverter in runAllConverters(converter)) {
        print(
          'DEBUG: Found converter $typeConverter for ${typeAnalysis.dartType.getDisplayString(withNullability: false)}',
        );
        if (seen.contains(typeConverter)) continue;

        seen.add(typeConverter);

        // Skip if the type is primitive or has no converter
        if (typeConverter is ConverterClassConverter) continue;

        // Generate converter class for this type
        buffer.write(ConverterTemplate(typeAnalysis));
      }
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
