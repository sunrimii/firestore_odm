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
    
    // Check if this is a generic type
    if (analysis.classTypeAnalysis.isGeneric) {
      return _generateGenericConverter(analysis);
    }
    
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



  /// Generate converters for custom types discovered through type analysis
  static String generateConvertersForCustomTypes(Map<String, TypeAnalysisResult> typeAnalyses) {
    final buffer = StringBuffer();

    for (final entry in typeAnalyses.entries) {
      final typeName = entry.key;
      final typeAnalysis = entry.value;
      
      // Generate converters for all custom types
      buffer.write(_generateTypeConverter(typeName, typeAnalysis));
    }

    return buffer.toString();
  }

  /// Generate converter for a specific type based on its analysis
  static String _generateTypeConverter(String typeName, TypeAnalysisResult typeAnalysis) {
    // Check if this is a generic type that needs special handling
    if (typeAnalysis.isGeneric) {
      return _generateGenericTypeConverter(typeName, typeAnalysis);
    }
    
    final converterClassName = '${typeName}Converter';
    final buffer = StringBuffer();

    // Generate converter class
    buffer.writeln('/// Generated converter for $typeName');
    buffer.writeln(
      'class $converterClassName implements FirestoreConverter<$typeName, Map<String, dynamic>> {',
    );
    buffer.writeln('  const $converterClassName();');
    buffer.writeln('');

    // Use manual toJson/fromJson methods since this is a custom type
    buffer.writeln('  @override');
    buffer.writeln('  $typeName fromFirestore(Map<String, dynamic> data) {');
    buffer.writeln('    return $typeName.fromJson(data);');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  @override');
    buffer.writeln('  Map<String, dynamic> toFirestore($typeName data) {');
    buffer.writeln('    return data.toJson();');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }



  /// Generate generic converter for types with type parameters
  static String _generateGenericConverter(ModelAnalysis analysis) {
    final className = analysis.className;
    final typeParams = analysis.classTypeAnalysis.typeParameters;
    final typeParamsString = '<${typeParams.join(', ')}>';
    final converterClassName = '${className}Converter';

    final buffer = StringBuffer();

    // Generate true generic converter with converter parameters
    buffer.writeln('/// Generated converter for $className$typeParamsString');
    buffer.writeln(
      'class $converterClassName$typeParamsString implements FirestoreConverter<$className$typeParamsString, dynamic> {',
    );
    
    // Generate constructor fields for converters
    if (typeParams.length == 1) {
      // Single type parameter (e.g., IList<T>, ISet<T>)
      buffer.writeln('  final FirestoreConverter<${typeParams[0]}, dynamic> valueConverter;');
      buffer.writeln('  const $converterClassName(this.valueConverter);');
    } else if (typeParams.length == 2) {
      // Two type parameters (e.g., IMap<K, V>)
      buffer.writeln('  final FirestoreConverter<${typeParams[0]}, dynamic> keyConverter;');
      buffer.writeln('  final FirestoreConverter<${typeParams[1]}, dynamic> valueConverter;');
      buffer.writeln('  const $converterClassName(this.keyConverter, this.valueConverter);');
    } else {
      // General case for multiple type parameters
      for (int i = 0; i < typeParams.length; i++) {
        buffer.writeln('  final FirestoreConverter<${typeParams[i]}, dynamic> converter$i;');
      }
      final constructorParams = List.generate(typeParams.length, (i) => 'this.converter$i').join(', ');
      buffer.writeln('  const $converterClassName($constructorParams);');
    }
    
    buffer.writeln('');

    // Generate fromFirestore method
    buffer.writeln('  @override');
    buffer.writeln('  $className$typeParamsString fromFirestore(dynamic data) {');
    
    if (typeParams.length == 1) {
      // Single type parameter
      buffer.writeln('    return $className.fromJson(data, (e) => valueConverter.fromFirestore(e));');
    } else if (typeParams.length == 2) {
      // Two type parameters
      buffer.writeln('    return $className.fromJson(data, (k) => keyConverter.fromFirestore(k), (v) => valueConverter.fromFirestore(v));');
    } else {
      // General case
      final paramConverters = typeParams.asMap().entries
          .map((entry) => '(p${entry.key}) => converter${entry.key}.fromFirestore(p${entry.key})')
          .join(', ');
      buffer.writeln('    return $className.fromJson(data, $paramConverters);');
    }
    
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate toFirestore method
    buffer.writeln('  @override');
    buffer.writeln('  dynamic toFirestore($className$typeParamsString data) {');
    
    if (typeParams.length == 1) {
      // Single type parameter
      buffer.writeln('    return data.toJson((e) => valueConverter.toFirestore(e));');
    } else if (typeParams.length == 2) {
      // Two type parameters
      buffer.writeln('    return data.toJson((k) => keyConverter.toFirestore(k), (v) => valueConverter.toFirestore(v));');
    } else {
      // General case
      final paramConverters = typeParams.asMap().entries
          .map((entry) => '(p${entry.key}) => converter${entry.key}.toFirestore(p${entry.key})')
          .join(', ');
      buffer.writeln('    return data.toJson($paramConverters);');
    }
    
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Generate converter for generic types like IList<T>, IMap<K,V>, etc.
  static String _generateGenericTypeConverter(String typeName, TypeAnalysisResult typeAnalysis) {
    final typeParams = typeAnalysis.typeParameters;
    final typeParamsString = '<${typeParams.join(', ')}>';
    final converterClassName = '${typeName}Converter';

    final buffer = StringBuffer();

    // Generate true generic converter with converter parameters
    buffer.writeln('/// Generated converter for $typeName$typeParamsString');
    buffer.writeln(
      'class $converterClassName$typeParamsString implements FirestoreConverter<$typeName$typeParamsString, dynamic> {',
    );
    
    // Generate constructor fields for converters
    if (typeParams.length == 1) {
      // Single type parameter (e.g., IList<T>, ISet<T>)
      buffer.writeln('  final FirestoreConverter<${typeParams[0]}, dynamic> valueConverter;');
      buffer.writeln('  const $converterClassName(this.valueConverter);');
    } else if (typeParams.length == 2) {
      // Two type parameters (e.g., IMap<K, V>)
      buffer.writeln('  final FirestoreConverter<${typeParams[0]}, dynamic> keyConverter;');
      buffer.writeln('  final FirestoreConverter<${typeParams[1]}, dynamic> valueConverter;');
      buffer.writeln('  const $converterClassName(this.keyConverter, this.valueConverter);');
    } else {
      // General case for multiple type parameters
      for (int i = 0; i < typeParams.length; i++) {
        buffer.writeln('  final FirestoreConverter<${typeParams[i]}, dynamic> converter$i;');
      }
      final constructorParams = List.generate(typeParams.length, (i) => 'this.converter$i').join(', ');
      buffer.writeln('  const $converterClassName($constructorParams);');
    }
    
    buffer.writeln('');

    // Generate fromFirestore method
    buffer.writeln('  @override');
    buffer.writeln('  $typeName$typeParamsString fromFirestore(dynamic data) {');
    
    if (typeParams.length == 1) {
      // Single type parameter
      buffer.writeln('    return $typeName.fromJson(data, (e) => valueConverter.fromFirestore(e));');
    } else if (typeParams.length == 2) {
      // Two type parameters
      buffer.writeln('    return $typeName.fromJson(data, (k) => keyConverter.fromFirestore(k), (v) => valueConverter.fromFirestore(v));');
    } else {
      // General case - would need more complex handling
      buffer.writeln('    throw UnimplementedError("Generic converters with ${typeParams.length} parameters not yet implemented");');
    }
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate toFirestore method
    buffer.writeln('  @override');
    buffer.writeln('  dynamic toFirestore($typeName$typeParamsString data) {');
    
    if (typeParams.length == 1) {
      // Single type parameter
      buffer.writeln('    return data.toJson((e) => valueConverter.toFirestore(e));');
    } else if (typeParams.length == 2) {
      // Two type parameters
      buffer.writeln('    return data.toJson((k) => keyConverter.toFirestore(k), (v) => valueConverter.toFirestore(v));');
    } else {
      // General case
      buffer.writeln('    throw UnimplementedError("Generic converters with ${typeParams.length} parameters not yet implemented");');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }

}
