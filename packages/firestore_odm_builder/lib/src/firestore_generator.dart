import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import 'generators/schema_generator.dart';

/// Collection information extracted from annotations
class CollectionInfo {
  final String path;
  final bool isSubcollection;

  CollectionInfo(this.path, this.isSubcollection);
}

/// Refactored Firestore code generator supporting multiple collections per model
class FirestoreGenerator extends Generator {
  const FirestoreGenerator();

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    // Check for schema variables first (new approach)
    final schemaVariables = <TopLevelVariableElement>[];
    for (final element in library.allElements) {
      if (element is TopLevelVariableElement) {
        final collections = SchemaGenerator.extractCollectionAnnotations(
          element,
        );
        if (collections.isNotEmpty) {
          schemaVariables.add(element);
        }
      }
    }

    // Check for deprecated @Collection usage on classes and throw error
    final classesWithCollectionAnnotations = <ClassElement>[];
    for (final element in library.allElements) {
      if (element is ClassElement) {
        final collections = _getCollectionAnnotations(element);
        if (collections.isNotEmpty) {
          classesWithCollectionAnnotations.add(element);
        }
      }
    }

    // Throw error if @Collection is used on classes
    if (classesWithCollectionAnnotations.isNotEmpty) {
      final classNames = classesWithCollectionAnnotations
          .map((e) => e.name)
          .join(', ');
      throw InvalidGenerationSourceError(
        'Invalid @Collection annotation usage found on classes: $classNames\n\n'
        'In the new schema-based architecture, @Collection annotations should only be used on top-level variables in schema files.\n\n'
        'Instead of:\n'
        '  @Collection("users")\n'
        '  class User { ... }\n\n'
        'Use:\n'
        '  @Collection<User>("users")\n'
        '  final schema = _\$Schema;\n\n'
        'Please move your @Collection annotations to a schema file (e.g., schema.dart) and remove them from model classes.',
        element: classesWithCollectionAnnotations.first,
      );
    }

    // If we have schema variables, use the new schema-based approach
    if (schemaVariables.isNotEmpty) {
      // Collect all model types from all schemas to generate converters only once
      final allModelTypes = <String>{};
      final allModelClassElements = <String, ClassElement>{};
      final allSchemas =
          <TopLevelVariableElement, List<SchemaCollectionInfo>>{};

      for (final schemaVar in schemaVariables) {
        final collections = SchemaGenerator.extractCollectionAnnotations(
          schemaVar,
        );
        allSchemas[schemaVar] = collections;
        for (final collection in collections) {
          allModelTypes.add(collection.modelTypeName);
          // Find the class element for this model type
          final classElement = _findClassElement(
            library,
            collection.modelTypeName,
          );
          if (classElement != null) {
            allModelClassElements[collection.modelTypeName] = classElement;
          }
        }
      }

      // Validate schema collections for conflicts
      _validateSchemaCollections(allSchemas);

      // Generate converter instances once for all model types
      SchemaGenerator.generateGlobalConverterInstances(buffer, allModelTypes);

      // Generate schema-based code for each schema
      for (final entry in allSchemas.entries) {
        final schemaCode = SchemaGenerator.generateSchemaCodeWithoutConverters(
          entry.key,
          entry.value,
          allModelClassElements,
        );
        buffer.write(schemaCode);
      }
    } else {
      // No schema variables found - no code generation needed
      // This library doesn't contain any ODM schema definitions
    }

    return buffer.isNotEmpty ? buffer.toString() : null;
  }

  /// Validate schema collections for conflicts
  void _validateSchemaCollections(
    Map<TopLevelVariableElement, List<SchemaCollectionInfo>> allSchemas,
  ) {
    final pathToModelTypes = <String, Set<String>>{};

    // Collect all path-to-model mappings across all schemas
    for (final entry in allSchemas.entries) {
      for (final collection in entry.value) {
        pathToModelTypes
            .putIfAbsent(collection.path, () => <String>{})
            .add(collection.modelTypeName);
      }
    }

    // Check for conflicts where same path is used by different model types
    final conflicts = <String, Set<String>>{};
    for (final entry in pathToModelTypes.entries) {
      if (entry.value.length > 1) {
        conflicts[entry.key] = entry.value;
      }
    }

    if (conflicts.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('🚨 Schema Collection Path Conflicts Detected!');
      buffer.writeln('=' * 60);
      buffer.writeln();

      for (final entry in conflicts.entries) {
        buffer.writeln('❌ Path: "${entry.key}"');
        buffer.writeln('   Used by models: ${entry.value.join(", ")}');
        buffer.writeln();
      }

      buffer.writeln('💡 Solutions:');
      buffer.writeln('• Use different collection paths for each model type');
      buffer.writeln('• Or combine the models into a single shared model');
      buffer.writeln('• Or use inheritance/polymorphism if models are related');
      buffer.writeln();
      buffer.writeln('Example fixes:');
      buffer.writeln('@Collection<Post>("posts")');
      buffer.writeln(
        '@Collection<SharedPost>("shared_posts")  // Different path',
      );

      throw InvalidGenerationSourceError(
        buffer.toString(),
        element: allSchemas.keys.first,
      );
    }
  }

  /// Extract all @Collection annotations from a class
  List<CollectionInfo> _getCollectionAnnotations(ClassElement element) {
    final collections = <CollectionInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);

    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null &&
          collectionChecker.isExactlyType(annotationValue.type!)) {
        final path = annotationValue.getField('path')!.toStringValue()!;
        final isSubcollection = path.contains('*');
        collections.add(CollectionInfo(path, isSubcollection));
      }
    }

    return collections;
  }

  /// Find a class element by name in the library
  ClassElement? _findClassElement(LibraryReader library, String className) {
    // First check the current library
    for (final element in library.allElements) {
      if (element is ClassElement && element.name == className) {
        return element;
      }
    }

    // Also check for classes in all imported libraries
    for (final import in library.element.importedLibraries) {
      for (final unit in import.units) {
        for (final element in unit.classes) {
          if (element.name == className) {
            return element;
          }
        }
      }
    }

    return null;
  }
}
