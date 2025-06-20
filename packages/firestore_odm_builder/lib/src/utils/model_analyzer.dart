import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';
import 'package:json_annotation/json_annotation.dart';
import 'type_analyzer.dart';

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

/// Information about a field in a model
class FieldInfo {
  final String parameterName;
  final String jsonFieldName;
  final DartType dartType;
  final FirestoreType firestoreType;
  final bool isDocumentId;
  final bool isNullable;
  final bool isOptional;
  final String? customFromFirestoreExpression;
  final String? customToFirestoreExpression;

  const FieldInfo({
    required this.parameterName,
    required this.jsonFieldName,
    required this.dartType,
    required this.firestoreType,
    required this.isDocumentId,
    required this.isNullable,
    required this.isOptional,
    this.customFromFirestoreExpression,
    this.customToFirestoreExpression,
  });

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

  const ModelAnalysis({
    required this.className,
    required this.documentIdFieldName,
    required this.fields,
    required this.updateableFields,
  });

  /// Get field by parameter name
  FieldInfo? getFieldByParam(String paramName) => fields[paramName];

  /// Get document ID field info
  FieldInfo? get documentIdField =>
      documentIdFieldName != null ? fields[documentIdFieldName] : null;

  @override
  String toString() =>
      'ModelAnalysis(class: $className, docIdField: $documentIdFieldName, fields: ${fields.length})';
}

/// Analyzer for complete model structure including JSON field mapping
class ModelAnalyzer {
  static final TypeChecker _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
  static final TypeChecker _jsonConverterChecker = TypeChecker.fromRuntime(
    JsonConverter,
  );

  /// Analyze a complete model class and return structured information
  static ModelAnalysis? analyzeModel(ClassElement classElement) {
    try {
      // Get all fields from the class and its supertypes (excluding Object)
      final fields = _getConstructorParameters(classElement);

      if (fields.isEmpty) {
        return null;
      }

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
          firestoreType: existingField.firestoreType,
          isDocumentId: true,
          isNullable: existingField.isNullable,
          isOptional: existingField.isOptional,
          customFromFirestoreExpression:
              existingField.customFromFirestoreExpression,
          customToFirestoreExpression:
              existingField.customToFirestoreExpression,
        );
      }

      // Get updateable fields (non-document-ID fields)
      final updateableFields = fieldsMap.values
          .where((field) => !field.isDocumentId)
          .toList();

      return ModelAnalysis(
        className: classElement.name,
        documentIdFieldName: documentIdFieldName,
        fields: fieldsMap,
        updateableFields: updateableFields,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a method name is a standard Object method that should be excluded
  static bool _isObjectMethod(String methodName) {
    const objectMethods = {
      'hashCode',
      'toString',
      'runtimeType',
      'noSuchMethod',
    };
    return objectMethods.contains(methodName);
  }

  /// Get all fields from the class and its supertypes (excluding Object)
  static List<(String, DartType, Element)> _getConstructorParameters(
    ClassElement classElement,
  ) {
    // 搵 factory constructor
    var constructor = classElement.constructors
        .where((c) => c.isFactory && c.name.isEmpty)
        .firstOrNull;

    // 如果 factory constructor redirect 到另一個 constructor，追上去
    if (constructor != null && constructor.redirectedConstructor != null) {
      constructor = constructor.redirectedConstructor;
    }

    // 如果仲係冇，搵 default constructor
    constructor ??= classElement.constructors
        .where((c) => !c.isFactory && c.name.isEmpty)
        .firstOrNull;

    if (constructor == null) {
      throw Exception('No suitable constructor found for ${classElement.name}');
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

    // Determine Firestore type
    final firestoreType = _determineFirestoreType(fieldType, element);

    // Generate custom conversion expressions
    final typeName = fieldType.getDisplayString(withNullability: false);
    String? customFromFirestoreExpression;
    String? customToFirestoreExpression;

    // **新增：檢查 @JsonConverter 先**
    final jsonConverter = _jsonConverterChecker.firstAnnotationOf(element);
    if (jsonConverter != null) {
      // 搵到 @JsonConverter，用佢嘅方法
      final converterConstantReader = ConstantReader(jsonConverter);

      // 獲取 converter 的 class name
      final converterType = jsonConverter.type;
      if (converterType != null && converterType is InterfaceType) {
        final converterClassName = converterType.element3.name3;

        // 生成 converter 表達式
        customFromFirestoreExpression =
            'const $converterClassName().fromJson(\$source)';
        customToFirestoreExpression =
            'const $converterClassName().toJson(\$source)';
      }
    } else {
      if (_hasGenericJsonSupport(fieldType)) {
        // **處理泛型 JSON 類型**
        if (fieldType is InterfaceType && fieldType.typeArguments.length >= 2) {
          // Map-like: IMap<K, V> - 需要兩個 converter
          final keyType = fieldType.typeArguments[0].getDisplayString(
            withNullability: false,
          );
          final valueType = fieldType.typeArguments[1].getDisplayString(
            withNullability: false,
          );

          final keyConverter =
              TypeAnalyzer.isPrimitiveType(fieldType.typeArguments[0])
              ? '(k) => k as $keyType'
              : '(k) => $keyType.fromJson(k)';

          final valueConverter =
              TypeAnalyzer.isPrimitiveType(fieldType.typeArguments[1])
              ? '(v) => v as $valueType'
              : '(v) => $valueType.fromJson(v)';

          customFromFirestoreExpression =
              '$typeName.fromJson(\$source, $keyConverter, $valueConverter)';
          customToFirestoreExpression = '\$source.toJson((k) => k, (v) => v)';
        } else {
          // List/Set-like: IList<T>, ISet<T> - 一個 converter
          final elementType = _getGenericElementType(fieldType);
          final elementDartType = _getElementDartType(fieldType);

          final converter = TypeAnalyzer.isPrimitiveType(elementDartType)
              ? '(e) => e as $elementType'
              : '(e) => $elementType.fromJson(e)';

          customFromFirestoreExpression =
              '$typeName.fromJson(\$source, $converter)';
          customToFirestoreExpression = '\$source.toJson((e) => e)';
        }
      } else if (_hasStandardJsonSupport(fieldType)) {
        // 標準 JSON 處理
        customFromFirestoreExpression = '$typeName.fromJson(\$source)';
        customToFirestoreExpression = '\$source.toJson()';
      }
    }

    return FieldInfo(
      parameterName: fieldName,
      jsonFieldName: jsonFieldName,
      dartType: fieldType,
      firestoreType: firestoreType,
      isDocumentId: false,
      isNullable: isNullable,
      isOptional: isOptional,
      customFromFirestoreExpression: customFromFirestoreExpression,
      customToFirestoreExpression: customToFirestoreExpression,
    );
  }

  static DartType _getElementDartType(DartType dartType) {
    if (dartType is InterfaceType && dartType.typeArguments.isNotEmpty) {
      final typeArgs = dartType.typeArguments;

      // 根據 type arguments 數量決定用邊個
      if (typeArgs.length >= 2) {
        // Map-like，用 value type
        return typeArgs[1];
      } else {
        // List/Set-like，用 element type
        return typeArgs.first;
      }
    }

    // Fallback to dynamic
    return dartType; // 或者返回某個 dynamic type
  }

  /// 檢查 type 是否支援標準 JSON serialization
  static bool _hasStandardJsonSupport(DartType dartType) {
    if (dartType is! InterfaceType) {
      return false;
    }

    final classElement = dartType.element;
    if (classElement is! ClassElement) {
      return false;
    }

    // 檢查有冇標準 toJson() 方法（無參數）
    final hasToJson = classElement.methods.any(
      (method) =>
          method.name == 'toJson' &&
          method.parameters.isEmpty &&
          !method.isStatic,
    );

    // 檢查有冇標準 fromJson constructor 或 static method（一個參數）
    final hasFromJsonConstructor = classElement.constructors.any(
      (constructor) =>
          constructor.name == 'fromJson' && constructor.parameters.length == 1,
    );

    final hasFromJsonMethod = classElement.methods.any(
      (method) =>
          method.name == 'fromJson' &&
          method.isStatic &&
          method.parameters.length == 1,
    );

    return hasToJson && (hasFromJsonConstructor || hasFromJsonMethod);
  }

  /// 檢查 type 是否支援泛型 JSON serialization
  static bool _hasGenericJsonSupport(DartType dartType) {
    if (dartType is! InterfaceType) {
      return false;
    }

    final classElement = dartType.element;
    if (classElement is! ClassElement) {
      return false;
    }

    // 檢查有冇 fromJson constructor（2個或3個參數都接受）
    final hasGenericFromJson = classElement.constructors.any(
      (constructor) =>
          constructor.name == 'fromJson' &&
          (constructor.parameters.length == 2 ||
              constructor.parameters.length == 3),
    );

    // 檢查有冇 toJson method（1個或2個參數都接受）
    final hasGenericToJson = classElement.methods.any(
      (method) =>
          method.name == 'toJson' &&
          (method.parameters.length == 1 || method.parameters.length == 2) &&
          !method.isStatic,
    );

    return hasGenericFromJson && hasGenericToJson;
  }

  /// 獲取泛型類型嘅 element type（通用方法）
  static String _getGenericElementType(DartType dartType) {
    if (dartType is InterfaceType && dartType.typeArguments.isNotEmpty) {
      final typeArgs = dartType.typeArguments;

      // 根據 type arguments 數量決定用邊個
      if (typeArgs.length == 1) {
        // List<T>, Set<T>, IList<T>, ISet<T> 等 - 用第一個
        return typeArgs.first.getDisplayString(withNullability: false);
      } else if (typeArgs.length >= 2) {
        // Map<K,V>, IMap<K,V> 等 - 用第二個 (value type)
        return typeArgs[1].getDisplayString(withNullability: false);
      }
    }
    return 'dynamic';
  }

  /// Determine the Firestore type for a Dart type
  /// Based on official Firestore supported data types, @JsonConverter annotations, and toJson/fromJson methods
  static FirestoreType _determineFirestoreType(
    DartType dartType,
    Element element,
  ) {
    // First, check for @JsonConverter annotation
    final jsonConverter = _jsonConverterChecker.firstAnnotationOf(element);
    if (jsonConverter != null) {
      // Get the JsonType from JsonConverter<DartType, JsonType>
      final converterType = jsonConverter.type;
      if (converterType != null && converterType is InterfaceType) {
        final typeArguments = converterType.typeArguments;
        if (typeArguments.length >= 2) {
          // Use the JsonType (second argument) to determine Firestore type
          return _processTypeToFirestoreType(typeArguments[1]);
        }
      }
    }

    // If no @JsonConverter, check if this is a custom object type with toJson/fromJson
    if (dartType is InterfaceType) {
      final typeName = dartType.getDisplayString(withNullability: false);

      // Skip primitive and known types
      if (!TypeAnalyzer.isPrimitiveType(dartType) &&
          !_isKnownFirestoreType(typeName)) {
        // Analyze based on what toJson would return for common immutable collection types
        // IList/ISet -> toJson returns List -> array
        if (typeName.startsWith('IList<') || typeName.startsWith('ISet<')) {
          return FirestoreType.array;
        }
        // IMap -> toJson returns Map -> map
        else if (typeName.startsWith('IMap<')) {
          return FirestoreType.map;
        }
        // Other custom objects with toJson/fromJson -> object
        else {
          return FirestoreType.object;
        }
      }
    }

    // Process the original Dart type to determine Firestore type
    return _processTypeToFirestoreType(dartType);
  }

  /// Process a Dart type to determine its Firestore type
  static FirestoreType _processTypeToFirestoreType(DartType dartType) {
    // Handle nullable types by getting the underlying type
    final actualType = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? (dartType as InterfaceType).element3.thisType
        : dartType;

    final typeName = actualType.getDisplayString(withNullability: false);

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
    if (typeName == 'Duration') {
      return FirestoreType
          .integer; // Duration converts to milliseconds (integer)
    }
    if (typeName == 'DateTime') {
      return FirestoreType
          .timestamp; // DateTime converts to Firestore Timestamp
    }

    // Handle collections
    if (actualType is InterfaceType) {
      final typeElement = actualType.element3;
      final elementName = typeElement.name3;

      if (elementName == 'List' ||
          elementName == 'Set' ||
          elementName == 'IList' ||
          elementName == 'ISet') {
        return FirestoreType.array;
      }
      if (elementName == 'Map' || elementName == 'IMap') {
        return FirestoreType.map;
      }
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

  /// Analyze a model and all its nested types recursively
  static Map<String, ModelAnalysis> analyzeModelWithNestedTypes(
    ClassElement rootClassElement,
  ) {
    final Map<String, ModelAnalysis> allAnalyses = {};
    final Set<String> processedTypes = {};

    _analyzeModelRecursively(rootClassElement, allAnalyses, processedTypes);

    return allAnalyses;
  }

  /// Recursively analyze a model and discover all nested custom types
  static void _analyzeModelRecursively(
    ClassElement classElement,
    Map<String, ModelAnalysis> allAnalyses,
    Set<String> processedTypes,
  ) {
    final typeName = classElement.name;

    // Skip if already processed
    if (processedTypes.contains(typeName)) {
      return;
    }
    processedTypes.add(typeName);

    // Analyze the current model
    final analysis = analyzeModel(classElement);
    if (analysis != null) {
      allAnalyses[typeName] = analysis;

      // Process nested types in all fields
      for (final field in analysis.fields.values) {
        _processFieldTypeForNestedModels(
          field.dartType,
          allAnalyses,
          processedTypes,
        );
      }
    }
  }

  /// Process a field type to discover nested custom model types
  static void _processFieldTypeForNestedModels(
    DartType fieldType,
    Map<String, ModelAnalysis> allAnalyses,
    Set<String> processedTypes,
  ) {
    // Handle nullable types
    final actualType = fieldType.nullabilitySuffix == NullabilitySuffix.question
        ? (fieldType as InterfaceType).element.thisType
        : fieldType;

    if (actualType is InterfaceType) {
      final element = actualType.element;

      if (TypeAnalyzer.isPrimitiveType(actualType)) {
        return; // Skip primitive types
      }

      if (element is ClassElement) {
        // If it's a custom class, analyze it recursively
        _analyzeModelRecursively(element, allAnalyses, processedTypes);
      }

      // Handle generic types (List<T>, Map<K,V>)
      for (final typeArg in actualType.typeArguments) {
        _processFieldTypeForNestedModels(typeArg, allAnalyses, processedTypes);
      }
    }
  }

  /// Get element type from List/Set type
  static String _getElementType(DartType type) {
    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      return type.typeArguments.first.getDisplayString(withNullability: false);
    }
    return 'dynamic';
  }

  /// Get value type from Map type
  static String _getMapValueType(DartType type) {
    if (type is InterfaceType && type.typeArguments.length >= 2) {
      return type.typeArguments[1].getDisplayString(withNullability: false);
    }
    return 'dynamic';
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
}
