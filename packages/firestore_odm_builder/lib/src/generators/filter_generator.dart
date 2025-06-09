import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../utils/type_analyzer.dart';

/// Generator for filter builders and filter classes
class FilterGenerator {
  /// Generate the filter builder class code
  static void generateFilterBuilderClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootFilterType,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated FilterBuilder for $className');
    buffer.writeln('extension ${className}FilterBuilderExtension on FilterBuilder<${className}> {');
    buffer.writeln('');

    // Add document ID filter if there's a document ID field
    if (documentIdField != null) {
      _generateDocumentIdFilter(buffer, documentIdField, rootFilterType);
    }

    // Generate field methods and nested object getters
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;
      
      if (TypeAnalyzer.isPrimitiveType(fieldType)) {
        _generateFieldMethod(buffer, className, fieldName, fieldType, rootFilterType);
      } else if (TypeAnalyzer.isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateNestedFilterGetter(buffer, fieldName, fieldType, rootFilterType);
      }
    }

    buffer.writeln('}');
  }

  static void _generateDocumentIdFilter(StringBuffer buffer, String documentIdField, String rootFilterType) {
    buffer.writeln('  /// Filter by document ID (${documentIdField} field)');
    buffer.writeln('  FirestoreFilter<$rootFilterType> $documentIdField({');
    buffer.writeln('    String? isEqualTo,');
    buffer.writeln('    String? isNotEqualTo,');
    buffer.writeln('    String? isLessThan,');
    buffer.writeln('    String? isLessThanOrEqualTo,');
    buffer.writeln('    String? isGreaterThan,');
    buffer.writeln('    String? isGreaterThanOrEqualTo,');
    buffer.writeln('    List<String>? whereIn,');
    buffer.writeln('    List<String>? whereNotIn,');
    buffer.writeln('    bool? isNull,');
    buffer.writeln('  }) {');
    buffer.writeln('    return stringFilter(FieldPath.documentId,');
    buffer.writeln('      isEqualTo: isEqualTo,');
    buffer.writeln('      isNotEqualTo: isNotEqualTo,');
    buffer.writeln('      isLessThan: isLessThan,');
    buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
    buffer.writeln('      isGreaterThan: isGreaterThan,');
    buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
    buffer.writeln('      whereIn: whereIn,');
    buffer.writeln('      whereNotIn: whereNotIn,');
    buffer.writeln('      isNull: isNull,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateNestedFilterGetter(StringBuffer buffer, String fieldName, DartType fieldType, String rootFilterType) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    
    buffer.writeln('  /// Access nested $fieldName filters');
    buffer.writeln('  FilterBuilder<${nestedTypeName}> get $fieldName {');
    buffer.writeln('    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return FilterBuilder<${nestedTypeName}>(prefix: nestedPrefix);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  static void _generateFieldMethod(StringBuffer buffer, String className, String fieldName, DartType fieldType, String rootFilterType) {
    final typeString = fieldType.getDisplayString(withNullability: false);
    
    buffer.writeln('  /// Filter by $fieldName');
    buffer.writeln('  FirestoreFilter<${rootFilterType}> $fieldName({');

    // Basic operators
    buffer.writeln('    $typeString? isEqualTo,');
    buffer.writeln('    $typeString? isNotEqualTo,');
    
    // Comparison operators for comparable types
    if (TypeAnalyzer.isComparableType(fieldType)) {
      buffer.writeln('    $typeString? isLessThan,');
      buffer.writeln('    $typeString? isLessThanOrEqualTo,');
      buffer.writeln('    $typeString? isGreaterThan,');
      buffer.writeln('    $typeString? isGreaterThanOrEqualTo,');
    }
    
    // Array operators
    if (TypeAnalyzer.isListType(fieldType)) {
      buffer.writeln('    dynamic arrayContains,');
      buffer.writeln('    List<dynamic>? arrayContainsAny,');
    }
    
    // In operators
    buffer.writeln('    List<$typeString>? whereIn,');
    buffer.writeln('    List<$typeString>? whereNotIn,');
    buffer.writeln('    bool? isNull,');
    
    buffer.writeln('  }) {');
    
    // Use base filter methods based on type
    if (typeString == 'String') {
      buffer.writeln('    return stringFilter<$rootFilterType>(\'$fieldName\',');
    } else if (TypeAnalyzer.isListType(fieldType)) {
      final elementType = TypeAnalyzer.getListElementType(fieldType);
      buffer.writeln('    return arrayFilter<$rootFilterType, $elementType>(\'$fieldName\',');
    } else if (typeString == 'bool') {
      buffer.writeln('    return boolFilter<$rootFilterType>(\'$fieldName\',');
    } else if (typeString == 'DateTime') {
      buffer.writeln('    return dateTimeFilter<$rootFilterType>(\'$fieldName\',');
    } else if (TypeAnalyzer.isNumericType(fieldType)) {
      buffer.writeln('    return numericFilter<$rootFilterType, $typeString>(\'$fieldName\',');
    } else {
      // Fallback for other types, treat as string-like
      buffer.writeln('    return stringFilter<$rootFilterType>(\'$fieldName\',');
    }
    
    // Parameters
    buffer.writeln('      isEqualTo: isEqualTo,');
    buffer.writeln('      isNotEqualTo: isNotEqualTo,');
    
    if (TypeAnalyzer.isComparableType(fieldType)) {
      buffer.writeln('      isLessThan: isLessThan,');
      buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
      buffer.writeln('      isGreaterThan: isGreaterThan,');
      buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
    }
    
    if (TypeAnalyzer.isListType(fieldType)) {
      buffer.writeln('      arrayContains: arrayContains,');
      buffer.writeln('      arrayContainsAny: arrayContainsAny,');
    }
    
    buffer.writeln('      whereIn: whereIn,');
    buffer.writeln('      whereNotIn: whereNotIn,');
    buffer.writeln('      isNull: isNull,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  /// Generate nested filter builder classes
  static void generateNestedFilterBuilderClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootFilterType,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;
      
      if (TypeAnalyzer.isCustomClass(fieldType)) {
        final element = fieldType.element;
        if (element is ClassElement) {
          final typeName = element.name;
          
          // Avoid processing the same type multiple times
          if (processedTypes.contains(typeName)) continue;
          processedTypes.add(typeName);
          
          final nestedConstructor = element.unnamedConstructor;
          if (nestedConstructor != null) {
            buffer.writeln('');
            generateFilterBuilderClass(buffer, typeName, nestedConstructor, rootFilterType, null);
            
            // Recursively generate for deeply nested types
            generateNestedFilterBuilderClasses(buffer, nestedConstructor, processedTypes, rootFilterType);
          }
        }
      }
    }
  }
}