import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/converters/handlers/json_converter.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:json_annotation/json_annotation.dart';

/// Firestore data type representation for Firestore ODM
/// Based on official Firestore supported data types
enum FirestoreType {
  // Primitive types
  string, // Text string
  integer, // 64-bit signed integer
  double, // 64-bit double precision floating-point
  boolean, // Boolean
  timestamp, // Date and time
  bytes, // Byte data
  geoPoint, // Geographical point
  reference, // Document reference
  // Complex types
  array, // Array
  map, // Map (embedded object)
  // Special values
  null_, // Null value
  // For custom objects that will be serialized as maps
  object,
}

/// Functional converter interface for type conversions
sealed class TypeConverter {
  Expression generateFromFirestore(Expression sourceExpression);
  Expression generateToFirestore(Expression sourceExpression);
}

/// Direct converter for primitive types (no conversion needed)
class DirectConverter implements TypeConverter {
  final String dartTypeName;

  const DirectConverter(this.dartTypeName);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return sourceExpression;
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return sourceExpression; // No conversion needed for primitive types
  }
}

class VariableConverterClassConverter implements TypeConverter {
  final Reference variableName;

  const VariableConverterClassConverter(this.variableName);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return variableName.property('fromFirestore').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return variableName.property('toFirestore').call([sourceExpression]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final otherConverter = other as VariableConverterClassConverter;
    return variableName == otherConverter.variableName;
  }

  @override
  int get hashCode => variableName.hashCode;
}

/// Converter using a specific converter class (handles both generic and non-generic)
class ConverterClassConverter implements TypeConverter {
  final String converterClassName;
  final List<TypeConverter> parameterConverters;

  const ConverterClassConverter(
    this.converterClassName, [
    this.parameterConverters = const [],
  ]);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final converterInstance = _createConverterInstance();
    return converterInstance.property('fromFirestore').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    final converterInstance = _createConverterInstance();
    return converterInstance.property('toFirestore').call([sourceExpression]);
  }

  Expression _createConverterInstance() {
    final args = _generateConverterArguments();
    return refer(converterClassName).call(args);
  }

  List<Expression> _generateConverterArguments() {
    return parameterConverters
        .map((converter) => _convertToExpression(converter))
        .toList();
  }

  Expression _convertToExpression(TypeConverter converter) {
    if (converter is ConverterClassConverter) {
      return converter._createConverterInstance();
    }
    return refer('${converter.runtimeType}').call([]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final otherConverter = other as ConverterClassConverter;
    return converterClassName == otherConverter.converterClassName &&
        parameterConverters.length ==
            otherConverter.parameterConverters.length &&
        parameterConverters.every(
          (converter) => otherConverter.parameterConverters.contains(converter),
        );
  }

  @override
  int get hashCode {
    return Object.hash(converterClassName, parameterConverters);
  }
}

/// Converter for generic types with element converters
class JsonConverter implements TypeConverter {
  final JsonConverterHandler handler = const JsonConverterHandler();
  final TypeReference dartType;
  final List<TypeConverter> elementConverters;
  final String? customFromJsonMethod;
  final String? customToJsonMethod;

  const JsonConverter(
    this.dartType,
    this.elementConverters, {
    this.customFromJsonMethod,
    this.customToJsonMethod,
  });

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return handler.fromJson(
      dartType,
      sourceExpression,
      elementConverters,
    );
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return handler.toJson(
      dartType,
      sourceExpression,
      elementConverters,
    );
  }
}

/// Converter for custom JsonConverter annotations
class AnnotationConverter implements TypeConverter {
  final String converterClassName;

  const AnnotationConverter(this.converterClassName);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return refer(
      converterClassName,
    ).call([]).property('fromJson').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return refer(
      converterClassName,
    ).call([]).property('toJson').call([sourceExpression]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final otherConverter = other as AnnotationConverter;
    return converterClassName == otherConverter.converterClassName;
  }

  @override
  int get hashCode {
    return converterClassName.hashCode;
  }
}

abstract class UnderlyingConverter implements TypeConverter {
  final TypeConverter innerConverter;

  const UnderlyingConverter(this.innerConverter);

  @override
  Expression generateFromFirestore(Expression sourceExpression);

  @override
  Expression generateToFirestore(Expression sourceExpression);
}

/// Nullable wrapper converter
class NullableConverter extends UnderlyingConverter {
  const NullableConverter(super._converter);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final innerExpr = innerConverter.generateFromFirestore(sourceExpression);
    return sourceExpression
        .equalTo(literalNull)
        .conditional(literalNull, innerExpr);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    final innerExpr = innerConverter.generateToFirestore(
      sourceExpression.nullChecked,
    );
    return sourceExpression
        .equalTo(literalNull)
        .conditional(literalNull, innerExpr);
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, innerConverter);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final otherConverter = other as NullableConverter;
    return innerConverter == otherConverter.innerConverter;
  }
}

/// Information about a field in a model
class FieldInfo {
  final String parameterName;
  final String jsonFieldName;
  final DartType dartType;
  final bool isDocumentId;
  final bool isOptional;

  final ModelAnalysis typeAnalysis;

  const FieldInfo({
    required this.parameterName,
    required this.jsonFieldName,
    required this.dartType,
    required this.isDocumentId,
    required this.isOptional,
    required this.typeAnalysis,
  });

  /// Get Firestore type from type analysis
  FirestoreType get firestoreType => typeAnalysis.firestoreType;

  /// Get converter from type analysis
  TypeConverter get converter => typeAnalysis.converter;

  /// Generate conversion from Firestore
  Expression generateFromFirestore(Expression sourceExpression) {
    return typeAnalysis.converter.generateFromFirestore(sourceExpression);
  }

  /// Generate conversion to Firestore
  Expression generateToFirestore(Expression sourceExpression) {
    return typeAnalysis.converter.generateToFirestore(sourceExpression);
  }

  @override
  String toString() =>
      'FieldInfo(param: $parameterName, json: $jsonFieldName, type: $dartType, firestoreType: $firestoreType, isDocId: $isDocumentId)';
}

/// Complete analysis of a model class
class ModelAnalysis {
  final String className;
  final String? documentIdFieldName;
  final Map<String, FieldInfo> fields;
  final List<FieldInfo> updateableFields;
  final DartType dartType;
  final FirestoreType firestoreType;
  final TypeConverter converter;

  const ModelAnalysis({
    required this.className,
    required this.documentIdFieldName,
    required this.fields,
    required this.updateableFields,
    required this.dartType,
    required this.firestoreType,
    required this.converter,
  });

  /// Get field by parameter name
  FieldInfo? getFieldByParam(String paramName) => fields[paramName];

  /// Get document ID field info
  FieldInfo? get documentIdField =>
      documentIdFieldName != null ? fields[documentIdFieldName] : null;

  bool get isGeneric =>
      dartType is InterfaceType &&
      (dartType as InterfaceType).typeArguments.isNotEmpty;

  List<String> get typeParameters => isGeneric
      ? (dartType as InterfaceType).typeArguments
            .map((e) => e.getDisplayString())
            .toList()
      : [];
}

/// Combined result of model and type analysis
class AnalysisResult {
  final Map<String, ModelAnalysis> modelAnalyses;

  const AnalysisResult({required this.modelAnalyses});

  /// Get all types that need converters (custom types - non-built-in Dart types)
  Map<String, ModelAnalysis> get customTypes {
    return Map.fromEntries(
      modelAnalyses.entries.where(
        (entry) => !_isBuiltInDartType(entry.key), // Not a built-in Dart type
      ),
    );
  }

  /// Check if a type name represents a built-in Dart type
  bool _isBuiltInDartType(String typeName) {
    const builtInTypes = {
      'String',
      'int',
      'double',
      'bool',
      'num',
      'DateTime',
      'Duration',
      'Uri',
      'dynamic',
      'Object',
      'void',
      'Null',
    };

    const typesWithExistingConverters = {
      'List',
      'Map',
      'Set', // These have universal converters in model_converter.dart
      'Uint8List', 'GeoPoint', 'DocumentReference',
    };

    // Check exact matches for primitive types
    if (builtInTypes.contains(typeName)) {
      return true;
    }

    // Check for types that already have universal converters
    if (typesWithExistingConverters.contains(typeName)) {
      return true;
    }

    return false;
  }
}

// /// Registry for caching type analysis results
// class TypeRegistry {
//   final Map<String, ModelAnalysis> _cache = {};
//   final Map<String, ModelAnalysis> _modelCache = {};

//   /// Get or analyze a type
//   ModelAnalysis getOrAnalyzeType(DartType dartType, Element? element) {
//     final typeKey = _getTypeKey(dartType, element);

//     if (_cache.containsKey(typeKey)) {
//       return _cache[typeKey]!;
//     }

//     final result = _analyzeType(dartType, element);
//     _cache[typeKey] = result;
//     return result;
//   }

//   /// Get or analyze a model
//   ModelAnalysis? getOrAnalyzeModel(ClassElement classElement) {
//     final className = classElement.name;

//     if (_modelCache.containsKey(className)) {
//       return _modelCache[className];
//     }

//     final result = ModelAnalyzer._analyzeModelInternal(classElement, this);
//     if (result != null) {
//       _modelCache[className] = result;
//     }
//     return result;
//   }

//   /// Generate a unique key for a type including element annotations
//   String _getTypeKey(DartType dartType, Element? element) {
//     final typeString = dartType.getDisplayString(withNullability: true);

//     // Include custom JsonConverter annotations in the key to avoid cache conflicts
//     if (element != null) {
//       final customConverter = _findCustomJsonConverter(element);
//       if (customConverter != null) {
//         return '$typeString@$customConverter';
//       }
//     }

//     return typeString;
//   }

//   /// Analyze a type and return its analysis result
//   TypeAnalysisResult _analyzeType(DartType dartType, Element? element) {
//     final firestoreType = ModelAnalyzer._determineFirestoreType(
//       dartType,
//       element,
//     );
//     final converter = _createConverter(dartType, element, firestoreType);
//     final hasJsonSupport = ModelAnalyzer._hasStandardJsonSupport(dartType);
//     final hasGenericJsonSupport = ModelAnalyzer._hasGenericJsonSupport(
//       dartType,
//     );

//     // Determine if this type is generic
//     bool isGeneric = false;
//     List<String> typeParameters = [];

//     if (dartType is InterfaceType) {
//       isGeneric = dartType.typeArguments.isNotEmpty;
//       if (isGeneric) {
//         typeParameters = dartType.typeArguments
//             .map((arg) => arg.getDisplayString(withNullability: false))
//             .toList();
//       }
//     }

//     return TypeAnalysisResult(
//       firestoreType: firestoreType,
//       converter: converter,
//       hasJsonSupport: hasJsonSupport,
//       hasGenericJsonSupport: hasGenericJsonSupport,
//       isGeneric: isGeneric,
//       typeParameters: typeParameters,
//     );
//   }

//   /// Create appropriate converter for a type

//   /// Analyze all types recursively and return all type analyses
//   Map<String, TypeAnalysisResult> analyzeAllTypesRecursively(
//     DartType rootType,
//   ) {
//     final Map<Object, TypeAnalysisResult> allTypeAnalyses = {};
//     final Set<Object> processedTypes = {};

//     _analyzeTypeRecursively(rootType, allTypeAnalyses, processedTypes);

//     // Convert back to String key Map for final result
//     final Map<String, TypeAnalysisResult> result = {};
//     for (final entry in allTypeAnalyses.entries) {
//       String keyName;
//       if (entry.key is InterfaceElement2) {
//         keyName = (entry.key as InterfaceElement2).name3!;
//       } else {
//         keyName = entry.key.toString();
//       }
//       result[keyName] = entry.value;
//     }

//     return result;
//   }

//   /// Recursively analyze a type and discover all nested types
//   void _analyzeTypeRecursively(
//     DartType dartType,
//     Map<Object, TypeAnalysisResult> allTypeAnalyses,
//     Set<Object> processedTypes,
//   ) {
//     // Skip type parameters (like T, K, V) - only analyze concrete types
//     if (dartType is TypeParameterType) {
//       return;
//     }

//     // Use element as key for interface types to avoid conflicts and deduplicate generics
//     Object keyObject;
//     if (dartType is InterfaceType) {
//       // Use element directly as key - this naturally deduplicates
//       // IList<String> and IList<int> to the same IList element
//       keyObject = dartType.element3;
//     } else {
//       // For non-interface types, use the type string
//       keyObject = dartType.getDisplayString(withNullability: false);
//     }

//     // Skip if already processed
//     if (processedTypes.contains(keyObject)) {
//       return;
//     }
//     processedTypes.add(keyObject);

//     // Analyze the current type
//     TypeAnalysisResult typeAnalysis;
//     if (dartType is InterfaceType && dartType.typeArguments.isNotEmpty) {
//       // For generic types, manually create a generic analysis
//       final baseAnalysis = getOrAnalyzeType(dartType, null);

//       // Generate generic type parameter names based on argument count
//       final argCount = dartType.typeArguments.length;
//       List<String> typeParameters;

//       if (argCount == 1) {
//         typeParameters = ['T'];
//       } else if (argCount == 2) {
//         typeParameters = ['K', 'V'];
//       } else {
//         typeParameters = List.generate(argCount, (i) => 'T${i + 1}');
//       }

//       // Override with generic analysis
//       typeAnalysis = TypeAnalysisResult(
//         firestoreType: baseAnalysis.firestoreType,
//         converter: baseAnalysis.converter,
//         hasJsonSupport: baseAnalysis.hasJsonSupport,
//         hasGenericJsonSupport: baseAnalysis.hasGenericJsonSupport,
//         isGeneric: true,
//         typeParameters: typeParameters,
//       );
//     } else {
//       typeAnalysis = getOrAnalyzeType(dartType, null);
//     }
//     allTypeAnalyses[keyObject] = typeAnalysis;

//     // Process nested types if this is a generic type
//     if (dartType is InterfaceType && dartType.typeArguments.isNotEmpty) {
//       for (final typeArg in dartType.typeArguments) {
//         // Skip type parameters (like T, K, V) - only analyze concrete types
//         if (typeArg is! TypeParameterType) {
//           _analyzeTypeRecursively(typeArg, allTypeAnalyses, processedTypes);
//         }
//       }
//     }
//   }
// }

/// Analyzer for complete model structure including JSON field mapping
class ModelAnalyzer {
  static final TypeChecker _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
  static final TypeChecker _jsonConverterChecker = TypeChecker.fromRuntime(
    JsonConverter,
  );

  static final TypeChecker _durationChecker = TypeChecker.fromRuntime(Duration);

  static final TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);

  static final Map<String, ModelAnalysis> _analyzed = {};

  /// Analyze a complete model class and return structured information
  static ModelAnalysis analyzeModel(DartType type, Element? element) {
    final className = type.name!;
    if (_analyzed.containsKey(className)) {
      return _analyzed[className]!;
    }
    final result = _analyzeModelInternal(type, element);
    _analyzed[className] = result;
    return result;
  }

  /// Internal method for analyzing a model with a given registry
  static ModelAnalysis _analyzeModelInternal(DartType type, Element? element) {
    // Get all fields from the class and its supertypes (excluding Object)
    final fields = element is ClassElement
        ? _getConstructorParameters(element)
        : <(String, DartType, Element)>[];

    // Analyze all fields
    final Map<String, FieldInfo> fieldsMap = {};

    for (final (fieldName, fieldType, element) in fields) {
      final fieldInfo = _analyzeFieldFromAccessor(
        fieldName,
        fieldType,
        element,
      );
      fieldsMap[fieldName] = fieldInfo;
    }

    // Find document ID field using logic
    final documentIdFieldName = _getDocumentIdFieldFromAccessors(fields);

    // Mark document ID field
    if (documentIdFieldName != null &&
        fieldsMap.containsKey(documentIdFieldName)) {
      final existingField = fieldsMap[documentIdFieldName]!;
      fieldsMap[documentIdFieldName] = FieldInfo(
        parameterName: existingField.parameterName,
        jsonFieldName: existingField.jsonFieldName,
        dartType: existingField.dartType,
        isDocumentId: true,
        isOptional: existingField.isOptional,
        typeAnalysis: existingField.typeAnalysis,
      );
    }

    // Get updateable fields (non-document-ID fields)
    final updateableFields = fieldsMap.values
        .where((field) => !field.isDocumentId)
        .toList();
    // _createConverter(dartType, element, firestoreType);
    //     final hasJsonSupport = ModelAnalyzer._hasStandardJsonSupport(dartType);
    //     final hasGenericJsonSupport = ModelAnalyzer._hasGenericJsonSupport(
    //       dartType,
    //     );

    return ModelAnalysis(
      className: type.getDisplayString(withNullability: false),
      documentIdFieldName: documentIdFieldName,
      fields: fieldsMap,
      updateableFields: updateableFields,
      dartType: type,
      firestoreType: _processTypeToFirestoreType(type),
      converter: _createConverter(type, type.element),
    );
  }

  static AnalysisResult analyzeModels(Iterable<DartType> types) {
    for (final type in types) {
      analyzeModel(type, type.element);
    }
    return AnalysisResult(modelAnalyses: _analyzed);
  }

  // /// Analyze a model and all its nested types recursively
  // static AnalysisResult analyzeModelWithNestedTypes(
  //   ClassElement rootClassElement,
  // ) {
  //   final registry = TypeRegistry();
  //   final Map<String, ModelAnalysis> modelAnalyses = {};
  //   final Map<String, TypeAnalysisResult> typeAnalyses = {};

  //   // First analyze the root model
  //   final rootAnalysis = registry.getOrAnalyzeModel(rootClassElement);
  //   if (rootAnalysis != null) {
  //     modelAnalyses[rootClassElement.name] = rootAnalysis;

  //     // Add the root model's type analysis
  //     final rootTypeAnalysis = registry.getOrAnalyzeType(
  //       rootClassElement.thisType,
  //       rootClassElement,
  //     );
  //     typeAnalyses[rootClassElement.name] = rootTypeAnalysis;

  //     // Then use TypeRegistry to analyze all nested types in the model's fields
  //     for (final field in rootAnalysis.fields.values) {
  //       final nestedTypeAnalyses = registry.analyzeAllTypesRecursively(
  //         field.dartType,
  //       );

  //       // Add all type analyses
  //       typeAnalyses.addAll(nestedTypeAnalyses);

  //       // Convert type analyses to model analyses for custom class types
  //       for (final entry in nestedTypeAnalyses.entries) {
  //         final typeName = entry.key;
  //         final typeAnalysis = entry.value;

  //         // Only create model analysis for user-defined custom classes with fields and document IDs
  //         // Skip generic collection types (IList, IMap, ISet) - they only need TypeAnalysisResult for converters
  //         if (typeAnalysis.firestoreType == FirestoreType.object &&
  //             !typeAnalysis.isGeneric && // Skip generic types like IList<T>
  //             !modelAnalyses.containsKey(typeName)) {
  //           // Try to find the ClassElement for this type
  //           if (field.dartType is InterfaceType) {
  //             final interfaceType = field.dartType as InterfaceType;
  //             final element = interfaceType.element;

  //             if (element is ClassElement && element.name == typeName) {
  //               final nestedModelAnalysis = registry.getOrAnalyzeModel(element);
  //               if (nestedModelAnalysis != null) {
  //                 modelAnalyses[typeName] = nestedModelAnalysis;

  //                 // Recursively analyze the fields of this nested model to discover even deeper types
  //                 for (final nestedField in nestedModelAnalysis.fields.values) {
  //                   final deeperNestedTypeAnalyses = registry
  //                       .analyzeAllTypesRecursively(nestedField.dartType);
  //                   typeAnalyses.addAll(deeperNestedTypeAnalyses);

  //                   // Process these deeper nested types as well
  //                   for (final deeperEntry
  //                       in deeperNestedTypeAnalyses.entries) {
  //                     final deeperTypeName = deeperEntry.key;
  //                     final deeperTypeAnalysis = deeperEntry.value;

  //                     if (deeperTypeAnalysis.firestoreType ==
  //                             FirestoreType.object &&
  //                         !deeperTypeAnalysis.isGeneric &&
  //                         !modelAnalyses.containsKey(deeperTypeName)) {
  //                       // Try to find ClassElement for this deeper nested type and recursively analyze it
  //                       _tryRecursiveAnalysis(
  //                         deeperTypeName,
  //                         nestedField.dartType,
  //                         modelAnalyses,
  //                         typeAnalyses,
  //                         registry,
  //                       );
  //                     }
  //                   }
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  //   return AnalysisResult(
  //     modelAnalyses: modelAnalyses,
  //     typeAnalyses: typeAnalyses,
  //   );
  // }

  // /// Try to recursively analyze a deeper nested type
  // static void _tryRecursiveAnalysis(
  //   String typeName,
  //   DartType fieldType,
  //   Map<String, ModelAnalysis> modelAnalyses,
  //   TypeRegistry registry,
  // ) {
  //   // For deeper nested types, we need to search through the entire type hierarchy
  //   // This is a simplified approach - in a production system, this would need more robust element resolution

  //   if (fieldType is InterfaceType) {
  //     final element = fieldType.element;

  //     // Check if this element matches our target type name
  //     if (element is ClassElement && element.name == typeName) {
  //       final deeperModelAnalysis = registry.getOrAnalyzeModel(element);
  //       if (deeperModelAnalysis != null) {
  //         modelAnalyses[typeName] = deeperModelAnalysis;

  //         // Continue even deeper recursion for fields of this model
  //         for (final deeperField in deeperModelAnalysis.fields.values) {
  //           final evenDeeperTypeAnalyses = registry.analyzeAllTypesRecursively(
  //             deeperField.dartType,
  //           );
  //           typeAnalyses.addAll(evenDeeperTypeAnalyses);

  //           // Process even deeper nested types
  //           for (final evenDeeperEntry in evenDeeperTypeAnalyses.entries) {
  //             final evenDeeperTypeName = evenDeeperEntry.key;
  //             final evenDeeperTypeAnalysis = evenDeeperEntry.value;

  //             if (evenDeeperTypeAnalysis.firestoreType ==
  //                     FirestoreType.object &&
  //                 !evenDeeperTypeAnalysis.isGeneric &&
  //                 !modelAnalyses.containsKey(evenDeeperTypeName)) {
  //               // Try one more level of recursion
  //               _tryRecursiveAnalysis(
  //                 evenDeeperTypeName,
  //                 deeperField.dartType,
  //                 modelAnalyses,
  //                 typeAnalyses,
  //                 registry,
  //               );
  //             }
  //           }
  //         }
  //       }
  //       return;
  //     }

  //     // Also check type arguments for nested custom types
  //     for (final typeArg in fieldType.typeArguments) {
  //       if (typeArg is InterfaceType) {
  //         final argElement = typeArg.element;
  //         if (argElement is ClassElement && argElement.name == typeName) {
  //           final deeperModelAnalysis = registry.getOrAnalyzeModel(argElement);
  //           if (deeperModelAnalysis != null) {
  //             modelAnalyses[typeName] = deeperModelAnalysis;
  //           }
  //           return;
  //         }
  //       }
  //     }
  //   }
  // }

  static TypeConverter _createConverter(DartType dartType, Element? element) {
    final isNullable = TypeAnalyzer.isNullableType(dartType);

    // Check for custom JsonConverter annotations first (like @ListLengthConverter())
    if (element != null) {
      // Look for any annotation that implements JsonConverter
      final customConverter = _findCustomJsonConverter(element);
      if (customConverter != null) {
        return AnnotationConverter(customConverter);
      }

      // Check for standard @JsonConverter annotation
      final jsonConverter = _jsonConverterChecker.firstAnnotationOf(element);
      if (jsonConverter != null) {
        final converterType = jsonConverter.type;
        if (converterType != null && converterType is InterfaceType) {
          final converterClassName = converterType.element3.name3!;
          return AnnotationConverter(converterClassName);
        }
      }

      // Check for generic JsonConverter support
      if (dartType is InterfaceType && _hasJsonSupport(dartType)) {
        final typeParams = dartType.typeArguments
            .map((t) => analyzeModel(t, t.element).converter)
            .toList();
        return JsonConverter(dartType.reference, typeParams);
      }
    }

    final converter = _createDefaultConverter(dartType);

    // Wrap with nullable converter if needed
    if (isNullable) {
      return NullableConverter(converter);
    }

    // If no custom converter found, create default converter based on type
    return converter;
  }

  /// Find custom JsonConverter annotation (like @ListLengthConverter())
  static String? _findCustomJsonConverter(Element element) {
    for (final annotation in element.metadata) {
      final annotationType = annotation.computeConstantValue()?.type;
      if (annotationType is InterfaceType) {
        final classElement = annotationType.element;

        // Check if this class implements JsonConverter interface
        if (_implementsJsonConverter(classElement)) {
          return classElement.name;
        }
      }
    }
    return null;
  }

  /// Check if a class implements JsonConverter interface
  static bool _implementsJsonConverter(Element classElement) {
    if (classElement is! ClassElement) return false;

    // Check all interfaces and superclasses
    for (final interface in classElement.allSupertypes) {
      final interfaceName = interface.element.name;
      if (interfaceName == 'JsonConverter') {
        return true;
      }
    }
    return false;
  }

  static String getBaseTypeName(DartType type) {
    if (type is InterfaceType) {
      return type.element3.name3!;
    }
    if (type is ParameterizedType) {
      return type.element?.name ?? type.toString();
    }
    return type.toString();
  }

  /// Create default converter based on type and firestore type
  static TypeConverter _createDefaultConverter(DartType dartType) {
    if (dartType.isDartCoreDouble ||
        dartType.isDartCoreInt ||
        dartType.isDartCoreString ||
        dartType.isDartCoreBool) {
      return ConverterClassConverter('PrimitiveConverter');
    }

    if (_durationChecker.isExactlyType(dartType)) {
      return ConverterClassConverter('DurationConverter');
    }

    if (_dateTimeChecker.isExactlyType(dartType)) {
      return ConverterClassConverter('DateTimeConverter');
    }

    final baseTypeName = getBaseTypeName(dartType);
    return ConverterClassConverter(
      '${baseTypeName}Converter',
      dartType is InterfaceType
          ? dartType.typeArguments.map((arg) {
              final argAnalysis = analyzeModel(arg, arg.element);
              return argAnalysis.converter;
            }).toList()
          : [],
    );
  }

  /// Get all fields from the class and its supertypes (excluding Object)
  static List<(String, DartType, Element)> _getConstructorParameters(
    ClassElement element,
  ) {
    var constructor = element.constructors
        .where((c) => c.isFactory && c.name.isEmpty)
        .firstOrNull;

    if (constructor != null && constructor.redirectedConstructor != null) {
      constructor = constructor.redirectedConstructor;
    }

    constructor ??= element.constructors
        .where((c) => !c.isFactory && c.name.isEmpty)
        .firstOrNull;

    if (constructor == null) {
      throw Exception('No suitable constructor found for ${element.name}');
    }

    return _extractParameters(constructor);
  }

  static List<(String, DartType, Element)> _extractParameters(
    ConstructorElement constructor,
  ) {
    return constructor.parameters
        .where((p) => p.isNamed) // Only named parameters
        .where((p) {
          // Check JsonKey annotations
          final jsonKey = _jsonKeyChecker.firstAnnotationOf(p);
          if (jsonKey != null) {
            final jsonKeyConstantReader = ConstantReader(jsonKey);

            // Check includeFromJson
            bool includeFromJson = true;
            try {
              final includeFromJsonField = jsonKeyConstantReader.read(
                'includeFromJson',
              );
              if (!includeFromJsonField.isNull) {
                includeFromJson = includeFromJsonField.boolValue;
              }
            } catch (e) {
              // Field not present, use default value true
            }

            // Check includeToJson
            bool includeToJson = true;
            try {
              final includeToJsonField = jsonKeyConstantReader.read(
                'includeToJson',
              );
              if (!includeToJsonField.isNull) {
                includeToJson = includeToJsonField.boolValue;
              }
            } catch (e) {
              // Field not present, use default value true
            }

            return includeFromJson && includeToJson;
          }
          return true;
        })
        .map((p) => (p.name, p.type, p))
        .toList();
  }

  /// Analyze a field from accessor element
  static FieldInfo _analyzeFieldFromAccessor(
    String fieldName,
    DartType fieldType,
    Element element,
  ) {
    final isNullable = TypeAnalyzer.isNullableType(fieldType);
    final isOptional = isNullable;

    // Determine JSON field name
    String jsonFieldName = fieldName;

    // Check for @JsonKey annotation
    final jsonKey = _jsonKeyChecker.firstAnnotationOf(element);
    if (jsonKey != null) {
      final jsonKeyConstantReader = ConstantReader(jsonKey);
      final nameValue = jsonKeyConstantReader.read('name').stringValue;
      if (nameValue.isNotEmpty) {
        jsonFieldName = nameValue;
      }
    }

    // Get type analysis result from registry
    return FieldInfo(
      parameterName: fieldName,
      jsonFieldName: jsonFieldName,
      isDocumentId: false,
      dartType: fieldType,
      isOptional: isOptional,
      typeAnalysis: analyzeModel(fieldType, element),
    );
  }

  /// Process a Dart type to determine its Firestore type
  static FirestoreType _processTypeToFirestoreType(DartType dartType) {
    // Handle nullable types by getting the underlying type
    final actualType = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? (dartType as InterfaceType).element3.thisType
        : dartType;
    // Handle primitive types
    if (TypeAnalyzer.isStringType(actualType)) {
      return FirestoreType.string;
    }
    if (TypeAnalyzer.isIntType(actualType)) {
      return FirestoreType.integer;
    }
    if (TypeAnalyzer.isDoubleType(actualType)) {
      return FirestoreType.double;
    }
    if (TypeAnalyzer.isBoolType(actualType)) {
      return FirestoreType.boolean;
    }

    // Handle special types that convert to different Firestore types
    if (TypeAnalyzer.isDurationType(actualType)) {
      return FirestoreType
          .integer; // Duration converts to milliseconds (integer)
    }
    if (TypeAnalyzer.isDateTimeType(actualType)) {
      return FirestoreType
          .timestamp; // DateTime converts to Firestore Timestamp
    }

    if (TypeAnalyzer.isMapType(actualType)) {
      return FirestoreType.map;
    }

    // Handle collections
    if (TypeAnalyzer.isListType(actualType)) {
      return FirestoreType.array;
    }

    // For custom objects, return object type (will be serialized as map)
    return FirestoreType.object;
  }

  /// Find the document ID field from accessors
  static String? _getDocumentIdFieldFromAccessors(
    List<(String, DartType, Element)> fields,
  ) {
    // First pass: Look for explicit @DocumentIdField() annotation
    for (final (fieldName, _, element) in fields) {
      final documentIdAnnotation = TypeAnalyzer.documentIdChecker
          .firstAnnotationOf(element);
      if (documentIdAnnotation != null) {
        return fieldName;
      }
    }

    // Second pass: Look for a field named 'id' as default
    for (final (fieldName, fieldType, _) in fields) {
      if (fieldName == 'id' && TypeAnalyzer.isStringType(fieldType)) {
        return fieldName;
      }
    }

    return null;
  }

  /// Check if type supports standard JSON serialization
  static bool _hasJsonSupport(DartType dartType) {
    if (dartType is! InterfaceType) {
      return false;
    }

    final classElement = dartType.element;
    if (classElement is! ClassElement) {
      return false;
    }

    // Check for fromJson constructor or static method (one parameter)
    final hasFromJson = _hasFromJsonMethod(classElement);

    // Check for toJson method (no parameters) in class hierarchy
    final hasToJson = _hasToJsonMethod(classElement);

    return hasFromJson && hasToJson;
  }

  /// Check if class or its hierarchy has fromJson method
  static bool _hasFromJsonMethod(ClassElement classElement) {
    final typeParameterCount = classElement.typeParameters.length;

    // Get all classes in hierarchy (current + supertypes, excluding Object)
    final allClasses = [
      classElement,
      ...classElement.allSupertypes
          .where((type) => type.element.name != 'Object')
          .map((type) => type.element)
          .whereType<ClassElement>(),
    ];

    // Check if any class has fromJson
    return allClasses.any((element) {
      final hasConstructor = element.constructors.any(
        (c) =>
            c.name == 'fromJson' &&
            c.parameters.length ==
                typeParameterCount + 1, // +1 for the context parameter
      );

      final hasStaticMethod = element.methods.any(
        (m) =>
            m.name == 'fromJson' &&
            m.isStatic &&
            m.parameters.length ==
                typeParameterCount + 1, // +1 for the context parameter
      );

      return hasConstructor || hasStaticMethod;
    });
  }

  /// Check if class or its hierarchy has toJson method
  static bool _hasToJsonMethod(ClassElement classElement) {
    final typeParameterCount = classElement.typeParameters.length;

    // Check instance methods in current class
    final hasToJsonMethod = classElement.methods.any(
      (method) =>
          method.name == 'toJson' &&
          method.parameters.length == typeParameterCount &&
          !method.isStatic,
    );

    if (hasToJsonMethod) {
      return true;
    }

    // Check mixins for toJson method (Freezed generates toJson in mixins)
    final hasMixinWithToJson = classElement.mixins.any((mixin) {
      final mixinElement = mixin.element;
      return mixinElement.methods.any(
        (method) =>
            method.name == 'toJson' &&
            method.parameters.isEmpty &&
            !method.isStatic,
      );
    });

    if (hasMixinWithToJson) {
      return true;
    }

    // Check superclass
    final supertype = classElement.supertype;
    if (supertype != null && supertype.element.name != 'Object') {
      final supertypeElement = supertype.element;
      if (supertypeElement is ClassElement &&
          _hasToJsonMethod(supertypeElement)) {
        return true;
      }
    }

    return false;
  }

  /// Check if type supports generic JSON serialization
  static bool _hasGenericJsonSupport(DartType dartType) {
    if (dartType is! InterfaceType) {
      return false;
    }

    final classElement = dartType.element;
    if (classElement is! ClassElement) {
      return false;
    }

    // Check for fromJson constructor (accepts 2 or 3 parameters)
    final hasGenericFromJson = classElement.constructors.any(
      (constructor) =>
          constructor.name == 'fromJson' &&
          (constructor.parameters.length == 2 ||
              constructor.parameters.length == 3),
    );

    // Check for toJson method (accepts 1 or 2 parameters)
    final hasGenericToJson = classElement.methods.any(
      (method) =>
          method.name == 'toJson' &&
          (method.parameters.length == 1 || method.parameters.length == 2) &&
          !method.isStatic,
    );

    return hasGenericFromJson && hasGenericToJson;
  }

  /// Check if a type name represents a known Firestore type
  static bool _isKnownFirestoreType(String typeName) {
    const knownTypes = {
      'String',
      'int',
      'double',
      'bool',
      'DateTime',
      'Duration',
      'List',
      'Map',
      'Set',
      'Uint8List',
      'GeoPoint',
      'DocumentReference',
      'Timestamp',
      'Blob',
      'FieldValue',
    };

    // Check exact matches
    if (knownTypes.contains(typeName)) {
      return true;
    }

    // Check generic types (e.g., List<String>, Map<String, dynamic>)
    for (final knownType in knownTypes) {
      if (typeName.startsWith('$knownType<')) {
        return true;
      }
    }

    return false;
  }

  /// Get the appropriate FirestoreConverter for a given FirestoreType and DartType
  static String getConverterForFirestoreType(
    FirestoreType firestoreType,
    DartType dartType, {
    bool isNullable = false,
  }) {
    String converter;

    // Handle special cases based on Dart type first
    final typeName = dartType.getDisplayString(withNullability: false);
    if (typeName == 'Duration') {
      converter = 'const DurationConverter()';
    } else {
      // Handle based on FirestoreType
      switch (firestoreType) {
        case FirestoreType.string:
          converter = 'null'; // No conversion needed for strings
          break;
        case FirestoreType.integer:
          converter = 'null'; // No conversion needed for integers
          break;
        case FirestoreType.double:
          converter = 'null'; // No conversion needed for doubles
          break;
        case FirestoreType.boolean:
          converter = 'null'; // No conversion needed for booleans
          break;
        case FirestoreType.timestamp:
          converter = 'const DateTimeConverter()';
          break;
        case FirestoreType.bytes:
          converter = 'const BytesConverter()';
          break;
        case FirestoreType.geoPoint:
          converter = 'const GeoPointConverter()';
          break;
        case FirestoreType.reference:
          converter = 'const DocumentReferenceConverter()';
          break;
        case FirestoreType.array:
          converter =
              'null'; // Will be handled by ListConverter with element converter
          break;
        case FirestoreType.map:
          converter =
              'null'; // Will be handled by MapConverter with value converter
          break;
        case FirestoreType.null_:
          converter = 'null'; // Null values don't need conversion
          break;
        case FirestoreType.object:
          // For custom objects, use ObjectConverter with the type's fromJson/toJson
          converter =
              'ObjectConverter<$typeName>($typeName.fromJson, (obj) => obj.toJson())';
          break;
      }
    }

    // Wrap with NullableConverter if needed
    if (isNullable && converter != 'null') {
      converter = 'NullableConverter($converter)';
    }

    return converter;
  }
}
