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
  generateForAnnotatedElement(
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

    // Generate extension for strong-typed update method
    buffer.writeln('');
    buffer.writeln(
      'extension ${className}DocumentExtension on FirestoreDocument<$className> {',
    );
    
    // Generate main update method
    buffer.writeln('  /// Strong-typed update method similar to copyWith');
    buffer.writeln('  Future<void> update({');
    
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type.getDisplayString(withNullability: false);
      
      // Skip the id field as it shouldn't be updated
      if (fieldName == 'id') continue;
      
      buffer.writeln('    $fieldType? $fieldName,');
    }
    
    buffer.writeln('  }) async {');
    buffer.writeln('    final updates = <String, dynamic>{};');
    
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      
      // Skip the id field
      if (fieldName == 'id') continue;
      
      buffer.writeln(
        '    if ($fieldName != null) updates[\'$fieldName\'] = $fieldName;',
      );
    }
    
    buffer.writeln('    if (updates.isNotEmpty) {');
    buffer.writeln('      await updateFields(updates);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    
    // Generate nested update methods for custom classes
    for (final param in constructor.parameters) {
      final fieldName = param.name;
      final fieldType = param.type;
      
      // Skip the id field
      if (fieldName == 'id') continue;
      
      // Check if this is a custom class (not built-in types)
      if (_isBuiltInType(fieldType)) {
        continue;
      }
      
      // Generate nested update method for custom classes
      final nestedClassName = fieldType.getDisplayString(withNullability: false);
      
      // Try to get the constructor of the nested class
      if (fieldType.element is ClassElement) {
        final nestedClass = fieldType.element as ClassElement;
        final nestedConstructor = nestedClass.unnamedConstructor;
        
        if (nestedConstructor != null) {
          // Collect valid parameters first
          final validParams = <ParameterElement>[];
          for (final nestedParam in nestedConstructor.parameters) {
            if (nestedParam.name != 'id') {
              validParams.add(nestedParam);
            }
          }
          
          // Only generate method if there are valid parameters
          if (validParams.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('  /// Update nested $fieldName fields');
            buffer.writeln('  Future<void> update${_capitalize(fieldName)}({');
            
            // Add parameters for each field in the nested class
            for (final nestedParam in validParams) {
              final nestedFieldName = nestedParam.name;
              final nestedFieldType = nestedParam.type.getDisplayString(withNullability: false);
              buffer.writeln('    $nestedFieldType? $nestedFieldName,');
            }
            
            buffer.writeln('  }) async {');
            buffer.writeln('    final updates = <String, dynamic>{};');
            
            // Generate field updates with dot notation
            for (final nestedParam in validParams) {
              final nestedFieldName = nestedParam.name;
              buffer.writeln(
                '    if ($nestedFieldName != null) updates[\'$fieldName.$nestedFieldName\'] = $nestedFieldName;',
              );
            }
            
            buffer.writeln('    if (updates.isNotEmpty) {');
            buffer.writeln('      await updateFields(updates);');
            buffer.writeln('    }');
            buffer.writeln('  }');
          }
        }
      }
    }
    
    buffer.writeln('}');

    return buffer.toString();
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
