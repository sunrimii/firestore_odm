import 'package:analyzer/dart/element/element.dart';
import '../utils/type_analyzer.dart';
import '../utils/string_helpers.dart';

/// Generator for Firestore collection classes
class CollectionGenerator {
  /// Generate the collection class code
  static void generateCollectionClass(
    StringBuffer buffer,
    String className,
    String collectionPath,
    ConstructorElement constructor,
    String? documentIdField,
    bool isSubcollection, {
    String suffix = '',
  }) {
    final pathSegments = collectionPath.split('/');
    final wildcardParams = <String>[];

    // Find wildcard parameters
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i] == '*') {
        if (i == 0) {
          throw ArgumentError('First path segment cannot be a wildcard');
        }
        final paramName =
            '${pathSegments[i - 1].replaceAll(RegExp(r's$'), '')}Id';
        wildcardParams.add(paramName);
      }
    }

    // Use generic naming without suffix for subcollections
    final collectionClassName = '${className}Collection';

    buffer.writeln('/// Generated Collection for $className');
    buffer.writeln(
      'class $collectionClassName extends FirestoreCollection<$className> {',
    );

    // Generate generic constructor that accepts CollectionReference
    buffer.writeln('  $collectionClassName(CollectionReference<Map<String, dynamic>> ref) : super(');
    buffer.writeln('    ref: ref,');
    buffer.writeln('    fromJson: (data) => $className.fromJson(data),');
    buffer.writeln('    toJson: (value) => value.toJson(),');
    buffer.writeln('  );');
    buffer.writeln('');

    // Generate document ID field if provided
    if (documentIdField != null) {
      buffer.writeln('  @override');
      buffer.writeln('  String get documentIdField => \'$documentIdField\';');
      buffer.writeln('');
    }

    buffer.writeln('}');
  }

}
