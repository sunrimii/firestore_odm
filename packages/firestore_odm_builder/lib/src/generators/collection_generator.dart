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
    // _generateFilterMethod(buffer, className);
    
    // Generate orderBy method
    // _generateOrderByMethod(buffer, className);

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
    buffer.writeln('   FirestoreQuery<$className> where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(ref, builtFilter);');
    buffer.writeln('    return FirestoreQuery<$className>(newQuery, fromJson, toJson, specialTimestamp);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateOrderByMethod(StringBuffer buffer, String className) {
    buffer.writeln('  /// Order using an OrderBy Builder');
    buffer.writeln('  FirestoreQuery<$className> orderBy(OrderByField Function(${className}OrderByBuilder order) orderBuilder) {');
    buffer.writeln('    final builder = ${className}OrderByBuilder();');
    buffer.writeln('    final orderField = orderBuilder(builder);');
    buffer.writeln('    return FirestoreQuery<$className>(ref.orderBy(orderField.field, descending: orderField.descending), fromJson, toJson, specialTimestamp);');
    buffer.writeln('  }');
    buffer.writeln('');
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