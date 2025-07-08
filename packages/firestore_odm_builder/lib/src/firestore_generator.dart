import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:firestore_odm_builder/src/generators/aggregate_generator.dart';
import 'package:firestore_odm_builder/src/generators/filter_generator.dart';
import 'package:firestore_odm_builder/src/generators/order_by_generator.dart';
import 'package:firestore_odm_builder/src/generators/update_generator.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_builder/src/generators/schema_generator.dart';

/// Generator for Firestore ODM using source_gen
class FirestoreGenerator extends GeneratorForAnnotation<Schema> {
  const FirestoreGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        'Schema annotation can only be applied to top-level variables.',
        element: element,
      );
    }

    return _generateForSchema(element, buildStep.resolver);
  }

  String _generateForSchema(
    TopLevelVariableElement element,
    Resolver resolver,
  ) {
    // 1. Extract all @Collection annotations from this schema variable
    final collections = _extractCollectionAnnotations(element);

    print('Found ${collections.length} collections in schema');

    // 3. Generate schema code with all types
    return SchemaGenerator.generateSchemaCode(element, collections);
  }

  /// Extract @Collection annotations from a schema variable
  List<SchemaCollectionInfo> _extractCollectionAnnotations(
    TopLevelVariableElement element,
  ) {
    final collections = <SchemaCollectionInfo>[];

    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'Collection') {
        // Extract path from @Collection("path")
        final path = annotationValue!.getField('path')!.toStringValue()!;

        // Extract model type from @Collection<ModelType>
        final collectionType = annotationValue.type!;
        if (collectionType is ParameterizedType &&
            collectionType.typeArguments.isNotEmpty) {
          final modelType = collectionType.typeArguments.first;
          final modelTypeName = modelType.getDisplayString();
          final isSubcollection = path.contains('*');

          if (modelType is! InterfaceType) {
            throw InvalidGenerationSourceError(
              'Model type must be an InterfaceType for @Collection annotation.',
              element: element,
            );
          }

          collections.add(
            SchemaCollectionInfo(
              modelTypeName: modelTypeName,
              path: path,
              isSubcollection: isSubcollection,
              schemaTypeName: element.name.upperFirst(),
              modelType: modelType, // Store the actual DartType
            ),
          );
        }
      }
    }

    return collections;
  }
}

class FirestoreGenerator3 extends Generator {
  FirestoreGenerator3();

  final Set<Element> _visitedElements = {};

  TypeChecker get nestedTypeChecker => TypeChecker.fromRuntime(FirestoreOdm);

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final modelAnalyzer = ModelAnalyzer();
    final converterFactory = ConverterFactory(modelAnalyzer);

    List<Spec> specs = [];

    for (var element in library.allElements.where(
      (e) => nestedTypeChecker.hasAnnotationOf(e, throwOnUnresolved: true),
    )) {
      print('Generating schema for ${element.name}');
      if (element is! InterfaceElement) {
        throw InvalidGenerationSourceError(
          'Schema annotation can only be applied to classes.',
          element: element,
        );
      }

      specs.add(
        _generatePatcheBuilder(
          element.thisType,
          modelAnalyzer: modelAnalyzer,
          converterFactory: converterFactory,
        ),
      );


      specs.addAll(
        FilterGenerator.generateFilterSelectorClasses(
          element.thisType,
          modelAnalyzer: modelAnalyzer,
        ),
      );

      
      specs.addAll(
        OrderByGenerator.generateOrderByClasses(
          element.thisType,
          modelAnalyzer: modelAnalyzer,
        ),
      );

      specs.addAll(
        AggregateGenerator.generateAggregateClasses(
          element.thisType,
          modelAnalyzer: modelAnalyzer,
        ),
      );
    }

    // for (var annotatedElement in library.annotatedWith(collectionTypeChecker)) {
    //   final element = annotatedElement.element;

    //   print('Generating schema for ${element.name}');
    //   if (element is! ClassElement) {
    //     throw InvalidGenerationSourceError(
    //       'Schema annotation can only be applied to classes.',
    //       element: element,
    //     );
    //   }

    //   if (_visitedElements.contains(element)) {
    //     // Prevent infinite recursion for circular references
    //     continue;
    //   }

    //   _visitedElements.add(element);

    //   final collections = _extractCollectionAnnotations(element);

    //   print('Found ${collections.length} collections in schema');
    //   specs.addAll(SchemaGenerator.generateCollectionIdentifiers(collections));

    //   // temporary: use class name as schema type name
    //   final schemaClassName = collections.first.schemaTypeName;

    //   // specs.addAll(
    //   //   SchemaGenerator.generateFilterAndOrderBySelectors(
    //   //     collections,
    //   //     schemaClassName,
    //   //     converterFactory: converterFactory,
    //   //     modelAnalyzer: modelAnalyzer,
    //   //   ),
    //   // );
    //   // Generate filter and order by builders for each model type

    //   // Generate ODM extensions
    //   specs.add(
    //     SchemaGenerator.generateODMExtensions(
    //       schemaClassName,
    //       collections,
    //       converterFactory,
    //       modelAnalyzer,
    //     ),
    //   );

    //   // Generate transaction context extensions
    //   specs.add(
    //     SchemaGenerator.generateTransactionContext(
    //       schemaClassName,
    //       collections,
    //       converterFactory,
    //       modelAnalyzer,
    //     ),
    //   );
    //   specs.addAll(
    //     SchemaGenerator.generateTransactionDocuments(
    //       schemaClassName,
    //       collections,
    //       converterFactory,
    //       modelAnalyzer,
    //     ),
    //   );

    //   // Generate batch context extensions

    //   // Generate unique document classes for each collection path
    //   specs.addAll(
    //     SchemaGenerator.generateUniqueDocumentClasses(
    //       schemaClassName,
    //       collections,
    //       converterFactory,
    //       modelAnalyzer,
    //     ),
    //   );

    //   // Generate document extensions for subcollections (path-specific)
    //   // specs.addAll(SchemaGenerator.generateDocumentExtensions(schemaClassName, collections));

    //   // Generate batch document extensions for subcollections
    //   final batchExtension = SchemaGenerator.generateBatchContextExtensions(
    //     schemaClassName,
    //     collections,
    //     converterFactory,
    //     modelAnalyzer,
    //   );
    //   if (batchExtension != null) specs.add(batchExtension);
    //   specs.addAll(
    //     SchemaGenerator.generateBatchDocumentExtensions(
    //       schemaClassName,
    //       collections,
    //       converterFactory,
    //       modelAnalyzer,
    //     ),
    //   );
    // }

    specs.addAll(converterFactory.specs);

    return Library(
      (b) => b..body.addAll(specs),
    ).accept(DartEmitter(useNullSafetySyntax: true)).toString();
  }

  Spec _generatePatcheBuilder(
    InterfaceType type, {
    required ModelAnalyzer modelAnalyzer,
    required ConverterFactory converterFactory,
  }) {
    final fields = modelAnalyzer.getFields(type);
    return Class(
      (b) => b
        ..docs.add('/// Patch builder for `${type.name}` model')
        ..name = '${type.name}PatchBuilder'
        ..types.addAll(
          type.element3.typeParameters2.map((typeParam) => typeParam.reference),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = 'PatchBuilder'
            ..types.add(type.reference),
        )
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Creates a patch builder for `${type.name}`')
              ..optionalParameters.addAll([
                ...type.element3.typeParameters2.map(
                  (typeParam) => Parameter(
                    (b) => b
                      ..name = 'converter${typeParam.name3}'
                      ..required = true
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'FirestoreConverter'
                          ..types.add(typeParam.reference)
                          ..types.add(
                            TypeReferences.mapOf(
                              TypeReferences.string,
                              TypeReferences.dynamic,
                            ),
                          ),
                      )
                      ..named = true,
                  ),
                ),
                Parameter(
                  (b) => b
                    ..name = 'name'
                    ..toSuper = true
                    ..named = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'parent'
                    ..toSuper = true
                    ..named = true,
                ),
              ])
              ..initializers.addAll([
                ...type.element3.typeParameters2.map(
                  (typeParam) => refer(
                    '_converter${typeParam.name3}',
                  ).assign(refer('converter${typeParam.name3}')).code,
                ),
                refer('super').call([], {
                  'converter':
                      converterFactory.getConverter(type).apply({
                        for (var typeParam in type.element3.typeParameters2)
                          typeParam.name3!: VariableConverter(
                            'converter${typeParam.name3}',
                          ),
                      }).toConverterExpr(),
                }).code,
              ]),
          ),
        )
        ..fields.addAll([
          ...type.element3.typeParameters2.map(
            (typeParam) => Field(
              (b) => b
                ..name = '_converter${typeParam.name3}'
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'FirestoreConverter'
                    ..types.add(typeParam.reference)
                    ..types.add(
                      TypeReferences.mapOf(
                        TypeReferences.string,
                        TypeReferences.dynamic,
                      ),
                    ),
                )
                ..modifier = FieldModifier.final$,
            ),
          ),
          ...fields.values.map(
            (field) => UpdateGenerator.generateGenericFieldUpdateField(
              field,
              {
                for (var typeParam in type.element3.typeParameters2)
                          typeParam.name3!: VariableConverter(
                            '_converter${typeParam.name3}',
                          ),
              },
              converterFactory: converterFactory,
            ),
          ),
        ]),
    );
  }

  /// Extract @Collection annotations from a schema variable
  //   List<SchemaCollectionInfo> _extractCollectionAnnotations(
  //     ClassElement element,
  //   ) {
  //     final collections = <SchemaCollectionInfo>[];

  //     final annotations = collectionTypeChecker.annotationsOf(element);

  //     for (final annotation in annotations) {
  //       // Extract path from @Collection("path")
  //       final path = ConstantReader(annotation).read('path').stringValue;

  //       // Extract model type from @Collection<ModelType>
  //       final collectionType = annotation.type!;
  //       if (collectionType is ParameterizedType &&
  //           collectionType.typeArguments.isNotEmpty) {
  //         final schemaType = collectionType.typeArguments.first;
  //         final modelType = element.thisType;
  //         final modelTypeName = element.thisType.getDisplayString();
  //         final isSubcollection = path.contains('*');

  //         collections.add(
  //           SchemaCollectionInfo(
  //             modelTypeName: modelTypeName,
  //             path: path,
  //             isSubcollection: isSubcollection,
  //             schemaTypeName: schemaType.getDisplayString(),
  //             modelType: modelType, // Store the actual DartType
  //           ),
  //         );
  //       }
  //     }

  //     return collections;
  //   }
}
