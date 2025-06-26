import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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
    final element = this.element3;
    if (element == null) {
      throw ArgumentError('DartType must have a valid element');
    }
    final name = element.name3;
    if (name == 'dynamic') {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    
    final uri = element.library2?.uri.toString();
    final typeArguments = switch (this) {
      InterfaceType type => type.typeArguments.map((t) => t.reference).toList(),
      _ => <TypeReference>[],
    };
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = uri
        ..types.addAll(typeArguments)
        ..isNullable = nullabilitySuffix == NullabilitySuffix.question 
            ? true
            : null,
    );
  }
}

extension ElementExtension on Element {
  TypeReference get reference {
    if (name == null) {
      throw ArgumentError('Element must have a valid name');
    }
    if (name == 'dynamic') {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    final library = this.library;
    final uri = library?.source.uri.toString();
    final typeParameters = switch (this) {
      ClassElement e => e.typeParameters.toList(),
      TypeAliasElement e => e.typeParameters.toList(),
      _ => <TypeParameterElement>[],
    };
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = uri
        ..types.addAll(typeParameters.map((t) => t.reference))
    );
  }
}

extension Element3Extension on Element2 {
  TypeReference get reference {
    final name = this.name3;
    if (name == null) {
      throw ArgumentError('Element must have a valid name');
    }
    if (name == 'dynamic') {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    final library = this.library2;
    final uri = library?.uri.toString();
    final typeParameters = switch (this) {
      TypeParameterizedElement2 e => e.typeParameters2.toList(),
      _ => <TypeParameterElement2>[],
    };
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = uri
        ..types.addAll(typeParameters.map((t) => t.reference))
    );
  }
}

class TypeReferences {
  static final string = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core'
  );
  static final int = TypeReference(
    (b) => b
      ..symbol = 'int'
      ..url = 'dart:core'
  );
  static final double = TypeReference(
    (b) => b
      ..symbol = 'double'
      ..url = 'dart:core'
  );
  static final bool = TypeReference(
    (b) => b
      ..symbol = 'bool'
      ..url = 'dart:core'
  );
  static final dynamic = TypeReference((b) => b..symbol = 'dynamic');
  static final list = TypeReference(
    (b) => b
      ..symbol = 'List'
      ..url = 'dart:core'
  );
  static final map = TypeReference(
    (b) => b
      ..symbol = 'Map'
      ..url = 'dart:core'
  );
  static final set = TypeReference(
    (b) => b
      ..symbol = 'Set'
      ..url = 'dart:core'
  );
  static final dateTime = TypeReference(
    (b) => b
      ..symbol = 'DateTime'
      ..url = 'dart:core'
  );
  static final duration = TypeReference(
    (b) => b
      ..symbol = 'Duration'
      ..url = 'dart:core'
  );

  static final timestamp = TypeReference(
    (b) => b
      ..symbol = 'Timestamp'
      ..url = 'package:cloud_firestore/cloud_firestore.dart'
  );

  static final geoPoint = TypeReference(
    (b) => b
      ..symbol = 'GeoPoint'
      ..url = 'package:cloud_firestore/cloud_firestore.dart'
  );

  static final documentReference = TypeReference(
    (b) => b
      ..symbol = 'DocumentReference'
      ..url = 'package:cloud_firestore/cloud_firestore.dart'
  );

  static final uint8List = TypeReference(
    (b) => b
      ..symbol = 'Uint8List'
      ..url = 'dart:typed_data'
  );

  static final bytes = TypeReference(
    (b) => b
      ..symbol = 'Bytes'
      ..url = 'package:firebase_storage/firebase_storage.dart'
  );

  static TypeReference listOf(TypeReference type) {
    return list.rebuild((b) => b..types.add(type));
  }

  static TypeReference mapOf(TypeReference key, TypeReference value) {
    return map.rebuild((b) => b..types.addAll([key, value]));
  }

  static TypeReference setOf(TypeReference type) {
    return set.rebuild((b) => b..types.add(type));
  }
}

extension StringUtils on String {
  String lowerFirst() => isEmpty ? this : this[0].toLowerCase() + substring(1);

  String camelCase() {
    if (isEmpty) return this;
    final parts = split('_');
    return parts
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : '')
        .join('');
  }
}


extension TypeReferenceX on TypeReference {
  TypeReference withNullability(bool isNullable) {
    return rebuild((b) => b..isNullable = isNullable == true ? true : null);
  }

  TypeReference withTypeArguments(List<TypeReference> typeArguments) {
    return rebuild((b) => b..types.addAll(typeArguments));
  }

  TypeReference withoutTypeArguments() {
    return rebuild((b) => b..types.clear());
  }

  TypeReference withoutNullability() {
    return rebuild((b) => b..isNullable = null);
  }
}