import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';
import '../utils/model_analyzer.dart';

/// Generator for update builders and related classes using code_builder
class ConverterGenerator {
  static TypeReference getJsonType({required DartType type}) {
    if (isPrimitive(type)) {
      return type.reference;
    }

    if (TypeChecker.fromRuntime(DateTime).isAssignableFromType(type)) {
      return TypeReferences.timestamp;
    }
    if (TypeChecker.fromRuntime(Iterable).isAssignableFromType(type)) {
      return TypeReferences.listOf(getJsonType(type: type.typeArguments.first));
    }

    if (TypeChecker.fromRuntime(Map).isAssignableFromType(type) ||
        TypeChecker.fromRuntime(IMap).isAssignableFromType(type)) {
      return TypeReferences.mapOf(
        TypeReferences.string,
        getJsonType(type: type.typeArguments.last),
      );
    }

    if (type is InterfaceType) {
      return TypeReferences.mapOf(
        TypeReferences.string,
        TypeReferences.dynamic,
      );
    }

    return TypeReferences.dynamic;
  }

  static Expression callToJson({
    required DartType type,
    required Expression value,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    if (typeConverters.containsKey(type)) {
      // If a type converter is provided, use it directly
      return typeConverters[type]!.call([value]);
    }

    if (isPrimitive(type)) {
      return value.asA(getJsonType(type: type));
    }

    if (TypeChecker.fromRuntime(DateTime).isAssignableFromType(type)) {
      return refer('const DateTimeConverter().toJson').call([value]);
    }

    if (TypeChecker.fromRuntime(List).isAssignableFromType(type)) {
      return refer('listToJson').call([
        value,
        getToJsonEnsured(
          type: type.typeArguments.first,
          typeConverters: typeConverters,
        ),
      ]);
    }

    if (TypeChecker.fromRuntime(Map).isAssignableFromType(type)) {
      return refer('mapToJson').call([
        value,
        getToJsonEnsured(
          type: type.typeArguments.first,
          typeConverters: typeConverters,
        ),
        getToJsonEnsured(
          type: type.typeArguments.last,
          typeConverters: typeConverters,
        ),
      ]);
    }

    if (type is InterfaceType) {
      final expectedType = getJsonType(type: type);

      final toJson = type.lookUpMethod3('toJson', type.element3.library2);
      if (toJson != null) {
        final args = [
          for (final type in type.typeArguments)
            getToJsonEnsured(type: type, typeConverters: typeConverters),
        ];
        final actualType = toJson.returnType.reference;
        final invokeExp = value.property('toJson').call(args);
        // If the type has a toJson method, use it directly
        return (actualType != expectedType
            ? invokeExp.asA(expectedType)
            : invokeExp);
      }

      return TypeReference(
        (b) => b
          ..symbol = '\$${type.element3.name3}ToJson'.lowerFirst()
          ..types.addAll(type.typeArguments.map((t) => t.reference)),
      ).call([
        value,
        for (final typeParam in type.element3.typeParameters2)
          typeConverters[typeParam] ??
              getToJsonEnsured(
                type:
                    type.typeArguments[type.element3.typeParameters2.indexOf(
                      typeParam,
                    )],
                typeConverters: typeConverters,
              ),
      ]);
    }

    return value; // refer('(value) => value');
  }

  static Expression callFromJson({
    required DartType type,
    required Expression value,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    if (typeConverters.containsKey(type)) {
      // If a type converter is provided, use it directly
      return typeConverters[type]!.call([value]);
    }

    if (isPrimitive(type)) {
      return value.asA(type.reference);
    }

    if (TypeChecker.fromRuntime(DateTime).isAssignableFromType(type)) {
      return refer('const DateTimeConverter().fromJson').call([value]);
    }

    if (TypeChecker.fromRuntime(List).isAssignableFromType(type)) {
      return refer('listFromJson').call([
        value.asA(TypeReferences.listOf(TypeReferences.dynamic)),
        getFromJsonEnsured(
          type: type.typeArguments.first,
          typeConverters: typeConverters,
        ),
      ]);
    }

    if (TypeChecker.fromRuntime(Map).isAssignableFromType(type)) {
      return refer('mapFromJson').call([
        value.asA(
          TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic),
        ),
        getFromJsonEnsured(
          type: type.typeArguments.first,
          typeConverters: typeConverters,
        ),
        getFromJsonEnsured(
          type: type.typeArguments.last,
          typeConverters: typeConverters,
        ),
      ]);
    }

    if (type is InterfaceType) {
      final expectedType = type.reference;

      final fromJson = type.lookUpConstructor2(
        'fromJson',
        type.element3.library2,
      );
      if (fromJson != null) {
        final args = [
          for (final type in type.typeArguments)
            getFromJsonEnsured(type: type, typeConverters: typeConverters),
        ];
        final actualType = fromJson.returnType.reference;
        final invokeExp = type.reference.property('fromJson').call([
          value,
          ...args,
        ]);
        // If the type has a toJson method, use it directly
        return (actualType != expectedType
            ? invokeExp.asA(expectedType)
            : invokeExp);
      }

      return TypeReference(
        (b) => b
          ..symbol = '\$${type.element3.name3}FromJson'.lowerFirst()
          ..types.addAll(type.typeArguments.map((t) => t.reference)),
      ).call([
        value.asA(
          TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic),
        ),
        for (final typeParam in type.element3.typeParameters2)
          typeConverters[typeParam] ??
              getFromJsonEnsured(
                type:
                    type.typeArguments[type.element3.typeParameters2.indexOf(
                      typeParam,
                    )],
                typeConverters: typeConverters,
              ),
      ]);
    }

    return value; // refer('(value) => value');
  }

  static Expression getToJsonEnsured({
    required DartType type,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    return Method(
      (b) => b
        ..requiredParameters.add(Parameter((b) => b..name = 'value'))
        ..returns = getJsonType(type: type)
        ..body = callToJson(
          type: type,
          value: refer('value'),
          typeConverters: typeConverters,
        ).code,
    ).closure;
  }

  static Expression getFromJsonEnsured({
    required DartType type,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    return Method(
      (b) => b
        ..requiredParameters.add(Parameter((b) => b..name = 'value'))
        ..returns = type.reference
        ..body = callFromJson(
          type: type,
          value: refer('value'),
          typeConverters: typeConverters,
        ).code,
    ).closure;
  }

  static Method generateToJsonMethod({required InterfaceType type}) {
    final fields = getFields(type);
    return Method(
      (b) => b
        ..name = '\$${type.element3.name3}ToJson'.lowerFirst()
        ..docs.addAll(['/// Converts ${type.name} to JSON map'])
        ..types.addAll(type.element3.typeParameters2.map((t) => t.reference))
        ..returns = TypeReferences.mapOf(
          TypeReferences.string,
          TypeReferences.dynamic,
        )
        ..requiredParameters.addAll([
          Parameter(
            (b) => b
              ..name = 'data'
              ..type = type.reference,
          ),
          for (final typeParam in type.element3.typeParameters2)
            Parameter(
              (b) => b
                ..name = '${typeParam.name3}ToJson'.lowerFirst()
                ..type = FunctionType(
                  (b) => b
                    ..returnType = refer('dynamic')
                    ..requiredParameters.add(typeParam.reference),
                ),
            ),
        ])
        ..body = literalMap({
          for (final field in fields.values)
            field.jsonName: callToJson(
              type: field.type,
              value: refer('data').property(field.parameterName),
              typeConverters: {
                for (final (i, typeParam) in type.typeArguments.indexed)
                  typeParam: refer(
                    '${type.element3.typeParameters2[i].name3}ToJson'
                        .lowerFirst(),
                  ),
              },
            ).code,
        }).returned.statement,
    );
  }

  static Method generateFromJsonMethod({required InterfaceType type}) {
    final fields = getFields(type);
    return Method(
      (b) => b
        ..name = '\$${type.element3.name3}FromJson'.lowerFirst()
        ..docs.addAll(['/// Converts JSON map to ${type.name}'])
        ..types.addAll(type.element3.typeParameters2.map((t) => t.reference))
        ..returns = type.reference
        ..requiredParameters.addAll([
          Parameter(
            (b) => b
              ..name = 'data'
              ..type = TypeReferences.mapOf(
                TypeReferences.string,
                TypeReferences.dynamic,
              ),
          ),
          for (final typeParam in type.element3.typeParameters2)
            Parameter(
              (b) => b
                ..name = '${typeParam.name3}FromJson'.lowerFirst()
                ..type = FunctionType(
                  (b) => b
                    ..returnType = typeParam.reference
                    ..requiredParameters.add(refer('dynamic')),
                ),
            ),
        ])
        ..body = type.reference
            .newInstance([], {
              for (final field in fields.values)
                field.jsonName: callFromJson(
                  type: field.type,
                  value: refer('data').index(literalString(field.jsonName)),
                  typeConverters: {
                    for (final (i, typeParam) in type.typeArguments.indexed)
                      typeParam: refer(
                        '${type.element3.typeParameters2[i].name3}FromJson'
                            .lowerFirst(),
                      ),
                  },
                ),
            })
            .returned
            .statement,
    );
  }

  static List<Spec> generate({required InterfaceType type}) {
    final specs = <Spec>[];

    // Generate toJson method
    if (type.lookUpMethod3('toJson', type.element3.library2) == null) {
      final toJsonMethod = generateToJsonMethod(type: type);
      specs.add(toJsonMethod);
    }

    // Generate fromJson method
    if (type.lookUpConstructor2('fromJson', type.element3.library2) == null) {
      final fromJsonMethod = generateFromJsonMethod(type: type);
      specs.add(fromJsonMethod);
    }

    return specs;
  }

  // static Class generateConverterClass({
  //   required InterfaceType type,
  //   required ModelAnalyzer modelAnalyzer,
  //   required ConverterFactory converterFactory,
  // }) {
  //   final fromTypeRef = type.reference;
  //   final toTypeRef = TypeReferences.mapOf(
  //     TypeReferences.string,
  //     TypeReferences.dynamic,
  //   );
  //   return Class(
  //       (b) => b
  //         ..docs.addAll([
  //           '/// Converter for ${type.name} model',
  //           '/// Generated by Firestore ODM Builder',
  //         ])
  //         ..name = '${type.name}JsonConverter'
  //       ..types.addAll(
  //         type.element3.typeParameters2.expand(
  //           (t) => [
  //             t.reference,
  //           ],
  //         ),
  //       )
  //         ..implements.add(
  //           TypeReference(
  //             (b) => b
  //               ..symbol = 'FirestoreConverter'
  //               ..types.addAll([
  //                 fromTypeRef,
  //                 toTypeRef,
  //               ]),
  //           ),
  //         )
  //         ..fields.addAll(
  //           type.element3.typeParameters2.map(
  //             (t) => Field(
  //               (b) => b
  //                 ..name = 'converter${t.name3}'
  //                 ..type = TypeReference(
  //                   (b) => b
  //                     ..symbol = 'FirestoreConverter'
  //                     ..types.addAll([t.reference, TypeReferences.dynamic]),
  //                 )
  //                 ..modifier = FieldModifier.final$,
  //             ),
  //           ),
  //         )
  //         ..constructors.add(
  //           Constructor(
  //             (b) => b
  //               ..constant = true
  //               ..optionalParameters.addAll(
  //                 type.element3.typeParameters2.map(
  //                   (t) => Parameter(
  //                     (b) => b
  //                       ..required = true
  //                       ..named = true
  //                       ..name = 'converter${t.name3}'
  //                       ..toThis = true,
  //                   ),
  //                 ),
  //               ),
  //           ),
  //         )
  //         ..methods.addAll([
  //           Method(
  //             (b) => b
  //               ..name = 'fromJson'
  //               ..annotations.add(refer('override'))
  //               ..returns = type.reference
  //               ..requiredParameters.add(
  //                 Parameter(
  //                   (b) => b
  //                     ..name = 'data'
  //                     ..type = toTypeRef,
  //                 ),
  //               )
  //               ..body = converter.fromFirestore(refer('data')).code,
  //           ),
  //           Method(
  //             (b) => b
  //               ..name = 'toJson'
  //               ..annotations.add(refer('override'))
  //               ..returns = toTypeRef
  //               ..requiredParameters.add(
  //                 Parameter(
  //                   (b) => b
  //                     ..name = 'value'
  //                     ..type = fromTypeRef,
  //                 ),
  //               )
  //               ..body = (cast
  //                   ? converter
  //                         .toFirestore(refer('value'))
  //                         .asA(toTypeResult)
  //                         .code
  //                   : converter.toFirestore(refer('value')).code),
  //           ),
  //         ]),
  //     ),
  // }
}
