import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import '../utils/string_helpers.dart';
import '../utils/model_analyzer.dart';
import 'converter_generator.dart';
import 'filter_generator.dart';
import 'order_by_generator.dart';
import 'update_generator.dart';
import 'aggregate_generator.dart';

/// Information about a collection annotation extracted from a schema variable
class SchemaCollectionInfo {
  final String path;
  final String modelTypeName;
  final bool isSubcollection;
  final DartType? modelType; // Store the actual DartType for element extraction

  SchemaCollectionInfo({
    required this.path,
    required this.modelTypeName,
    required this.isSubcollection,
    this.modelType,
  });
}

/// Generator for schema-based ODM code
class SchemaGenerator {
  /// Generate schema class and extensions from annotated variable (with converters)
  static String generateSchemaCode(
    TopLevelVariableElement variableElement,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    final buffer = StringBuffer();

    // Use variable name for clean class name (e.g., "schema" -> "Schema", "helloSchema" -> "HelloSchema")
    final variableName = variableElement.name;
    final schemaClassName = StringHelpers.capitalize(variableName);

    // Extract the assigned value (e.g., "_$TestSchema") for the const name
    final assignedValue = _extractAssignedValue(variableElement);
    final schemaConstName = assignedValue;

    // Generate the schema class
    _generateSchemaClass(buffer, schemaClassName, schemaConstName);

    // Generate converters for all custom types discovered through type analysis
    buffer.write(ConverterGenerator.generateConvertersForCustomTypes(modelAnalyses));
  

    // Generate filter and order by builders for each model type
    buffer.writeln('// Starting to generate filter and order by selectors...');
    _generateFilterAndOrderBySelectors(buffer, modelAnalyses);
    buffer.writeln('// Finished generating filter and order by selectors');

    // Generate ODM extensions
    _generateODMExtensions(buffer, schemaClassName, collections, modelAnalyses);

    // Generate transaction context extensions
    _generateTransactionContextExtensions(
      buffer,
      schemaClassName,
      collections,
      modelAnalyses,
    );

    // Generate batch context extensions
    _generateBatchContextExtensions(
      buffer,
      schemaClassName,
      collections,
      modelAnalyses,
    );

    // Generate unique document classes for each collection path
    _generateUniqueDocumentClasses(
      buffer,
      schemaClassName,
      collections,
      modelAnalyses,
    );

    // Generate document extensions for subcollections (path-specific)
    _generateDocumentExtensions(
      buffer,
      schemaClassName,
      collections,
      modelAnalyses,
    );

    // Generate batch document extensions for subcollections
    _generateBatchDocumentExtensions(
      buffer,
      schemaClassName,
      collections,
      modelAnalyses,
    );

    return buffer.toString();
  }


  /// Generate the schema class and const instance
  static void _generateSchemaClass(
    StringBuffer buffer,
    String schemaClassName,
    String originalVariableName,
  ) {
    // Generate the schema class
    buffer.writeln(
      '/// Generated schema class - dummy class that only serves as type marker',
    );
    buffer.writeln('class $schemaClassName extends FirestoreSchema {');
    buffer.writeln('  const $schemaClassName();');
    buffer.writeln('}');
    buffer.writeln('');

    // Generate the const instance that can be assigned to _$VariableName
    buffer.writeln('/// Generated schema instance');
    buffer.writeln(
      'const $schemaClassName $originalVariableName = $schemaClassName();',
    );
    buffer.writeln('');
  }

  /// Generate ODM extensions for the schema
  static void _generateODMExtensions(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();
    if (rootCollections.isEmpty) return;

    buffer.writeln(
      '/// Extension to add collections to FirestoreODM<$schemaClassName>',
    );
    buffer.writeln(
      'extension ${schemaClassName}ODMExtensions on FirestoreODM<$schemaClassName> {',
    );

    for (final collection in rootCollections) {
      final collectionName = StringHelpers.camelCase(collection.path);
      // Get document ID field from model analysis
      final baseClassName = _extractBaseClassName(collection.modelTypeName);
      final analysis = modelAnalyses[collection.modelTypeName] ?? modelAnalyses[baseClassName];
      final converterName = _generateConverterCall(collection.modelTypeName, analysis);
      final documentIdField = analysis?.documentIdFieldName;
      final documentIdFieldValue = documentIdField ?? 'id';

      final collectionClassName = _generateDocumentClassName(collection.path).replaceAll('Document', 'Collection');
      
      buffer.writeln('  /// Access ${collection.path} collection');
      buffer.writeln(
        '  $collectionClassName get $collectionName =>',
      );
      buffer.writeln(
        '    $collectionClassName(',
      );
      buffer.writeln(
        '      query: firestore.collection(\'${collection.path}\'),',
      );
      buffer.writeln('      converter: $converterName,');
      buffer.writeln('      documentIdField: \'$documentIdFieldValue\',');
      buffer.writeln('    );');
      buffer.writeln('');
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate ODM extensions for the schema
  static void _generateTransactionContextExtensions(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();
    if (rootCollections.isEmpty) return;

    buffer.writeln(
      '/// Extension to add collections to FirestoreODM<$schemaClassName>',
    );
    buffer.writeln(
      'extension ${schemaClassName}TransactionContextExtensions on TransactionContext<$schemaClassName> {',
    );

    for (final collection in rootCollections) {
      final collectionName = StringHelpers.camelCase(collection.path);
      final baseClassName = _extractBaseClassName(collection.modelTypeName);
      final analysis = modelAnalyses[collection.modelTypeName] ?? modelAnalyses[baseClassName];
      final converterName = _generateConverterCall(collection.modelTypeName, analysis);

      // Get document ID field from model analysis
      final documentIdField = analysis?.documentIdFieldName;
      final documentIdFieldValue = documentIdField ?? 'id';

      buffer.writeln('  /// Access ${collection.path} collection');
      buffer.writeln(
        '  TransactionCollection<$schemaClassName, ${collection.modelTypeName}> get $collectionName =>',
      );
      buffer.writeln(
        '    TransactionCollection<$schemaClassName, ${collection.modelTypeName}>(',
      );
      buffer.writeln('      transaction: transaction,');
      buffer.writeln('      query: ref.collection(\'${collection.path}\'),');
      buffer.writeln('      converter: $converterName,');
      buffer.writeln('      context: this,');
      buffer.writeln('      documentIdField: \'$documentIdFieldValue\',');
      buffer.writeln('    );');
      buffer.writeln('');
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate batch context extensions for the schema
  static void _generateBatchContextExtensions(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();
    if (rootCollections.isEmpty) return;

    buffer.writeln(
      '/// Extension to add collections to BatchContext<$schemaClassName>',
    );
    buffer.writeln(
      'extension ${schemaClassName}BatchContextExtensions on BatchContext<$schemaClassName> {',
    );

    for (final collection in rootCollections) {
      final collectionName = StringHelpers.camelCase(collection.path);
      
      // Get document ID field from model analysis
      final baseClassName = _extractBaseClassName(collection.modelTypeName);
      final analysis = modelAnalyses[collection.modelTypeName] ?? modelAnalyses[baseClassName];
      final converterName = _generateConverterCall(collection.modelTypeName, analysis);
      final documentIdField = analysis?.documentIdFieldName;
      final documentIdFieldValue = documentIdField ?? 'id';

      buffer.writeln('  /// Access ${collection.path} collection');
      buffer.writeln(
        '  BatchCollection<$schemaClassName, ${collection.modelTypeName}> get $collectionName =>',
      );
      buffer.writeln(
        '    BatchCollection<$schemaClassName, ${collection.modelTypeName}>(',
      );
      buffer.writeln(
        '      collection: firestoreInstance.collection(\'${collection.path}\'),',
      );
      buffer.writeln('      converter: $converterName,');
      buffer.writeln('      documentIdField: \'$documentIdFieldValue\',');
      buffer.writeln('      context: this,');
      buffer.writeln('    );');
      buffer.writeln('');
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  /// Generate unique document and collection classes for each collection path
  static void _generateUniqueDocumentClasses(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    buffer.writeln('// Generated unique document and collection classes for each collection path');
    
    for (final collection in collections) {
      final documentClassName = _generateDocumentClassName(collection.path);
      final collectionClassName = documentClassName.replaceAll('Document', 'Collection');
      final modelType = collection.modelTypeName;
      
      // Generate document class
      buffer.writeln('/// Document class for ${collection.path} collection');
      buffer.writeln('class $documentClassName extends FirestoreDocument<$schemaClassName, $modelType> {');
      buffer.writeln('  $documentClassName(');
      buffer.writeln('    super.ref,');
      buffer.writeln('    super.converter,');
      buffer.writeln('    super.documentIdField,');
      buffer.writeln('  );');
      buffer.writeln('}');
      buffer.writeln('');
      
      // Generate collection class
      buffer.writeln('/// Collection class for ${collection.path} collection');
      buffer.writeln('class $collectionClassName extends FirestoreCollection<$schemaClassName, $modelType> {');
      buffer.writeln('  $collectionClassName({');
      buffer.writeln('    required super.query,');
      buffer.writeln('    required super.converter,');
      buffer.writeln('    required super.documentIdField,');
      buffer.writeln('  });');
      buffer.writeln('');
      buffer.writeln('  /// Gets a document reference with the specified ID');
      buffer.writeln('  @override');
      buffer.writeln('  $documentClassName call(String id) =>');
      buffer.writeln('    $documentClassName(query.doc(id), converter, documentIdField);');
      buffer.writeln('}');
      buffer.writeln('');
    }
  }

  /// Generate document extensions for subcollections
  static void _generateDocumentExtensions(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    final subcollections = collections.where((c) => c.isSubcollection).toList();

    // Group subcollections by parent type and include path info
    final parentGroups = <String, List<SchemaCollectionInfo>>{};
    for (final subcol in subcollections) {
      final parentType = _getParentTypeFromPath(subcol.path, collections);
      if (parentType != null) {
        parentGroups.putIfAbsent(parentType, () => []).add(subcol);
      }
    }

    // Group subcollections by their parent collection path
    final pathGroups = <String, List<SchemaCollectionInfo>>{};
    for (final subcol in subcollections) {
      final parentPath = _getParentCollectionPath(subcol.path);
      if (parentPath != null) {
        pathGroups.putIfAbsent(parentPath, () => []).add(subcol);
      }
    }

    for (final entry in pathGroups.entries) {
      final parentPath = entry.key;
      final subcolsForParent = entry.value;
      final parentDocumentClassName = _generateDocumentClassName(parentPath);

      buffer.writeln(
        '/// Extension to access subcollections on $parentDocumentClassName',
      );
      buffer.writeln(
        'extension ${parentDocumentClassName}Extensions on $parentDocumentClassName {',
      );

      for (final subcol in subcolsForParent) {
        final subcollectionName = _getSubcollectionName(subcol.path);
        final getterName = StringHelpers.camelCase(subcollectionName);
        final subcolBaseClassName = _extractBaseClassName(subcol.modelTypeName);
        final subcolAnalysis = modelAnalyses[subcol.modelTypeName] ?? modelAnalyses[subcolBaseClassName];
        final converterName = _generateConverterCall(subcol.modelTypeName, subcolAnalysis);

        // Find the class element for this model type to get document ID field
        final analysis = modelAnalyses[subcol.modelTypeName];
        // ignore: deprecated_member_use
        final documentIdField = analysis?.documentIdFieldName;
        final documentIdFieldValue = documentIdField ?? 'id';

        // Generate unique collection class name for this subcollection path
        final subcollectionClassName = _generateDocumentClassName(subcol.path).replaceAll('Document', 'Collection');
        
        buffer.writeln('  /// Access $subcollectionName subcollection');
        buffer.writeln(
          '  $subcollectionClassName get $getterName =>',
        );
        buffer.writeln(
          '    $subcollectionClassName(',
        );
        buffer.writeln('      query: ref.collection(\'$subcollectionName\'),');
        buffer.writeln('      converter: $converterName,');
        buffer.writeln('      documentIdField: \'$documentIdFieldValue\',');
        buffer.writeln('    );');
        buffer.writeln('');
      }

      buffer.writeln('}');
      buffer.writeln('');
    }
  }

  /// Extract collection annotations from a variable element
  static List<SchemaCollectionInfo> extractCollectionAnnotations(
    TopLevelVariableElement element,
  ) {
    final collections = <SchemaCollectionInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);

    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null &&
          collectionChecker.isExactlyType(annotationValue.type!)) {
        final path = annotationValue.getField('path')!.toStringValue()!;
        final modelTypeName = _extractModelTypeFromAnnotation(annotation);
        final isSubcollection = path.contains('*');

        collections.add(
          SchemaCollectionInfo(
            path: path,
            modelTypeName: modelTypeName,
            isSubcollection: isSubcollection,
          ),
        );
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
  static String? _getParentTypeFromPath(
    String path,
    List<SchemaCollectionInfo> allCollections,
  ) {
    final segments = path.split('/');
    if (segments.length < 3) return null;

    // For subcollections like "users/*/posts", the parent collection is "users"
    // For nested subcollections like "users/*/posts/*/comments", the parent collection is "users/*/posts"
    // Build the parent path by removing the last segment (subcollection name)
    final parentSegments = segments.sublist(0, segments.length - 1);
    final parentPath = parentSegments.join('/');
    
    // First try to find exact match
    for (final collection in allCollections) {
      if (collection.path == parentPath) {
        return collection.modelTypeName;
      }
    }
    
    // If no exact match and parent path contains wildcards, try to find the base collection
    // For example: "users/*" should match "users"
    if (parentPath.contains('*')) {
      // Remove wildcard segments and try to find base collection
      final baseSegments = <String>[];
      for (final segment in parentSegments) {
        if (segment == '*') break;
        baseSegments.add(segment);
      }
      
      if (baseSegments.isNotEmpty) {
        final basePath = baseSegments.join('/');
        for (final collection in allCollections) {
          if (collection.path == basePath && !collection.isSubcollection) {
            return collection.modelTypeName;
          }
        }
      }
    }

    return null;
  }

  /// Get subcollection name from full path (last segment)
  static String _getSubcollectionName(String path) {
    return path.split('/').last;
  }

  /// Generate filter and order by builders for all model types
  static void _generateFilterAndOrderBySelectors(
    StringBuffer buffer,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    for (final analysis in modelAnalyses.values) {
      if (!analysis.fields.entries.isNotEmpty) continue;

      // Generate FilterBuilder class using ModelAnalysis
      FilterGenerator.generateFilterSelectorClassFromAnalysis(buffer, analysis);
      buffer.writeln('');

      // Generate OrderBySelector class using ModelAnalysis
      OrderByGenerator.generateOrderBySelectorClassFromAnalysis(
        buffer,
        analysis,
      );
      buffer.writeln('');

      // Generate UpdateBuilder class using new signature
      UpdateGenerator.generateUpdateBuilderClass(buffer, analysis);
      buffer.writeln('');

      // Generate AggregateFieldSelector class using ModelAnalysis
      AggregateGenerator.generateAggregateFieldSelectorFromAnalysis(
        buffer,
        analysis,
      );

      buffer.writeln('');
    }
  }

  /// Extract the assigned value from a variable element (e.g., "_$TestSchema" from "final testSchema = _$TestSchema;")
  static String _extractAssignedValue(TopLevelVariableElement variableElement) {
    try {
      // Try to get the source location and extract the assigned value
      final source = variableElement.source;
      if (source != null) {
        final contents = source.contents.data;
        final name = variableElement.name;

        // Find the variable declaration line
        final lines = contents.split('\n');
        for (final line in lines) {
          if (line.contains('$name =') && line.contains('_\$')) {
            // Extract the assigned value (everything after '=' and before ';')
            final equalIndex = line.indexOf('$name =');
            if (equalIndex != -1) {
              final afterEqual = line
                  .substring(equalIndex + '$name ='.length)
                  .trim();
              final assignedValue = afterEqual
                  .replaceAll(RegExp(r';.*$'), '')
                  .trim();

              // Validate that it looks like a proper assigned value
              if (assignedValue.isNotEmpty && assignedValue.startsWith('_\$')) {
                return assignedValue;
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors and fall back to convention
    }

    // Fallback: generate from variable name following the convention
    return '_\$${StringHelpers.capitalize(variableElement.name)}';
  }

  /// Generate batch document extensions for subcollections
  static void _generateBatchDocumentExtensions(
    StringBuffer buffer,
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    Map<String, ModelAnalysis> modelAnalyses,
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

      buffer.writeln(
        '/// Extension to access subcollections on $parentType batch document',
      );
      buffer.writeln(
        'extension ${schemaClassName}${parentType}BatchDocumentSubcollectionExtensions on BatchDocument<$schemaClassName, $parentType> {',
      );

      for (final subcol in subcolsForParent) {
        final subcollectionName = _getSubcollectionName(subcol.path);
        final getterName = StringHelpers.camelCase(subcollectionName);
        final subcolBaseClassName = _extractBaseClassName(subcol.modelTypeName);
        final subcolAnalysis = modelAnalyses[subcol.modelTypeName] ?? modelAnalyses[subcolBaseClassName];
        final converterName = _generateConverterCall(subcol.modelTypeName, subcolAnalysis);

        // Find the class element for this model type to get document ID field
        final analysis = modelAnalyses[subcol.modelTypeName];
        final documentIdField = analysis?.documentIdFieldName;
        final documentIdFieldValue = documentIdField ?? 'id';

        buffer.writeln('  /// Access $subcollectionName subcollection for batch operations');
        buffer.writeln(
          '  BatchCollection<$schemaClassName, ${subcol.modelTypeName}> get $getterName =>',
        );
        buffer.writeln(
          '    BatchCollection<$schemaClassName, ${subcol.modelTypeName}>(',
        );
        buffer.writeln('      collection: ref.collection(\'$subcollectionName\'),');
        buffer.writeln('      converter: $converterName,');
        buffer.writeln('      documentIdField: \'$documentIdFieldValue\',');
        buffer.writeln('      context: context,');
        buffer.writeln('    );');
        buffer.writeln('');
      }

      buffer.writeln('}');
      buffer.writeln('');
    }
  }

  /// Convert PascalCase to lowerCamelCase
  static String _toLowerCamelCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toLowerCase() + text.substring(1);
  }

  /// Get parent collection path from subcollection path
  /// e.g., "users/*/posts" -> "users"
  /// e.g., "posts/*/comments" -> "posts"
  /// e.g., "users/*/posts/*/comments" -> "users/*/posts"
  static String? _getParentCollectionPath(String subcollectionPath) {
    final segments = subcollectionPath.split('/');
    if (segments.length >= 3) {
      // Return all segments except the last one (which is the subcollection name)
      final parentSegments = segments.take(segments.length - 2).toList();
      if (parentSegments.isNotEmpty) {
        return parentSegments.join('/');
      }
    }
    return null;
  }

  /// Generate document class name from collection path
  /// e.g., "users" -> "UsersDocument", "users2" -> "Users2Document"
  /// e.g., "users/*/posts" -> "Users_PostsDocument"
  /// e.g., "users/*/posts/*/comments" -> "Users_Posts_CommentsDocument"
  static String _generateDocumentClassName(String collectionPath) {
    // Split path and filter out wildcards
    final segments = collectionPath.split('/')
        .where((segment) => segment != '*')
        .toList();
    
    // Convert each segment to PascalCase and join with underscore
    final capitalizedSegments = segments
        .map((segment) => StringHelpers.capitalize(segment))
        .toList();
    
    final className = capitalizedSegments.join('_');
    return '${className}Document';
  }

  /// Get model type from collection path
  /// e.g., "users" -> "User", "posts" -> "Post"
  static String? _getModelTypeFromCollectionPath(String collectionPath, List<SchemaCollectionInfo> collections) {
    for (final collection in collections) {
      if (collection.path == collectionPath && !collection.isSubcollection) {
        return collection.modelTypeName;
      }
    }
    return null;
  }

  /// Generate converter call based on whether the type is generic or not
  static String _generateConverterCall(String modelTypeName, ModelAnalysis? analysis) {
    // Extract base class name from potentially generic type name
    final baseClassName = _extractBaseClassName(modelTypeName);
    
    if (analysis == null || !analysis.isGeneric) {
      // Non-generic converter
      return 'const ${baseClassName}Converter()';
    }
    
    // Generic converter - need to extract type parameters from modelTypeName
    final typeArgs = _extractTypeArguments(modelTypeName);
    if (typeArgs.isNotEmpty) {
      final args = typeArgs.map((typeArg) {
        // For primitive types, use PrimitiveConverter
        if (_isPrimitiveType(typeArg)) {
          return 'const PrimitiveConverter<$typeArg>()';
        } else {
          // For custom types, use their converter
          return 'const ${typeArg}Converter()';
        }
      }).join(', ');
      return 'const ${baseClassName}Converter($args)';
    }
    
    // Fallback for generic types without parameter converters
    return 'const ${baseClassName}Converter()';
  }

  /// Extract type arguments from generic type name
  /// e.g., "SimpleGeneric<String>" -> ["String"]
  /// e.g., "Map<String, int>" -> ["String", "int"]
  static List<String> _extractTypeArguments(String typeName) {
    final startIndex = typeName.indexOf('<');
    final endIndex = typeName.lastIndexOf('>');
    
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      return [];
    }
    
    final typeArgsString = typeName.substring(startIndex + 1, endIndex);
    // Simple split by comma, could be enhanced for nested generics
    return typeArgsString.split(',').map((s) => s.trim()).toList();
  }

  /// Check if a type is a primitive type
  static bool _isPrimitiveType(String typeName) {
    const primitiveTypes = {
      'String', 'int', 'double', 'bool', 'num',
      'DateTime', 'Duration', 'dynamic', 'Object'
    };
    return primitiveTypes.contains(typeName);
  }

  /// Extract base class name from generic type name
  /// e.g., "SimpleGeneric<String>" -> "SimpleGeneric"
  static String _extractBaseClassName(String typeName) {
    final genericIndex = typeName.indexOf('<');
    if (genericIndex == -1) {
      return typeName;
    }
    return typeName.substring(0, genericIndex);
  }

}
