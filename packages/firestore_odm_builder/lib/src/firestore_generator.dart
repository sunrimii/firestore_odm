import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import 'utils/type_analyzer.dart';
import 'generators/collection_generator.dart';
import 'generators/document_generator.dart';
import 'generators/query_generator.dart';
import 'generators/filter_generator.dart';
import 'generators/order_by_generator.dart';
import 'generators/update_generator.dart';
import 'generators/odm_extension_generator.dart';

/// Refactored Firestore code generator using modular architecture
class FirestoreGenerator extends GeneratorForAnnotation<Collection> {
  const FirestoreGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Collection can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final collectionPath = annotation.read('path').stringValue;
    final constructor = element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'Class must have an unnamed constructor.',
        element: element,
      );
    }

    // Check if this is a subcollection (contains wildcards)
    final isSubcollection = collectionPath.contains('*');
    
    // Find document ID field using the TypeAnalyzer utility
    final documentIdField = TypeAnalyzer.getDocumentIdField(constructor);

    final buffer = StringBuffer();

    // Generate all components using the modular generators
    _generateAllComponents(buffer, className, collectionPath, constructor, documentIdField, isSubcollection);

    return buffer.toString();
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
