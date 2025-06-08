import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

class FirestoreGenerator extends GeneratorForAnnotation<CollectionPath> {
  const FirestoreGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'CollectionPath can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final collectionPath = annotation.read('path').stringValue;
    final constructor = element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'Class must have an unnamed constructor.',
        element: element,
      );
    }

    final buffer = StringBuffer();
    final subcollectionChecker = TypeChecker.fromRuntime(SubcollectionPath);
    final documentIdChecker = TypeChecker.fromRuntime(DocumentIdField);

    // Find document ID field
    String? documentIdField;
    for (final param in constructor.parameters) {
      // Check parameter metadata directly
      for (final metadata in param.metadata) {
        final metadataValue = metadata.computeConstantValue();
        if (metadataValue != null &&
            metadataValue.type != null &&
            documentIdChecker.isExactlyType(metadataValue.type!)) {
          documentIdField = param.name;
          break;
        }
      }
      if (documentIdField != null) break;
    }

    // Generate Collection class
    _generateCollectionClass(buffer, className, collectionPath, constructor, documentIdField);
    buffer.writeln('');

    // Generate Document class
    _generateDocumentClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate Query class
    _generateQueryClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate FilterBuilder class
    _generateFilterBuilderClass(buffer, className, constructor, className, documentIdField);
    
    // Generate FilterBuilder classes for all nested types
    _generateNestedFilterBuilderClasses(buffer, constructor, <String>{}, className);

    // Generate OrderByBuilder class
    _generateOrderByBuilderClass(buffer, className, constructor, className, documentIdField);
    
    // Generate OrderByBuilder classes for all nested types
    _generateNestedOrderByBuilderClasses(buffer, constructor, <String>{}, className);

    // Generate base update classes first
    _generateBaseUpdateClasses(buffer);

    // Generate UpdateBuilder class and all nested types
    _generateUpdateBuilderClass(buffer, className, constructor, className);
    _generateNestedUpdateBuilderClasses(buffer, constructor, <String>{className}, className);

    // Generate Filter class
    _generateFilterClass(buffer, className);
    buffer.writeln('');

    // Generate Query Extension (for new where API)
    _generateQueryExtension(buffer, className, constructor);
    buffer.writeln('');

    // Generate extension to add the collection to FirestoreODM
    _generateODMExtension(buffer, className, collectionPath);

    return buffer.toString();
  }

  void _generateNestedFilterBuilderClasses(StringBuffer buffer, ConstructorElement constructor, Set<String> processedTypes, String rootFilterType) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;
      
      if (_isCustomClass(fieldType)) {
        final element = fieldType.element;
        if (element is ClassElement) {
          final typeName = element.name;
          
          // Avoid processing the same type multiple times
          if (processedTypes.contains(typeName)) continue;
          processedTypes.add(typeName);
          
          final nestedConstructor = element.unnamedConstructor;
          if (nestedConstructor != null) {
            buffer.writeln('');
            _generateFilterBuilderClass(buffer, typeName, nestedConstructor, rootFilterType, null);
            
            // Recursively generate for deeply nested types
            _generateNestedFilterBuilderClasses(buffer, nestedConstructor, processedTypes, rootFilterType);
          }
        }
      }
    }
  }

  void _generateCollectionClass(StringBuffer buffer, String className, String collectionPath, ConstructorElement constructor, String? documentIdField) {
    buffer.writeln('/// Generated Collection for $className');
    buffer.writeln('class ${className}Collection extends FirestoreCollection<$className> {');
    buffer.writeln('  ${className}Collection(FirebaseFirestore firestore) : super(');
    buffer.writeln('    ref: firestore.collection(\'$collectionPath\'),');
    
    if (documentIdField != null) {
      buffer.writeln('    fromJson: (data, [documentId]) {');
      buffer.writeln('      // Add document ID to data for ${documentIdField} field');
      buffer.writeln('      final dataWithId = Map<String, dynamic>.from(data);');
      buffer.writeln('      if (documentId != null) dataWithId[\'$documentIdField\'] = documentId;');
      buffer.writeln('      return $className.fromJson(dataWithId);');
      buffer.writeln('    },');
      buffer.writeln('    toJson: (value) {');
      buffer.writeln('      // Remove document ID field from JSON as it\'s virtual');
      buffer.writeln('      final json = value.toJson();');
      buffer.writeln('      json.remove(\'$documentIdField\');');
      buffer.writeln('      return json;');
      buffer.writeln('    },');
    } else {
      buffer.writeln('    fromJson: (data, [documentId]) {');
      buffer.writeln('      // Add document ID to data for backward compatibility');
      buffer.writeln('      final dataWithId = Map<String, dynamic>.from(data);');
      buffer.writeln('      if (documentId != null) dataWithId[\'id\'] = documentId;');
      buffer.writeln('      return $className.fromJson(dataWithId);');
      buffer.writeln('    },');
      buffer.writeln('    toJson: (value) => value.toJson(),');
    }
    
    buffer.writeln('  );');
    buffer.writeln('');
    
    // Add upsert method if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Upsert a document using the $documentIdField field as document ID');
      buffer.writeln('  Future<void> upsert($className value) async {');
      buffer.writeln('    final json = value.toJson();');
      buffer.writeln('    final documentId = json[\'$documentIdField\'] as String?;');
      buffer.writeln('    if (documentId == null || documentId.isEmpty) {');
      buffer.writeln('      throw ArgumentError(\'Document ID field \\\'$documentIdField\\\' must not be null or empty for upsert operation\');');
      buffer.writeln('    }');
      buffer.writeln('    // Remove document ID from data since it\'s the document ID');
      buffer.writeln('    json.remove(\'$documentIdField\');');
      buffer.writeln('    await ref.doc(documentId).set(json, SetOptions(merge: true));');
      buffer.writeln('  }');
      buffer.writeln('');
    }
    
    buffer.writeln('  /// Filter using a Filter Builder');
    buffer.writeln('  ${className}Query where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(ref, builtFilter);');
    buffer.writeln('    return ${className}Query(this, newQuery);');
    buffer.writeln('  }');
    buffer.writeln('');
    
    // Generate new orderBy method using OrderByBuilder
    buffer.writeln('  /// Order using an OrderBy Builder');
    buffer.writeln('  ${className}Query orderBy(OrderByField Function(${className}OrderByBuilder order) orderBuilder) {');
    buffer.writeln('    final builder = ${className}OrderByBuilder();');
    buffer.writeln('    final orderField = orderBuilder(builder);');
    buffer.writeln('    return ${className}Query(this, ref.orderBy(orderField.field, descending: orderField.descending));');
    buffer.writeln('  }');


    buffer.writeln('}');
  }

  void _generateDocumentClass(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Generated extension for $className Document');
    buffer.writeln('extension ${className}DocumentExtension on FirestoreDocument<$className> {');
    
    // Array-style update method (primary API)
    buffer.writeln('  /// Update using array-style update operations');
    buffer.writeln('  Future<void> update(List<UpdateOperation> Function(${className}UpdateBuilder update) updateBuilder) async {');
    buffer.writeln('    final builder = ${className}UpdateBuilder();');
    buffer.writeln('    final operations = updateBuilder(builder);');
    buffer.writeln('    final updateMap = UpdateBuilder.operationsToMap(operations);');
    buffer.writeln('    if (updateMap.isNotEmpty) {');
    buffer.writeln('      await updateFields(updateMap);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('');
    
    buffer.writeln('}');
  }

  void _generateQueryClass(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Generated Query for $className');
    buffer.writeln('class ${className}Query extends FirestoreQuery<$className> {');
    buffer.writeln('  final FirestoreCollection<$className> collection;');
    buffer.writeln('');
    buffer.writeln('  ${className}Query(this.collection, Query<Map<String, dynamic>> query) : super(query, collection.fromJson, collection.toJson);');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  FirestoreQuery<$className> newInstance(Query<Map<String, dynamic>> query) => ${className}Query(collection, query);');
    buffer.writeln('');
    
    // Generate new orderBy method using OrderByBuilder
    buffer.writeln('  /// Order using an OrderBy Builder');
    buffer.writeln('  ${className}Query orderBy(OrderByField Function(${className}OrderByBuilder order) orderBuilder) {');
    buffer.writeln('    final builder = ${className}OrderByBuilder();');
    buffer.writeln('    final orderField = orderBuilder(builder);');
    buffer.writeln('    return ${className}Query(collection, query.orderBy(orderField.field, descending: orderField.descending));');
    buffer.writeln('  }');


    buffer.writeln('}');
  }

  void _generateQueryExtension(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Extension methods for $className queries');
    buffer.writeln('extension ${className}QueryExtension on ${className}Query {');
    
    // Generate where method
    buffer.writeln('  /// Filter using a Filter Builder');
    buffer.writeln('  ${className}Query where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(underlyingQuery, builtFilter);');
    buffer.writeln('    return ${className}Query(collection, newQuery);');
    buffer.writeln('  }');
    
    buffer.writeln('}');
  }

  void _generateFilterBuilderClass(StringBuffer buffer, String className, ConstructorElement constructor, String rootFilterType, String? documentIdField) {
    buffer.writeln('/// Generated FilterBuilder for $className');
    buffer.writeln('class ${className}FilterBuilder extends RootFilterBuilder<${rootFilterType}Filter> {');
    buffer.writeln('  ${className}FilterBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Add document ID filter if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Filter by document ID (${documentIdField} field)');
      buffer.writeln('  ${rootFilterType}Filter $documentIdField({');
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

    // Generate field methods and nested object getters
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;
      
      if (_isPrimitiveType(fieldType)) {
        _generateFieldMethod(buffer, className, fieldName, fieldType, rootFilterType);
      } else if (_isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateNestedFilterGetter(buffer, fieldName, fieldType, rootFilterType);
      }
    }

    // Implement abstract method from RootFilterBuilder
    buffer.writeln('  @override');
    buffer.writeln('  ${rootFilterType}Filter wrapFilter(FirestoreFilter coreFilter) {');
    buffer.writeln('    return ${rootFilterType}Filter._fromCore(coreFilter);');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  void _generateNestedFilterGetter(StringBuffer buffer, String fieldName, DartType fieldType, String rootFilterType) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    
    buffer.writeln('  /// Access nested $fieldName filters');
    buffer.writeln('  ${nestedTypeName}FilterBuilder get $fieldName {');
    buffer.writeln('    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return ${nestedTypeName}FilterBuilder(prefix: nestedPrefix);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  void _generateFieldMethod(StringBuffer buffer, String className, String fieldName, DartType fieldType, String rootFilterType) {
    final typeString = fieldType.getDisplayString(withNullability: false);
    
    buffer.writeln('  /// Filter by $fieldName');
    buffer.writeln('  ${rootFilterType}Filter $fieldName({');
    
    // Basic operators
    buffer.writeln('    $typeString? isEqualTo,');
    buffer.writeln('    $typeString? isNotEqualTo,');
    
    // Comparison operators for comparable types
    if (_isComparableType(fieldType)) {
      buffer.writeln('    $typeString? isLessThan,');
      buffer.writeln('    $typeString? isLessThanOrEqualTo,');
      buffer.writeln('    $typeString? isGreaterThan,');
      buffer.writeln('    $typeString? isGreaterThanOrEqualTo,');
    }
    
    // Array operators
    if (_isListType(fieldType)) {
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
      buffer.writeln('    return stringFilter(\'$fieldName\',');
    } else if (_isListType(fieldType)) {
      final elementType = _getListElementType(fieldType);
      buffer.writeln('    return arrayFilter<$elementType>(\'$fieldName\',');
    } else if (typeString == 'bool') {
      buffer.writeln('    return boolFilter(\'$fieldName\',');
    } else if (typeString == 'DateTime') {
      buffer.writeln('    return dateTimeFilter(\'$fieldName\',');
    } else if (_isNumericType(fieldType)) {
      buffer.writeln('    return numericFilter<$typeString>(\'$fieldName\',');
    } else {
      // Fallback for other types, treat as string-like
      buffer.writeln('    return stringFilter(\'$fieldName\',');
    }
    
    // Parameters
    buffer.writeln('      isEqualTo: isEqualTo,');
    buffer.writeln('      isNotEqualTo: isNotEqualTo,');
    
    if (_isComparableType(fieldType)) {
      buffer.writeln('      isLessThan: isLessThan,');
      buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
      buffer.writeln('      isGreaterThan: isGreaterThan,');
      buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
    }
    
    if (_isListType(fieldType)) {
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

  void _generateDocumentIdFieldMethod(StringBuffer buffer, String className, String fieldName, DartType fieldType, String rootFilterType) {
    final typeString = fieldType.getDisplayString(withNullability: false);
    
    buffer.writeln('  /// Filter by document ID ($fieldName field)');
    buffer.writeln('  ${rootFilterType}Filter $fieldName({');
    
    // Basic operators
    buffer.writeln('    $typeString? isEqualTo,');
    buffer.writeln('    $typeString? isNotEqualTo,');
    
    // Comparison operators for comparable types
    if (_isComparableType(fieldType)) {
      buffer.writeln('    $typeString? isLessThan,');
      buffer.writeln('    $typeString? isLessThanOrEqualTo,');
      buffer.writeln('    $typeString? isGreaterThan,');
      buffer.writeln('    $typeString? isGreaterThanOrEqualTo,');
    }
    
    // In operators
    buffer.writeln('    List<$typeString>? whereIn,');
    buffer.writeln('    List<$typeString>? whereNotIn,');
    buffer.writeln('    bool? isNull,');
    
    buffer.writeln('  }) {');
    
    // Use special documentId filter method
    buffer.writeln('    return documentIdFilter(');
    buffer.writeln('      isEqualTo: isEqualTo,');
    buffer.writeln('      isNotEqualTo: isNotEqualTo,');
    
    if (_isComparableType(fieldType)) {
      buffer.writeln('      isLessThan: isLessThan,');
      buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
      buffer.writeln('      isGreaterThan: isGreaterThan,');
      buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
    }
    
    buffer.writeln('      whereIn: whereIn,');
    buffer.writeln('      whereNotIn: whereNotIn,');
    buffer.writeln('      isNull: isNull,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('');
  }


  void _generateFilterClass(StringBuffer buffer, String className) {
    buffer.writeln('/// Generated Filter for $className');
    buffer.writeln('class ${className}Filter extends FirestoreFilter {');
    buffer.writeln('  const ${className}Filter() : super();');
    buffer.writeln('');
    buffer.writeln('  /// Create from core FirestoreFilter - handles both field and logical filters');
    buffer.writeln('  ${className}Filter._fromCore(super.filter) : super.fromFilter();');
    buffer.writeln('}');
  }

  void _generateODMExtension(StringBuffer buffer, String className, String collectionPath) {
    buffer.writeln('/// Extension to add the collection to FirestoreODM');
    buffer.writeln('extension FirestoreODM${className}Extension on FirestoreODM {');
    buffer.writeln('  ${className}Collection get ${_camelCase(collectionPath)} => ${className}Collection(firestore);');
    buffer.writeln('}');
  }

  void _generateUpdateBuilder(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
  ) {
    buffer.writeln('');
    buffer.writeln('class ${className}UpdateBuilder {');
    buffer.writeln('  final FirestoreDocument _document;');
    buffer.writeln('  final String _path;');
    buffer.writeln('');
    buffer.writeln('  ${className}UpdateBuilder(this._document, this._path);');
    buffer.writeln('');

    // Collect valid parameters first
    final validParams = <ParameterElement>[];
    for (final param in constructor.parameters) {
      if (param.name != 'id') {
        validParams.add(param);
      }
    }

    // Only generate call method if there are valid parameters
    if (validParams.isNotEmpty) {
      // Generate call method for direct field updates
      buffer.writeln('  /// Update fields at current level');
      buffer.writeln('  Future<void> call({');

      // Generate parameters
      for (final param in validParams) {
        final fieldName = param.name;
        final fieldType = param.type.getDisplayString(withNullability: false);
        buffer.writeln('    $fieldType? $fieldName,');
      }

      buffer.writeln('  }) async {');
      buffer.writeln('    final updates = <String, dynamic>{};');

      for (final param in validParams) {
        final fieldName = param.name;

        buffer.writeln('    if ($fieldName != null) {');
        buffer.writeln(
          '      final fieldPath = _path.isEmpty ? \'$fieldName\' : \'\$_path.$fieldName\';',
        );
        buffer.writeln('      updates[fieldPath] = $fieldName;');
        buffer.writeln('    }');
      }

      buffer.writeln('    if (updates.isNotEmpty) {');
      buffer.writeln('      await _document.updateFields(updates);');
      buffer.writeln('    }');
      buffer.writeln('  }');
    }

    // Generate nested builders for custom classes only
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;

      // Skip the id field and built-in types
      if (fieldName == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }

      // Only generate for custom classes that have constructors
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;

        if (nestedConstructor != null) {
          final nestedClassName = fieldType.getDisplayString(
            withNullability: false,
          );

          buffer.writeln('');
          buffer.writeln('  /// Access nested $fieldName builder');
          buffer.writeln('  ${nestedClassName}UpdateBuilder get $fieldName {');
          buffer.writeln(
            '    final newPath = _path.isEmpty ? \'$fieldName\' : \'\$_path.$fieldName\';',
          );
          buffer.writeln(
            '    return ${nestedClassName}UpdateBuilder(_document, newPath);',
          );
          buffer.writeln('  }');
        }
      }
    }

    buffer.writeln('}');
  }

  void _generateNestedUpdateBuilders(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      // Skip the id field and built-in types
      if (param.name == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }

      final nestedClassName = fieldType.getDisplayString(
        withNullability: false,
      );

      // Avoid generating duplicate builders
      if (processedTypes.contains(nestedClassName)) {
        continue;
      }
      processedTypes.add(nestedClassName);

      // Try to get the constructor of the nested class
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;

        if (nestedConstructor != null) {
          _generateUpdateBuilder(buffer, nestedClassName, nestedConstructor);

          // Recursively generate builders for nested classes
          _generateNestedUpdateBuilders(
            buffer,
            nestedConstructor,
            processedTypes,
          );
        }
      }
    }
  }

  bool _isPrimitiveType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return [
      'String', 'int', 'double', 'bool', 'DateTime', 'Timestamp',
      'List<String>', 'List<int>', 'List<double>', 'List<bool>',
    ].contains(typeName);
  }

  bool _isCustomClass(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    // Check if it's not a primitive type and not a collection type
    return !_isPrimitiveType(type) &&
           !_isListType(type) &&
           !typeName.startsWith('Map<') &&
           !typeName.startsWith('Set<');
  }

  bool _isComparableType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return ['int', 'double', 'DateTime', 'Timestamp'].contains(typeName);
  }

  bool _isListType(DartType type) {
    return type.getDisplayString(withNullability: false).startsWith('List<');
  }

  bool _isBuiltInType(DartType type) {
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

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  String _camelCase(String text) {
    if (text.isEmpty) return text;
    final words = text.split('_');
    return words[0] + words.skip(1).map((word) => _capitalize(word)).join();
  }

  void _generateOrderByBuilderClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootOrderByType,
    String? documentIdField,
  ) {
    buffer.writeln('/// Generated OrderByBuilder for $className');
    buffer.writeln('class ${className}OrderByBuilder extends OrderByBuilder {');
    buffer.writeln('  ${className}OrderByBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Add document ID order method if there's a document ID field
    if (documentIdField != null) {
      buffer.writeln('  /// Order by document ID (${documentIdField} field)');
      buffer.writeln('  OrderByField $documentIdField({bool descending = false}) => orderByField(FieldPath.documentId, descending: descending);');
      buffer.writeln('');
    }

    // Generate field methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      // Skip document ID field as it's handled separately above
      if (fieldName == documentIdField) continue;
      
      if (_isPrimitiveType(fieldType) || _isComparableType(fieldType)) {
        _generateOrderByFieldMethod(buffer, className, fieldName);
      } else if (_isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateOrderByNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  void _generateOrderByFieldMethod(StringBuffer buffer, String className, String fieldName) {
    buffer.writeln('  /// Order by $fieldName');
    buffer.writeln('  OrderByField $fieldName({bool descending = false}) => orderByField(\'$fieldName\', descending: descending);');
    buffer.writeln('');
  }

  void _generateOrderByNestedGetter(StringBuffer buffer, String fieldName, DartType fieldType) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    buffer.writeln('  /// Access nested $fieldName for ordering');
    buffer.writeln('  ${nestedTypeName}OrderByBuilder get $fieldName {');
    buffer.writeln('    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return ${nestedTypeName}OrderByBuilder(prefix: nestedPrefix);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  void _generateNestedOrderByBuilderClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootOrderByType,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      // Skip the id field and built-in types
      if (param.name == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }

      final nestedClassName = fieldType.getDisplayString(
        withNullability: false,
      );

      // Avoid generating duplicate builders
      if (processedTypes.contains(nestedClassName)) {
        continue;
      }
      processedTypes.add(nestedClassName);

      // Try to get the constructor of the nested class
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;

        if (nestedConstructor != null) {
          _generateOrderByBuilderClass(buffer, nestedClassName, nestedConstructor, rootOrderByType, null);

          // Recursively generate builders for nested classes
          _generateNestedOrderByBuilderClasses(
            buffer,
            nestedConstructor,
            processedTypes,
            rootOrderByType,
          );
        }
      }
    }
  }

  void _generateUpdateBuilderClass(
    StringBuffer buffer,
    String className,
    ConstructorElement constructor,
    String rootUpdateType,
  ) {
    buffer.writeln('/// Generated UpdateBuilder for $className');
    buffer.writeln('class ${className}UpdateBuilder extends UpdateBuilder {');
    buffer.writeln('  ${className}UpdateBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Generate object update method (for as({...}) syntax)
    buffer.writeln('  /// Update with object data');
    buffer.writeln('  UpdateOperation call(Map<String, dynamic> data) {');
    buffer.writeln('    return UpdateOperation(prefix, UpdateOperationType.objectMerge, data);');
    buffer.writeln('  }');
    buffer.writeln('');

    // Generate field methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      if (fieldName == 'id') continue;
      
      if (_isPrimitiveType(fieldType) || _isComparableType(fieldType)) {
        _generateUpdateFieldMethod(buffer, className, fieldName, fieldType);
      } else if (_isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateUpdateNestedGetter(buffer, fieldName, fieldType);
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
  }

  void _generateUpdateFieldMethod(StringBuffer buffer, String className, String fieldName, DartType fieldType) {
    final typeString = fieldType.getDisplayString(withNullability: false);
    
    // Generate field getter that returns appropriate field builder
    buffer.writeln('  /// Access $fieldName field operations');
    
    if (_isListType(fieldType)) {
      final elementType = _getListElementType(fieldType);
      buffer.writeln('  ListFieldBuilder<$elementType> get $fieldName => ListFieldBuilder<$elementType>(getFieldPath(\'$fieldName\'));');
    } else if (_isNumericType(fieldType)) {
      buffer.writeln('  NumericFieldBuilder<$typeString> get $fieldName => NumericFieldBuilder<$typeString>(getFieldPath(\'$fieldName\'));');
    } else if (typeString == 'DateTime') {
      buffer.writeln('  DateTimeFieldBuilder get $fieldName => DateTimeFieldBuilder(getFieldPath(\'$fieldName\'));');
    } else {
      buffer.writeln('  FieldBuilder<$typeString> get $fieldName => FieldBuilder<$typeString>(getFieldPath(\'$fieldName\'));');
    }
    buffer.writeln('');
  }


  String _getListElementType(DartType listType) {
    final typeString = listType.getDisplayString(withNullability: false);
    if (typeString.startsWith('List<') && typeString.endsWith('>')) {
      return typeString.substring(5, typeString.length - 1);
    }
    return 'dynamic';
  }

  void _generateUpdateNestedGetter(StringBuffer buffer, String fieldName, DartType fieldType) {
    final nestedTypeName = fieldType.getDisplayString(withNullability: false);
    buffer.writeln('  /// Access nested $fieldName for updates');
    buffer.writeln('  ${nestedTypeName}UpdateBuilder get $fieldName {');
    buffer.writeln('    final nestedPrefix = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return ${nestedTypeName}UpdateBuilder(prefix: nestedPrefix);');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  void _generateNestedUpdateBuilderClasses(
    StringBuffer buffer,
    ConstructorElement constructor,
    Set<String> processedTypes,
    String rootUpdateType,
  ) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;

      // Skip the id field and built-in types
      if (param.name == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }

      final nestedClassName = fieldType.getDisplayString(
        withNullability: false,
      );

      // Avoid generating duplicate builders
      if (processedTypes.contains(nestedClassName)) {
        continue;
      }
      processedTypes.add(nestedClassName);

      // Try to get the constructor of the nested class
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;

        if (nestedConstructor != null) {
          _generateUpdateBuilderClass(buffer, nestedClassName, nestedConstructor, rootUpdateType);

          // Recursively generate builders for nested classes
          _generateNestedUpdateBuilderClasses(
            buffer,
            nestedConstructor,
            processedTypes,
            rootUpdateType,
          );
        }
      }
    }
  }

  bool _isNumericType(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    return ['int', 'double'].contains(typeName);
  }

  String _getSubcollectionType(DartObject constantValue) {
    final type = constantValue.type;
    if (type is ParameterizedType) {
      final typeArgument = type.typeArguments.first;
      if (typeArgument is InterfaceType) {
        return typeArgument.element.name;
      }
    }
    throw InvalidGenerationSourceError('Invalid subcollection type');
  }

  void _generateBaseUpdateClasses(StringBuffer buffer) {
    // Base classes are now provided by the core package
    // Only need to generate specific update builders for each model

  }
}
