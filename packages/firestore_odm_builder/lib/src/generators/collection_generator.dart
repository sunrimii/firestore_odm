import 'package:analyzer/dart/element/element2.dart';
import '../utils/string_helpers.dart';

/// Generator for collection converter functions and related utilities
class CollectionGenerator {
  /// Generate converter functions for a model class
  static String generateConverters(ClassElement2 element) {
    final buffer = StringBuffer();
    final className = element.name3!;

    // Generate fromJson converter function
    buffer.writeln('/// Generated fromJson converter for $className');
    buffer.writeln(
      '$className ${StringHelpers.camelCase(className)}FromJson(Map<String, dynamic> json) {',
    );
    buffer.writeln('  return $className.fromJson(json);');
    buffer.writeln('}');
    buffer.writeln('');

    // Generate toJson converter function
    buffer.writeln('/// Generated toJson converter for $className');
    buffer.writeln(
      'Map<String, dynamic> ${StringHelpers.camelCase(className)}ToJson($className instance) {',
    );
    buffer.writeln('  return instance.toJson();');
    buffer.writeln('}');
    buffer.writeln('');

    return buffer.toString();
  }

  /// Get the fromJson function name for a model
  static String getFromJsonFunctionName(String className) {
    return '${StringHelpers.camelCase(className)}FromJson';
  }

  /// Get the toJson function name for a model
  static String getToJsonFunctionName(String className) {
    return '${StringHelpers.camelCase(className)}ToJson';
  }
}
