import 'package:analyzer/dart/element/element.dart';
import '../utils/type_analyzer.dart';
import '../utils/string_helpers.dart';

/// Generator for Firestore collection classes
class CollectionGenerator {
  /// Generate the collection class code
  static void generateCollectionClass(
    StringBuffer buffer,
    String className,
    String collectionPath,
    ConstructorElement constructor,
    String? documentIdField,
    bool isSubcollection, {
    String suffix = '',
  }) {
    final pathSegments = collectionPath.split('/');
    final wildcardParams = <String>[];
    
    // Find wildcard parameters
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i] == '*') {
        if (i == 0) {
          throw ArgumentError('First path segment cannot be a wildcard');
        }
        final paramName = '${pathSegments[i-1].replaceAll(RegExp(r's$'), '')}Id';
        wildcardParams.add(paramName);
      }
    }
    
    final collectionClassName = '${className}Collection$suffix';
    
    buffer.writeln('/// Generated Collection for $className');
    if (isSubcollection) {
      buffer.writeln('/// Subcollection path: $collectionPath');
    }
    buffer.writeln('class $collectionClassName extends FirestoreCollection<$className> {');
    
    // Generate constructor
    if (isSubcollection && wildcardParams.isNotEmpty) {
      buffer.writeln('  $collectionClassName(FirebaseFirestore firestore, {');
      for (final param in wildcardParams) {
        buffer.writeln('    required String $param,');
      }
      buffer.writeln('  }) : super(');
      
      // Build dynamic collection path
      final dynamicPath = _buildDynamicPath(collectionPath, wildcardParams);
      buffer.writeln('    ref: firestore.collection($dynamicPath),');
    } else {
      buffer.writeln('  $collectionClassName(FirebaseFirestore firestore) : super(');
      buffer.writeln('    ref: firestore.collection(\'$collectionPath\'),');
    }
    
    buffer.writeln('    fromJson: (data) => $className.fromJson(data),');
    buffer.writeln('    toJson: (value) => value.toJson(),');

    buffer.writeln('  );');
    buffer.writeln('');

    // Generate document ID field if provided
    if (documentIdField != null) {
      buffer.writeln('  @override');
      buffer.writeln('  String get documentIdField => \'$documentIdField\';');
      buffer.writeln('');
    }

    buffer.writeln('}');

  }

  /// Build dynamic collection path for subcollections
  static String _buildDynamicPath(String collectionPath, List<String> wildcardParams) {
    final pathSegments = collectionPath.split('/');
    final pathParts = <String>[];
    int paramIndex = 0;
    
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i] == '*') {
        if (paramIndex < wildcardParams.length) {
          pathParts.add('\${${wildcardParams[paramIndex]}}');
          paramIndex++;
        } else {
          throw ArgumentError('Not enough parameters for wildcards in path: $collectionPath');
        }
      } else {
        pathParts.add(pathSegments[i]);
      }
    }
    
    return "'${pathParts.join('/')}'";
  }
}