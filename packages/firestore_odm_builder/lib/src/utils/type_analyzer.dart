import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

/// Utility class for analyzing Dart types in Firestore ODM generation
class TypeAnalyzer {
  static final TypeChecker documentIdChecker = TypeChecker.fromRuntime(DocumentIdField);
  static final TypeChecker subcollectionChecker = TypeChecker.fromRuntime(SubcollectionPath);

  /// Find the document ID field in a constructor
  static String? getDocumentIdField(ConstructorElement constructor) {
    for (final param in constructor.parameters) {
      for (final metadata in param.metadata) {
        final metadataValue = metadata.computeConstantValue();
        if (metadataValue != null &&
            metadataValue.type != null &&
            documentIdChecker.isExactlyType(metadataValue.type!)) {
          return param.name;
        }
      }
    }
    return null;
  }

  /// Check if a type is a primitive type supported by Firestore
  static bool isPrimitiveType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return [
      'String', 'int', 'double', 'bool', 'DateTime', 'Timestamp',
      'List<String>', 'List<int>', 'List<double>', 'List<bool>',
    ].contains(typeName);
  }

  /// Check if a type is a custom class (not primitive or built-in)
  static bool isCustomClass(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return !isPrimitiveType(type) &&
           !isListType(type) &&
           !typeName.startsWith('Map<') &&
           !typeName.startsWith('Set<');
  }

  /// Check if a type is comparable (supports ordering operations)
  static bool isComparableType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return ['int', 'double', 'DateTime', 'Timestamp'].contains(typeName);
  }

  /// Check if a type is a List type
  static bool isListType(DartType type) {
    return type.getDisplayString(withNullability: false).startsWith('List<');
  }

  /// Check if a type is a built-in Dart type
  static bool isBuiltInType(DartType type) {
    final typeString = type.getDisplayString(withNullability: false);
    return type.isDartCoreType ||
        typeString.startsWith('List<') ||
        typeString.startsWith('Map<') ||
        typeString == 'DateTime' ||
        typeString == 'double' ||
        typeString == 'int' ||
        typeString == 'bool' ||
        typeString == 'String';
  }

  /// Check if a type is numeric (int or double)
  static bool isNumericType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return ['int', 'double'].contains(typeName);
  }

  /// Check if a type is String
  static bool isStringType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return typeName == 'String';
  }

  /// Check if a type is bool
  static bool isBoolType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return typeName == 'bool';
  }

  /// Check if a type is DateTime or Timestamp
  static bool isDateTimeType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return typeName == 'DateTime' || typeName == 'Timestamp';
  }

  /// Get the element type of a List
  static String getListElementType(DartType listType) {
    final typeString = listType.getDisplayString(withNullability: false);
    if (typeString.startsWith('List<') && typeString.endsWith('>')) {
      return typeString.substring(5, typeString.length - 1);
    }
    return 'dynamic';
  }
}