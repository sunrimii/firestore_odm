import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import 'utils/type_analyzer.dart';
import 'utils/collection_validator.dart';
import 'generators/collection_generator.dart';
import 'generators/document_generator.dart';
import 'generators/query_generator.dart';
import 'generators/filter_generator.dart';
import 'generators/order_by_generator.dart';
import 'generators/update_generator.dart';
import 'generators/odm_extension_generator.dart';

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
    // Step 1: Validate all @Collection configurations first
    final validationErrors = CollectionValidator.validateCollections(library);
    
    if (validationErrors.isNotEmpty) {
      final errorReport = CollectionValidator.generateErrorReport(validationErrors);
      throw InvalidGenerationSourceError(
        '\n' + errorReport,
        todo: 'Fix the @Collection configuration errors listed above.',
      );
    }
    
    final buffer = StringBuffer();
    final generatedClasses = <String>{};
    
    // Step 2: Process all classes with @Collection annotations (validation passed)
    for (final element in library.allElements) {
      if (element is ClassElement) {
        final collections = _getCollectionAnnotations(element);
        if (collections.isNotEmpty) {
          _generateForClass(buffer, element, collections, generatedClasses);
        }
      }
    }
    
    return buffer.isNotEmpty ? buffer.toString() : null;
  }

  /// Extract all @Collection annotations from a class
  List<CollectionInfo> _getCollectionAnnotations(ClassElement element) {
    final collections = <CollectionInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);
    
    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null && collectionChecker.isExactlyType(annotationValue.type!)) {
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
        parentParts.add(_capitalize(parts[i].replaceAll(RegExp(r's$'), ''))); // Remove plural 's'
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
      _generateSharedComponents(buffer, className, constructor, documentIdField);
      generatedClasses.add(className);
    }

    // Generate collection-specific components for each path
    for (final collection in collections) {
      _generateCollectionSpecificComponents(
        buffer,
        className,
        collection.path,
        collection.suffix,
        constructor,
        documentIdField,
        collection.isSubcollection,
      );
    }
  }

  /// Generate components shared by all collections (Document, Query, FilterBuilder, etc.)
  void _generateSharedComponents(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String? documentIdField,
  ) {
    // Generate Document class
    DocumentGenerator.generateDocumentClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate Query class
    QueryGenerator.generateQueryClass(buffer, className, constructor);
    buffer.writeln('');

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
    OrderByGenerator.generateOrderByBuilderClass(buffer, className, constructor, className, documentIdField);
    buffer.writeln('');

    // Generate UpdateBuilder class
    UpdateGenerator.generateUpdateBuilderClass(buffer, className, constructor, className, documentIdField);
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
  ) {
    // Generate Collection class with unique name
    CollectionGenerator.generateCollectionClass(
      buffer,
      className,
      collectionPath,
      constructor,
      documentIdField,
      isSubcollection,
      suffix: suffix,
    );
    buffer.writeln('');
    
    // Generate ODM extension for this specific collection
    ODMExtensionGenerator.generateODMExtension(buffer, className, collectionPath, isSubcollection);
    buffer.writeln('');
  }

  void _generateAllComponents(
    StringBuffer buffer,
    String className,
    String collectionPath,
    ConstructorElement constructor,
    String? documentIdField,
    bool isSubcollection,
  ) {
    // Generate Collection class
    CollectionGenerator.generateCollectionClass(
      buffer,
      className,
      collectionPath,
      constructor,
      documentIdField,
      isSubcollection,
    );
    buffer.writeln('');

    // Generate Document class
    DocumentGenerator.generateDocumentClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate Query class
    QueryGenerator.generateQueryClass(buffer, className, constructor);
    buffer.writeln('');

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

    // Generate Filter class
    FilterGenerator.generateFilterClass(buffer, className);
    buffer.writeln('');

    // Generate Query Extension (for new where API)
    QueryGenerator.generateQueryExtension(buffer, className, constructor);
    buffer.writeln('');

    // Generate extension to add the collection to FirestoreODM
    ODMExtensionGenerator.generateODMExtension(buffer, className, collectionPath, isSubcollection);
  }
}
