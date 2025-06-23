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
    // ModelAnalysis is only created for custom classes, so no primitive type check needed
    final className = analysis.dartType.element?.name;
    if (className == null) {
      throw ArgumentError('ModelAnalysis must have a valid Dart type element.');
    }
    
    final isGeneric = analysis.isGeneric;
    final typeParameters = analysis.typeParameters;
    final typeParamsString = isGeneric ? '<${typeParameters.join(', ')}>' : '';
    final classNameWithTypeParams = isGeneric ? '$className$typeParamsString' : className;

    // Generate OrderByFieldSelector extension
    buffer.writeln('/// Generated OrderByFieldSelector for $classNameWithTypeParams');
    buffer.writeln(
      'extension ${className}OrderByFieldSelectorExtension$typeParamsString on OrderByFieldSelector<$classNameWithTypeParams> {',
    );

    // Generate field selectors from analysis
    for (final field in analysis.fields.values) {
      // Skip document ID field as it's handled separately above
      final fieldType = field.dartType;
      if (analysis.documentIdFieldName == field.parameterName) {
        final docIdField = analysis.documentIdFieldName!;
        buffer.writeln('  /// Order by document ID ($docIdField field)');
        buffer.writeln(
          '  OrderByField<String> get ${field.parameterName} => OrderByField(name: \'${field.jsonFieldName}\', parent: this, type: FieldPathType.documentId);',
        );
        buffer.writeln('');
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        _generateOrderByFieldSelectorNestedGetter(buffer, field);
      } else {
        _generateOrderByFieldSelectorMethod(buffer, field);
      }
    }

    buffer.writeln('}');
  }
}
