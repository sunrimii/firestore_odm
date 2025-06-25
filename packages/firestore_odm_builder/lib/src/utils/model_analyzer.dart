import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_builder/code_builder.dart';
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
}

class GenericTypeConverter implements TypeConverter {
  final Reference typeParameter;
  const GenericTypeConverter(this.typeParameter);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return sourceExpression;
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return sourceExpression;
  }
}

class CustomConverter implements TypeConverter {
  final InterfaceElement element;
  final Map<Reference, TypeConverter> typeParameterConverters;

  const CustomConverter(
    this.element, [
    this.typeParameterConverters = const {},
  ]);

  TypeConverter _refine(TypeConverter converter) {
    if (converter is GenericTypeConverter) {
      if (typeParameterConverters.containsKey(converter.typeParameter)) {
        return typeParameterConverters[converter.typeParameter]!;
      } else {
        // throw Warning if no specific converter found
        print(
          'Warning: No specific converter found for type parameter ${converter.typeParameter}. Using generic converter.',
        );
        return converter; // Return as-is if no specific converter found
      }
    }
    return converter; // Return as-is if no refinement needed
  }

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final analysis = ModelAnalyzer.analyzeModel(element.thisType, element);
    return element.reference.newInstance(
      [],
      Map.fromEntries(
        analysis.fields.values.map(
          (field) => MapEntry(
            field.parameterName,
            _refine(field.converter).generateFromFirestore(
              sourceExpression.index(literalString(field.jsonFieldName)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    // to map
    return literalMap(
      Map.fromEntries(
        ModelAnalyzer.analyzeModel(element.thisType, element).fields.values.map(
          (field) => MapEntry(
            field.jsonFieldName,
            _refine(field.converter).generateToFirestore(
              sourceExpression.property(field.parameterName),
            ),
          ),
        ),
      ),
    );
  }
}

/// Converter using a specific converter class (handles both generic and non-generic)
class ConverterClassConverter implements TypeConverter {
  final Expression instance;

  const ConverterClassConverter(this.instance);

  ConverterClassConverter.fromClassName(
    String converterClassName, [
    List<TypeConverter> parameterConverters = const [],
  ]) : this(
         refer(converterClassName).call(
           parameterConverters
               .map((converter) => _convertToExpression(converter))
               .toList(),
         ),
       );

  @override
  Expression generateFromFirestore(Expression sourceExpression) =>
      instance.property('fromFirestore').call([sourceExpression]);

  @override
  Expression generateToFirestore(Expression sourceExpression) =>
      instance.property('toFirestore').call([sourceExpression]);

  static Expression _convertToExpression(TypeConverter converter) {
    if (converter is ConverterClassConverter) {
      return converter.instance;
    }
    return refer('${converter.runtimeType}').call([]);
  }
}

class BuiltInConverter extends ConverterClassConverter {
  const BuiltInConverter(super.instance);

  BuiltInConverter.fromClassName(
    String converterClassName, [
    List<TypeConverter> parameterConverters = const [],
  ]) : super.fromClassName(converterClassName, parameterConverters);
}

/// Converter for generic types with element converters
class JsonConverter implements TypeConverter {
  final TypeReference dartType;
  final List<TypeConverter> elementConverters;
  final String? customFromJsonMethod;
  final String? customToJsonMethod;
  final TypeReference? toType;

  const JsonConverter(
    this.dartType,
    this.elementConverters, {
    this.customFromJsonMethod,
    this.customToJsonMethod,
    this.toType,
  });

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final fromJsonMethod = customFromJsonMethod ?? 'fromJson';
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateFromFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return dartType.property(fromJsonMethod).call([
      sourceExpression,
      ...converterLambdas,
    ]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    final toJsonMethod = customToJsonMethod ?? 'toJson';
    if (elementConverters.isEmpty) {
      return sourceExpression.property(toJsonMethod).call([]);
    }
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateToFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return sourceExpression.property(toJsonMethod).call(converterLambdas);
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
  Expression generateToFirestore(Expression sourceExpression) {
    return innerConverter.generateToFirestore(sourceExpression);
  }
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
  final String documentIdField;
  final Map<String, FieldInfo> fields;
  final List<FieldInfo> updateableFields;
  final DartType dartType;
  final FirestoreType firestoreType;
  final TypeConverter converter;

  const ModelAnalysis({
    required this.className,
    required this.documentIdField,
    required this.fields,
    required this.updateableFields,
    required this.dartType,
    required this.firestoreType,
    required this.converter,
  });

  /// Get field by parameter name
  FieldInfo? getFieldByParam(String paramName) => fields[paramName];

  bool get isGeneric =>
      dartType is InterfaceType &&
      (dartType as InterfaceType).typeArguments.isNotEmpty;

  List<Reference> get typeParameters => isGeneric
      ? (dartType as InterfaceType).element3.typeParameters2
            .map((e) => refer(e.name3!))
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

  static final TypeChecker _durationChecker = TypeChecker.fromRuntime(Duration);

  static final TypeChecker _dateTimeChecker = TypeChecker.fromRuntime(DateTime);

  static final Map<DartType, ModelAnalysis> _analyzed = {};

  /// Analyze a complete model class and return structured information
  static ModelAnalysis analyzeModel(DartType type, [Element? element]) {
    final className = type.name!;
    if (_analyzed.containsKey(type)) {
      return _analyzed[type]!;
    }

    // Ensure we use the correct ClassElement for user-defined InterfaceTypes
    Element? correctElement = element;
    if (type is InterfaceType &&
        type.element is ClassElement &&
        !type.element.library.isInSdk &&
        !_isBuiltInType(className)) {
      correctElement = type.element;
    }

    final result = _analyzeModelInternal(type, correctElement);
    _analyzed[type] = result;
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
      firestoreType: _processTypeToFirestoreType(type),
      converter: _createConverter(type, type.element),
    );
  }

  static AnalysisResult analyzeModels(Iterable<DartType> types) {
    // First analyze all root types
    for (final type in types) {
      analyzeModel(type, type.element);
    }

    // Then analyze all nested types recursively
    _analyzeNestedTypes();

    return AnalysisResult(modelAnalyses: _analyzed);
  }

  /// Analyze all nested types from already analyzed models
  static void _analyzeNestedTypes() {
    final analyzedNames = _analyzed.keys.toSet();

    for (final analysis in _analyzed.values.toList()) {
      _discoverNestedTypes(analysis, analyzedNames);
    }
  }

  /// Discover and analyze nested types in a model's fields
  static void _discoverNestedTypes(
    ModelAnalysis analysis,
    Set<DartType> processedTypes,
  ) {
    for (final field in analysis.fields.values) {
      _analyzeFieldType(field.dartType, processedTypes);
    }
  }

  /// Analyze a field type and its nested types recursively
  static void _analyzeFieldType(DartType type, Set<DartType> processedTypes) {
    // Handle interface types (classes)
    if (type is InterfaceType) {
      final element = type.element;
      final typeName = element.name;

      // Skip if already processed or is a built-in type
      if (processedTypes.contains(typeName) || _isBuiltInType(typeName)) {
        return;
      }

      // Only analyze ClassElements that are user-defined types
      if (element is ClassElement && !element.library.isInSdk) {
        // Ensure we don't have a cached analysis with wrong element
        _analyzed.remove(typeName);

        // Analyze this nested type with the correct ClassElement
        final nestedAnalysis = analyzeModel(type, element);
        processedTypes.add(type);

        // Recursively analyze fields of this nested type
        _discoverNestedTypes(nestedAnalysis, processedTypes);
      }

      // Also analyze type arguments for generic types
      for (final typeArg in type.typeArguments) {
        _analyzeFieldType(typeArg, processedTypes);
      }
    }
  }

  /// Check if a type is a built-in Dart/Flutter type that we should skip
  static bool _isBuiltInType(String typeName) {
    const builtInTypes = {
      'String', 'int', 'double', 'bool', 'DateTime', 'Duration',
      'List', 'Set', 'Map', 'Iterable', 'Future', 'Stream',
      'IList', 'ISet', 'IMap', // Fast immutable collections
      'Timestamp', 'GeoPoint', 'DocumentReference', // Firestore types
    };
    return builtInTypes.contains(typeName);
  }

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
        final toType = [dartType , ...dartType.allSupertypes]
            .map((x) => x.getMethod2('toJson'))
            .where((m) => m != null)
            .firstOrNull
            ?.returnType
            .reference;
        return JsonConverter(dartType.reference, typeParams, toType: toType);
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
        dartType.isDartCoreBool ||
        // or dynamic
        dartType.getDisplayString() == 'dynamic') {
      return BuiltInConverter.fromClassName('PrimitiveConverter');
    }

    if (_durationChecker.isExactlyType(dartType)) {
      return BuiltInConverter.fromClassName('DurationConverter');
    }

    if (_dateTimeChecker.isExactlyType(dartType)) {
      return BuiltInConverter.fromClassName('DateTimeConverter');
    }

    if (dartType is InterfaceType) {
      return CustomConverter(dartType.element);
    }

    if (dartType is TypeParameterType) {
      // Handle generic types like IList<T>, IMap<K, V>
      return GenericTypeConverter(dartType.reference);
    }

    throw ArgumentError(
      'Unsupported Dart type for conversion: ${dartType.getDisplayString(withNullability: true)}',
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
