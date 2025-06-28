import 'package:code_builder/code_builder.dart';

/// Utility functions for string manipulation in code generation
class StringHelpers {
  /// Capitalize the first letter of a string
  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Convert underscore_case to camelCase
  static String camelCase(String text) {
    if (text.isEmpty) return text;
    final words = text.split('_');
    return words[0] + words.skip(1).map((word) => capitalize(word)).join();
  }

  /// Generate a field path with proper prefix handling
  static String getFieldPath(String prefix, String fieldName) {
    return prefix.isEmpty ? fieldName : '$prefix.$fieldName';
  }

  /// Generate a nested prefix for field access
  static String getNestedPrefix(String currentPrefix, String fieldName) {
    return currentPrefix.isEmpty ? fieldName : '$currentPrefix.$fieldName';
  }
}


extension ExpressionnX on Expression  {
  /// Converts the expression to a string representation
  Expression debug(String message) {
    return refer('/* $message */ ${accept(DartEmitter())}');
  }
}