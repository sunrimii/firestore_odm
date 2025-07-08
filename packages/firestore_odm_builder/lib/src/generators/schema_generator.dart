import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType, RecordType;
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:firestore_odm_builder/src/generators/aggregate_generator.dart';
import 'package:firestore_odm_builder/src/generators/filter_generator.dart';
import 'package:firestore_odm_builder/src/generators/order_by_generator.dart';
import 'package:firestore_odm_builder/src/generators/update_generator.dart';
import 'package:firestore_odm_builder/src/utils/converters/converter_factory.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';

import '../utils/model_analyzer.dart';

/// Information about a collection annotation extracted from a schema variable
class SchemaCollectionInfo {
  final String path;
  final String modelTypeName;
  final bool isSubcollection;
  final String schemaTypeName;
  final InterfaceType modelType;

  const SchemaCollectionInfo({
    required this.path,
    required this.modelTypeName,
    required this.isSubcollection,
    required this.schemaTypeName,
    required this.modelType,
  });
}

final preferInlineAnnotation = refer(
  'pragma',
).call([literalString('vm:prefer-inline')]);
final overrideAnnotation = refer('override');

enum ClassType {
  root('Root'),
  collection('Collection'),
  document('Document'),
  transactionContext('TransactionContext'),
  transactionCollection('TransactionCollection'),
  transactionDocument('TransactionDocument'),
  batchContext('BatchContext'),
  batchCollection('BatchCollection'),
  batchDocument('BatchDocument'),
  patchBuilder('PatchBuilder');

  const ClassType(this.suffix);

  final String suffix;
}

/// Generator for schema-based ODM code using code_builder
class SchemaGenerator {
  /// Generate schema class and extensions from annotated variable (with converters)
  static String generateSchemaCode(
    TopLevelVariableElement variableElement,
    List<SchemaCollectionInfo> collections,
  ) {
    // Create fresh instances for this schema to avoid cache pollution
    final modelAnalyzer = ModelAnalyzer();
    final converterFactory = ConverterFactory(modelAnalyzer);

    validate(collections: collections, modelAnalyzer: modelAnalyzer);

    final library = Library(
      (b) => b.body.addAll(
        generateAllLibraryMembers(
          variableElement: variableElement,
          collections: collections,
          modelAnalyzer: modelAnalyzer,
          converterFactory: converterFactory,
        ),
      ),
    );

    final emitter = DartEmitter(useNullSafetySyntax: true);
    return library.accept(emitter).toString();
  }

  /// Generate schema class and extensions from annotated variable (with converters)
  static String generateSchemaCode2(
    ClassElement classElement,
    List<SchemaCollectionInfo> collections,
  ) {
    final library = Library(
      (b) =>
          b.body.addAll(generateAllLibraryMembers2(classElement, collections)),
    );

    final emitter = DartEmitter(useNullSafetySyntax: true);
    return library.accept(emitter).toString();
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
    return '_\$${variableElement.name.upperFirst()}';
  }

  /// Generate document class name from collection path
  /// e.g., "users" -> "UsersDocument", "users2" -> "Users2Document"
  /// e.g., "users/*/posts" -> "UsersCollectionPostsDocument"
  /// e.g., "users/*/posts/*/comments" -> "UsersCollectionPostsCollectionCommentsDocument"
  static String generateClassName({
    required String schemaClassName,
    required ClassType type,
    String collectionPath = '',
    bool private = false,
  }) {
    return (private ? '_' : '') +
        '\$' +
        schemaClassName.upperFirst() +
        _getSegments(collectionPath).join('') +
        type.suffix.upperFirst();
  }

  static List<String> _getSegments(String collectionPath) {
    // Split path and filter out wildcards
    final segments = collectionPath
        .split('/')
        .where((segment) => segment != '*')
        .toList();

    // Convert each segment to PascalCase and join with underscore
    final capitalizedSegments = segments
        .map((segment) => segment.upperFirst())
        .toList();

    return capitalizedSegments;
  }

  static TypeReference _getPatchBuilderType(SchemaCollectionInfo collection) {
    return TypeReference(
      (b) => b
        ..symbol = collection.modelType.element.name + 'PatchBuilder'
        ..types.addAll(
          collection.modelType.typeArguments.map((t) => t.reference),
        ),
    );
  }

  static Expression _getPatchBuilderInstanceExpression(
    SchemaCollectionInfo collection, {
    required ConverterFactory converterFactory,
  }) {
    return _getPatchBuilderType(collection).newInstance(
      [],
      Map.fromIterables(
        collection.modelType.element.typeParameters.map(
          (e) => 'converter${e.name.camelCase()}',
        ),
        collection.modelType.typeArguments.map(
          (e) => converterFactory.getConverter(e).toConverterExpr(),
        ),
      ),
    );
  }

  static RecordType _getPathRecord(String path) {
    final segments = _getSegments(path);
    return RecordType(
      (b) => b
        ..positionalFieldTypes.addAll(
          segments.map(
            (segment) => TypeReference(
              (b) => b..symbol = '_\$${segment.upperFirst()}Collection',
            ),
          ),
        ),
    );
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

  /// Get subcollection name from full path (last segment)
  static String _getCollectionName(String path) {
    return path.split('/').last;
  }

  static void validate({
    required List<SchemaCollectionInfo> collections,
    required ModelAnalyzer modelAnalyzer,
  }) {
    // Ensure all collections have unique paths
    final uniquePaths = <String>{};
    for (final collection in collections) {
      if (!uniquePaths.add(collection.path)) {
        throw ArgumentError(
          'Duplicate collection path found: ${collection.path}',
        );
      }
    }

    // Ensure no subcollection has the same path as a root collection
    final rootPaths = collections
        .where((c) => !c.isSubcollection)
        .map((c) => c.path)
        .toSet();
    for (final collection in collections.where((c) => c.isSubcollection)) {
      if (rootPaths.contains(collection.path)) {
        throw ArgumentError(
          'Subcollection path "${collection.path}" conflicts with root collection',
        );
      }
    }
    const odmTypeChecker = TypeChecker.fromRuntime(FirestoreOdm);
    final missingAnnotations = collections
        .expand((c) => run(c.modelType, modelAnalyzer))
        .where(isUserType)
        .whereType<InterfaceType>()
        .map((t) => t.element.thisType)
        .where((t) => !odmTypeChecker.hasAnnotationOf(t.element));
    if (missingAnnotations.isNotEmpty) {
      throw ArgumentError(
        'The following model types are missing @FirestoreOdm annotation: '
        '${missingAnnotations.map((t) => t.element.name).join(', ')}',
      );
    }
  }

  static List<Spec> generateAllLibraryMembers2(
    ClassElement classElement,
    List<SchemaCollectionInfo> collections,
  ) {
    final specs = <Spec>[];

    // Create fresh instances for this schema to avoid cache pollution
    final modelAnalyzer = ModelAnalyzer();
    final converterFactory = ConverterFactory(modelAnalyzer);

    specs.addAll(generateCollectionIdentifiers(collections));

    // temporary: use class name as schema type name
    final schemaClassName = collections.first.schemaTypeName;

    // specs.addAll(
    //   generateFilterAndOrderBySelectors(
    //     collections,
    //     schemaClassName,
    //     converterFactory: converterFactory,
    //     modelAnalyzer: modelAnalyzer,
    //   ),
    // );
    // Generate filter and order by builders for each model type

    // Generate ODM extensions
    specs.add(
      generateODMExtensions(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate transaction context extensions
    specs.add(
      generateTransactionContext(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );
    specs.addAll(
      generateTransactionDocuments(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate batch context extensions

    // Generate unique document classes for each collection path
    specs.addAll(
      generateUniqueDocumentClasses(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate document extensions for subcollections (path-specific)
    // specs.addAll(generateDocumentExtensions(schemaClassName, collections));

    // Generate batch document extensions for subcollections
    final batchExtension = generateBatchContextExtensions(
      schemaClassName,
      collections,
      converterFactory,
      modelAnalyzer,
    );
    if (batchExtension != null) specs.add(batchExtension);
    specs.addAll(
      generateBatchDocumentExtensions(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    specs.addAll(converterFactory.specs);

    return specs;
  }

  /// Generate all library members
  static List<Spec> generateAllLibraryMembers({
    required TopLevelVariableElement variableElement,
    required List<SchemaCollectionInfo> collections,
    required ModelAnalyzer modelAnalyzer,
    required ConverterFactory converterFactory,
  }) {
    final specs = <Spec>[];

    specs.addAll(generateCollectionIdentifiers(collections));

    // Use variable name for clean class name (e.g., "schema" -> "Schema", "helloSchema" -> "HelloSchema")
    final variableName = variableElement.name;
    final schemaClassName = variableName.upperFirst();

    // Extract the assigned value (e.g., "_$TestSchema") for the const name
    final assignedValue = _extractAssignedValue(variableElement);
    final schemaConstName = assignedValue;

    // Generate the schema class and constant
    specs.addAll(
      generateSchemaClassAndConstant(schemaClassName, schemaConstName),
    );

    // specs.addAll(
    //   generateFilterAndOrderBySelectors(
    //     collections,
    //     schemaClassName,
    //     converterFactory: converterFactory,
    //     modelAnalyzer: modelAnalyzer,
    //   ),
    // );
    // Generate filter and order by builders for each model type

    // Generate ODM extensions
    specs.add(
      generateODMExtensions(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate transaction context extensions
    specs.add(
      generateTransactionContext(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );
    specs.addAll(
      generateTransactionDocuments(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate batch context extensions

    // Generate unique document classes for each collection path
    specs.addAll(
      generateUniqueDocumentClasses(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    // Generate document extensions for subcollections (path-specific)
    // specs.addAll(generateDocumentExtensions(schemaClassName, collections));

    // Generate batch document extensions for subcollections
    final batchExtension = generateBatchContextExtensions(
      schemaClassName,
      collections,
      converterFactory,
      modelAnalyzer,
    );
    if (batchExtension != null) specs.add(batchExtension);
    specs.addAll(
      generateBatchDocumentExtensions(
        schemaClassName,
        collections,
        converterFactory,
        modelAnalyzer,
      ),
    );

    specs.addAll(converterFactory.specs);

    return specs;
  }

  /// Generate the schema class and constant instance
  static List<Spec> generateSchemaClassAndConstant(
    String schemaClassName,
    String originalVariableName,
  ) {
    final specs = <Spec>[];

    // Generate the schema class
    final schemaClass = Class(
      (b) => b
        ..docs.add(
          '/// Generated schema class - dummy class that only serves as type marker',
        )
        ..name = schemaClassName
        ..extend = refer('FirestoreSchema')
        ..constructors.add(Constructor((b) => b..constant = true)),
    );
    specs.add(schemaClass);

    // Generate the const instance
    final constInstance = Field(
      (b) => b
        ..docs.add('/// Generated schema instance')
        ..modifier = FieldModifier.constant
        ..name = originalVariableName
        ..type = refer(schemaClassName)
        ..assignment = refer(schemaClassName).newInstance([]).code,
    );
    specs.add(constInstance);

    return specs;
  }

  /// Generate filter and order by builders for all model types
  static List<Spec> generateFilterAndOrderBySelectors(
    List<SchemaCollectionInfo> collections,
    String schemaClassName, {
    required ConverterFactory converterFactory,
    required ModelAnalyzer modelAnalyzer,
  }) {
    final specs = <Spec>[];

    for (final entry
        in collections
            .expand((c) => run(c.modelType, modelAnalyzer))
            .where(isUserType)
            .whereType<InterfaceType>()
            .groupSetsBy((t) => t.element.thisType)
            .entries) {
      if (TypeChecker.fromRuntime(
        FirestoreOdm,
      ).hasAnnotationOf(entry.key.element)) {
        // Skip types that are annotated with @FirestoreOdm
        continue;
      }

      final baseType = entry.key;

      // Generate FilterSelector class using ModelAnalysis
      final filterClass =
          FilterGenerator.generateFilterSelectorClassFromAnalysis(
            schemaClassName,
            baseType,
            modelAnalyzer: modelAnalyzer,
          );
      specs.add(filterClass);

      // Generate OrderBySelector class using ModelAnalysis
      final orderByClasses = OrderByGenerator.generateOrderByClasses(
        baseType,
        modelAnalyzer: modelAnalyzer,
      );
      specs.addAll(orderByClasses);

      // Generate AggregateFieldSelector extension using ModelAnalysis
      final aggregateExtension =
          AggregateGenerator.generateAggregateFieldSelectorFromAnalysis(
            schemaClassName,
            baseType,
            modelAnalyzer: modelAnalyzer,
          );
      if (aggregateExtension != null) {
        specs.add(aggregateExtension);
      }

      final updateExtension = UpdateGenerator.generateGenericUpdateBuilderClass(
        schemaClassName,
        baseType,
        modelAnalyzer: modelAnalyzer,
        converterFactory: converterFactory,
      );
      if (updateExtension != null) {
        specs.add(updateExtension);
      }

      for (final type in entry.value) {
        // Generate UpdateBuilder extension using ModelAnalysis
        final updateExtension = UpdateGenerator.generateUpdateBuilderClass(
          schemaClassName,
          type,
          modelAnalyzer: modelAnalyzer,
          converterFactory: converterFactory,
        );
        if (updateExtension != null) {
          specs.add(updateExtension);
        }
      }
    }

    return specs;
  }

  /// Generate ODM extensions for the schema
  static Extension generateODMExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionName = _getCollectionName(collection.path);
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'FirestoreCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
            _getPatchBuilderType(collection),
            FilterGenerator.getBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
              isRoot: true,
            ),
            OrderByGenerator.getOrderByBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
            ),
            AggregateGenerator.getBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
              isRoot: true,
            ),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collectionName.camelCase().lowerFirst()
            ..returns = collectionType
            ..type = MethodType.getter
            ..annotations.add(preferInlineAnnotation)
            ..body = collectionType
                // to simplify the type arguments
                .rebuild((b) => b..types.replace([]))
                .newInstance([], {
                  'query': refer('firestore').property('collection').call([
                    literalString(collection.path),
                  ]),
                  'converter': converterFactory
                      .getConverter(collection.modelType)
                      .toConverterExpr(),
                  'documentIdField': literalString(
                    modelAnalyzer.getDocumentIdFieldName(collection.modelType),
                  ),
                  'patchBuilder': _getPatchBuilderInstanceExpression(
                    collection,
                    converterFactory: converterFactory,
                  ),
                  'filterBuilder':
                      FilterGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,
                    modelAnalyzer: modelAnalyzer,
                    isRoot: true,
                  ),
                  'orderByBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body =
                          OrderByGenerator.getOrderByBuilderInstanceExpression(
                            type: collection.modelType,
                            context: refer('context'),
                            modelAnalyzer: modelAnalyzer,
                          ).code,
                  ).closure,
                  'aggregateBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body = AggregateGenerator.getBuilderInstanceExpression(
                        type: collection.modelType,
                        context: refer('context'),
                        modelAnalyzer: modelAnalyzer,
                        isRoot: true,
                      ).code,
                  ).closure,
                })
                .code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Class to add collections to `FirestoreODM<$schemaClassName>`',
        )
        ..name = '\$${schemaClassName.upperFirst()}ODM'
        ..on = TypeReference(
          (b) => b
            ..symbol = 'FirestoreODM'
            ..types.add(
              refer(
                schemaClassName.isEmpty ? 'FirestoreSchema' : schemaClassName,
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate ODM extensions for the schema
  static Class generateODMClass(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionName = _getCollectionName(collection.path);
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'FirestoreCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
            _getPatchBuilderType(collection),
            FilterGenerator.getBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
            ),
            OrderByGenerator.getOrderByBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
            ),
            AggregateGenerator.getBuilderType(
              type: collection.modelType,
              modelAnalyzer: modelAnalyzer,
              isRoot: true,
            ),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collectionName.camelCase().lowerFirst()
            ..returns = collectionType
            ..type = MethodType.getter
            ..annotations.add(preferInlineAnnotation)
            ..body = collectionType
                // to simplify the type arguments
                .rebuild((b) => b..types.replace([]))
                .newInstance([], {
                  'query': refer('firestore').property('collection').call([
                    literalString(collection.path),
                  ]),
                  'converter': converterFactory
                      .getConverter(collection.modelType)
                      .toConverterExpr(),
                  'documentIdField': literalString(
                    modelAnalyzer.getDocumentIdFieldName(collection.modelType),
                  ),
                  'patchBuilder': _getPatchBuilderInstanceExpression(
                    collection,
                    converterFactory: converterFactory,
                  ),
                  'filterBuilder':
                      FilterGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,
                    modelAnalyzer: modelAnalyzer,
                    isRoot: true,
                  ),
                  'orderByBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body =
                          OrderByGenerator.getOrderByBuilderInstanceExpression(
                            type: collection.modelType,
                            context: refer('context'),
                            modelAnalyzer: modelAnalyzer,
                          ).code,
                  ).closure,
                  'aggregateBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body = AggregateGenerator.getBuilderInstanceExpression(
                        type: collection.modelType,
                        context: refer('context'),
                        modelAnalyzer: modelAnalyzer,
                        isRoot: true,
                      ).code,
                  ).closure,
                })
                .code,
        ),
      );
    }

    return Class(
      (b) => b
        ..docs.add(
          '/// Class to add collections to `FirestoreODM<$schemaClassName>`',
        )
        ..name = '\$${schemaClassName.upperFirst()}ODM'
        ..extend = TypeReference(
          (b) => b
            ..symbol = 'FirestoreODM'
            ..types.add(
              refer(
                schemaClassName.isEmpty ? 'FirestoreSchema' : schemaClassName,
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate transaction context extensions for the schema
  static Extension generateTransactionContext(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.transactionCollection,
      );
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'TransactionCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collection.path.camelCase().lowerFirst()
            ..annotations.addAll([preferInlineAnnotation])
            ..returns = collectionType
            ..type = MethodType.getter
            ..body = collectionType.newInstance([], {
              'query': refer(
                'ref',
              ).property('collection').call([literalString(collection.path)]),
              'context': refer('this'),
              'converter': converterFactory
                  .getConverter(collection.modelType)
                  .toConverterExpr(),
              'documentIdField': literalString(
                modelAnalyzer.getDocumentIdFieldName(collection.modelType),
              ),
            }).code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Extension to add collections to `TransactionContext<$schemaClassName>`',
        )
        ..name = generateClassName(
          schemaClassName: schemaClassName,
          type: ClassType.transactionContext,
        )
        ..on = TypeReference(
          (b) => b
            ..symbol = 'TransactionContext'
            ..types.add(refer(schemaClassName)),
        )
        ..methods.addAll(methods),
    );
  }

  static List<Spec> generateTransactionDocuments(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.transactionDocument,
      );

      final modelType = collection.modelTypeName;
      final methods = <Method>[];
      for (final subcol in getSubcollections(collections, collection)) {
        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'TransactionCollection'
            ..types.addAll([
              refer(schemaClassName),
              refer(subcol.modelTypeName),
              _getPathRecord(subcol.path),
            ]),
        );

        methods.add(
          Method(
            (b) => b
              ..docs.add(
                '/// Access ${_getCollectionName(subcol.path)} subcollection',
              )
              ..annotations.addAll([preferInlineAnnotation])
              ..type = MethodType.getter
              ..name = _getCollectionName(subcol.path).camelCase().lowerFirst()
              ..returns = collectionType
              ..lambda = true
              ..body = collectionType.newInstance([], {
                'query': refer('ref').property('collection').call([
                  literalString(_getCollectionName(subcol.path)),
                ]),
                'context': refer('context'),
                'converter': converterFactory
                    .getConverter(subcol.modelType)
                    .toConverterExpr(),
                'documentIdField': literalString(
                  modelAnalyzer.getDocumentIdFieldName(subcol.modelType),
                ),
              }).code,
          ),
        );
      }

      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add(
              '/// Transaction document class for ${collection.path} collection',
            )
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'TransactionDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelType),
                  _getPathRecord(collection.path),
                ]),
            )
            ..methods.addAll(methods),
        );

        specs.add(documentClass);
      }
    }
    return specs;
  }

  /// Generate batch context extensions for the schema
  static Extension? generateBatchContextExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();
    if (rootCollections.isEmpty) return null;

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final documentIdFieldName = modelAnalyzer.getDocumentIdFieldName(
        collection.modelType,
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..type = MethodType.getter
            ..name = collection.path.camelCase().lowerFirst()
            ..returns = TypeReference(
              (b) => b
                ..symbol = 'BatchCollection'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(collection.modelTypeName),
                  _getPathRecord(collection.path),
                ]),
            )
            ..lambda = true
            ..body = TypeReference((b) => b..symbol = 'BatchCollection')
                .newInstance([], {
                  'collection': refer('firestoreInstance')
                      .property('collection')
                      .call([literalString(collection.path)]),
                  'converter': converterFactory
                      .getConverter(collection.modelType)
                      .toConverterExpr(),
                  'documentIdField': literalString(documentIdFieldName),
                  'context': refer('this'),
                })
                .code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Extension to add collections to BatchContext<$schemaClassName>',
        )
        ..name = '\$${schemaClassName.upperFirst()}BatchContextExtensions'
        ..on = TypeReference(
          (b) => b
            ..symbol = 'BatchContext'
            ..types.add(refer(schemaClassName)),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate unique document and collection classes for each collection path
  static List<Spec> generateUniqueDocumentClasses(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.document,
      );
      final collectionClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.collection,
      );
      final modelTypeName = collection.modelTypeName;

      final methods = <Method>[];

      for (final subcol in getSubcollections(collections, collection)) {
        final subcollectionName = _getCollectionName(subcol.path);
        final getterName = subcollectionName.camelCase().lowerFirst();
        final documentIdFieldName = modelAnalyzer.getDocumentIdFieldName(
          subcol.modelType,
        );

        // Generate unique collection class name for this subcollection path
        final collectionClassName = generateClassName(
          schemaClassName: schemaClassName,
          collectionPath: subcol.path,
          type: ClassType.collection,
        );

        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'FirestoreCollection'
            ..types.addAll([
              refer(schemaClassName),
              subcol.modelType.reference,
              _getPathRecord(subcol.path),
              _getPatchBuilderType(subcol),
              FilterGenerator.getBuilderType(
                type: subcol.modelType,
                modelAnalyzer: modelAnalyzer,
                isRoot: true,
              ),
              OrderByGenerator.getOrderByBuilderType(
                type: subcol.modelType,
                modelAnalyzer: modelAnalyzer,
              ),
              AggregateGenerator.getBuilderType(
                type: subcol.modelType,
                modelAnalyzer: modelAnalyzer,
                isRoot: true,
              ),
            ]),
        );
        methods.add(
          Method(
            (b) => b
              ..docs.add('/// Access $subcollectionName subcollection')
              ..type = MethodType.getter
              ..name = getterName
              ..returns = collectionType
              ..lambda = true
              ..body = collectionType
                  // to simplify the type arguments
                  .rebuild((b) => b..types.replace([]))
                  .newInstance([], {
                    'query': refer('ref').property('collection').call([
                      literalString(subcollectionName),
                    ]),
                    'converter': converterFactory
                        .getConverter(subcol.modelType)
                        .toConverterExpr(),
                    'documentIdField': literalString(documentIdFieldName),
                    'patchBuilder': _getPatchBuilderInstanceExpression(
                      subcol,
                      converterFactory: converterFactory,
                    ),
                    'filterBuilder':
                      FilterGenerator.getBuilderInstanceExpression(
                    type: subcol.modelType,
                    modelAnalyzer: modelAnalyzer,
                    isRoot: true,
                  ),
                    'orderByBuilderFunc': Method(
                      (b) => b
                        ..requiredParameters.add(
                          Parameter((b) => b..name = 'context'),
                        )
                        ..lambda = true
                        ..body =
                            OrderByGenerator.getOrderByBuilderInstanceExpression(
                              type: subcol.modelType,
                              context: refer('context'),
                              modelAnalyzer: modelAnalyzer,
                            ).code,
                    ).closure,
                    'aggregateBuilderFunc': Method(
                      (b) => b
                        ..requiredParameters.add(
                          Parameter((b) => b..name = 'context'),
                        )
                        ..lambda = true
                        ..body =
                            AggregateGenerator.getBuilderInstanceExpression(
                              type: subcol.modelType,
                              context: refer('context'),
                              modelAnalyzer: modelAnalyzer,
                              isRoot: true,
                            ).code,
                    ).closure,
                  })
                  .code,
          ),
        );
      }

      // Generate document class
      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add('/// Document class for ${collection.path} collection')
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'FirestoreDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelTypeName),
                  _getPathRecord(collection.path),
                  _getPatchBuilderType(collection),
                ]),
            )
            ..methods.addAll(methods),
        );
        specs.add(documentClass);
      }
    }

    return specs;
  }

  /// Generate document extensions for subcollections
  static List<Spec> generateCollectionIdentifiers(
    List<SchemaCollectionInfo> collections,
  ) {
    return [
      Code('''
/// Identifiers for all Firestore collections in the schema
/// Used to map collection paths to their respective collection classes
/// By combining collection classes (e.g., as tuple types),
/// we can use extension methods with record types to reduce boilerplate
/// Example: (_\$UsersCollection, _\$PostsCollection)
      '''),
      ...collections.map((c) => _getCollectionName(c.path)).toSet().map((c) {
        return Class(
          (b) => b
            ..name = '_\$${c.upperFirst()}Collection'
            ..modifier = ClassModifier.final$,
        );
      }),
    ];
  }

  static List<SchemaCollectionInfo> getSubcollections(
    List<SchemaCollectionInfo> collections,
    SchemaCollectionInfo parentCollection,
  ) {
    return collections.where((c) {
      final parentPath = _getParentCollectionPath(c.path);
      return c.isSubcollection && parentPath == parentCollection.path;
    }).toList();
  }

  /// Generate document extensions for subcollections
  static List<Spec> generateDocumentExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final specs = <Spec>[];
    final subcollections = collections.where((c) => c.isSubcollection).toList();

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
      final parentDocumentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: parentPath,
        type: ClassType.document,
      );

      final methods = <Method>[];

      for (final subcol in subcolsForParent) {
        final subcollectionName = _getCollectionName(subcol.path);
        final getterName = subcollectionName.camelCase().lowerFirst();
        final documentIdFieldName = modelAnalyzer.getDocumentIdFieldName(
          subcol.modelType,
        );

        // Generate unique collection class name for this subcollection path
        final collectionClassName = generateClassName(
          schemaClassName: schemaClassName,
          collectionPath: subcol.path,
          type: ClassType.collection,
        );
        methods.add(
          Method(
            (b) => b
              ..docs.add('/// Access $subcollectionName subcollection')
              ..type = MethodType.getter
              ..name = getterName
              ..returns = refer(collectionClassName)
              ..lambda = true
              ..body = refer(collectionClassName).newInstance([], {
                'query': refer('ref').property('collection').call([
                  literalString(subcollectionName),
                ]),
                'converter': converterFactory
                    .getConverter(subcol.modelType)
                    .toConverterExpr(),
                'documentIdField': literalString(documentIdFieldName),
              }).code,
          ),
        );
      }

      if (methods.isNotEmpty) {
        specs.add(
          Extension(
            (b) => b
              ..docs.add(
                '/// Extension to access subcollections on $parentDocumentClassName',
              )
              ..name = '${parentDocumentClassName}Extensions'
              ..on = refer(parentDocumentClassName)
              ..methods.addAll(methods),
          ),
        );
      }
    }

    return specs;
  }

  /// Generate batch document extensions for subcollections
  static List<Spec> generateBatchDocumentExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
    ConverterFactory converterFactory,
    ModelAnalyzer modelAnalyzer,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.batchDocument,
      );

      final modelType = collection.modelTypeName;
      final methods = <Method>[];
      for (final subcol in getSubcollections(collections, collection)) {
        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'BatchCollection'
            ..types.addAll([
              refer(schemaClassName),
              refer(subcol.modelTypeName),
              _getPathRecord(subcol.path),
            ]),
        );

        methods.add(
          Method(
            (b) => b
              ..docs.add(
                '/// Access ${_getCollectionName(subcol.path)} subcollection',
              )
              ..annotations.addAll([preferInlineAnnotation])
              ..type = MethodType.getter
              ..name = _getCollectionName(subcol.path).camelCase().lowerFirst()
              ..returns = collectionType
              ..lambda = true
              ..body = refer('getBatchCollection').call([], {
                'parent': refer('this'),
                'name': literalString(_getCollectionName(subcol.path)),
                'converter': converterFactory
                    .getConverter(subcol.modelType)
                    .toConverterExpr(),
                'documentIdField': literalString(
                  modelAnalyzer.getDocumentIdFieldName(subcol.modelType),
                ),
              }).code,
          ),
        );
      }

      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add(
              '/// Batch document class for ${collection.path} collection',
            )
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'BatchDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelType),
                  _getPathRecord(collection.path),
                ]),
            )
            ..methods.addAll(methods),
        );

        specs.add(documentClass);
      }
    }
    return specs;
  }

  static Iterable<DartType> run(
    DartType type,
    ModelAnalyzer modelAnalyzer, [
    Element? annotatedElement,
  ]) sync* {
    yield type;

    if (type is! InterfaceType) return;

    final fields = modelAnalyzer.getFields(type);
    // Recursively find all nested InterfaceTypes in the fields of this type
    for (final field in fields.values) {
      yield* run(field.type, modelAnalyzer, field.element);
    }

    // If this is a ParameterizedType, analyze its type arguments as well
    for (final arg in type.typeArguments) {
      yield* run(arg, modelAnalyzer);
    }
  }
}
