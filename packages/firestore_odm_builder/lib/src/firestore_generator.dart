import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
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

    // Generate mixin for query methods
    buffer.writeln('mixin ${className}QueryMixin {');
    buffer.writeln('  FirestoreCollection<$className> get collection;');
    buffer.writeln('  Query<Map<String, dynamic>> get query;');

    // Generate where and orderBy methods for each field
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type.getDisplayString(withNullability: false);

      if (fieldName == 'id') continue; // Skip id field for queries

      // Generate where methods
      buffer.writeln('');
      buffer.writeln('  ${className}Query where${_capitalize(fieldName)}({');
      buffer.writeln('    $fieldType? isEqualTo,');
      buffer.writeln('    $fieldType? isNotEqualTo,');
      buffer.writeln('    $fieldType? isLessThan,');
      buffer.writeln('    $fieldType? isLessThanOrEqualTo,');
      buffer.writeln('    $fieldType? isGreaterThan,');
      buffer.writeln('    $fieldType? isGreaterThanOrEqualTo,');
      buffer.writeln('    Iterable<$fieldType>? whereIn,');
      buffer.writeln('    Iterable<$fieldType>? whereNotIn,');

      // Add isNull parameter for nullable types
      if (param.type.nullabilitySuffix != NullabilitySuffix.none) {
        buffer.writeln('    bool? isNull,');
      }

      buffer.writeln('  }) {');
      buffer.writeln('    var newQuery = query.where(');
      buffer.writeln('      \'$fieldName\',');
      buffer.writeln('      isEqualTo: isEqualTo,');
      buffer.writeln('      isNotEqualTo: isNotEqualTo,');
      buffer.writeln('      isLessThan: isLessThan,');
      buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
      buffer.writeln('      isGreaterThan: isGreaterThan,');
      buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
      buffer.writeln('      whereIn: whereIn,');
      buffer.writeln('      whereNotIn: whereNotIn,');

      if (param.type.nullabilitySuffix != NullabilitySuffix.none) {
        buffer.writeln('      isNull: isNull,');
      }

      buffer.writeln('    );');
      buffer.writeln('    return ${className}Query(collection, newQuery);');
      buffer.writeln('  }');

      // Generate orderBy methods
      buffer.writeln('');
      buffer.writeln(
        '  ${className}Query orderBy${_capitalize(fieldName)}({bool descending = false}) {',
      );
      buffer.writeln(
        '    return ${className}Query(collection, query.orderBy(\'$fieldName\', descending: descending));',
      );
      buffer.writeln('  }');
    }

    buffer.writeln('}'); // Close the mixin

    // Generate collection class
    buffer.writeln('');
    buffer.writeln(
      'class ${className}Collection extends FirestoreCollection<$className> with ${className}QueryMixin {',
    );
    buffer.writeln('  ${className}Collection() : super(');
    buffer.writeln(
      '    ref: FirebaseFirestore.instance.collection(\'$collectionPath\'),',
    );
    buffer.writeln('    fromJson: (data) => $className.fromJson(data),');
    buffer.writeln('    toJson: (value) => value.toJson(),');
    buffer.writeln('  );');

    buffer.writeln('  @override');
    buffer.writeln('  Query<Map<String, dynamic>> get query => ref;');

    buffer.writeln('  @override');
    buffer.writeln('  FirestoreCollection<$className> get collection => this;');

    buffer.writeln('}'); // Close the collection class

    // Generate query class
    buffer.writeln('');
    buffer.writeln(
      'class ${className}Query extends FirestoreQuery<$className> with ${className}QueryMixin {',
    );
    buffer.writeln('  ${className}Query(super.collection, super.query);');
    buffer.writeln('  @override');
    buffer.writeln(
      '  FirestoreQuery<$className> newInstance(Query<Map<String, dynamic>> query) => ${className}Query(collection, query);',
    );
    buffer.writeln('}'); // Close the query class

    // Generate document class
    buffer.writeln('');
    buffer.writeln(
      'class ${className}Document extends FirestoreDocument<$className> {',
    );
    buffer.writeln('  ${className}Document(super.collection, super.id);');

    // Generate subcollections under the document class
    for (final metadata in element.metadata) {
      final constantValue = metadata.computeConstantValue();
      if (constantValue != null &&
          subcollectionChecker.isExactlyType(constantValue.type!)) {
        final subcollectionType = _getSubcollectionType(constantValue);
        final subcollectionPath = constantValue
            .getField('path')!
            .toStringValue()!;
        buffer.writeln(
          '  FirestoreCollection<$subcollectionType> get $subcollectionPath => FirestoreCollection(',
        );
        buffer.writeln('    ref: ref.collection(\'$subcollectionPath\'),');
        buffer.writeln(
          '    fromJson: (data) => $subcollectionType.fromJson(data),',
        );
        buffer.writeln('    toJson: (value) => value.toJson(),');
        buffer.writeln('  );');
      }
    }

    buffer.writeln('}'); // Close the document class

    // Generate extension to add the collection to FirestoreODM
    buffer.writeln('');
    buffer.writeln(
      'extension FirestoreODM${className}Extension on FirestoreODM {',
    );
    buffer.writeln(
      '  ${className}Collection get ${_camelCase(collectionPath)} => ${className}Collection();',
    );
    buffer.writeln('}');

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
    buffer.writeln('  ${className}UpdateBuilder get update => ${className}UpdateBuilder(this, \'\');');
    buffer.writeln('}');

    return buffer.toString();
  }

  void _generateUpdateBuilder(StringBuffer buffer, String className, ConstructorElement constructor) {
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
        buffer.writeln('      final fieldPath = _path.isEmpty ? \'$fieldName\' : \'\$_path.$fieldName\';');
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
          final nestedClassName = fieldType.getDisplayString(withNullability: false);
          
          buffer.writeln('');
          buffer.writeln('  /// Access nested $fieldName builder');
          buffer.writeln('  ${nestedClassName}UpdateBuilder get $fieldName {');
          buffer.writeln('    final newPath = _path.isEmpty ? \'$fieldName\' : \'\$_path.$fieldName\';');
          buffer.writeln('    return ${nestedClassName}UpdateBuilder(_document, newPath);');
          buffer.writeln('  }');
        }
      }
    }
    
    buffer.writeln('}');
  }

  void _generateNestedUpdateBuilders(StringBuffer buffer, ConstructorElement constructor, Set<String> processedTypes) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;
      
      // Skip the id field and built-in types
      if (param.name == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }
      
      final nestedClassName = fieldType.getDisplayString(withNullability: false);
      
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
          _generateNestedUpdateBuilders(buffer, nestedConstructor, processedTypes);
        }
      }
    }
  }

  void _collectCustomTypes(ConstructorElement constructor, Set<String> customTypes) {
    for (final param in constructor.parameters) {
      final fieldType = param.type;
      
      // Skip the id field and built-in types
      if (param.name == 'id' || _isBuiltInType(fieldType)) {
        continue;
      }
      
      final typeName = fieldType.getDisplayString(withNullability: false);
      customTypes.add(typeName);
      
      // Recursively collect types from nested classes
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;
        
        if (nestedConstructor != null) {
          _collectCustomTypes(nestedConstructor, customTypes);
        }
      }
    }
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

  String _camelToSnake(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _camelCase(String text) {
    if (text.isEmpty) {
      return text;
    }
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
