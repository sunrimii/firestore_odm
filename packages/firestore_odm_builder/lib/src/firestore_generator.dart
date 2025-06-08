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

    // Generate Collection class
    _generateCollectionClass(buffer, className, collectionPath, constructor);
    buffer.writeln('');

    // Generate Document class
    _generateDocumentClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate Query class
    _generateQueryClass(buffer, className, constructor);
    buffer.writeln('');

    // Generate FilterBuilder class
    _generateFilterBuilderClass(buffer, className, constructor, className);
    
    // Generate FilterBuilder classes for all nested types
    _generateNestedFilterBuilderClasses(buffer, constructor, <String>{}, className);

    // Generate OrderByBuilder class
    _generateOrderByBuilderClass(buffer, className, constructor, className);
    
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
            _generateFilterBuilderClass(buffer, typeName, nestedConstructor, rootFilterType);
            
            // Recursively generate for deeply nested types
            _generateNestedFilterBuilderClasses(buffer, nestedConstructor, processedTypes, rootFilterType);
          }
        }
      }
    }
  }

  void _generateCollectionClass(StringBuffer buffer, String className, String collectionPath, ConstructorElement constructor) {
    buffer.writeln('/// Generated Collection for $className');
    buffer.writeln('class ${className}Collection extends FirestoreCollection<$className> {');
    buffer.writeln('  ${className}Collection(FirebaseFirestore firestore) : super(');
    buffer.writeln('    ref: firestore.collection(\'$collectionPath\'),');
    buffer.writeln('    fromJson: (data) => $className.fromJson(data),');
    buffer.writeln('    toJson: (value) => value.toJson(),');
    buffer.writeln('  );');
    buffer.writeln('');
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
    buffer.writeln('    final newQuery = applyFilterToQuery(query, builtFilter);');
    buffer.writeln('    return ${className}Query(collection, newQuery);');
    buffer.writeln('  }');
    
    buffer.writeln('}');
  }

  void _generateFilterBuilderClass(StringBuffer buffer, String className, ConstructorElement constructor, String rootFilterType) {
    buffer.writeln('/// Generated FilterBuilder for $className');
    buffer.writeln('class ${className}FilterBuilder extends FilterBuilder {');
    buffer.writeln('  ${className}FilterBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Generate field methods and nested object getters
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      if (fieldName == 'id') continue;
      
      if (_isPrimitiveType(fieldType)) {
        _generateFieldMethod(buffer, className, fieldName, fieldType, rootFilterType);
      } else if (_isCustomClass(fieldType)) {
        // Generate nested object getter for custom classes
        _generateNestedFilterGetter(buffer, fieldName, fieldType, rootFilterType);
      }
    }

    // Generate type-safe or and and methods with support for up to 30 filters
    buffer.writeln('  /// Create OR filter with type safety (supports up to 30 filters)');
    buffer.write('  ${rootFilterType}Filter or(${rootFilterType}Filter filter1, ${rootFilterType}Filter filter2, [');
    for (int i = 3; i <= 30; i++) {
      buffer.write('${rootFilterType}Filter? filter$i, ');
    }
    buffer.writeln(']) {');
    buffer.writeln('    final allFilters = <FirestoreFilter>[filter1, filter2];');
    for (int i = 3; i <= 30; i++) {
      buffer.writeln('    if (filter$i != null) allFilters.add(filter$i);');
    }
    buffer.writeln('    return ${rootFilterType}Filter._or(allFilters);');
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  /// Create AND filter with type safety (supports up to 30 filters)');
    buffer.write('  ${rootFilterType}Filter and(${rootFilterType}Filter filter1, ${rootFilterType}Filter filter2, [');
    for (int i = 3; i <= 30; i++) {
      buffer.write('${rootFilterType}Filter? filter$i, ');
    }
    buffer.writeln(']) {');
    buffer.writeln('    final allFilters = <FirestoreFilter>[filter1, filter2];');
    for (int i = 3; i <= 30; i++) {
      buffer.writeln('    if (filter$i != null) allFilters.add(filter$i);');
    }
    buffer.writeln('    return ${rootFilterType}Filter._and(allFilters);');
    buffer.writeln('  }');
    buffer.writeln('');

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
    buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    if (isEqualTo != null) {');
    buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'==\', value: isEqualTo);');
    buffer.writeln('    }');
    buffer.writeln('    if (isNotEqualTo != null) {');
    buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'!=\', value: isNotEqualTo);');
    buffer.writeln('    }');
    
    if (_isComparableType(fieldType)) {
      buffer.writeln('    if (isLessThan != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'<\', value: isLessThan);');
      buffer.writeln('    }');
      buffer.writeln('    if (isLessThanOrEqualTo != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'<=\', value: isLessThanOrEqualTo);');
      buffer.writeln('    }');
      buffer.writeln('    if (isGreaterThan != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'>\', value: isGreaterThan);');
      buffer.writeln('    }');
      buffer.writeln('    if (isGreaterThanOrEqualTo != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'>=\', value: isGreaterThanOrEqualTo);');
      buffer.writeln('    }');
    }
    
    if (_isListType(fieldType)) {
      buffer.writeln('    if (arrayContains != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'array-contains\', value: arrayContains);');
      buffer.writeln('    }');
      buffer.writeln('    if (arrayContainsAny != null) {');
      buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'array-contains-any\', value: arrayContainsAny);');
      buffer.writeln('    }');
    }
    
    buffer.writeln('    if (whereIn != null) {');
    buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'in\', value: whereIn);');
    buffer.writeln('    }');
    buffer.writeln('    if (whereNotIn != null) {');
    buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: \'not-in\', value: whereNotIn);');
    buffer.writeln('    }');
    buffer.writeln('    if (isNull != null) {');
    buffer.writeln('      return ${rootFilterType}Filter._field(field: fieldPath, operator: isNull ? \'==\' : \'!=\', value: null);');
    buffer.writeln('    }');
    buffer.writeln('    throw ArgumentError(\'At least one filter condition must be provided\');');
    buffer.writeln('  }');
    buffer.writeln('');
  }

  void _generateFilterClass(StringBuffer buffer, String className) {
    buffer.writeln('/// Generated Filter for $className');
    buffer.writeln('class ${className}Filter extends FirestoreFilter {');
    buffer.writeln('  const ${className}Filter() : super();');
    buffer.writeln('  ');
    buffer.writeln('  /// Create field filter');
    buffer.writeln('  const ${className}Filter._field({');
    buffer.writeln('    required String field,');
    buffer.writeln('    required String operator,');
    buffer.writeln('    required dynamic value,');
    buffer.writeln('  }) : super.field(field: field, operator: operator, value: value);');
    buffer.writeln('  ');
    buffer.writeln('  /// Create OR filter');
    buffer.writeln('  const ${className}Filter._or(List<FirestoreFilter> filters) : super.or(filters);');
    buffer.writeln('  ');
    buffer.writeln('  /// Create AND filter');
    buffer.writeln('  const ${className}Filter._and(List<FirestoreFilter> filters) : super.and(filters);');
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
    final typeString = type.toString();
    return type.isDartCoreType ||
        typeString.startsWith('List<') ||
        typeString.startsWith('Map<') ||
        typeString == 'DateTime' ||
        typeString == 'DateTime?';
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
  ) {
    buffer.writeln('/// Generated OrderByBuilder for $className');
    buffer.writeln('class ${className}OrderByBuilder extends OrderByBuilder {');
    buffer.writeln('  ${className}OrderByBuilder({super.prefix = \'\'});');
    buffer.writeln('');

    // Generate field methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      if (fieldName == 'id') continue;
      
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
    buffer.writeln('  OrderByField $fieldName({bool descending = false}) {');
    buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
    buffer.writeln('    return OrderByField(fieldPath, descending: descending);');
    buffer.writeln('  }');
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
          _generateOrderByBuilderClass(buffer, nestedClassName, nestedConstructor, rootOrderByType);

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
      buffer.writeln('  _ListFieldBuilder<$elementType> get $fieldName {');
      buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
      buffer.writeln('    return _ListFieldBuilder<$elementType>(fieldPath);');
    } else if (_isNumericType(fieldType)) {
      buffer.writeln('  _NumericFieldBuilder<$typeString> get $fieldName {');
      buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
      buffer.writeln('    return _NumericFieldBuilder<$typeString>(fieldPath);');
    } else if (typeString == 'DateTime') {
      buffer.writeln('  _DateTimeFieldBuilder get $fieldName {');
      buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
      buffer.writeln('    return _DateTimeFieldBuilder(fieldPath);');
    } else {
      buffer.writeln('  _FieldBuilder<$typeString> get $fieldName {');
      buffer.writeln('    final fieldPath = prefix.isEmpty ? \'$fieldName\' : \'\$prefix.$fieldName\';');
      buffer.writeln('    return _FieldBuilder<$typeString>(fieldPath);');
    }
    buffer.writeln('  }');
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
    buffer.writeln('/// Update operation types');
    buffer.writeln('enum UpdateOperationType {');
    buffer.writeln('  set,');
    buffer.writeln('  increment,');
    buffer.writeln('  arrayAdd,');
    buffer.writeln('  arrayRemove,');
    buffer.writeln('  serverTimestamp,');
    buffer.writeln('  objectMerge,');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('/// Represents a single update operation');
    buffer.writeln('class UpdateOperation {');
    buffer.writeln('  final String field;');
    buffer.writeln('  final UpdateOperationType type;');
    buffer.writeln('  final dynamic value;');
    buffer.writeln('');
    buffer.writeln('  const UpdateOperation(this.field, this.type, this.value);');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  String toString() => \'UpdateOperation(field: \$field, type: \$type, value: \$value)\';');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('/// Base class for update builders');
    buffer.writeln('abstract class UpdateBuilder {');
    buffer.writeln('  final String prefix;');
    buffer.writeln('');
    buffer.writeln('  const UpdateBuilder({this.prefix = \'\'});');
    buffer.writeln('');
    buffer.writeln('  /// Convert operations to Firestore update map');
    buffer.writeln('  static Map<String, dynamic> operationsToMap(List<UpdateOperation> operations) {');
    buffer.writeln('    final Map<String, dynamic> updateMap = {};');
    buffer.writeln('    final Map<String, List<dynamic>> arrayAdds = {};');
    buffer.writeln('    final Map<String, List<dynamic>> arrayRemoves = {};');
    buffer.writeln('    final Map<String, num> increments = {};');
    buffer.writeln('');
    buffer.writeln('    for (final operation in operations) {');
    buffer.writeln('      switch (operation.type) {');
    buffer.writeln('        case UpdateOperationType.set:');
    buffer.writeln('          updateMap[operation.field] = operation.value;');
    buffer.writeln('          break;');
    buffer.writeln('        case UpdateOperationType.increment:');
    buffer.writeln('          increments[operation.field] = (increments[operation.field] ?? 0) + (operation.value as num);');
    buffer.writeln('          break;');
    buffer.writeln('        case UpdateOperationType.arrayAdd:');
    buffer.writeln('          arrayAdds.putIfAbsent(operation.field, () => []).add(operation.value);');
    buffer.writeln('          break;');
    buffer.writeln('        case UpdateOperationType.arrayRemove:');
    buffer.writeln('          arrayRemoves.putIfAbsent(operation.field, () => []).add(operation.value);');
    buffer.writeln('          break;');
    buffer.writeln('        case UpdateOperationType.serverTimestamp:');
    buffer.writeln('          updateMap[operation.field] = FieldValue.serverTimestamp();');
    buffer.writeln('          break;');
    buffer.writeln('        case UpdateOperationType.objectMerge:');
    buffer.writeln('          // For object merge, flatten the nested fields');
    buffer.writeln('          final data = operation.value as Map<String, dynamic>;');
    buffer.writeln('          for (final entry in data.entries) {');
    buffer.writeln('            final fieldPath = operation.field.isEmpty ? entry.key : \'\${operation.field}.\${entry.key}\';');
    buffer.writeln('            updateMap[fieldPath] = entry.value;');
    buffer.writeln('          }');
    buffer.writeln('          break;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    // Handle fields with both add and remove operations by executing them sequentially');
    buffer.writeln('    final fieldsWithBothOps = arrayAdds.keys.toSet().intersection(arrayRemoves.keys.toSet());');
    buffer.writeln('    if (fieldsWithBothOps.isNotEmpty) {');
    buffer.writeln('      throw ArgumentError(\'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update. Fields: \$fieldsWithBothOps\');');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    // Apply accumulated increment operations');
    buffer.writeln('    for (final entry in increments.entries) {');
    buffer.writeln('      updateMap[entry.key] = FieldValue.increment(entry.value);');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    // Apply accumulated array operations');
    buffer.writeln('    for (final entry in arrayAdds.entries) {');
    buffer.writeln('      updateMap[entry.key] = FieldValue.arrayUnion(entry.value);');
    buffer.writeln('    }');
    buffer.writeln('    for (final entry in arrayRemoves.entries) {');
    buffer.writeln('      updateMap[entry.key] = FieldValue.arrayRemove(entry.value);');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    return updateMap;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    // Generate field builder classes
    buffer.writeln('/// Generic field builder');
    buffer.writeln('class _FieldBuilder<T> {');
    buffer.writeln('  final String fieldPath;');
    buffer.writeln('  _FieldBuilder(this.fieldPath);');
    buffer.writeln('');
    buffer.writeln('  /// Set field value');
    buffer.writeln('  UpdateOperation call(T value) {');
    buffer.writeln('    return UpdateOperation(fieldPath, UpdateOperationType.set, value);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('/// List field builder');
    buffer.writeln('class _ListFieldBuilder<T> extends _FieldBuilder<List<T>> {');
    buffer.writeln('  _ListFieldBuilder(super.fieldPath);');
    buffer.writeln('');
    buffer.writeln('  /// Add element to array');
    buffer.writeln('  UpdateOperation add(T value) {');
    buffer.writeln('    return UpdateOperation(fieldPath, UpdateOperationType.arrayAdd, value);');
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  /// Remove element from array');
    buffer.writeln('  UpdateOperation remove(T value) {');
    buffer.writeln('    return UpdateOperation(fieldPath, UpdateOperationType.arrayRemove, value);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('/// Numeric field builder');
    buffer.writeln('class _NumericFieldBuilder<T extends num> extends _FieldBuilder<T> {');
    buffer.writeln('  _NumericFieldBuilder(super.fieldPath);');
    buffer.writeln('');
    buffer.writeln('  /// Increment field value');
    buffer.writeln('  UpdateOperation increment(T value) {');
    buffer.writeln('    return UpdateOperation(fieldPath, UpdateOperationType.increment, value);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('/// DateTime field builder');
    buffer.writeln('class _DateTimeFieldBuilder extends _FieldBuilder<DateTime> {');
    buffer.writeln('  _DateTimeFieldBuilder(super.fieldPath);');
    buffer.writeln('');
    buffer.writeln('  /// Set field to server timestamp');
    buffer.writeln('  UpdateOperation serverTimestamp() {');
    buffer.writeln('    return UpdateOperation(fieldPath, UpdateOperationType.serverTimestamp, null);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');
  }
}
