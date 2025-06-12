import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_builder/src/generators/schema_generator.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';

/// Custom builder that replaces source_gen for Firestore ODM generation
class FirestoreOdmBuilder implements Builder {
  const FirestoreOdmBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.odm.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final library = await buildStep.resolver.libraryFor(buildStep.inputId);
    final schemaElements = <TopLevelVariableElement>[];

    // Find all @Schema annotated variables
    for (final element in library.topLevelElements) {
      if (element is TopLevelVariableElement) {
        for (final annotation in element.metadata) {
          final annotationValue = annotation.computeConstantValue();
          if (annotationValue?.type?.element?.name == 'Schema') {
            schemaElements.add(element);
            break;
          }
        }
      }
    }

    if (schemaElements.isEmpty) return;

    // Generate code for each schema
    final buffer = StringBuffer();
    buffer.writeln('// dart format width=80');
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln("part of '${buildStep.inputId.pathSegments.last}';");
    buffer.writeln();
    buffer.writeln('// **************************************************************************');
    buffer.writeln('// FirestoreGenerator');
    buffer.writeln('// **************************************************************************');
    buffer.writeln();

    for (final schemaElement in schemaElements) {
      final generatedCode = await _generateForSchema(schemaElement, resolver);
      buffer.write(generatedCode);
    }

    final outputId = buildStep.inputId.changeExtension('.odm.dart');
    await buildStep.writeAsString(outputId, buffer.toString());
  }

  Future<String> _generateForSchema(TopLevelVariableElement element, Resolver resolver) async {
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
          final nestedAnalyses = ModelAnalyzer.analyzeModelWithNestedTypes(classElement);
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
  List<SchemaCollectionInfo> _extractCollectionAnnotations(TopLevelVariableElement element) {
    final collections = <SchemaCollectionInfo>[];
    print('DEBUG: Extracting @Collection annotations from ${element.name}');

    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      print('DEBUG: Found annotation: ${annotationValue?.type?.element?.name}');
      if (annotationValue?.type?.element?.name == 'Collection') {
        // Extract path from @Collection("path")
        final path = annotationValue!.getField('path')!.toStringValue()!;
        print('DEBUG: Collection path: $path');
        
        // Extract model type from @Collection<ModelType>
        final collectionType = annotationValue.type!;
        print('DEBUG: Collection type: $collectionType');
        if (collectionType is ParameterizedType && collectionType.typeArguments.isNotEmpty) {
          final modelType = collectionType.typeArguments.first;
          final modelTypeName = modelType.getDisplayString();
          final isSubcollection = path.contains('*');
          print('DEBUG: Model type: $modelTypeName, isSubcollection: $isSubcollection');
          
          collections.add(SchemaCollectionInfo(
            modelTypeName: modelTypeName,
            path: path,
            isSubcollection: isSubcollection,
            modelType: modelType, // Store the actual DartType
          ));
        }
      }
    }

    print('DEBUG: Found ${collections.length} collections: ${collections.map((c) => c.modelTypeName).join(', ')}');
    return collections;
  }
}

/// Legacy generator class for backwards compatibility
class FirestoreGenerator {
  const FirestoreGenerator();
}
