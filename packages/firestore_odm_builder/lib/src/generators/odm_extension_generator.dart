import '../utils/string_helpers.dart';

/// Generator for ODM extension classes
class ODMExtensionGenerator {
  /// Generate the ODM extension code
  static void generateODMExtension(StringBuffer buffer, String className, String collectionPath, bool isSubcollection, {String suffix = ''}) {
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
    
    if (isSubcollection && wildcardParams.isNotEmpty) {
      // For subcollections, generate document reference class first (outside extension)
      _generateDocumentReferenceClass(buffer, className, pathSegments, wildcardParams, suffix: suffix);
    }
    
    buffer.writeln('/// Extension to add the collection to FirestoreODM');
    buffer.writeln('extension FirestoreODM${className}${suffix}Extension on FirestoreODM {');
    
    if (isSubcollection && wildcardParams.isNotEmpty) {
      // Generate method to create document reference
      _generateDocumentReferenceMethod(buffer, className, pathSegments, wildcardParams, suffix);
    } else {
      // Generate getter for regular collection
      buffer.writeln('  ${className}Collection${suffix} get ${StringHelpers.camelCase(collectionPath)} => ${className}Collection${suffix}(firestore);');
    }
    
    buffer.writeln('}');
  }
  
  /// Generate document reference class for fluent API
  static void _generateDocumentReferenceClass(StringBuffer buffer, String className, List<String> pathSegments, List<String> wildcardParams, {String suffix = ''}) {
    final collectionsOnly = pathSegments.where((segment) => segment != '*').toList();
    if (collectionsOnly.length >= 2) {
      final parentCollection = collectionsOnly[collectionsOnly.length - 2];
      final childCollection = collectionsOnly.last;
      final parentClassName = StringHelpers.capitalize(parentCollection.replaceAll(RegExp(r's$'), ''));
      final childCollectionName = StringHelpers.camelCase(childCollection);
      final parentDocClassName = '${parentClassName}DocumentReference';
      
      buffer.writeln('/// Document reference for $parentClassName with subcollections');
      buffer.writeln('class $parentDocClassName {');
      buffer.writeln('  final FirebaseFirestore _firestore;');
      for (final param in wildcardParams) {
        buffer.writeln('  final String _$param;');
      }
      buffer.writeln('');
      buffer.write('  $parentDocClassName(this._firestore');
      for (final param in wildcardParams) {
        buffer.write(', this._$param');
      }
      buffer.writeln(');');
      buffer.writeln('');
      buffer.writeln('  /// Access $childCollection subcollection');
      buffer.write('  ${className}Collection${suffix} get $childCollectionName => ${className}Collection${suffix}(_firestore');
      for (final param in wildcardParams) {
        buffer.write(', ${param.replaceAll('_', '')}: _$param');
      }
      buffer.writeln(');');
      buffer.writeln('}');
      buffer.writeln('');
    }
  }
  
  /// Generate method to create document reference
  static void _generateDocumentReferenceMethod(StringBuffer buffer, String className, List<String> pathSegments, List<String> wildcardParams, String suffix) {
    final collectionsOnly = pathSegments.where((segment) => segment != '*').toList();
    if (collectionsOnly.length >= 2) {
      final parentCollection = collectionsOnly[collectionsOnly.length - 2];
      final parentClassName = StringHelpers.capitalize(parentCollection.replaceAll(RegExp(r's$'), ''));
      final parentDocClassName = '${parentClassName}DocumentReference';
      
      buffer.writeln('  /// Get $parentClassName document reference for accessing subcollections');
      buffer.write('  $parentDocClassName ${StringHelpers.camelCase(parentCollection)}(');
      for (int i = 0; i < wildcardParams.length; i++) {
        if (i > 0) buffer.write(', ');
        buffer.write('String ${wildcardParams[i]}');
      }
      buffer.writeln(') {');
      buffer.write('    return $parentDocClassName(firestore');
      for (final param in wildcardParams) {
        buffer.write(', $param');
      }
      buffer.writeln(');');
      buffer.writeln('  }');
    }
  }
}