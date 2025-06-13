import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

import '../utils/string_helpers.dart';
import '../utils/model_analyzer.dart';
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

    // Generate global converter instances for all model types
    final allModelTypes = collections.map((c) => c.modelTypeName).toSet();
    generateGlobalConverterInstances(buffer, allModelTypes);

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

    // Generate document extensions for subcollections
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

  /// Generate converter instances globally for all model types
  static void generateGlobalConverterInstances(
    StringBuffer buffer,
    Set<String> modelTypes,
  ) {
    // Generate converter instances for each model type
    for (final modelType in modelTypes) {
      final converterName = '${_toLowerCamelCase(modelType)}Converter';
      buffer.writeln('/// Generated converter for $modelType');
      buffer.writeln('final $converterName = ModelConverter<$modelType>(');
      buffer.writeln('  fromJson: (json) => $modelType.fromJson(json),');
      buffer.writeln('  toJson: (instance) => instance.toJson(),');
      buffer.writeln(');');
      buffer.writeln('');
    }
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
      final converterName =
          '${_toLowerCamelCase(collection.modelTypeName)}Converter';

      // Get document ID field from model analysis
      final analysis = modelAnalyses[collection.modelTypeName];
      final documentIdField = analysis?.documentIdFieldName;
      final documentIdFieldValue = documentIdField ?? 'id';

      buffer.writeln('  /// Access ${collection.path} collection');
      buffer.writeln(
        '  FirestoreCollection<$schemaClassName, ${collection.modelTypeName}> get $collectionName =>',
      );
      buffer.writeln(
        '    FirestoreCollection<$schemaClassName, ${collection.modelTypeName}>(',
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
      final converterName =
          '${_toLowerCamelCase(collection.modelTypeName)}Converter';

      // Get document ID field from model analysis
      final analysis = modelAnalyses[collection.modelTypeName];
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
      final converterName =
          '${_toLowerCamelCase(collection.modelTypeName)}Converter';

      // Get document ID field from model analysis
      final analysis = modelAnalyses[collection.modelTypeName];
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

  /// Generate document extensions for subcollections
  static void _generateDocumentExtensions(
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
        '/// Extension to access subcollections on $parentType document',
      );
      buffer.writeln(
        'extension ${schemaClassName}${parentType}DocumentExtensions on FirestoreDocument<$schemaClassName, $parentType> {',
      );

      for (final subcol in subcolsForParent) {
        final subcollectionName = _getSubcollectionName(subcol.path);
        final getterName = StringHelpers.camelCase(subcollectionName);
        final converterName =
            '${_toLowerCamelCase(subcol.modelTypeName)}Converter';

        // Find the class element for this model type to get document ID field
        final analysis = modelAnalyses[subcol.modelTypeName];
        // ignore: deprecated_member_use
        final documentIdField = analysis?.documentIdFieldName;
        final documentIdFieldValue = documentIdField ?? 'id';

        buffer.writeln('  /// Access $subcollectionName subcollection');
        buffer.writeln(
          '  FirestoreCollection<$schemaClassName, ${subcol.modelTypeName}> get $getterName =>',
        );
        buffer.writeln(
          '    FirestoreCollection<$schemaClassName, ${subcol.modelTypeName}>(',
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

  /// Generate filter and order by builders for all model types
  static void _generateFilterAndOrderBySelectors(
    StringBuffer buffer,
    Map<String, ModelAnalysis> modelAnalyses,
  ) {
    for (final analysis in modelAnalyses.values) {
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
        final converterName =
            '${_toLowerCamelCase(subcol.modelTypeName)}Converter';

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
}
