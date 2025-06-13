import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_builder/src/generators/schema_generator.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';

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

    // 2. Extract model types and their ClassElement2 instances directly from annotations
    final Map<String, ModelAnalysis> allModelAnalyses = {};

    for (final collection in collections) {
      final modelType = collection.modelType;
      if (modelType is InterfaceType) {
        final classElement = modelType.element3 as ClassElement2?;
        if (classElement != null) {
          // Use ModelAnalyzer to discover all nested types
          final nestedAnalyses = ModelAnalyzer.analyzeModelWithNestedTypes(
            classElement,
          );
          allModelAnalyses.addAll(nestedAnalyses);
        }
      }
    }

    // 3. Generate schema code with all types
    return SchemaGenerator.generateSchemaCode(
      element,
      collections,
      allModelAnalyses,
    );
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

          collections.add(
            SchemaCollectionInfo(
              modelTypeName: modelTypeName,
              path: path,
              isSubcollection: isSubcollection,
              modelType: modelType, // Store the actual DartType
            ),
          );
        }
      }
    }

    return collections;
  }
}
