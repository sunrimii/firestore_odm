import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

/// Utility class for analyzing Dart types in Firestore ODM generation
class TypeAnalyzer {
  static final TypeChecker documentIdChecker = TypeChecker.fromRuntime(
    DocumentIdField,
  );

  // TypeCheckers for robust primitive type checking
  static const TypeChecker _stringChecker = TypeChecker.fromRuntime(String);
  static const TypeChecker _intChecker = TypeChecker.fromRuntime(int);
  static const TypeChecker _doubleChecker = TypeChecker.fromRuntime(double);
  static const TypeChecker _boolChecker = TypeChecker.fromRuntime(bool);
  static const TypeChecker _numChecker = TypeChecker.fromRuntime(num);
  static const TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);
  static const TypeChecker _durationChecker = TypeChecker.fromRuntime(Duration);

  // TypeCheckers for collection types - use Iterable to support any iterable
  static const TypeChecker _iterableChecker = TypeChecker.fromRuntime(Iterable);
  static const TypeChecker _listChecker = TypeChecker.fromRuntime(List);
  static const TypeChecker _mapChecker = TypeChecker.fromRuntime(Map);

  static const TypeChecker _immutableCollectionChecker =
      TypeChecker.fromRuntime(ImmutableCollection);
  static const TypeChecker _immutableMapChecker = TypeChecker.fromRuntime(IMap);
  static const TypeChecker _immutableListChecker = TypeChecker.fromRuntime(
    IList,
  );

  /// Find the document ID field in a constructor
  /// First looks for fields with @DocumentIdField() annotation.
  /// If none found, defaults to a field named 'id' (must be String type).
  static String? getDocumentIdField(ConstructorElement2 constructor) {
    // First pass: Look for explicit @DocumentIdField() annotation
    for (final param in constructor.formalParameters) {
      for (final metadata in param.metadata2.annotations) {
        final metadataValue = metadata.computeConstantValue();
        if (metadataValue != null &&
            metadataValue.type != null &&
            documentIdChecker.isExactlyType(metadataValue.type!)) {
          return param.name3!;
        }
      }
    }

    // Second pass: Look for a field named 'id' as default
    for (final param in constructor.formalParameters) {
      if (param.name3 == 'id' && isStringType(param.type)) {
        return param.name3!;
      }
    }

    return null;
  }

  /// Get the non-nullable version of a type for consistent comparison
  static DartType _getNonNullableType(DartType type) {
    return type;
  }

  /// Check if a type is a primitive type supported by Firestore
  static bool isPrimitiveType(DartType type) {
    final nonNullableType = _getNonNullableType(type);

    // Check basic primitive types using TypeChecker
    if (_stringChecker.isExactlyType(nonNullableType) ||
        _intChecker.isExactlyType(nonNullableType) ||
        _doubleChecker.isExactlyType(nonNullableType) ||
        _boolChecker.isExactlyType(nonNullableType) ||
        _dateTimeChecker.isExactlyType(nonNullableType)) {
      return true;
    }

    // Check for iterables of primitives (supports any iterable type)
    if (isIterableType(nonNullableType)) {
      return true;
      // final elementType = getIterableElementType(nonNullableType);
      // if (elementType != null) {
      //   return _stringChecker.isExactlyType(elementType) ||
      //       _intChecker.isExactlyType(elementType) ||
      //       _doubleChecker.isExactlyType(elementType) ||
      //       _boolChecker.isExactlyType(elementType);
      // }
    }

    return false;
  }

  /// Check if a type is an iterable type (List, Set, any custom iterable)
  static bool isIterableType(DartType type) {
    if (_iterableChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }

    // if IMap, ISet, IList are used, they are also iterable
    if (_immutableCollectionChecker.isAssignableFromType(
          _getNonNullableType(type),
        ) ||
        _immutableMapChecker.isAssignableFromType(_getNonNullableType(type)) ||
        _immutableListChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }
    return false;
  }

  /// Get the element type of any iterable using proper type analysis
  static DartType? getIterableElementType(DartType iterableType) {
    final nonNullableType = _getNonNullableType(iterableType);

    if (nonNullableType is ParameterizedType &&
        nonNullableType.typeArguments.isNotEmpty) {
      return nonNullableType.typeArguments.first;
    }
    return null;
  }

  /// Check if a type is a custom class (not primitive or built-in)
  static bool isCustomClass(DartType type) {
    final nonNullableType = _getNonNullableType(type);

    return !isPrimitiveType(nonNullableType) &&
        !isIterableType(nonNullableType) &&
        !_mapChecker.isAssignableFromType(nonNullableType) &&
        !nonNullableType.isDartCoreType;
  }

  /// Check if a type is comparable (supports ordering operations)
  static bool isComparableType(DartType type) {
    final nonNullableType = _getNonNullableType(type);

    return _intChecker.isExactlyType(nonNullableType) ||
        _doubleChecker.isExactlyType(nonNullableType) ||
        _dateTimeChecker.isExactlyType(nonNullableType);
  }

  /// Check if a type is a List type (specifically List, not just any iterable)
  static bool isListType(DartType type) {
    if (_listChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }

    // Check for IList, which is a custom immutable list type
    if (_immutableListChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }

    return false;
  }

  /// Check if a type is a Map type
  static bool isMapType(DartType type) {
    if (_mapChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }

    // Check for IMap, which is a custom immutable map type
    if (_immutableMapChecker.isAssignableFromType(_getNonNullableType(type))) {
      return true;
    }

    return false;
  }

  /// Get the key and value types of a Map using proper type analysis
  static (DartType? keyType, DartType? valueType) getMapTypes(
    DartType mapType,
  ) {
    final nonNullableType = _getNonNullableType(mapType);

    if (nonNullableType is ParameterizedType &&
        nonNullableType.typeArguments.length >= 2) {
      return (
        nonNullableType.typeArguments[0],
        nonNullableType.typeArguments[1],
      );
    }
    return (null, null);
  }

  /// Get the key and value type names of a Map (backward compatibility)
  static (String keyType, String valueType) getMapTypeNames(DartType mapType) {
    final (keyType, valueType) = getMapTypes(mapType);
    return (
      keyType?.getDisplayString() ?? 'dynamic',
      valueType?.getDisplayString() ?? 'dynamic',
    );
  }

  /// Check if a type is a built-in Dart type
  static bool isBuiltInType(DartType type) {
    final nonNullableType = _getNonNullableType(type);

    return nonNullableType.isDartCoreType ||
        isIterableType(nonNullableType) ||
        _mapChecker.isAssignableFromType(nonNullableType) ||
        _dateTimeChecker.isExactlyType(nonNullableType) ||
        nonNullableType.getDisplayString() == 'Timestamp';
  }

  /// Check if a type is numeric (int, double, or num)
  static bool isNumericType(DartType type) {
    final nonNullableType = _getNonNullableType(type);

    return _intChecker.isExactlyType(nonNullableType) ||
        _doubleChecker.isExactlyType(nonNullableType) ||
        _numChecker.isExactlyType(nonNullableType);
  }

  /// Check if a type is String
  static bool isStringType(DartType type) {
    return _stringChecker.isExactlyType(_getNonNullableType(type));
  }

  /// Check if a type is bool
  static bool isBoolType(DartType type) {
    return _boolChecker.isExactlyType(_getNonNullableType(type));
  }

  /// Check if a type is int
  static bool isIntType(DartType type) {
    return _intChecker.isExactlyType(_getNonNullableType(type));
  }

  /// Check if a type is double
  static bool isDoubleType(DartType type) {
    return _doubleChecker.isExactlyType(_getNonNullableType(type));
  }

  /// Check if a type is DateTime or Timestamp
  static bool isDateTimeType(DartType type) {
    final nonNullableType = _getNonNullableType(type);
    return _dateTimeChecker.isExactlyType(nonNullableType) ||
        nonNullableType.getDisplayString() == 'Timestamp';
  }

  /// Check if a type is Duration
  static bool isDurationType(DartType type) {
    return _durationChecker.isExactlyType(_getNonNullableType(type));
  }

  /// Get the element type of a List using proper type analysis
  static DartType? getListElementType(DartType listType) {
    return getIterableElementType(_getNonNullableType(listType));
  }

  /// Get the element type name of a List (backward compatibility)
  static String getListElementTypeName(DartType listType) {
    final elementType = getListElementType(listType);
    return elementType?.getDisplayString() ?? 'dynamic';
  }

  /// Get the element type name of any iterable (backward compatibility)
  static String getIterableElementTypeName(DartType iterableType) {
    final elementType = getIterableElementType(iterableType);
    return elementType?.getDisplayString() ?? 'dynamic';
  }

  /// Check if a type is nullable
  static bool isNullableType(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// Check if an iterable contains primitive elements
  static bool isIterableOfPrimitives(DartType type) {
    final elementType = getIterableElementType(type);
    return elementType != null && isPrimitiveType(elementType);
  }

  /// Check if a Map has string keys and primitive values
  static bool isMapOfStringToPrimitive(DartType type) {
    final (keyType, valueType) = getMapTypes(type);
    return keyType != null &&
        valueType != null &&
        isStringType(keyType) &&
        isPrimitiveType(valueType);
  }
}
