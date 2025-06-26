// import 'package:analyzer/dart/element/type.dart';
// import 'package:code_builder/code_builder.dart';
// import 'package:fast_immutable_collections/fast_immutable_collections.dart';
// import 'package:firestore_odm_builder/src/generators/generater.dart';
// import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
// import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
// import '../utils/model_analyzer.dart';
// import 'package:signals/signals.dart';

// abstract class Template {
//   String toString();
// }

// class ConverterTemplate implements Template {
//   final String className;
//   final TypeConverter converter;
//   final TypeReference fromType;
//   final TypeReference toType;
//   final List<TypeReference> typeParameters;

//   const ConverterTemplate({
//     required this.className,
//     required this.fromType,
//     required this.toType,
//     required this.converter,
//     required this.typeParameters,
//   });

//   Expression _fromJsonBody(Expression source) {
//     switch (converter) {
//       case GenericConverter converter:
//         final elementConverter = typeParameters.isNotEmpty
//             ? converter
//                   .toGeneric([
//                     for (var i = 0; i < typeParameters.length; i++)
//                       GenericTypeConverter(fromType: typeParameters[i]),
//                   ])
//                   .applyConverters({
//                     for (var i = 0; i < typeParameters.length; i++)
//                       typeParameters[i]: VariableConverterClassConverter(
//                         variableReference: refer('converter$i'),
//                         fromType: typeParameters[i],
//                         toType: TypeReferences.dynamic,
//                       ),
//                   })
//             : converter;
//         return elementConverter.generateFromFirestore(source);
//       default:
//         return converter.generateFromFirestore(source);
//     }
//   }

//   Expression _toJsonBody(Expression source) {
//     switch (converter) {
//       case GenericConverter converter:
//         final elementConverter = typeParameters.isNotEmpty
//             ? converter
//                   .toGeneric([
//                     for (var i = 0; i < typeParameters.length; i++)
//                       GenericTypeConverter(fromType: typeParameters[i]),
//                   ])
//                   .applyConverters({
//                     for (var i = 0; i < typeParameters.length; i++)
//                       typeParameters[i]: VariableConverterClassConverter(
//                         variableReference: refer('converter$i'),
//                         fromType: typeParameters[i],
//                         toType: TypeReferences.dynamic,
//                       ),
//                   })
//             : converter;
//         final expression = elementConverter.generateToFirestore(source);
//         // print(
//         //   'Converting $source from ${elementConverter.toType} to ${toType} (check: ${elementConverter.toType != toType})',
//         // );
//         return elementConverter.toType != toType
//             ? expression.asA(toType)
//             : expression;
//       default:
//         return converter.generateToFirestore(source);
//     }
//   }

//   Constructor _buildConstructor() {
//     return Constructor(
//       (b) => b
//         ..constant = true
//         ..requiredParameters.addAll(
//           List.generate(
//             typeParameters.length,
//             (i) => Parameter(
//               (b) => b
//                 ..name = 'converter$i'
//                 ..toThis = true,
//             ),
//           ),
//         ),
//     );
//   }

//   Class toClass() {
//     return Class(
//       (b) => b
//         ..docs.add(
//           '/// Generated converter for ${className}, Converter Type: ${converter.runtimeType}',
//         )
//         ..name = '${className}Converter'
//         ..types.addAll(typeParameters)
//         ..implements.add(
//           TypeReference(
//             (b) => b
//               ..symbol = 'FirestoreConverter'
//               ..types.addAll([fromType, toType]),
//           ),
//         )
//         ..constructors.add(_buildConstructor())
//         ..fields.addAll(
//           typeParameters.mapIndexedAndLast(
//             (i, t, l) => Field(
//               (b) => b
//                 ..name = 'converter${i}'
//                 ..type = TypeReference(
//                   (b) => b
//                     ..symbol = 'FirestoreConverter'
//                     ..types.addAll([t, refer('dynamic')]),
//                 )
//                 ..modifier = FieldModifier.final$,
//             ),
//           ),
//         )
//         ..methods.addAll([
//           Method(
//             (b) => b
//               ..annotations.add(refer('override'))
//               ..name = 'fromFirestore'
//               ..returns = fromType
//               ..requiredParameters.add(
//                 Parameter(
//                   (b) => b
//                     ..name = 'data'
//                     ..type = toType,
//                 ),
//               )
//               ..body = _fromJsonBody(refer('data')).code,
//           ),
//           Method(
//             (b) => b
//               ..annotations.add(refer('override'))
//               ..name = 'toFirestore'
//               ..returns = toType
//               ..requiredParameters.add(
//                 Parameter(
//                   (b) => b
//                     ..name = 'data'
//                     ..type = fromType,
//                 ),
//               )
//               ..body = _toJsonBody(refer('data')).code,
//           ),
//         ]),
//     );
//   }
// }

// /// Generator for Firestore converters for custom types
// class ConverterService extends Generater {
//   final Map<String, Class> _cache = {};
//   final Map<ModelAnalysis, DefaultConverter> _converterCache = {};

//   DefaultConverter get(ModelAnalysis analysis) {
//     if (analysis.converter is DefaultConverter) {
//       return analysis.converter as DefaultConverter;
//     }

//     if (_converterCache.containsKey(analysis)) {
//       return _converterCache[analysis]!;
//     }

//     final converterClass = getConverterClass(analysis);
//     final typeArguments = switch (analysis.dartType) {
//       InterfaceType type => type.typeArguments,
//       _ => <DartType>[],
//     };
//     final parameterConverters = [
//       for (var t in typeArguments) get(ModelAnalyzer.analyze(t)),
//     ];

//     _converterCache[analysis] = DefaultConverter(
//       reference: TypeReference((b) => b..symbol = converterClass.name)
//           .newInstance(
//             analysis.converter is AnnotationConverter
//                 ? []
//                 : parameterConverters.map((c) => c.reference).toList(),
//           ),
//       elementConverters: parameterConverters,
//       fromType:
//           converterClass.methods
//                   .firstWhere((m) => m.name == 'fromFirestore')
//                   .returns!
//                   .type
//               as TypeReference,
//       toType:
//           converterClass.methods
//                   .firstWhere((m) => m.name == 'toFirestore')
//                   .returns!
//                   .type
//               as TypeReference,
//     );
//     return _converterCache[analysis]!;
//   }

//   Class getConverterClass(ModelAnalysis analysis) {
//     final className = analysis.converter is AnnotationConverter
//         ? (analysis.converter as AnnotationConverter).reference.symbol
//         : analysis.dartType.element3?.name3;
//     if (className == null) {
//       throw ArgumentError(
//         'ModelAnalysis must have a valid Dart type element or converter.',
//       );
//     }
//     if (_cache.containsKey(className)) {
//       return _cache[className]!;
//     }

//     final converterClass = analysis.converter is AnnotationConverter
//         ? ConverterTemplate(
//             className: className,
//             fromType: analysis.dartType.reference,
//             toType: (analysis.converter as AnnotationConverter).toType,
//             converter: analysis.converter as AnnotationConverter,
//             typeParameters:
//                 [], // AnnotationConverter does not use type parameters
//           ).toClass()
//         : ConverterTemplate(
//             className: className,
//             fromType:
//                 analysis.dartType.element3?.reference ?? TypeReferences.dynamic,
//             toType: analysis.firestoreType,
//             converter: analysis.converter,
//             typeParameters: analysis.typeParameters,
//           ).toClass();
//     _cache[className] = converterClass;
//     print('Generated converter class: $className');
//     write(converterClass);
//     return converterClass;
//   }
// }

// final converterServiceSignal = signal(ConverterService());
