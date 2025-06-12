import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';
import 'package:json_annotation/json_annotation.dart';
import 'type_analyzer.dart';

/// Information about a field in a model
class FieldInfo {
  final String parameterName;
  final String jsonFieldName;
  final DartType dartType;
  final bool isDocumentId;
  final bool isNullable;
  final bool isOptional;

  const FieldInfo({
    required this.parameterName,
    required this.jsonFieldName,
    required this.dartType,
    required this.isDocumentId,
    required this.isNullable,
    required this.isOptional,
  });

  @override
  String toString() =>
      'FieldInfo(param: $parameterName, json: $jsonFieldName, type: $dartType, isDocId: $isDocumentId)';
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

  /// Analyze a complete model class and return structured information
  static ModelAnalysis? analyzeModel(ClassElement2 classElement) {
    print('DEBUG: analyzeModel called for ${classElement.name3}');

    try {
      // Get all fields from the class and its supertypes (excluding Object)
      final fields = _getFields(classElement);
      print(
        'DEBUG: Found ${fields.length} fields in ${classElement.name3} (including supertypes)',
      );

      if (fields.isEmpty) {
        print('DEBUG: No fields found in ${classElement.name3}');
        return null;
      }

      // Analyze all fields
      final Map<String, FieldInfo> fieldsMap = {};
      print('DEBUG: Starting field analysis loop');

      for (final (fieldName, fieldType, element) in fields) {
        print('DEBUG: Analyzing field $fieldName of type $fieldType');
        final fieldInfo = _analyzeFieldFromAccessor(
          fieldName,
          fieldType,
          element,
        );
        fieldsMap[fieldName] = fieldInfo;
      }

      print(
        'DEBUG: Analyzed ${fieldsMap.length} fields, looking for document ID field',
      );

      // Find document ID field using logic
      final documentIdFieldName = _getDocumentIdFieldFromAccessors(fields);
      print('DEBUG: Document ID field: $documentIdFieldName');

      // Mark document ID field
      if (documentIdFieldName != null &&
          fieldsMap.containsKey(documentIdFieldName)) {
        final existingField = fieldsMap[documentIdFieldName]!;
        fieldsMap[documentIdFieldName] = FieldInfo(
          parameterName: existingField.parameterName,
          jsonFieldName: existingField.jsonFieldName,
          dartType: existingField.dartType,
          isDocumentId: true,
          isNullable: existingField.isNullable,
          isOptional: existingField.isOptional,
        );
      }

      // Get updateable fields (non-document-ID fields)
      final updateableFields = fieldsMap.values
          .where((field) => !field.isDocumentId)
          .toList();

      print(
        'DEBUG: Creating ModelAnalysis for ${classElement.name3} with ${fieldsMap.length} fields',
      );

      return ModelAnalysis(
        className: classElement.name3!,
        documentIdFieldName: documentIdFieldName,
        fields: fieldsMap,
        updateableFields: updateableFields,
      );
    } catch (e, stackTrace) {
      print('DEBUG: Exception analyzing ${classElement.name3}: $e');
      print('DEBUG: Stack trace: $stackTrace');
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

    return FieldInfo(
      parameterName: fieldName,
      jsonFieldName: jsonFieldName,
      dartType: fieldType,
      isDocumentId: false, // Will be set later if this is the document ID field
      isNullable: isNullable,
      isOptional: isOptional,
    );
  }

  /// Find the document ID field from accessors
  static String? _getDocumentIdFieldFromAccessors(
    List<(String, DartType, Element)> fields,
  ) {
    // First pass: Look for explicit @DocumentIdField() annotation
    for (final (fieldName, fieldType, element) in fields) {
      final documentIdAnnotation = TypeAnalyzer.documentIdChecker
          .firstAnnotationOf(element);
      if (documentIdAnnotation != null) {
        return fieldName;
      }
    }

    // Second pass: Look for a field named 'id' as default
    for (final (fieldName, fieldType, element) in fields) {
      if (fieldName == 'id' && TypeAnalyzer.isStringType(fieldType)) {
        return fieldName;
      }
    }

    return null;
  }

  /// Analyze a single property field
  static FieldInfo _analyzeProperty(FieldElement2 field) {
    final fieldName = field.name3!;
    final dartType = field.type;
    final isNullable = TypeAnalyzer.isNullableType(dartType);
    final isOptional = isNullable; // Properties are optional if nullable

    // Determine JSON field name
    String jsonFieldName = fieldName; // Default to field name

    // Check for @JsonKey annotation
    for (final metadata in field.metadata2.annotations) {
      final metadataValue = metadata.computeConstantValue();
      if (metadataValue != null &&
          metadataValue.type != null &&
          _jsonKeyChecker.isExactlyType(metadataValue.type!)) {
        // Extract 'name' field from @JsonKey annotation
        final nameField = metadataValue.getField('name');
        if (nameField != null && !nameField.isNull) {
          final nameValue = nameField.toStringValue();
          if (nameValue != null && nameValue.isNotEmpty) {
            jsonFieldName = nameValue;
          }
        }
        break;
      }
    }

    return FieldInfo(
      parameterName: fieldName,
      jsonFieldName: jsonFieldName,
      dartType: dartType,
      isDocumentId: false, // Will be set later if this is the document ID field
      isNullable: isNullable,
      isOptional: isOptional,
    );
  }

  /// Find the document ID field from properties
  static String? _getDocumentIdFieldFromProperties(List<FieldElement2> fields) {
    // First pass: Look for explicit @DocumentIdField() annotation
    for (final field in fields) {
      for (final metadata in field.metadata2.annotations) {
        final metadataValue = metadata.computeConstantValue();
        if (metadataValue != null &&
            metadataValue.type != null &&
            TypeAnalyzer.documentIdChecker.isExactlyType(metadataValue.type!)) {
          return field.name3!;
        }
      }
    }

    // Second pass: Look for a field named 'id' as default
    for (final field in fields) {
      if (field.name3 == 'id' && TypeAnalyzer.isStringType(field.type)) {
        return field.name3!;
      }
    }

    return null;
  }

  /// Analyze a single field parameter (legacy method for constructor-based analysis)
  static FieldInfo _analyzeField(FormalParameterElement param) {
    final paramName = param.name3!;
    final dartType = param.type;
    final isNullable = TypeAnalyzer.isNullableType(dartType);
    final isOptional = param.isOptional || param.hasDefaultValue;

    // Determine JSON field name
    String jsonFieldName = paramName; // Default to parameter name

    // Check for @JsonKey annotation
    for (final metadata in param.metadata2.annotations) {
      final metadataValue = metadata.computeConstantValue();
      if (metadataValue != null &&
          metadataValue.type != null &&
          _jsonKeyChecker.isExactlyType(metadataValue.type!)) {
        // Extract 'name' field from @JsonKey annotation
        final nameField = metadataValue.getField('name');
        if (nameField != null && !nameField.isNull) {
          final nameValue = nameField.toStringValue();
          if (nameValue != null && nameValue.isNotEmpty) {
            jsonFieldName = nameValue;
          }
        }
        break;
      }
    }

    return FieldInfo(
      parameterName: paramName,
      jsonFieldName: jsonFieldName,
      dartType: dartType,
      isDocumentId: false, // Will be set later if this is the document ID field
      isNullable: isNullable,
      isOptional: isOptional,
    );
  }

  /// Analyze a model and all its nested types recursively
  static Map<String, ModelAnalysis> analyzeModelWithNestedTypes(
    ClassElement2 rootClassElement,
  ) {
    final Map<String, ModelAnalysis> allAnalyses = {};
    final Set<String> processedTypes = {};

    print('DEBUG: Starting nested analysis for ${rootClassElement.name3}');
    _analyzeModelRecursively(rootClassElement, allAnalyses, processedTypes);
    print(
      'DEBUG: Finished nested analysis. Found ${allAnalyses.length} types: ${allAnalyses.keys.join(', ')}',
    );

    return allAnalyses;
  }

  /// Recursively analyze a model and discover all nested custom types
  static void _analyzeModelRecursively(
    ClassElement2 classElement,
    Map<String, ModelAnalysis> allAnalyses,
    Set<String> processedTypes,
  ) {
    final typeName = classElement.name3!;
    print('DEBUG: Analyzing model: $typeName');

    // Skip if already processed
    if (processedTypes.contains(typeName)) {
      print('DEBUG: Skipping already processed: $typeName');
      return;
    }
    processedTypes.add(typeName);

    // Analyze the current model
    final analysis = analyzeModel(classElement);
    if (analysis != null) {
      print(
        'DEBUG: Successfully analyzed $typeName with ${analysis.fields.length} fields',
      );
      allAnalyses[typeName] = analysis;

      // Process nested types in all fields
      for (final field in analysis.fields.values) {
        print(
          'DEBUG: Processing field ${field.parameterName} of type ${field.dartType}',
        );
        _processFieldTypeForNestedModels(
          field.dartType,
          allAnalyses,
          processedTypes,
        );
      }
    } else {
      print('DEBUG: Failed to analyze: $typeName');
    }
  }

  /// Process a field type to discover nested custom model types
  static void _processFieldTypeForNestedModels(
    DartType fieldType,
    Map<String, ModelAnalysis> allAnalyses,
    Set<String> processedTypes,
  ) {
    print(
      'DEBUG: _processFieldTypeForNestedModels called with: ${fieldType.getDisplayString()}',
    );

    // Handle nullable types
    final actualType = fieldType.nullabilitySuffix == NullabilitySuffix.question
        ? (fieldType as InterfaceType).element3.thisType
        : fieldType;

    print(
      'DEBUG: Actual type after nullable handling: ${actualType.getDisplayString()}',
    );

    if (actualType is InterfaceType) {
      final element = actualType.element3;
      print('DEBUG: Found InterfaceType element: ${element.name3}');

      if (TypeAnalyzer.isPrimitiveType(actualType)) {
        print(
          'DEBUG: Skipping primitive type: ${actualType.getDisplayString()}',
        );
        return; // Skip primitive types
      }

      print('DEBUG: Processing custom class recursively: ${element.name3}');
      _analyzeModelRecursively(
        element as ClassElement2,
        allAnalyses,
        processedTypes,
      );

      // Handle generic types (List<T>, Map<K,V>)
      for (final typeArg in actualType.typeArguments) {
        print('DEBUG: Processing type argument: ${typeArg.getDisplayString()}');
        _processFieldTypeForNestedModels(typeArg, allAnalyses, processedTypes);
      }
    } else {
      print('DEBUG: Not an InterfaceType: ${actualType.runtimeType}');
    }
  }
}
