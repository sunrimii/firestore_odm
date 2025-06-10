import '../utils/string_helpers.dart';

/// Generator for ODM extension classes
class ODMExtensionGenerator {
  /// Generate the ODM extension code
  static void generateODMExtension(
    StringBuffer buffer,
    String className,
    String collectionPath,
    bool isSubcollection,
    Map<String, String> collectionTypeMap,
  ) {
    final pathSegments = collectionPath.split('/');
    final wildcardParams = <String>[];

    // Find wildcard parameters
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i] == '*') {
        if (i == 0) {
          throw ArgumentError('First path segment cannot be a wildcard');
        }
        final paramName =
            '${pathSegments[i - 1].replaceAll(RegExp(r's$'), '')}Id';
        wildcardParams.add(paramName);
      }
    }

    if (isSubcollection && wildcardParams.isNotEmpty) {
      // For subcollections, generate document extension for subcollection access
      _generateDocumentExtension(
        buffer,
        className,
        pathSegments,
        wildcardParams,
        collectionTypeMap,
      );
    }

    // Only generate FirestoreODM extension for root collections, not subcollections
    if (!isSubcollection || wildcardParams.isEmpty) {
      buffer.writeln('/// Extension to add the collection to FirestoreODM');
      buffer.writeln(
        'extension FirestoreODM${className}Extension<S extends FirestoreSchema> on FirestoreODM<S> {',
      );

      // Generate getter for regular collection
      buffer.writeln(
        '  FirestoreCollection<S, $className> get ${StringHelpers.camelCase(collectionPath)} => FirestoreCollection<S, $className>(',
      );
      buffer.writeln('    ref: firestore.collection(\'$collectionPath\'),');
      buffer.writeln(
        '    fromJson: ${StringHelpers.camelCase(className)}FromJson,',
      );
      buffer.writeln(
        '    toJson: ${StringHelpers.camelCase(className)}ToJson,',
      );
      buffer.writeln('  );');

      buffer.writeln('}');
    }
  }

  /// Generate document extension for subcollection access
  static void _generateDocumentExtension(
    StringBuffer buffer,
    String className,
    List<String> pathSegments,
    List<String> wildcardParams,
    Map<String, String> collectionTypeMap,
  ) {
    final collectionsOnly = pathSegments
        .where((segment) => segment != '*')
        .toList();
    if (collectionsOnly.length >= 2) {
      final parentCollection = collectionsOnly[collectionsOnly.length - 2];
      final childCollection = collectionsOnly.last;

      // Use collectionTypeMap to get the correct parent type
      final parentTypeName =
          collectionTypeMap[parentCollection] ??
          StringHelpers.capitalize(
            parentCollection.replaceAll(RegExp(r's$'), ''),
          );

      final childCollectionName = StringHelpers.camelCase(childCollection);

      // Use generic collection class name
      final collectionClassName = '${className}Collection';

      // Get the subcollection name (last segment that's not a wildcard)
      final subcollectionName = collectionsOnly.last;

      buffer.writeln(
        '/// Extension to access $childCollection subcollection on $parentTypeName document',
      );
      buffer.writeln(
        'extension ${className}Extension<S extends FirestoreSchema> on FirestoreDocument<S, $parentTypeName> {',
      );
      buffer.writeln('  /// Access $childCollection subcollection');
      buffer.writeln(
        '  FirestoreCollection<S, $className> get $childCollectionName => FirestoreCollection<S, $className>(',
      );
      buffer.writeln('    ref: ref.collection(\'$subcollectionName\'),');
      buffer.writeln(
        '    fromJson: ${StringHelpers.camelCase(className)}FromJson,',
      );
      buffer.writeln(
        '    toJson: ${StringHelpers.camelCase(className)}ToJson,',
      );
      buffer.writeln('  );');
      buffer.writeln('}');
      buffer.writeln('');
    }
  }
}
