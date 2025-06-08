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
  ) {
    buffer.writeln('/// Generated Collection for $className');
    buffer.writeln('class ${className}Collection extends FirestoreCollection<$className> {');
    buffer.writeln('  ${className}Collection(FirebaseFirestore firestore) : super(');
    buffer.writeln('    ref: firestore.collection(\'$collectionPath\'),');
    
    buffer.writeln('    fromJson: (data, [documentId]) {');
    buffer.writeln('      final processedData = FirestoreDataProcessor.processFirestoreData(');
    buffer.writeln('        data,');
    buffer.writeln('        documentIdField: ${documentIdField != null ? '\'$documentIdField\'' : 'null'},');
    buffer.writeln('        documentId: documentId,');
    buffer.writeln('      );');
    buffer.writeln('      return $className.fromJson(processedData);');
    buffer.writeln('    },');
    buffer.writeln('    toJson: (value) {');
    buffer.writeln('      final json = value.toJson();');
    buffer.writeln('      final serialized = FirestoreDataProcessor.serializeForFirestore(json);');
    buffer.writeln('      return DocumentIdHandler.removeDocumentIdField(serialized, ${documentIdField != null ? '\'$documentIdField\'' : 'null'});');
    buffer.writeln('    },');
    
    buffer.writeln('  );');
    buffer.writeln('');
    
    // Add upsert method if there's a document ID field
    if (documentIdField != null) {
      _generateUpsertMethod(buffer, className, documentIdField);
    }
    
    // Generate filter method
    _generateFilterMethod(buffer, className);
    
    // Generate orderBy method
    _generateOrderByMethod(buffer, className);

    buffer.writeln('}');
  }

  static void _generateUpsertMethod(StringBuffer buffer, String className, String documentIdField) {
    buffer.writeln('  /// Upsert a document using the $documentIdField field as document ID');
    buffer.writeln('  Future<void> upsert($className value) async {');
    buffer.writeln('    final json = toJson(value);');
    buffer.writeln('    final documentId = DocumentIdHandler.extractDocumentId(value.toJson(), \'$documentIdField\');');
    buffer.writeln('    DocumentIdHandler.validateDocumentId(documentId, \'$documentIdField\');');
    buffer.writeln('    await ref.doc(documentId!).set(json, SetOptions(merge: true));');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateFilterMethod(StringBuffer buffer, String className) {
    buffer.writeln('  /// Filter using a Filter Builder');
    buffer.writeln('  ${className}Query where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(ref, builtFilter);');
    buffer.writeln('    return ${className}Query(this, newQuery);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateOrderByMethod(StringBuffer buffer, String className) {
    buffer.writeln('  /// Order using an OrderBy Builder');
    buffer.writeln('  ${className}Query orderBy(OrderByField Function(${className}OrderByBuilder order) orderBuilder) {');
    buffer.writeln('    final builder = ${className}OrderByBuilder();');
    buffer.writeln('    final orderField = orderBuilder(builder);');
    buffer.writeln('    return ${className}Query(this, ref.orderBy(orderField.field, descending: orderField.descending));');
    buffer.writeln('  }');
    buffer.writeln('');
  }
}