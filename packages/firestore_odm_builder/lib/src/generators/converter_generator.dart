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
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Generate conversion code for a field from Firestore
  static String _generateFieldFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    final isNullable = field.isNullable;

    // Handle null values
    if (isNullable) {
      final nonNullConversion = _generateNonNullFromFirestoreConversion(
        field,
        sourceExpression,
      );
      return '$sourceExpression == null ? null : $nonNullConversion';
    }

    return _generateNonNullFromFirestoreConversion(field, sourceExpression);
  }

  /// Generate conversion code for a field to Firestore
  static String _generateFieldToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    final isNullable = field.isNullable;

    // Handle null values
    if (isNullable) {
      final nonNullConversion = _generateNonNullToFirestoreConversion(
        field,
        sourceExpression,
      );
      return '$sourceExpression == null ? null : $nonNullConversion';
    }

    return _generateNonNullToFirestoreConversion(field, sourceExpression);
  }

  /// Generate non-null conversion from Firestore
  static String _generateNonNullFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    if (field.customFromFirestoreExpression != null) {
      return field.customFromFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    switch (field.firestoreType) {
      case FirestoreType.string:
      case FirestoreType.double:
      case FirestoreType.boolean:
      case FirestoreType.null_:
        // Primitive types - direct cast
        return '$sourceExpression as ${field.dartType.getDisplayString()}';

      case FirestoreType.integer:
        // Check if this is a Duration type (stored as int milliseconds)
        final dartTypeName = field.dartType.getDisplayString(
          withNullability: false,
        );
        if (dartTypeName == 'Duration') {
          return 'const DurationConverter().fromFirestore($sourceExpression)';
        }
        // Regular integer
        return '$sourceExpression as ${field.dartType.getDisplayString()}';

      case FirestoreType.timestamp:
        return 'const DateTimeConverter().fromFirestore($sourceExpression)';

      case FirestoreType.bytes:
        return 'const BytesConverter().fromFirestore($sourceExpression as Blob)';

      case FirestoreType.geoPoint:
        return '$sourceExpression as GeoPoint';

      case FirestoreType.reference:
        return '$sourceExpression as DocumentReference';

      case FirestoreType.array:
        return _generateListFromFirestoreConversion(field, sourceExpression);

      case FirestoreType.map:
        return _generateMapFromFirestoreConversion(field, sourceExpression);

      case FirestoreType.object:

        // Check if this is actually a collection type that should use ObjectConverter
        final dartTypeName = field.dartType.getDisplayString(
          withNullability: false,
        );
        if (dartTypeName.startsWith('IList<') ||
            dartTypeName.startsWith('ISet<') ||
            dartTypeName.startsWith('IMap<')) {
          return 'ObjectConverter<$dartTypeName>($dartTypeName.fromJson, (obj) => obj.toJson()).fromFirestore($sourceExpression)';
        }
        return _generateObjectFromFirestoreConversion(field, sourceExpression);
    }
  }

  /// Generate non-null conversion to Firestore
  static String _generateNonNullToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    if (field.customToFirestoreExpression != null) {
      return field.customToFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    switch (field.firestoreType) {
      case FirestoreType.string:
      case FirestoreType.double:
      case FirestoreType.boolean:
      case FirestoreType.null_:
        // Primitive types - no conversion needed
        return sourceExpression;

      case FirestoreType.integer:
        // Check if this is a Duration type (stored as int milliseconds)
        final dartTypeName = field.dartType.getDisplayString(
          withNullability: false,
        );
        if (dartTypeName == 'Duration') {
          return 'const DurationConverter().toFirestore($sourceExpression!)';
        }
        // Regular integer
        return sourceExpression;

      case FirestoreType.timestamp:
        return 'const DateTimeConverter().toFirestore($sourceExpression!)';

      case FirestoreType.bytes:
        return 'const BytesConverter().toFirestore($sourceExpression!)';

      case FirestoreType.geoPoint:
      case FirestoreType.reference:
        // No conversion needed
        return sourceExpression;

      case FirestoreType.array:
        return _generateListToFirestoreConversion(field, sourceExpression);

      case FirestoreType.map:
        return _generateMapToFirestoreConversion(field, sourceExpression);

      case FirestoreType.object:

        // Check if this is actually a collection type that should use ObjectConverter
        final dartTypeName = field.dartType.getDisplayString(
          withNullability: false,
        );
        if (dartTypeName.startsWith('IList<') ||
            dartTypeName.startsWith('ISet<') ||
            dartTypeName.startsWith('IMap<')) {
          return 'ObjectConverter<$dartTypeName>($dartTypeName.fromJson, (obj) => obj.toJson()).toFirestore($sourceExpression)';
        }

        return _generateObjectToFirestoreConversion(field, sourceExpression);
    }
  }

  /// Generate List conversion from Firestore
  static String _generateListFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Check if this field has custom conversion expression
    if (field.customFromFirestoreExpression != null) {
      return field.customFromFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    // Regular List/Set conversion - handle List<dynamic> from Firestore
    final elementType = _getListElementType(field);
    return '($sourceExpression as List<dynamic>).cast<$elementType>()';
  }

  /// Generate List conversion to Firestore
  static String _generateListToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Check if this field has custom conversion expression
    if (field.customToFirestoreExpression != null) {
      return field.customToFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    // Regular List/Set conversion
    return sourceExpression;
  }

  /// Generate Map conversion from Firestore
  static String _generateMapFromFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Check if this field has custom conversion expression
    if (field.customFromFirestoreExpression != null) {
      return field.customFromFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    // Regular Map conversion - handle Map<String, dynamic> from Firestore
    final valueType = _getMapValueType(field);
    if (valueType == 'dynamic') {
      return '$sourceExpression as Map<String, dynamic>';
    } else {
      return '($sourceExpression as Map<String, dynamic>).cast<String, $valueType>()';
    }
  }

  /// Generate Map conversion to Firestore
  static String _generateMapToFirestoreConversion(
    FieldInfo field,
    String sourceExpression,
  ) {
    // Check if this field has custom conversion expression
    if (field.customToFirestoreExpression != null) {
      return field.customToFirestoreExpression!.replaceAll(
        '\$source',
        sourceExpression,
      );
    }

    // Regular Map conversion
    return sourceExpression;
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
