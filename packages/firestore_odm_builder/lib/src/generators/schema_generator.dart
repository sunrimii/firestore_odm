import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import '../utils/string_helpers.dart';
import '../utils/type_analyzer.dart';
import 'filter_generator.dart';
import 'order_by_generator.dart';
import 'update_generator.dart';
import 'aggregate_generator.dart';

/// Information about a collection annotation extracted from a schema variable
class SchemaCollectionInfo {
  final String path;
  final String modelTypeName;
  final bool isSubcollection;
  
  SchemaCollectionInfo({
    required this.path,
    required this.modelTypeName,
    required this.isSubcollection,
  });
}

/// Generator for schema-based ODM code
class SchemaGenerator {
  /// Generate schema class and extensions from annotated variable
  static String generateSchemaCode(
    TopLevelVariableElement variableElement,
    List<SchemaCollectionInfo> collections,
    Map<String, ClassElement> modelTypes,
  ) {
    final buffer = StringBuffer();
    final variableName = variableElement.name;
    final schemaClassName = '_\$${StringHelpers.capitalize(variableName)}Impl';
    final schemaConstName = '_\$${StringHelpers.capitalize(variableName)}';
    
    // Generate the schema class
    _generateSchemaClass(buffer, schemaClassName, schemaConstName);
    
    // Generate filter and order by builders for each model type
    _generateFilterAndOrderByBuilders(buffer, modelTypes);
    
    // Generate ODM extensions
    _generateODMExtensions(buffer, schemaClassName, collections);
    
    // Generate document extensions for subcollections
    _generateDocumentExtensions(buffer, schemaConstName, collections);
    
    return buffer.toString();
  }
  
  /// Generate schema class and extensions from annotated variable (without converters)
  static String generateSchemaCodeWithoutConverters(
    TopLevelVariableElement variableElement,
    List<SchemaCollectionInfo> collections,
    Map<String, ClassElement> modelTypes,
  ) {
    final buffer = StringBuffer();
    final variableName = variableElement.name;
    final schemaClassName = '\$${StringHelpers.capitalize(variableName)}Impl';
    final schemaConstName = '_\$${StringHelpers.capitalize(variableName)}';
    
    // Generate the schema class
    _generateSchemaClass(buffer, schemaClassName, schemaConstName);
    
    // Generate filter and order by builders for each model type
    _generateFilterAndOrderByBuilders(buffer, modelTypes);
    
    // Generate ODM extensions
    _generateODMExtensions(buffer, schemaClassName, collections);
    
    // Generate document extensions for subcollections
    _generateDocumentExtensions(buffer, schemaClassName, collections);
    
    return buffer.toString();
  }
  
  /// Generate converter instances globally for all model types
  static void generateGlobalConverterInstances(
    StringBuffer buffer,
    Set<String> modelTypes,
  ) {
    // Generate converter instances for each model type
    for (final modelType in modelTypes) {
      final converterName = '${StringHelpers.camelCase(modelType)}Converter';
      buffer.writeln('/// Generated converter for $modelType');
      buffer.writeln('final $converterName = ModelConverter<$modelType>(');
      buffer.writeln('  fromMap: (json) => $modelType.fromJson(json),');
      buffer.writeln('  toMap: (instance) => instance.toJson(),');
      buffer.writeln(');');
      buffer.writeln('');
    }
  }
  
  /// Generate the schema class and const instance
  static void _generateSchemaClass(StringBuffer buffer, String schemaClassName, String originalVariableName) {
    // Generate the schema class
    buffer.writeln('/// Generated schema class - dummy class that only serves as type marker');
    buffer.writeln('class $schemaClassName extends FirestoreSchema {');
    buffer.writeln('  const $schemaClassName();');
    buffer.writeln('}');
    buffer.writeln('');
    
    // Generate the const instance that can be assigned to _$VariableName
    buffer.writeln('/// Generated schema instance');
    buffer.writeln('const $schemaClassName $originalVariableName = $schemaClassName();');
    buffer.writeln('');
  }
  
  /// Generate ODM extensions for the schema
  static void _generateODMExtensions(
    StringBuffer buffer, 
    String schemaClassName, 
    List<SchemaCollectionInfo> collections,
  ) {
    final rootCollections = collections.where((c) => !c.isSubcollection).toList();
    if (rootCollections.isEmpty) return;
    
    buffer.writeln('/// Extension to add collections to FirestoreODM<$schemaClassName>');
    buffer.writeln('extension ${schemaClassName}ODMExtensions on FirestoreODM<$schemaClassName> {');
    
    for (final collection in rootCollections) {
      final collectionName = StringHelpers.camelCase(collection.path);
      final converterName = '${StringHelpers.camelCase(collection.modelTypeName)}Converter';
      buffer.writeln('  /// Access ${collection.path} collection');
      buffer.writeln('  FirestoreCollection<$schemaClassName, ${collection.modelTypeName}> get $collectionName =>');
      buffer.writeln('    FirestoreCollection<$schemaClassName, ${collection.modelTypeName}>(');
      buffer.writeln('      ref: firestore.collection(\'${collection.path}\'),');
      buffer.writeln('      fromJson: $converterName.fromJson,');
      buffer.writeln('      toJson: $converterName.toJson,');
      buffer.writeln('    );');
      buffer.writeln('');
      
      // Generate document access method
      final singularName = _getSingularName(collection.path);
      buffer.writeln('  /// Access a specific document in ${collection.path}');
      buffer.writeln('  FirestoreDocument<$schemaClassName, ${collection.modelTypeName}> $singularName(String id) =>');
      buffer.writeln('    FirestoreDocument.fromRef(');
      buffer.writeln('      firestore.collection(\'${collection.path}\').doc(id),');
      buffer.writeln('      $converterName.fromJson,');
      buffer.writeln('      $converterName.toJson,');
      buffer.writeln('    );');
      buffer.writeln('');
    }
    
    buffer.writeln('}');
    buffer.writeln('');
  }
  
  /// Generate document extensions for subcollections
  static void _generateDocumentExtensions(
    StringBuffer buffer, 
    String schemaClassName, 
    List<SchemaCollectionInfo> collections,
  ) {
    final subcollections = collections.where((c) => c.isSubcollection).toList();
    
    // Group subcollections by parent type
    final parentGroups = <String, List<SchemaCollectionInfo>>{};
    for (final subcol in subcollections) {
      final parentType = _getParentTypeFromPath(subcol.path, collections);
      if (parentType != null) {
        parentGroups.putIfAbsent(parentType, () => []).add(subcol);
      }
    }
    
    for (final entry in parentGroups.entries) {
      final parentType = entry.key;
      final subcolsForParent = entry.value;
      
      buffer.writeln('/// Extension to access subcollections on $parentType document');
      buffer.writeln('extension ${schemaClassName}${parentType}DocumentExtensions on FirestoreDocument<$schemaClassName, $parentType> {');
      
      for (final subcol in subcolsForParent) {
        final subcollectionName = _getSubcollectionName(subcol.path);
        final getterName = StringHelpers.camelCase(subcollectionName);
        final converterName = '${StringHelpers.camelCase(subcol.modelTypeName)}Converter';
        
        buffer.writeln('  /// Access $subcollectionName subcollection');
        buffer.writeln('  FirestoreCollection<$schemaClassName, ${subcol.modelTypeName}> get $getterName =>');
        buffer.writeln('    FirestoreCollection<$schemaClassName, ${subcol.modelTypeName}>(');
        buffer.writeln('      ref: ref.collection(\'$subcollectionName\'),');
        buffer.writeln('      fromJson: $converterName.fromJson,');
        buffer.writeln('      toJson: $converterName.toJson,');
        buffer.writeln('    );');
        buffer.writeln('');
      }
      
      buffer.writeln('}');
      buffer.writeln('');
    }
  }
  
  /// Extract collection annotations from a variable element
  static List<SchemaCollectionInfo> extractCollectionAnnotations(TopLevelVariableElement element) {
    final collections = <SchemaCollectionInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);
    
    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null && 
          collectionChecker.isExactlyType(annotationValue.type!)) {
        
        final path = annotationValue.getField('path')!.toStringValue()!;
        final modelTypeName = _extractModelTypeFromAnnotation(annotation);
        final isSubcollection = path.contains('*');
        
        collections.add(SchemaCollectionInfo(
          path: path,
          modelTypeName: modelTypeName,
          isSubcollection: isSubcollection,
        ));
      }
    }
    
    return collections;
  }
  
  /// Extract the model type name from a Collection annotation
  static String _extractModelTypeFromAnnotation(ElementAnnotation annotation) {
    // Try to extract from annotation source
    final source = annotation.toSource();
    final match = RegExp(r'@Collection<(\w+)>').firstMatch(source);
    if (match != null) {
      return match.group(1)!;
    }
    
    // Default fallback
    return 'dynamic';
  }
  
  /// Get parent type name from subcollection path
  static String? _getParentTypeFromPath(String path, List<SchemaCollectionInfo> allCollections) {
    final segments = path.split('/');
    if (segments.length < 3) return null;
    
    // Find the parent collection that matches the pattern
    final parentPath = segments[0];
    for (final collection in allCollections) {
      if (collection.path == parentPath && !collection.isSubcollection) {
        return collection.modelTypeName;
      }
    }
    
    return null;
  }
  
  /// Get subcollection name from full path (last segment)
  static String _getSubcollectionName(String path) {
    return path.split('/').last;
  }
  
  
  /// Get singular name from collection path
  static String _getSingularName(String path) {
    final collectionName = path.split('/').last;
    // Simple pluralization removal - remove 's' if present
    if (collectionName.endsWith('s') && collectionName.length > 1) {
      return collectionName.substring(0, collectionName.length - 1);
    }
    return collectionName;
  }
  
  /// Generate filter and order by builders for all model types
  static void _generateFilterAndOrderByBuilders(
    StringBuffer buffer,
    Map<String, ClassElement> modelTypes,
  ) {
    for (final entry in modelTypes.entries) {
      final modelTypeName = entry.key;
      final classElement = entry.value;
      final constructor = classElement.unnamedConstructor;
      
      if (constructor == null) continue;
      
      // Find document ID field using the TypeAnalyzer utility
      final documentIdField = TypeAnalyzer.getDocumentIdField(constructor);
      
      // Generate FilterBuilder class
      FilterGenerator.generateFilterBuilderClass(
        buffer,
        modelTypeName,
        constructor,
        modelTypeName,
        documentIdField,
      );

      // Generate FilterBuilder classes for all nested types
      FilterGenerator.generateNestedFilterBuilderClasses(
        buffer,
        constructor,
        <String>{},
        modelTypeName,
      );
      buffer.writeln('');

      // Generate OrderByBuilder class
      OrderByGenerator.generateOrderByBuilderClass(
        buffer,
        modelTypeName,
        constructor,
        modelTypeName,
        documentIdField,
      );

      // Generate nested OrderByBuilder classes
      OrderByGenerator.generateNestedOrderByBuilderClasses(
        buffer,
        constructor,
        <String>{},
        modelTypeName,
        documentIdField,
      );
      buffer.writeln('');

      // Generate UpdateBuilder class
      UpdateGenerator.generateUpdateBuilderClass(
        buffer,
        modelTypeName,
        constructor,
        modelTypeName,
        documentIdField,
      );

      // Generate nested UpdateBuilder classes
      UpdateGenerator.generateNestedUpdateBuilderClasses(
        buffer,
        constructor,
        <String>{},
        modelTypeName,
      );

      // Generate nested updater classes
      UpdateGenerator.generateAllNestedUpdaterClasses(
        buffer,
        constructor,
        <String>{},
      );
      buffer.writeln('');

      // Generate AggregateFieldSelector class
      AggregateGenerator.generateAggregateFieldSelectorClass(
        buffer,
        modelTypeName,
        constructor,
        documentIdField,
      );

      // Generate nested aggregate selector classes
      AggregateGenerator.generateNestedAggregateSelector(
        buffer,
        modelTypeName,
        constructor,
        documentIdField,
      );

      // Generate nested aggregate selectors for all nested types
      AggregateGenerator.generateNestedAggregateSelectors(
        buffer,
        constructor,
        <String>{},
        documentIdField,
      );
      buffer.writeln('');
    }
  }
  
}