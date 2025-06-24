import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

class NameUtil {
  static String getName(
    DartType type, {
    String postfix = '',
    String prefix = '',
    withTypeArguments = true,
  }) {
    final className = type.element?.name;
    if (className == null) {
      throw ArgumentError('Type must have a valid element name');
    }
    return composeTypeName(
      className,
      postfix: postfix,
      prefix: prefix,
      typeParameters: withTypeArguments && type is InterfaceType
          ? type.typeArguments.map(
              (t) => t.getDisplayString(withNullability: false),
            )
          : <String>[],
    );
  }

  static String composeTypeName(
    String name, {
    String prefix = '',
    String postfix = '',
    Iterable<String> typeParameters = const [],
  }) {
    return '${prefix}${name}$postfix${typeParameters.isNotEmpty ? '<${typeParameters.join(', ')}>' : ''}';
  }
}

extension DartTypeExtension on DartType {
  TypeReference get reference {
    final element = this.element;
    if (element == null) return TypeReference((b) => b..symbol = 'dynamic');
    
    final name = element.name!;
    final library = element.library;
    final uri = library?.source.uri.toString();
    
    return TypeReference((b) => b
      ..symbol = name
      ..url = uri);
  }
}

extension StringUtils on String {
  String lowerFirst() => isEmpty ? this : this[0].toLowerCase() + substring(1);
}