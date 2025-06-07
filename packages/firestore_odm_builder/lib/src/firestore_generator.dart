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

    // Generate Filter class
    _generateFilterClass(buffer, className);
    buffer.writeln('');

    // Generate Query Extension (for new where API)
    _generateQueryExtension(buffer, className, constructor);
    buffer.writeln('');

    // Generate extension to add the collection to FirestoreODM
    _generateODMExtension(buffer, className, collectionPath);

    // Generate the main update builder class
    _generateUpdateBuilder(buffer, className, constructor);

    // Generate update builders for all nested custom classes
    final processedTypes = <String>{className};
    _generateNestedUpdateBuilders(buffer, constructor, processedTypes);

    // Generate extension for the chained update API
    buffer.writeln('');
    buffer.writeln(
      'extension ${className}DocumentExtension on FirestoreDocument<$className> {',
    );
    buffer.writeln('  /// Chained update API similar to copyWith');
    buffer.writeln(
      '  ${className}UpdateBuilder get update => ${className}UpdateBuilder(this, \'\');',
    );
    buffer.writeln('}');

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

    // Generate orderBy methods for Collection
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      if (fieldName == 'id') continue;

      buffer.writeln('');
      buffer.writeln('  /// Order by $fieldName');
      buffer.writeln('  ${className}Query orderBy${_capitalize(fieldName)}({bool descending = false}) {');
      buffer.writeln('    return ${className}Query(this, ref.orderBy(\'$fieldName\', descending: descending));');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
  }

  void _generateDocumentClass(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Generated Document for $className');
    buffer.writeln('class ${className}Document extends FirestoreDocument<$className> {');
    buffer.writeln('  ${className}Document(super.collection, super.id);');
    buffer.writeln('');
    
    // Generate top-level update method
    _generateTopLevelUpdateMethod(buffer, className, constructor);
    
    buffer.writeln('}');
  }

  void _generateTopLevelUpdateMethod(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('  /// Update top-level fields');
    buffer.write('  Future<void> update({');
    
    bool first = true;
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      if (fieldName == 'id') continue;
      
      if (!first) buffer.write(', ');
      // Always make parameters nullable for updates
      final nullableType = fieldType.getDisplayString(withNullability: false);
      buffer.write('$nullableType? $fieldName');
      first = false;
    }
    
    buffer.writeln('}) async {');
    buffer.writeln('    final updates = <String, dynamic>{};');
    
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      if (fieldName == 'id') continue;
      
      buffer.writeln('    if ($fieldName != null) updates[\'$fieldName\'] = $fieldName;');
    }
    
    buffer.writeln('    if (updates.isNotEmpty) {');
    buffer.writeln('      await updateFields(updates);');
    buffer.writeln('    }');
    buffer.writeln('  }');
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

    // Generate orderBy methods
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      if (fieldName == 'id') continue;

      buffer.writeln('');
      buffer.writeln('  /// Order by $fieldName');
      buffer.writeln('  ${className}Query orderBy${_capitalize(fieldName)}({bool descending = false}) {');
      buffer.writeln('    return ${className}Query(collection, query.orderBy(\'$fieldName\', descending: descending));');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
  }

  void _generateQueryExtension(StringBuffer buffer, String className, ConstructorElement constructor) {
    buffer.writeln('/// Extension methods for $className queries');
    buffer.writeln('extension ${className}QueryExtension on FirestoreQuery<$className> {');
    
    // Generate where method
    buffer.writeln('  /// Filter using a Filter Builder');
    buffer.writeln('  FirestoreQuery<$className> where(${className}Filter Function(${className}FilterBuilder filter) filterBuilder) {');
    buffer.writeln('    final builder = ${className}FilterBuilder();');
    buffer.writeln('    final builtFilter = filterBuilder(builder);');
    buffer.writeln('    final newQuery = applyFilterToQuery(query, builtFilter);');
    buffer.writeln('    return newInstance(newQuery);');
    buffer.writeln('  }');
    
    buffer.writeln('}');
  }

  void _generateFilterBuilderClass(StringBuffer buffer, String className, ConstructorElement constructor, String rootFilterType) {
    buffer.writeln('/// Generated FilterBuilder for $className');
    buffer.writeln('class ${className}FilterBuilder extends FilterBuilder {');
    buffer.writeln('  ${className}FilterBuilder({String prefix = \'\'}) : super(prefix: prefix);');
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
      buffer.writeln('    if (filter$i != null) allFilters.add(filter$i!);');
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
      buffer.writeln('    if (filter$i != null) allFilters.add(filter$i!);');
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
}
