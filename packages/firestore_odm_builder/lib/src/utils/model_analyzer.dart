import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
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
  String toString() => 'FieldInfo(param: $parameterName, json: $jsonFieldName, type: $dartType, isDocId: $isDocumentId)';
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
  FieldInfo? get documentIdField => documentIdFieldName != null 
      ? fields[documentIdFieldName]
      : null;

  @override
  String toString() => 'ModelAnalysis(class: $className, docIdField: $documentIdFieldName, fields: ${fields.length})';
}

/// Analyzer for complete model structure including JSON field mapping
class ModelAnalyzer {
  static final TypeChecker _jsonKeyChecker = TypeChecker.fromUrl('package:json_annotation/json_annotation.dart#JsonKey');

  /// Analyze a complete model class and return structured information
  static ModelAnalysis? analyzeModel(ClassElement classElement) {
    final constructor = classElement.unnamedConstructor;
    if (constructor == null) return null;

    // Analyze all fields
    final Map<String, FieldInfo> fieldsMap = {};
    
    for (final param in constructor.parameters) {
      final fieldInfo = _analyzeField(param);
      fieldsMap[param.name] = fieldInfo;
    }

    // Find document ID field using existing logic
    final documentIdFieldName = TypeAnalyzer.getDocumentIdField(constructor);

    // Mark document ID field
    if (documentIdFieldName != null && fieldsMap.containsKey(documentIdFieldName)) {
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

    return ModelAnalysis(
      className: classElement.name,
      documentIdFieldName: documentIdFieldName,
      fields: fieldsMap,
      updateableFields: updateableFields,
    );
  }

  /// Analyze a single field parameter
  static FieldInfo _analyzeField(ParameterElement param) {
    final paramName = param.name;
    final dartType = param.type;
    final isNullable = TypeAnalyzer.isNullableType(dartType);
    final isOptional = param.isOptional || param.hasDefaultValue;

    // Determine JSON field name
    String jsonFieldName = paramName; // Default to parameter name

    // Check for @JsonKey annotation
    for (final metadata in param.metadata) {
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
}