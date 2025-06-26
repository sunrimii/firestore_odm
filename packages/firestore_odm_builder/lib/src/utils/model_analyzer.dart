import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_builder/src/generators/converter_service.dart';
import 'package:firestore_odm_builder/src/utils/converters/type_converter.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';
import 'package:firestore_odm_builder/src/utils/type_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:json_annotation/json_annotation.dart';

/// Information about a field in a model
class FieldInfo {
  final String parameterName;
  final String jsonFieldName;
  final Element element;
  final DartType dartType;
  final bool isDocumentId;
  final bool isOptional;

  final ModelAnalysis typeAnalysis;

  const FieldInfo({
    required this.parameterName,
    required this.jsonFieldName,
    required this.element,
    required this.dartType,
    required this.isDocumentId,
    required this.isOptional,
    required this.typeAnalysis,
  });

  /// Get Firestore type from type analysis
  TypeReference get firestoreType => typeAnalysis.firestoreType;

  /// Get converter from type analysis
  // TypeConverter get converter => typeAnalysis.converter;
}

/// Complete analysis of a model class
class ModelAnalysis {
  final String className;
  final String documentIdField;
  final Map<String, FieldInfo> fields;
  final List<FieldInfo> updateableFields;
  final DartType dartType;
  final TypeReference firestoreType;
  // final TypeConverter converter;

  const ModelAnalysis({
    required this.className,
    required this.documentIdField,
    required this.fields,
    required this.updateableFields,
    required this.dartType,
    required this.firestoreType,
    // required this.converter,
  });

  /// Get field by parameter name
  FieldInfo? getFieldByParam(String paramName) => fields[paramName];

  bool get isGeneric =>
      dartType is InterfaceType &&
      (dartType as InterfaceType).typeArguments.isNotEmpty;

  List<TypeReference> get typeParameters => isGeneric
      ? (dartType as InterfaceType).element3.typeParameters2
            .map((e) => e.reference)
            .toList()
      : [];
}

/// Combined result of model and type analysis
class AnalysisResult {
  final Map<DartType, ModelAnalysis> modelAnalyses;

  const AnalysisResult({required this.modelAnalyses});
}

/// Analyzer for complete model structure including JSON field mapping
class ModelAnalyzer {
  static final TypeChecker _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
  static final TypeChecker _jsonConverterChecker = TypeChecker.fromRuntime(
    JsonConverter,
  );

  static final Map<(DartType, Element?), ModelAnalysis> _cached = {};

  /// Analyze a complete model class and return structured information
  static ModelAnalysis analyze(DartType type, [Element? annotatedElement]) {
    final key = (type, annotatedElement);
    if (_cached.containsKey(key)) {
      return _cached[key]!;
    }

    final result = _analyze(type, annotatedElement);
    _cached[key] = result;
    return result;
  }

  /// Internal method for analyzing a model with a given registry
  static ModelAnalysis _analyze(DartType type, [Element? annotatedElement]) {
    // Get all fields from the class and its supertypes (excluding Object)
    final typeElement = type.element;
    final fields = typeElement is ClassElement
        ? _getConstructorParameters(typeElement)
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
        element: existingField.element,
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
      documentIdField:
          documentIdFieldName ?? 'id', // Default to 'id' if not found
      fields: fieldsMap,
      updateableFields: updateableFields,
      dartType: type,
      firestoreType: _getFirestoreType(type),
      // converter: _getConverter(type, annotatedElement),
    );
  }

  // static TypeConverter _getConverter(
  //   DartType dartType,
  //   Element? annotatedElement,
  // ) {
  //   // Check for custom JsonConverter annotations first (like @ListLengthConverter())
  //   if (annotatedElement != null) {
  //     // Look for any annotation that implements JsonConverter
  //     final customConverter = _findCustomJsonConverter(annotatedElement);
  //     if (customConverter != null) {
  //       print('Found JsonConverter annotation: ${customConverter}');
  //       return AnnotationConverter(
  //         reference: customConverter.reference,
  //         fromType: customConverter.getMethod('fromJson')!.returnType.reference,
  //         toType: customConverter.getMethod('toJson')!.returnType.reference,
  //       );
  //     }

  //     // Check for standard @JsonConverter annotation
  //     final jsonConverter = _jsonConverterChecker.firstAnnotationOf(
  //       annotatedElement,
  //     );
  //     if (jsonConverter != null) {
  //       print('Found JsonConverter annotation: ${jsonConverter.type}');
  //       final converterType = jsonConverter.type;
  //       if (converterType != null && converterType is InterfaceType) {
  //         return AnnotationConverter(
  //           reference: converterType.element3.reference,
  //           fromType: converterType.element3
  //               .getMethod2('fromJson')!
  //               .returnType
  //               .reference,
  //           toType: converterType.element3
  //               .getMethod2('toJson')!
  //               .returnType
  //               .reference,
  //         );
  //       }
  //     }
  //   }

  //   // Check for generic JsonConverter support
  //   if (dartType is InterfaceType && _hasJsonSupport(dartType)) {
  //     final converterService = converterServiceSignal.get();
  //     final typeParams = dartType.typeArguments.map((t) {
  //       final analysis = analyze(t, t.element);
  //       return converterService.get(analysis);
  //     }).toList();
  //     final toType = [dartType, ...dartType.allSupertypes]
  //         .map((x) => x.getMethod2('toJson'))
  //         .where((m) => m != null)
  //         .firstOrNull!
  //         .returnType
  //         .reference;
  //     return JsonConverterConverter(
  //       elementConverters: typeParams,
  //       fromType: dartType.reference,
  //       toType: toType,
  //     );
  //   }

  //   return _createDefaultConverter(dartType);
  // }

  /// Find custom JsonConverter annotation (like @ListLengthConverter())
  static InterfaceElement? _findCustomJsonConverter(Element element) {
    for (final annotation in element.metadata) {
      final annotationType = annotation.computeConstantValue()?.type;
      if (annotationType is InterfaceType) {
        final classElement = annotationType.element;

        // Check if this class implements JsonConverter interface
        if (_implementsJsonConverter(classElement)) {
          return classElement;
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

  // /// Create default converter based on type and firestore type
  // static TypeConverter _createDefaultConverter(DartType dartType) {
  //   final converterService = converterServiceSignal.get();
  //   // built-in converters
  //   if (dartType.isDartCoreString ||
  //       dartType.isDartCoreInt ||
  //       dartType.isDartCoreDouble ||
  //       dartType.isDartCoreBool ||
  //       dartType.isDartCoreNull ||
  //       // or dynamic
  //       dartType.getDisplayString() == 'dynamic') {
  //     return DefaultConverter(
  //       reference: TypeReference(
  //         (b) => b
  //           ..symbol = 'PrimitiveConverter'
  //           ..types.add(dartType.reference),
  //       ).call([]),
  //       elementConverters: [],
  //       fromType: dartType.reference,
  //       toType: dartType.reference,
  //     );
  //   }

  //   if (dartType.isDartCoreList || dartType.isDartCoreSet) {
  //     final typeArguments = switch (dartType) {
  //       InterfaceType type => type.typeArguments,
  //       _ => <DartType>[],
  //     };
  //     final parameterConverters = [
  //       for (var t in typeArguments)
  //         converterService.get(ModelAnalyzer.analyze(t)),
  //     ];

  //     return DefaultConverter(
  //       reference: TypeReference(
  //         (b) => b
  //           ..symbol = dartType.isDartCoreList
  //               ? 'ListConverter'
  //               : 'SetConverter',
  //       ).call(parameterConverters.map((e) => e.reference)),
  //       elementConverters:  parameterConverters,
  //       fromType: dartType.reference,
  //       toType: TypeReferences.listOf(TypeReferences.dynamic),
  //     );
  //   }

  //   if (dartType.isDartCoreMap) {
  //     final typeArguments = switch (dartType) {
  //       InterfaceType type => type.typeArguments,
  //       _ => <DartType>[],
  //     };
  //     final parameterConverters = [
  //       for (var t in typeArguments)
  //         converterService.get(ModelAnalyzer.analyze(t)),
  //     ];

  //     return DefaultConverter(
  //       reference: TypeReference((b) => b..symbol = 'MapConverter')
  //       .call(
  //         parameterConverters.map((e) => e.reference),
  //       ),
  //       elementConverters: parameterConverters,
  //       fromType: TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic),
  //       toType: TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic),
  //     );
  //   }

  //   if (TypeAnalyzer.isDateTimeType(dartType)) {
  //     return DefaultConverter.fromClassName(
  //       name: 'DateTimeConverter',
  //       fromType: TypeReferences.dateTime,
  //       toType: TypeReferences.timestamp,
  //     );
  //   }

  //   if (TypeAnalyzer.isDurationType(dartType)) {
  //     return DefaultConverter.fromClassName(
  //       name: 'DurationConverter',
  //       fromType: TypeReferences.duration,
  //       toType: TypeReferences.int,
  //     );
  //   }

  //   if (dartType is InterfaceType) {
  //     return CustomConverter(
  //       element: dartType.element,
  //       fromType: dartType.reference,
  //     );
  //   }

  //   if (dartType is TypeParameterType) {
  //     // Handle generic types like IList<T>, IMap<K, V>
  //     return GenericTypeConverter(
  //       fromType: dartType.reference,
  //     );
  //   }

  //   throw ArgumentError(
  //     'Unsupported Dart type for Firestore conversion: ${dartType.getDisplayString(withNullability: false)}',
  //   );
  // }

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
      return [];
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
      element: element,
      dartType: fieldType,
      isOptional: isOptional,
      typeAnalysis: analyze(fieldType, element),
    );
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

  static TypeReference _getFirestoreType(DartType dartType) {
    if (dartType.isDartCoreString) {
      return TypeReferences.string;
    }

    if (dartType.isDartCoreInt) {
      return TypeReferences.int;
    }

    if (dartType.isDartCoreDouble) {
      return TypeReferences.double;
    }

    if (dartType.isDartCoreBool) {
      return TypeReferences.bool;
    }

    if (TypeChecker.fromRuntime(DateTime).isAssignableFromType(dartType)) {
      return TypeReferences.timestamp;
    }

    if (TypeChecker.fromRuntime(Duration).isAssignableFromType(dartType)) {
      return TypeReferences.int;
    }

    if (dartType.isDartCoreList ||
        dartType.isDartCoreSet ||
        TypeChecker.fromRuntime(IList).isAssignableFromType(dartType) ||
        TypeChecker.fromRuntime(ISet).isAssignableFromType(dartType)) {
      return TypeReferences.listOf(TypeReferences.dynamic);
    }

    if (dartType.isDartCoreObject ||
        dartType.isDartCoreMap ||
        dartType is InterfaceType ||
        TypeChecker.fromRuntime(IMap).isAssignableFromType(dartType)) {
      return TypeReferences.mapOf(
        TypeReferences.string,
        TypeReferences.dynamic,
      );
    }

    return TypeReferences.dynamic;
  }
}

