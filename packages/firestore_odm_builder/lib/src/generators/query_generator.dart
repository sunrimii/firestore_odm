import 'package:analyzer/dart/element/element.dart';

/// Generator for Firestore query classes and extensions
class QueryGenerator {
  /// Generate the query class code
  static void generateQueryClass(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Generated Query for $className');
    buffer.writeln('class ${className}Query extends FirestoreQuery<$className> {');
    buffer.writeln('  final FirestoreCollection<$className> collection;');
    buffer.writeln('');
    buffer.writeln('  ${className}Query(this.collection, Query<Map<String, dynamic>> query) : super(query, collection.fromJson, collection.toJson);');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  FirestoreQuery<$className> newInstance(Query<Map<String, dynamic>> query) => ${className}Query(collection, query);');
    buffer.writeln('');
    
    // Generate new orderBy method using OrderByBuilder
    buffer.writeln('  /// Order using an OrderBy Builder');
    buffer.writeln('  ${className}Query orderBy(OrderByField Function(${className}OrderByBuilder order) orderBuilder) {');
    buffer.writeln('    final builder = ${className}OrderByBuilder();');
    buffer.writeln('    final orderField = orderBuilder(builder);');
    buffer.writeln('    return ${className}Query(collection, query.orderBy(orderField.field, descending: orderField.descending));');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  /// Generate the query extension code
  static void generateQueryExtension(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Extension methods for $className queries');
    buffer.writeln('extension ${className}QueryExtension on ${className}Query {');
    
    // Generate where method
    buffer.writeln('  /// Filter using a Filter Builder');
    buffer.writeln('  ${className}Query where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(underlyingQuery, builtFilter);');
    buffer.writeln('    return ${className}Query(collection, newQuery);');
    buffer.writeln('  }');
    
    buffer.writeln('}');
  }
}