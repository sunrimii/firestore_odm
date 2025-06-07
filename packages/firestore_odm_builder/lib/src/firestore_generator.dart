import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

class FirestoreGenerator extends GeneratorForAnnotation<CollectionPath> {
  static const TypeChecker subcollectionChecker =
      TypeChecker.fromRuntime(SubcollectionPath);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`.',
        todo: 'Remove the CollectionPath annotation from `${element.name}`.',
      );
    }

    final className = element.name;
    final collectionPath = annotation.read('path').stringValue;
    final buffer = StringBuffer();

    // Generate mixin for where and orderBy methods
    buffer.writeln('mixin ${className}QueryMixin {');
    buffer.writeln('  FirestoreCollection<$className> get collection;');
    buffer.writeln('  Query<Map<String, dynamic>> get query;');

    // Helper method for where clauses
    void writeWhereClause(String field, String fieldName, String fieldType,
        bool isArray, bool isNullable) {
      buffer.writeln('  ${className}Query where${_capitalize(fieldName)}({');

      if (isArray) {
        buffer.writeln('    Object? arrayContains,');
        buffer.writeln('    Iterable<Object?>? arrayContainsAny,');
      } else {
        buffer.writeln('    $fieldType? isEqualTo,');
        buffer.writeln('    $fieldType? isNotEqualTo,');
        buffer.writeln('    $fieldType? isLessThan,');
        buffer.writeln('    $fieldType? isLessThanOrEqualTo,');
        buffer.writeln('    $fieldType? isGreaterThan,');
        buffer.writeln('    $fieldType? isGreaterThanOrEqualTo,');
        buffer.writeln('    Iterable<$fieldType>? whereIn,');
        buffer.writeln('    Iterable<$fieldType>? whereNotIn,');
        if (fieldType == 'String') {
          buffer.writeln('    String? startsWith,');
        }
      }

      if (isNullable) {
        buffer.writeln('    bool? isNull,');
      }

      buffer.writeln('  }) {');
      buffer.writeln('    var newQuery = query.where(');
      buffer.writeln('      $field,');
      if (isArray) {
        buffer.writeln('      arrayContains: arrayContains,');
        buffer.writeln('      arrayContainsAny: arrayContainsAny,');
      } else {
        buffer.writeln('      isEqualTo: isEqualTo,');
        buffer.writeln('      isNotEqualTo: isNotEqualTo,');
        buffer.writeln('      isLessThan: isLessThan,');
        buffer.writeln('      isLessThanOrEqualTo: isLessThanOrEqualTo,');
        buffer.writeln('      isGreaterThan: isGreaterThan,');
        buffer.writeln('      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,');
        buffer.writeln('      whereIn: whereIn,');
        buffer.writeln('      whereNotIn: whereNotIn,');
      }
      if (isNullable) {
        buffer.writeln('      isNull: isNull,');
      }
      buffer.writeln('    );');
      buffer.writeln('    return ${className}Query(collection, newQuery);');
      buffer.writeln('  }');
    }

    // Generate whereDocumentId method using the helper method
    writeWhereClause(
        'FieldPath.documentId', 'DocumentId', 'String', false, true);

    // Generate orderByDocumentId method
    buffer.writeln(
        '  ${className}Query orderByDocumentId({bool descending = false}) {');
    buffer.writeln(
        '    return ${className}Query(collection, query.orderBy(FieldPath.documentId, descending: descending));');
    buffer.writeln('  }');

    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      for (final param in constructor.parameters) {
        final fieldName = param.name;
        final fieldType = param.type.getDisplayString(withNullability: false);
        final isNullable =
            param.type.nullabilitySuffix != NullabilitySuffix.none;
        final isArray = param.type.isDartCoreList;

        writeWhereClause(
            '\'$fieldName\'', fieldName, fieldType, isArray, isNullable);

        // Generate orderBy methods
        buffer.writeln(
            '  ${className}Query orderBy${_capitalize(fieldName)}({bool descending = false}) {');
        buffer.writeln(
            '    return ${className}Query(collection, query.orderBy(\'$fieldName\', descending: descending));');
        buffer.writeln('  }');
      }
    }

    buffer.writeln('}'); // Close the mixin

    // Generate collection class
    buffer.writeln(
        'class ${className}Collection extends FirestoreCollection<$className> with ${className}QueryMixin {');
    buffer.writeln('  ${className}Collection() : super(');
    buffer.writeln(
        '    ref: FirebaseFirestore.instance.collection(\'$collectionPath\'),');
    buffer.writeln('    fromJson: (data) => $className.fromJson(data),');
    buffer.writeln('    toJson: (value) => value.toJson(),');
    buffer.writeln('  );');

    buffer.writeln('  @override');
    buffer.writeln('  Query<Map<String, dynamic>> get query => ref;');

    buffer.writeln('  @override');
    buffer.writeln('  FirestoreCollection<$className> get collection => this;');

    buffer.writeln('}'); // Close the collection class

    // Generate query class
    buffer.writeln(
        'class ${className}Query extends FirestoreQuery<$className> with ${className}QueryMixin {');
    buffer.writeln('  ${className}Query(super.collection, super.query);');
    buffer.writeln('  @override');
    buffer.writeln(
        '  FirestoreQuery<$className> newInstance(Query<Map<String, dynamic>> query) => ${className}Query(collection, query);');
    buffer.writeln('}'); // Close the query class

    // Generate document class
    buffer.writeln(
        'class ${className}Document extends FirestoreDocument<$className> {');
    buffer.writeln('  ${className}Document(super.collection, super.id);');

    // Generate strong-typed update method
    buffer.writeln('');
    buffer.writeln('  /// Strong-typed update method similar to copyWith');
    buffer.writeln('  Future<void> update({');
    
    if (constructor != null) {
      for (final param in constructor.parameters) {
        final fieldName = param.name;
        final fieldType = param.type.getDisplayString(withNullability: false);
        final isNullable = param.type.nullabilitySuffix != NullabilitySuffix.none;
        
        // Skip the id field as it shouldn't be updated
        if (fieldName == 'id') continue;
        
        if (isNullable) {
          buffer.writeln('    $fieldType? $fieldName,');
        } else {
          buffer.writeln('    $fieldType? $fieldName,');
        }
      }
    }
    
    buffer.writeln('  }) async {');
    buffer.writeln('    final updates = <String, dynamic>{};');
    
    if (constructor != null) {
      for (final param in constructor.parameters) {
        final fieldName = param.name;
        
        // Skip the id field
        if (fieldName == 'id') continue;
        
        buffer.writeln('    if ($fieldName != null) updates[\'$fieldName\'] = $fieldName;');
      }
    }
    
    buffer.writeln('    if (updates.isNotEmpty) {');
    buffer.writeln('      await updateFields(updates);');
    buffer.writeln('    }');
    buffer.writeln('  }');

    // Generate subcollections under the document class
    for (final metadata in element.metadata) {
      final constantValue = metadata.computeConstantValue();
      if (constantValue != null && subcollectionChecker.isExactlyType(constantValue.type!)) {
        final subcollectionType = _getSubcollectionType(constantValue);
        final subcollectionPath =
            constantValue.getField('path')!.toStringValue()!;
        buffer.writeln(
            '  FirestoreCollection<$subcollectionType> get $subcollectionPath => FirestoreCollection(');
        buffer.writeln('    ref: ref.collection(\'$subcollectionPath\'),');
        buffer.writeln(
            '    fromJson: (data) => $subcollectionType.fromJson(data),');
        buffer.writeln('    toJson: (value) => value.toJson(),');
        buffer.writeln('  );');
      }
    }

    buffer.writeln('}'); // Close the document class

    // Generate extension to add the collection to FirestoreODM
    buffer.writeln(
        'extension FirestoreODM${className}Extension on FirestoreODM {');
    buffer.writeln(
        '  ${className}Collection get ${_camelCase(collectionPath)} => ${className}Collection();');
    buffer.writeln('}');

    return buffer.toString();
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
