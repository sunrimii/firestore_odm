import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for order by builders
class OrderByGenerator {


  static void _generateOrderByFieldSelectorMethod(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    buffer.writeln('  /// Order by ${field.parameterName}');
    buffer.writeln(
      '  OrderByField<${field.dartType}> get ${field.parameterName} => OrderByField(name: \'${field.jsonFieldName}\', parent: this);',
    );
    buffer.writeln('');
  }

  static void _generateOrderByFieldSelectorNestedGetter(
    StringBuffer buffer,
    FieldInfo field,
  ) {
    buffer.writeln('  /// Access nested ${field.parameterName} for ordering');
    buffer.writeln(
      '  OrderByFieldSelector<${field.dartType}> get ${field.parameterName} => OrderByFieldSelector<${field.dartType}>(',
    );
    buffer.writeln('    name: \'${field.jsonFieldName}\',');
    buffer.writeln('    parent: this,');
    buffer.writeln('  );');
    buffer.writeln('');
  }


  /// Generate order by selector class using ModelAnalysis instead of constructor
  static void generateOrderBySelectorClassFromAnalysis(
    StringBuffer buffer,
    ModelAnalysis analysis,
  ) {
    final className = analysis.className;

    // Generate OrderByFieldSelector extension
    buffer.writeln('/// Generated OrderByFieldSelector for $className');
    buffer.writeln(
      'extension ${className}OrderByFieldSelectorExtension on OrderByFieldSelector<$className> {',
    );

    // Add document ID order method if there's a document ID field
    if (analysis.documentIdFieldName != null) {
      final docIdField = analysis.documentIdFieldName!;
      buffer.writeln('  /// Order by document ID ($docIdField field)');
      buffer.writeln('  OrderByField<String> get $docIdField => OrderByField(name: \'$docIdField\', parent: this, type: FieldPathType.documentId);');
      buffer.writeln('');
    }

    // Generate field selectors from analysis
    for (final field in analysis.fields.values) {
      // Skip document ID field as it's handled separately above
      if (field.parameterName == analysis.documentIdFieldName) continue;

      final fieldType = field.dartType;

      if (TypeAnalyzer.isPrimitiveType(fieldType) ||
          TypeAnalyzer.isIterableType(fieldType) ||
          TypeAnalyzer.isMapType(fieldType)) {
        _generateOrderByFieldSelectorMethod(buffer, field);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        _generateOrderByFieldSelectorNestedGetter(buffer, field);
      }
    }

    buffer.writeln('}');
  }

  
}
