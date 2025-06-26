// ===== Code Generator =====

import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';

class ConverterGenerator {
  final ConverterFactory factory = ConverterFactory();

  Class generateConverterClass({
    required String className,
    required DartType type,
    required TypeConverter converter,
  }) {
    // Check if we need a generic converter class based on the converter type
    if (converter is JsonMethodConverter && converter.isGeneric) {
      return _generateGenericJsonConverter(
        className,
        type as InterfaceType,
        converter,
      );
    }

    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      return _generateGenericConverter(className, type, converter);
    }

    return _generateSimpleConverter(className, type, converter);
  }

  Class _generateGenericJsonConverter(
    String className,
    InterfaceType type,
    JsonMethodConverter converter,
  ) {
    // Generate a generic converter class like IListConverter<T>
    return Class(
      (b) => b
        ..name = '${className}Converter'
        ..types.addAll(
          type.element3.typeParameters2.map((p) => refer(p.name3!)),
        )
        ..implements.add(
          TypeReference(
            (b) => b
              ..symbol = 'FirestoreConverter'
              ..types.addAll([type.reference, refer('dynamic')]),
          ),
        )
        ..fields.addAll(
          List.generate(
            type.element3.typeParameters2.length,
            (i) => Field(
              (b) => b
                ..name = 'converter$i'
                ..type = refer(
                  'FirestoreConverter<${type.element3.typeParameters2[i].name3!}, dynamic>',
                )
                ..modifier = FieldModifier.final$,
            ),
          ),
        )
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..requiredParameters.addAll(
                List.generate(
                  type.element3.typeParameters2.length,
                  (i) => Parameter(
                    (b) => b
                      ..name = 'converter$i'
                      ..toThis = true,
                  ),
                ),
              ),
          ),
        )
        ..methods.addAll([
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'fromFirestore'
              ..returns = type.reference
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'data'
                    ..type = refer('dynamic'),
                ),
              )
              ..body = converter
                  .specialize({
                    for (
                      var i = 0;
                      i < type.element3.typeParameters2.length;
                      i++
                    )
                      type.element3.typeParameters2[i].name3!:
                          VariableConverter('converter$i'),
                  })
                  .fromFirestore(refer('data'))
                  .code,
          ),
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'toFirestore'
              ..returns = refer('dynamic')
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'value'
                    ..type = type.reference,
                ),
              )
              ..body = converter
                  .specialize({
                    for (
                      var i = 0;
                      i < type.element3.typeParameters2.length;
                      i++
                    )
                      type.element3.typeParameters2[i].name3!:
                          VariableConverter('converter$i'),
                  })
                  .toFirestore(refer('value'))
                  .code,
          ),
        ]),
    );
  }

  Class _generateSimpleConverter(
    String className,
    DartType type,
    TypeConverter converter,
  ) {
    return Class(
      (b) => b
        ..name = '${className}Converter'
        ..implements.add(
          refer('FirestoreConverter<$className, Map<String, dynamic>>'),
        )
        ..constructors.add(Constructor((b) => b..constant = true))
        ..methods.addAll([
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'fromFirestore'
              ..returns = type.reference
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'data'
                    ..type = refer('Map<String, dynamic>'),
                ),
              )
              ..body = converter.fromFirestore(refer('data')).code,
          ),
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'toFirestore'
              ..returns = refer('Map<String, dynamic>')
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'value'
                    ..type = type.reference,
                ),
              )
              ..body = converter.toFirestore(refer('value')).code,
          ),
        ]),
    );
  }

  Class _generateGenericConverter(
    String className,
    InterfaceType type,
    TypeConverter converter,
  ) {
    // Replace type parameters with variable converters
    final typeMapping = <String, TypeConverter>{};
    for (var i = 0; i < type.element3.typeParameters2.length; i++) {
      final param = type.element3.typeParameters2[i];
      typeMapping[param.name3!] = VariableConverter('converter$i');
    }

    // Specialize converter if it's a ModelConverter
    final specializedConverter = converter is ModelConverter
        ? converter.specialize(typeMapping)
        : converter;

    return Class(
      (b) => b
        ..name = '${className}Converter'
        ..types.addAll(
          type.element3.typeParameters2.map((p) => refer(p.name3!)),
        )
        ..implements.add(
          refer('FirestoreConverter<$className, Map<String, dynamic>>'),
        )
        ..fields.addAll(
          List.generate(
            type.element3.typeParameters2.length,
            (i) => Field(
              (b) => b
                ..name = 'converter$i'
                ..type = refer(
                  'FirestoreConverter<${type.element3.typeParameters2[i].name3!}, dynamic>',
                )
                ..modifier = FieldModifier.final$,
            ),
          ),
        )
        ..constructors.add(
          Constructor(
            (b) => b
              ..constant = true
              ..requiredParameters.addAll(
                List.generate(
                  type.element3.typeParameters2.length,
                  (i) => Parameter(
                    (b) => b
                      ..name = 'converter$i'
                      ..toThis = true,
                  ),
                ),
              ),
          ),
        )
        ..methods.addAll([
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'fromFirestore'
              ..returns = type.reference
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'data'
                    ..type = TypeReferences.mapOf(
                      TypeReferences.string,
                      TypeReferences.dynamic,
                    ),
                ),
              )
              ..body = specializedConverter.fromFirestore(refer('data')).code,
          ),
          Method(
            (b) => b
              ..annotations.add(refer('override'))
              ..name = 'toFirestore'
              ..returns = TypeReferences.mapOf(
                TypeReferences.string,
                TypeReferences.dynamic,
              )
              ..requiredParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'value'
                    ..type = type.reference,
                ),
              )
              ..body = specializedConverter.toFirestore(refer('value')).code,
          ),
        ]),
    );
  }
}

final ConverterGenerator converterGenerator = ConverterGenerator();
