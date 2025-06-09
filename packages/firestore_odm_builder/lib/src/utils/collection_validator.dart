import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

/// Collection validation information
class CollectionValidationInfo {
  final String path;
  final bool isSubcollection;
  final ClassElement element;
  final int annotationIndex;

  CollectionValidationInfo(
    this.path,
    this.isSubcollection,
    this.element,
    this.annotationIndex,
  );
}

/// Validation errors for @Collection configurations
class CollectionValidationError {
  final String title;
  final String description;
  final String solution;
  final ClassElement? element;
  final String? collectionPath;

  CollectionValidationError({
    required this.title,
    required this.description,
    required this.solution,
    this.element,
    this.collectionPath,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('❌ $title');
    buffer.writeln('   $description');
    buffer.writeln('   💡 Solution: $solution');
    if (element != null) {
      buffer.writeln('   📍 Class: ${element!.name}');
    }
    if (collectionPath != null) {
      buffer.writeln('   🔗 Path: $collectionPath');
    }
    return buffer.toString();
  }
}

/// Comprehensive validator for @Collection annotation configurations
class CollectionValidator {
  static List<CollectionValidationError> validateCollections(
    LibraryReader library,
  ) {
    final errors = <CollectionValidationError>[];
    final allCollections = <CollectionValidationInfo>[];

    // Step 1: Collect all @Collection annotations
    for (final element in library.allElements) {
      if (element is ClassElement) {
        final collections = _extractCollectionInfo(element);
        allCollections.addAll(collections);

        // Validate individual class configurations
        errors.addAll(_validateClassConfiguration(element, collections));
      }
    }

    // Step 2: Validate cross-class constraints
    errors.addAll(_validateGlobalConstraints(allCollections));

    return errors;
  }

  /// Extract @Collection annotation information from a class
  static List<CollectionValidationInfo> _extractCollectionInfo(
    ClassElement element,
  ) {
    final collections = <CollectionValidationInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);

    int annotationIndex = 0;
    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null &&
          collectionChecker.isExactlyType(annotationValue.type!)) {
        final path = annotationValue.getField('path')!.toStringValue()!;
        final isSubcollection = path.contains('*');
        collections.add(
          CollectionValidationInfo(
            path,
            isSubcollection,
            element,
            annotationIndex,
          ),
        );
        annotationIndex++;
      }
    }

    return collections;
  }

  /// Validate configuration for a single class
  static List<CollectionValidationError> _validateClassConfiguration(
    ClassElement element,
    List<CollectionValidationInfo> collections,
  ) {
    final errors = <CollectionValidationError>[];

    if (collections.isEmpty) return errors;

    // Check 1: Class must have unnamed constructor
    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      errors.add(
        CollectionValidationError(
          title: 'Missing Unnamed Constructor',
          description:
              'Class ${element.name} with @Collection annotation must have an unnamed constructor.',
          solution:
              'Add an unnamed constructor: const factory ${element.name}(...) = _${element.name};',
          element: element,
        ),
      );
      return errors; // Cannot proceed without constructor
    }

    // Check 2: Must have @DocumentIdField
    final hasDocumentIdField = constructor.parameters.any((param) {
      return param.metadata.any((meta) {
        final metaValue = meta.computeConstantValue();
        return metaValue != null &&
            TypeChecker.fromRuntime(
              DocumentIdField,
            ).isExactlyType(metaValue.type!);
      });
    });

    if (!hasDocumentIdField) {
      errors.add(
        CollectionValidationError(
          title: 'Missing @DocumentIdField',
          description:
              'Class ${element.name} must have exactly one field marked with @DocumentIdField() annotation.',
          solution:
              'Add @DocumentIdField() to one String field: @DocumentIdField() required String id,',
          element: element,
        ),
      );
    }

    // Check 3: Validate each collection path
    for (final collection in collections) {
      errors.addAll(_validateCollectionPath(collection));
    }

    // Check 4: Check for duplicate paths in same class
    final pathCounts = <String, int>{};
    for (final collection in collections) {
      pathCounts[collection.path] = (pathCounts[collection.path] ?? 0) + 1;
    }

    for (final entry in pathCounts.entries) {
      if (entry.value > 1) {
        errors.add(
          CollectionValidationError(
            title: 'Duplicate Collection Path',
            description:
                'Class ${element.name} has ${entry.value} @Collection annotations with the same path "${entry.key}".',
            solution:
                'Remove duplicate @Collection annotations or use different collection paths.',
            element: element,
            collectionPath: entry.key,
          ),
        );
      }
    }

    return errors;
  }

  /// Validate a specific collection path
  static List<CollectionValidationError> _validateCollectionPath(
    CollectionValidationInfo collection,
  ) {
    final errors = <CollectionValidationError>[];
    final path = collection.path;
    final element = collection.element;

    // Check 1: Path cannot be empty
    if (path.trim().isEmpty) {
      errors.add(
        CollectionValidationError(
          title: 'Empty Collection Path',
          description: 'Collection path cannot be empty or whitespace.',
          solution:
              'Provide a valid collection path: @Collection("users") or @Collection("users/*/posts")',
          element: element,
          collectionPath: path,
        ),
      );
      return errors;
    }

    // Check 2: Path cannot start or end with slash
    if (path.startsWith('/') || path.endsWith('/')) {
      errors.add(
        CollectionValidationError(
          title: 'Invalid Path Format',
          description: 'Collection path "$path" cannot start or end with "/".',
          solution:
              'Remove leading/trailing slashes: @Collection("users") not @Collection("/users/")',
          element: element,
          collectionPath: path,
        ),
      );
    }

    // Check 3: Path cannot contain consecutive slashes
    if (path.contains('//')) {
      errors.add(
        CollectionValidationError(
          title: 'Invalid Path Format',
          description:
              'Collection path "$path" cannot contain consecutive slashes "//".',
          solution:
              'Use single slashes to separate path segments: @Collection("users/posts")',
          element: element,
          collectionPath: path,
        ),
      );
    }

    // Check 4: Validate wildcard usage
    if (path.contains('*')) {
      errors.addAll(_validateWildcardUsage(collection));
    }

    // Check 5: Path segments cannot be empty
    final segments = path.split('/');
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].trim().isEmpty && segments[i] != '*') {
        errors.add(
          CollectionValidationError(
            title: 'Empty Path Segment',
            description:
                'Collection path "$path" has an empty segment at position ${i + 1}.',
            solution:
                'Ensure all path segments are non-empty: @Collection("users/posts")',
            element: element,
            collectionPath: path,
          ),
        );
      }
    }

    // Check 6: Collection paths must have odd number of segments
    if (segments.length % 2 == 0) {
      errors.add(
        CollectionValidationError(
          title: 'Invalid Collection Path Structure',
          description:
              'Collection path "$path" must end with a collection name, not a document ID.',
          solution:
              'Collection paths must have odd number of segments. Use "users" not "users/user1", or "users/*/posts" not "users/*/posts/post1"',
          element: element,
          collectionPath: path,
        ),
      );
    }

    return errors;
  }

  /// Validate wildcard usage in subcollection paths
  static List<CollectionValidationError> _validateWildcardUsage(
    CollectionValidationInfo collection,
  ) {
    final errors = <CollectionValidationError>[];
    final path = collection.path;
    final element = collection.element;
    final segments = path.split('/');

    // Check 1: Wildcards must be in document position (even index)
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] == '*') {
        if (i % 2 == 0) {
          errors.add(
            CollectionValidationError(
              title: 'Invalid Wildcard Position',
              description:
                  'Wildcard "*" at position ${i + 1} in path "$path" is in a collection position.',
              solution:
                  'Wildcards must be in document positions (even positions): "users/*/posts" not "*/users/posts"',
              element: element,
              collectionPath: path,
            ),
          );
        }
      }
    }

    // Check 2: Cannot start with wildcard
    if (segments.isNotEmpty && segments[0] == '*') {
      errors.add(
        CollectionValidationError(
          title: 'Invalid Path Start',
          description:
              'Collection path "$path" cannot start with a wildcard "*".',
          solution:
              'Paths must start with a collection name: "users/*/posts" not "*/posts"',
          element: element,
          collectionPath: path,
        ),
      );
    }

    // Check 3: Must have at least one segment before wildcard
    if (segments.length < 3 && path.contains('*')) {
      errors.add(
        CollectionValidationError(
          title: 'Insufficient Path Segments',
          description:
              'Subcollection path "$path" must have at least 3 segments: collection/*/subcollection.',
          solution:
              'Use format like "users/*/posts" with parent collection, wildcard document, and subcollection',
          element: element,
          collectionPath: path,
        ),
      );
    }

    return errors;
  }

  /// Validate constraints across all classes
  static List<CollectionValidationError> _validateGlobalConstraints(
    List<CollectionValidationInfo> allCollections,
  ) {
    final errors = <CollectionValidationError>[];

    // Check 1: Same path cannot be used by different classes (except for multiple collections on same class)
    final pathToClasses = <String, Set<String>>{};

    for (final collection in allCollections) {
      final className = collection.element.name;
      pathToClasses
          .putIfAbsent(collection.path, () => <String>{})
          .add(className);
    }

    for (final entry in pathToClasses.entries) {
      if (entry.value.length > 1) {
        errors.add(
          CollectionValidationError(
            title: 'Conflicting Collection Path',
            description:
                'Collection path "${entry.key}" is used by multiple classes: ${entry.value.join(", ")}.',
            solution:
                'Each collection path should only be used by one model class. Use different paths or combine into a single model.',
            collectionPath: entry.key,
          ),
        );
      }
    }

    // Check 2: Validate subcollection parent-child relationships
    errors.addAll(_validateSubcollectionRelationships(allCollections));

    return errors;
  }

  /// Validate subcollection parent-child relationships
  static List<CollectionValidationError> _validateSubcollectionRelationships(
    List<CollectionValidationInfo> allCollections,
  ) {
    final errors = <CollectionValidationError>[];
    final rootCollections = <String>{};
    final subcollections = <CollectionValidationInfo>[];

    // Separate root collections and subcollections
    for (final collection in allCollections) {
      if (collection.isSubcollection) {
        subcollections.add(collection);
      } else {
        rootCollections.add(collection.path);
      }
    }

    // Check that subcollections have valid parent collections
    for (final subcollection in subcollections) {
      final pathSegments = subcollection.path.split('/');
      if (pathSegments.isNotEmpty) {
        final parentCollection = pathSegments[0];

        // Check if parent collection exists
        if (!rootCollections.contains(parentCollection)) {
          errors.add(
            CollectionValidationError(
              title: 'Missing Parent Collection',
              description:
                  'Subcollection "${subcollection.path}" references parent collection "$parentCollection" but no @Collection("$parentCollection") exists.',
              solution:
                  'Create a model with @Collection("$parentCollection") or use an existing parent collection name.',
              element: subcollection.element,
              collectionPath: subcollection.path,
            ),
          );
        }
      }
    }

    return errors;
  }

  /// Generate a comprehensive error report
  static String generateErrorReport(List<CollectionValidationError> errors) {
    if (errors.isEmpty) {
      return '✅ All @Collection configurations are valid!';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      '🚨 @Collection Configuration Errors Found (${errors.length} issues)',
    );
    buffer.writeln('=' * 80);
    buffer.writeln();

    // Group errors by type
    final errorGroups = <String, List<CollectionValidationError>>{};
    for (final error in errors) {
      errorGroups.putIfAbsent(error.title, () => []).add(error);
    }

    for (final entry in errorGroups.entries) {
      buffer.writeln(
        '📋 ${entry.key} (${entry.value.length} occurrence${entry.value.length == 1 ? '' : 's'})',
      );
      buffer.writeln('-' * 40);
      for (final error in entry.value) {
        buffer.writeln(error.toString());
        buffer.writeln();
      }
    }

    buffer.writeln('=' * 80);
    buffer.writeln('📚 Common Solutions:');
    buffer.writeln(
      '• Add @DocumentIdField() to one String field in your model',
    );
    buffer.writeln('• Use valid collection paths: "users", "users/*/posts"');
    buffer.writeln(
      '• Ensure wildcards (*) are in document positions (even indices)',
    );
    buffer.writeln(
      '• Avoid duplicate collection paths across different classes',
    );
    buffer.writeln(
      '• Create parent collections before referencing in subcollections',
    );
    buffer.writeln();
    buffer.writeln(
      '📖 Documentation: https://github.com/your-repo/firestore-odm#collection-annotation',
    );

    return buffer.toString();
  }
}
