import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

/// Code generator for Firestore ODM annotations
class FirestoreGenerator extends Generator {
  static const TypeChecker collectionPathChecker = TypeChecker.fromUrl(
    'package:firestore_odm_annotation/firestore_odm_annotation.dart#CollectionPath',
  );

  static const TypeChecker subcollectionChecker = TypeChecker.fromUrl(
    'package:firestore_odm_annotation/firestore_odm_annotation.dart#SubcollectionPath',
  );

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    for (final element in library.allElements) {
      if (element is ClassElement &&
          collectionPathChecker.hasAnnotationOfExact(element)) {
        final annotation = collectionPathChecker.firstAnnotationOfExact(
          element,
        );
        if (annotation == null) continue;

        final result = _generateForElement(element, ConstantReader(annotation));
        if (result != null) {
          buffer.writeln(result);
        }
      }
    }

    return buffer.toString();
  }

  String? _generateForElement(Element element, ConstantReader annotation) {
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
    void writeWhereClause(
      String field,
      String fieldName,
      String fieldType,
      bool isArray,
      bool isNullable,
    ) {
      buffer.writeln('  ${className}Query where${_capitalize(fieldName)}({');

      if (isArray) {
        buffer.writeln('    Object? arrayContains,');
        buffer.writeln('    List<Object?>? arrayContainsAny,');
        buffer.writeln('    List<Object?>? whereIn,');
        buffer.writeln('    List<Object?>? whereNotIn,');
      } else {
        buffer.writeln('    Object? isEqualTo,');
        buffer.writeln('    Object? isNotEqualTo,');
        buffer.writeln('    Object? isLessThan,');
        buffer.writeln('    Object? isLessThanOrEqualTo,');
        buffer.writeln('    Object? isGreaterThan,');
        buffer.writeln('    Object? isGreaterThanOrEqualTo,');
        buffer.writeln('    List<Object?>? whereIn,');
        buffer.writeln('    List<Object?>? whereNotIn,');
      }

      if (isNullable) {
        buffer.writeln('    bool? isNull,');
      }

      buffer.writeln('  }) {');
      buffer.writeln('    Query<Map<String, dynamic>> newQuery = query;');

      if (isArray) {
        buffer.writeln('    if (arrayContains != null) {');
        buffer.writeln(
          '      newQuery = newQuery.where($field, arrayContains: arrayContains);',
        );
        buffer.writeln('    }');
        buffer.writeln('    if (arrayContainsAny != null) {');
        buffer.writeln(
          '      newQuery = newQuery.where($field, arrayContainsAny: arrayContainsAny);',
        );
        buffer.writeln('    }');
        buffer.writeln('    if (whereIn != null) {');
        buffer.writeln(
          '      newQuery = newQuery.where($field, whereIn: whereIn);',
        );
        buffer.writeln('    }');
        buffer.writeln('    if (whereNotIn != null) {');
        buffer.writeln(
          '      newQuery = newQuery.where($field, whereNotIn: whereNotIn);',
        );
        buffer.writeln('    }');
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
      'FieldPath.documentId',
      'DocumentId',
      'String',
      false,
      true,
    );

    // Generate orderByDocumentId method
    buffer.writeln(
      '  ${className}Query orderByDocumentId({bool descending = false}) {',
    );
    buffer.writeln(
      '    return ${className}Query(collection, query.orderBy(FieldPath.documentId, descending: descending));',
    );
    buffer.writeln('  }');

    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      for (final param in constructor.parameters) {
        final fieldName = param.name;
        final fieldType = param.type.getDisplayString();
        final isNullable =
            param.type.nullabilitySuffix != NullabilitySuffix.none;
        final isArray = param.type.isDartCoreList;

        writeWhereClause(
          '\'$fieldName\'',
          fieldName,
          fieldType,
          isArray,
          isNullable,
        );

        // Generate orderBy methods
        buffer.writeln(
          '  ${className}Query orderBy${_capitalize(fieldName)}({bool descending = false}) {',
        );
        buffer.writeln(
          '    return ${className}Query(collection, query.orderBy(\'$fieldName\', descending: descending));',
        );
        buffer.writeln('  }');
      }
    }

    buffer.writeln('}'); // Close the mixin

    // Generate collection class
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
    buffer.writeln(
      'class ${className}Query extends FirestoreQuery<$className> with ${className}QueryMixin {',
    );
    buffer.writeln(
      '  ${className}Query(this.collection, Query<Map<String, dynamic>> query)',
    );
    buffer.writeln('      : super(query, collection.fromJson);');

    buffer.writeln('  @override');
    buffer.writeln('  final FirestoreCollection<$className> collection;');

    buffer.writeln('  @override');
    buffer.writeln('  Query<Map<String, dynamic>> get query => _query;');

    buffer.writeln('}'); // Close the query class

    return buffer.toString();
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
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
