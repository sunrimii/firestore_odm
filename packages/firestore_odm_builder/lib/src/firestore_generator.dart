import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import 'utils/type_analyzer.dart';
import 'utils/collection_validator.dart';
import 'generators/collection_generator.dart';
import 'generators/filter_generator.dart';
import 'generators/order_by_generator.dart';
import 'generators/update_generator.dart';
import 'generators/aggregate_generator.dart';
import 'generators/odm_extension_generator.dart';
import 'generators/schema_generator.dart';

/// Collection information extracted from annotations
class CollectionInfo {
  final String path;
  final bool isSubcollection;
  final String suffix;

  CollectionInfo(this.path, this.isSubcollection, this.suffix);
}

/// Refactored Firestore code generator supporting multiple collections per model
class FirestoreGenerator extends Generator {
  const FirestoreGenerator();

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();
    final generatedClasses = <String>{};
    
    // Check for schema variables first (new approach)
    final schemaVariables = <TopLevelVariableElement>[];
    for (final element in library.allElements) {
      if (element is TopLevelVariableElement) {
        final collections = SchemaGenerator.extractCollectionAnnotations(element);
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
      final classNames = classesWithCollectionAnnotations.map((e) => e.name).join(', ');
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
      final allSchemas = <TopLevelVariableElement, List<SchemaCollectionInfo>>{};
      
      for (final schemaVar in schemaVariables) {
        final collections = SchemaGenerator.extractCollectionAnnotations(schemaVar);
        allSchemas[schemaVar] = collections;
        for (final collection in collections) {
          allModelTypes.add(collection.modelTypeName);
          // Find the class element for this model type
          final classElement = _findClassElement(library, collection.modelTypeName);
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
  void _validateSchemaCollections(Map<TopLevelVariableElement, List<SchemaCollectionInfo>> allSchemas) {
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
      buffer.writeln('@Collection<SharedPost>("shared_posts")  // Different path');
      
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
        final suffix = _generateSuffix(path);
        collections.add(CollectionInfo(path, isSubcollection, suffix));
      }
    }

    return collections;
  }

  /// Generate a unique suffix for collection class names based on path
  String _generateSuffix(String path) {
    if (!path.contains('*')) {
      return ''; // No suffix for root collections
    }

    // For subcollections, create a descriptive suffix
    // e.g., "users/*/posts" -> "ForUser"
    final parts = path.split('/');
    final parentParts = <String>[];

    for (int i = 0; i < parts.length - 1; i += 2) {
      if (i + 1 < parts.length && parts[i + 1] == '*') {
        parentParts.add(
          _capitalize(parts[i].replaceAll(RegExp(r's$'), '')),
        ); // Remove plural 's'
      }
    }

    return parentParts.isNotEmpty ? 'For${parentParts.join('')}' : '';
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Generate code for a class with multiple collection annotations
  void _generateForClass(
    StringBuffer buffer,
    ClassElement element,
    List<CollectionInfo> collections,
    Set<String> generatedClasses,
    Map<String, String> collectionTypeMap,
  ) {
    final className = element.name;
    final constructor = element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'Class must have an unnamed constructor.',
        element: element,
      );
    }

    // Find document ID field using the TypeAnalyzer utility
    final documentIdField = TypeAnalyzer.getDocumentIdField(constructor);

    // Generate shared components once (Document, Query, FilterBuilder, etc.)
    if (!generatedClasses.contains(className)) {
      _generateSharedComponents(
        buffer,
        className,
        constructor,
        documentIdField,
      );
      generatedClasses.add(className);
    }

    // Generate converter functions for this model
    final converterCode = CollectionGenerator.generateConverters(element);
    buffer.write(converterCode);

    // Generate ODM extensions for each collection path
    for (final collection in collections) {
      ODMExtensionGenerator.generateODMExtension(
        buffer,
        className,
        collection.path,
        collection.isSubcollection,
        collectionTypeMap,
      );
      buffer.writeln('');
    }
  }

  /// Generate components shared by all collections (Document, Query, FilterBuilder, etc.)
  void _generateSharedComponents(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String? documentIdField,
  ) {
    // Generate FilterBuilder class
    FilterGenerator.generateFilterBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );

    // Generate FilterBuilder classes for all nested types
    FilterGenerator.generateNestedFilterBuilderClasses(
      buffer,
      constructor,
      <String>{},
      className,
    );
    buffer.writeln('');

    // Generate OrderByBuilder class
    OrderByGenerator.generateOrderByBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );

    // Generate nested OrderByBuilder classes
    OrderByGenerator.generateNestedOrderByBuilderClasses(
      buffer,
      constructor,
      <String>{},
      className,
      documentIdField,
    );
    buffer.writeln('');

    // Generate UpdateBuilder class
    UpdateGenerator.generateUpdateBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );

    // Generate nested UpdateBuilder classes
    UpdateGenerator.generateNestedUpdateBuilderClasses(
      buffer,
      constructor,
      <String>{},
      className,
    );

    // Generate nested updater classes (ProfileNestedUpdater, etc.)
    UpdateGenerator.generateAllNestedUpdaterClasses(
      buffer,
      constructor,
      <String>{},
    );
    buffer.writeln('');
  }

  /// Generate collection-specific components (Collection class)
  void _generateCollectionSpecificComponents(
    StringBuffer buffer,
    String className,
    String collectionPath,
    String suffix,
    ConstructorElement constructor,
    String? documentIdField,
    bool isSubcollection,
    Map<String, String> collectionTypeMap,
  ) {
    // Note: Collection classes are no longer generated - using FirestoreCollection directly
    // Converter functions are generated once per model

    // Generate ODM extension for this specific collection
    ODMExtensionGenerator.generateODMExtension(
      buffer,
      className,
      collectionPath,
      isSubcollection,
      collectionTypeMap,
    );
    buffer.writeln('');
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

  void _generateAllComponents(
    StringBuffer buffer,
    String className,
    String collectionPath,
    ConstructorElement constructor,
    String? documentIdField,
    bool isSubcollection,
  ) {
    // Note: Collection classes are no longer generated - using FirestoreCollection directly
    // Converter functions are generated once per model

    // Generate FilterBuilder class
    FilterGenerator.generateFilterBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );

    // Generate FilterBuilder classes for all nested types
    FilterGenerator.generateNestedFilterBuilderClasses(
      buffer,
      constructor,
      <String>{},
      className,
    );

    // Generate OrderByBuilder class
    OrderByGenerator.generateOrderByBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );

    // Generate OrderByBuilder classes for all nested types
    OrderByGenerator.generateNestedOrderByBuilderClasses(
      buffer,
      constructor,
      <String>{},
      className,
      documentIdField,
    );

    // Generate base update classes first
    UpdateGenerator.generateBaseUpdateClasses(buffer);

    // Generate UpdateBuilder class and all nested types
    UpdateGenerator.generateUpdateBuilderClass(
      buffer,
      className,
      constructor,
      className,
      documentIdField,
    );
    UpdateGenerator.generateNestedUpdateBuilderClasses(
      buffer,
      constructor,
      <String>{className},
      className,
    );

    // Generate nested updater classes
    UpdateGenerator.generateAllNestedUpdaterClasses(
      buffer,
      constructor,
      <String>{className},
    );

    // Generate extension to add the collection to FirestoreODM
    ODMExtensionGenerator.generateODMExtension(
      buffer,
      className,
      collectionPath,
      isSubcollection,
      <String, String>{}, // Empty map for backwards compatibility
    );
  }
}
