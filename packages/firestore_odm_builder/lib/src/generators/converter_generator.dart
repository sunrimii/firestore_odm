import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import '../utils/model_analyzer.dart';
import '../utils/string_helpers.dart';

/// Generator for Firestore converters for custom types
class ConverterGenerator {
  /// Generate converter class for a custom model
  static String generateConverterClass(ModelAnalysis analysis) {
    final className = analysis.className;
    final converterClassName = '${className}Converter';

    final buffer = StringBuffer();

    // Generate converter class
    buffer.writeln('/// Generated converter for $className');
    buffer.writeln(
      'class $converterClassName implements FirestoreConverter<$className, Map<String, dynamic>> {',
    );
    buffer.writeln('  const $converterClassName();');
    buffer.writeln('');

    // Check if the class has manual serialization methods
    if (analysis.hasManualSerialization) {
      // Use manual toJson/fromJson methods
      buffer.writeln('  @override');
      buffer.writeln('  $className fromFirestore(Map<String, dynamic> data) {');
      buffer.writeln('    return $className.fromJson(data);');
      buffer.writeln('  }');
      buffer.writeln('');

      buffer.writeln('  @override');
      buffer.writeln('  Map<String, dynamic> toFirestore($className data) {');
      buffer.writeln('    return data.toJson();');
      buffer.writeln('  }');
    } else {
      // Generate field-by-field conversion
      // Generate fromFirestore method
      buffer.writeln('  @override');
      buffer.writeln('  $className fromFirestore(Map<String, dynamic> data) {');
      buffer.writeln('    return $className(');

      for (final field in analysis.fields.values) {
        final paramName = field.parameterName;
        final jsonFieldName = field.jsonFieldName;

        buffer.write('      $paramName: ');

        // Generate field conversion based on FirestoreType
        final conversion = _generateFieldFromFirestoreConversion(
          field,
          "data['$jsonFieldName']",
        );

        buffer.writeln('$conversion,');
      }

      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln('');

      // Generate toFirestore method
      buffer.writeln('  @override');
      buffer.writeln('  Map<String, dynamic> toFirestore($className data) {');
      buffer.writeln('    return {');

      for (final field in analysis.fields.values) {
        final paramName = field.parameterName;
        final jsonFieldName = field.jsonFieldName;

        // Generate field conversion based on FirestoreType
        final conversion = _generateFieldToFirestoreConversion(
          field,
          'data.$paramName',
        );

        buffer.writeln("      '$jsonFieldName': $conversion,");
      }

      buffer.writeln('    };');
      buffer.writeln('  }');
    }
    
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Generate conversion code for a field from Firestore
  static String _generateFieldFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new unified converter system which handles nullability internally
    return field.generateFromFirestore(sourceExpression);
  }

  /// Generate conversion code for a field to Firestore
  static String _generateFieldToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new unified converter system which handles nullability internally
    return field.generateToFirestore(sourceExpression);
  }

  /// Generate List conversion from Firestore (legacy - now handled by converter system)
  static String _generateListFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new functional converter system
    return field.generateFromFirestore(sourceExpression);
  }

  /// Generate List conversion to Firestore (legacy - now handled by converter system)
  static String _generateListToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new functional converter system
    return field.generateToFirestore(sourceExpression);
  }

  /// Generate Map conversion from Firestore (legacy - now handled by converter system)
  static String _generateMapFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new functional converter system
    return field.generateFromFirestore(sourceExpression);
  }

  /// Generate Map conversion to Firestore (legacy - now handled by converter system)
  static String _generateMapToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Use the new functional converter system
    return field.generateToFirestore(sourceExpression);
  }

  /// Generate custom object conversion from Firestore
  static String _generateObjectFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    final typeName = _getCleanTypeName(field.dartType);
    return 'const ${typeName}Converter().fromFirestore($sourceExpression as Map<String, dynamic>)';
  }

  /// Generate custom object conversion to Firestore
  static String _generateObjectToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    final typeName = _getCleanTypeName(field.dartType);
    return 'const ${typeName}Converter().toFirestore($sourceExpression!)';
  }

  /// Extract clean type name for converter class name
  static String _getCleanTypeName(dynamic dartType) {
    // Get the element name directly from the type
    if (dartType is InterfaceType) {
      return dartType.element.name;
    }

    // Fallback to display string processing
    final fullTypeName = dartType.getDisplayString();

    // Remove nullability suffix (?)
    var cleanName = fullTypeName.replaceAll('?', '');

    // Extract base type name from generic types
    // e.g., "IList<String>" -> "IList", "Map<String, int>" -> "Map"
    final genericMatch = RegExp(r'^([^<]+)').firstMatch(cleanName);
    if (genericMatch != null) {
      cleanName = genericMatch.group(1)!;
    }

    return cleanName;
  }

  /// Get List element type as string
  static String _getListElementType(FieldInfo field) {
    final dartType = field.dartType;

    // Handle nullable types
    final actualType = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? (dartType as InterfaceType).element3.thisType
        : dartType;

    if (actualType is InterfaceType) {
      final typeArguments = actualType.typeArguments;
      if (typeArguments.isNotEmpty) {
        // Get the element type (first type argument for List<T>)
        final elementType = typeArguments.first;
        return elementType.getDisplayString(withNullability: false);
      }
    }

    return 'dynamic';
  }

  /// Get Map value type as string
  static String _getMapValueType(FieldInfo field) {
    final dartType = field.dartType;

    // Handle nullable types
    final actualType = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? (dartType as InterfaceType).element3.thisType
        : dartType;

    if (actualType is InterfaceType) {
      final typeArguments = actualType.typeArguments;
      if (typeArguments.length >= 2) {
        // Get the value type (second type argument for Map<K, V>)
        final valueType = typeArguments[1];
        return valueType.getDisplayString(withNullability: false);
      }
    }

    return 'dynamic';
  }

  /// Generate all converters for a model and its nested types
  static String generateAllConverters(Map<String, ModelAnalysis> allAnalyses) {
    final buffer = StringBuffer();

    for (final analysis in allAnalyses.values) {
      buffer.write(generateConverterClass(analysis));
    }

    return buffer.toString();
  }

  /// Generate converter constants for easy access
  static String generateConverterConstants(
    Map<String, ModelAnalysis> allAnalyses,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('/// Generated converter constants for easy access');

    for (final analysis in allAnalyses.values) {
      final className = analysis.className;
      final converterClassName = '${className}Converter';
      // Generate camelCase constant name (e.g., "User" -> "userConverter")
      final constantName =
          '${className[0].toLowerCase()}${className.substring(1)}Converter';

      buffer.writeln('const $constantName = $converterClassName();');
    }

    buffer.writeln('');

    return buffer.toString();
  }
}
