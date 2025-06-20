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
  string,           // Text string
  integer,          // 64-bit signed integer
  double,           // 64-bit double precision floating-point
  boolean,          // Boolean
  timestamp,        // Date and time
  bytes,            // Byte data
  geoPoint,         // Geographical point
  reference,        // Document reference
  
  // Complex types
  array,            // Array
  map,              // Map (embedded object)
  
  // Special values
  null_,            // Null value
  
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

  const FieldInfo({
    required this.parameterName,
    required this.jsonFieldName,
    required this.dartType,
    required this.firestoreType,
    required this.isDocumentId,
    required this.isNullable,
    required this.isOptional,
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
  static final TypeChecker _jsonConverterChecker = TypeChecker.fromRuntime(JsonConverter);

  /// Analyze a complete model class and return structured information
  static ModelAnalysis? analyzeModel(ClassElement2 classElement) {

    try {
      // Get all fields from the class and its supertypes (excluding Object)
      final fields = _getFields(classElement);

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
        );
      }

      // Get updateable fields (non-document-ID fields)
      final updateableFields = fieldsMap.values
          .where((field) => !field.isDocumentId)
          .toList();

      return ModelAnalysis(
        className: classElement.name3!,
        documentIdFieldName: documentIdFieldName,
        fields: fieldsMap,
        updateableFields: updateableFields,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all fields from the class and its supertypes (excluding Object)
  static List<(String, DartType, Element)> _getFields(
    ClassElement2 classElement,
  ) {
    final objectChecker = TypeChecker.fromRuntime(Object);
    return classElement.allSupertypes
        .where((supertype) => !objectChecker.isExactlyType(supertype))
        .expand((t) => t.element.accessors)
        .where((f) => !f.isStatic && f.isPublic && f.isGetter)
        .where((f) {
          final jsonKey = _jsonKeyChecker.firstAnnotationOf(f);
          if (jsonKey != null) {
            final jsonKeyConstantReader = ConstantReader(jsonKey);

            // Check includeFromJson (default is true if not specified)
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

            // Check includeToJson (default is true if not specified)
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
        .map((f) => (f.name, f.returnType, f))
        .toList();
  }

  /// Analyze a field from accessor element
  static FieldInfo _analyzeFieldFromAccessor(
    String fieldName,
    DartType fieldType,
    Element element,
  ) {
    final isNullable = TypeAnalyzer.isNullableType(fieldType);
    final isOptional = isNullable; // Accessors are optional if nullable

    // Determine JSON field name
    String jsonFieldName = fieldName; // Default to field name

    // Check for @JsonKey annotation
    final jsonKey = _jsonKeyChecker.firstAnnotationOf(element);
    if (jsonKey != null) {
      final jsonKeyConstantReader = ConstantReader(jsonKey);
      final nameValue = jsonKeyConstantReader.read('name').stringValue;
      if (nameValue.isNotEmpty) {
        jsonFieldName = nameValue;
      }
    }

    // Determine Firestore type, considering @JsonConverter if present
    final firestoreType = _determineFirestoreType(fieldType, element);

    return FieldInfo(
      parameterName: fieldName,
      jsonFieldName: jsonFieldName,
      dartType: fieldType,
      firestoreType: firestoreType,
      isDocumentId: false, // Will be set later if this is the document ID field
      isNullable: isNullable,
      isOptional: isOptional,
    );
  }

  /// Determine the Firestore type for a Dart type
  /// Based on official Firestore supported data types and @JsonConverter annotations
  static FirestoreType _determineFirestoreType(DartType dartType, Element element) {
    // Check for @JsonConverter annotation and get the converted type
    final jsonConverter = _jsonConverterChecker.firstAnnotationOf(element);
    DartType actualType = dartType;
    
    if (jsonConverter != null) {
      // Get the JsonType from JsonConverter<DartType, JsonType>
      final converterType = jsonConverter.type;
      if (converterType != null && converterType is InterfaceType) {
        final typeArguments = converterType.typeArguments;
        if (typeArguments.length >= 2) {
          // Use the JsonType (second argument) as the actual type
          actualType = typeArguments[1];
        }
      }
    }

    // Process the actual type (either original dartType or converted JsonType)
    return _processTypeToFirestoreType(actualType);
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
      return FirestoreType.integer; // Duration converts to milliseconds (integer)
    }
    if (typeName == 'DateTime') {
      return FirestoreType.timestamp; // DateTime converts to Firestore Timestamp
    }

    // Handle collections
    if (actualType is InterfaceType) {
      final typeElement = actualType.element3;
      final elementName = typeElement.name3;

      if (elementName == 'List' || elementName == 'Set') {
        return FirestoreType.array;
      }
      if (elementName == 'Map') {
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
    ClassElement2 rootClassElement,
  ) {
    final Map<String, ModelAnalysis> allAnalyses = {};
    final Set<String> processedTypes = {};

    _analyzeModelRecursively(rootClassElement, allAnalyses, processedTypes);

    return allAnalyses;
  }

  /// Recursively analyze a model and discover all nested custom types
  static void _analyzeModelRecursively(
    ClassElement2 classElement,
    Map<String, ModelAnalysis> allAnalyses,
    Set<String> processedTypes,
  ) {
    final typeName = classElement.name3!;

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
        ? (fieldType as InterfaceType).element3.thisType
        : fieldType;

    if (actualType is InterfaceType) {
      final element = actualType.element3;

      if (TypeAnalyzer.isPrimitiveType(actualType)) {
        return; // Skip primitive types
      }

      _analyzeModelRecursively(
        element as ClassElement2,
        allAnalyses,
        processedTypes,
      );

      // Handle generic types (List<T>, Map<K,V>)
      for (final typeArg in actualType.typeArguments) {
        _processFieldTypeForNestedModels(typeArg, allAnalyses, processedTypes);
      }
    }
  }
}
