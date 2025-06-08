import 'package:analyzer/dart/element/element.dart';

/// Generator for Firestore document extensions
class DocumentGenerator {
  /// Generate the document extension code
  static void generateDocumentClass(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Generated extension for $className Document');
    buffer.writeln('extension ${className}DocumentExtension on FirestoreDocument<$className> {');
    
    // Array-style update method (primary API)
    buffer.writeln('  /// Update using array-style update operations');
    buffer.writeln('  Future<void> update(List<UpdateOperation> Function(${className}UpdateBuilder update) updateBuilder) async {');
    buffer.writeln('    final builder = ${className}UpdateBuilder();');
    buffer.writeln('    final operations = updateBuilder(builder);');
    buffer.writeln('    final updateMap = UpdateBuilder.operationsToMap(operations);');
    buffer.writeln('    if (updateMap.isNotEmpty) {');
    buffer.writeln('      await updateFields(updateMap);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('');
    
    buffer.writeln('}');
  }
}