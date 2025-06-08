import '../utils/string_helpers.dart';

/// Generator for ODM extension classes
class ODMExtensionGenerator {
  /// Generate the ODM extension code
  static void generateODMExtension(StringBuffer buffer, String className, String collectionPath) {
    buffer.writeln('/// Extension to add the collection to FirestoreODM');
    buffer.writeln('extension FirestoreODM${className}Extension on FirestoreODM {');
    buffer.writeln('  ${className}Collection get ${StringHelpers.camelCase(collectionPath)} => ${className}Collection(firestore);');
    buffer.writeln('}');
  }
}