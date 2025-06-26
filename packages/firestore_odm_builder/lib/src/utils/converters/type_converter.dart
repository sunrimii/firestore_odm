import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/generators/converter_service.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';

/// Functional converter interface for type conversions
sealed class TypeConverter {
  TypeReference get fromType;
  TypeReference get toType;
  Expression generateFromFirestore(Expression sourceExpression);
  Expression generateToFirestore(Expression sourceExpression);
}

/// Direct converter for primitive types (no conversion needed)
class DirectConverter implements TypeConverter {
  const DirectConverter({required this.fromType});

  final TypeReference fromType;
  TypeReference get toType => fromType;

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return sourceExpression;
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return sourceExpression; // No conversion needed for primitive types
  }
}

class VariableConverterClassConverter implements TypeConverter {
  const VariableConverterClassConverter({
    required this.variableReference,
    required this.fromType,
    required this.toType,
  });

  final Reference variableReference;
  final TypeReference fromType;
  final TypeReference toType;

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return variableReference.property('fromFirestore').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return variableReference.property('toFirestore').call([sourceExpression]);
  }
}

class GenericTypeConverter implements TypeConverter {
  const GenericTypeConverter({required this.fromType});

  final TypeReference fromType;
  TypeReference get toType => fromType;

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return sourceExpression;
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return sourceExpression;
  }
}

class CustomConverter extends GenericConverter {
  final InterfaceElement element;

  const CustomConverter({
    required this.element,
    super.typeParameterConverters,
    required this.fromType,
  });

  final TypeReference fromType;
  TypeReference get toType =>
      TypeReferences.mapOf(TypeReferences.string, TypeReferences.dynamic);

  CustomConverter toGeneric(List<GenericTypeConverter> converters) {
    return CustomConverter(
      element: element,
      typeParameterConverters: {
        for (var i = 0; i < converters.length; i++)
          converters[i].fromType: converters[i],
      },
      fromType: fromType.rebuild(
        (b) => b..types.replace(converters.map((c) => c.fromType).toList()),
      ),
    );
  }

  CustomConverter applyConverters(
    Map<TypeReference, TypeConverter> converters,
  ) {
    return CustomConverter(
      element: element,
      typeParameterConverters: {
        for (var entry in typeParameterConverters.entries)
          entry.key: converters[entry.value.fromType] ?? entry.value,
      },
      fromType: fromType,
    );
  }

  // TypeConverter _refine(FieldInfo field) {
  //   final converter = field.converter;
  //   if (converter is GenericTypeConverter) {
  //     if (typeParameterConverters.containsKey(converter.fromType)) {
  //       return typeParameterConverters[converter.fromType]!;
  //     } else {
  //       // throw Warning if no specific converter found
  //       print(
  //         'Warning: No specific converter found for type parameter ${converter.fromType}. Using generic converter.',
  //       );
  //       return converter; // Return as-is if no specific converter found
  //     }
  //   }

  //   final converterService = converterServiceSignal.get();
  //   final analysis = ModelAnalyzer.analyze(field.dartType, field.element);
  //   return converterService.get(analysis);
  // }

  Expression _handleNullable(
    DartType type,
    Expression expression,
    Expression Function(Expression expression) then,
  ) {
    // If the type is nullable, we need to handle null values
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return expression
          .equalTo(literalNull)
          .conditional(literalNull, then(expression.nullChecked));
    }
    return then(expression);
  }

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final analysis = ModelAnalyzer.analyze(element.thisType, element);
    return element.reference.newInstance(
      [],
      Map.fromEntries(
        analysis.fields.values.map(
          (field) => MapEntry(
            field.parameterName,
            _handleNullable(
              field.dartType,
              sourceExpression.index(literalString(field.jsonFieldName)),
              (expression) =>
                  refine(field.converter).generateFromFirestore(expression),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    // to map
    return literalMap(
      Map.fromEntries(
        ModelAnalyzer.analyze(element.thisType, element).fields.values
            .where((x) => !x.isDocumentId)
            .map(
              (field) => MapEntry(
                field.jsonFieldName,
                _handleNullable(
                  field.dartType,
                  sourceExpression.property(field.parameterName),
                  (expression) =>
                      refine(field.converter).generateToFirestore(expression),
                ),
              ),
            ),
      ),
    );
  }
}

abstract class GenericConverter implements TypeConverter {
  const GenericConverter({this.typeParameterConverters = const {}});

  final Map<Reference, TypeConverter> typeParameterConverters;

  TypeConverter refine(TypeConverter converter) {
    if (converter is GenericTypeConverter) {
      if (typeParameterConverters.containsKey(converter.fromType)) {
        return typeParameterConverters[converter.fromType]!;
      } else {
        // throw Warning if no specific converter found
        print(
          'Warning: No specific converter found for type parameter ${converter.fromType}. Using generic converter.',
        );
        return converter; // Return as-is if no specific converter found
      }
    }

    return converter;
  }

  GenericConverter toGeneric(List<GenericTypeConverter> converters);

  GenericConverter applyConverters(
    Map<TypeReference, TypeConverter> converters,
  );
}

class TypedDefaultConverter extends DefaultConverter {
  TypedDefaultConverter({
    required this.typeReference,
    this.typeParameters = const [],
    required this.fromType,
    required this.toType,
  }) : super(
         reference: typeReference.call(typeParameters),
         fromType: fromType,
         toType: toType,
       );

  final TypeReference typeReference;
  final List<Expression> typeParameters;
  final TypeReference fromType;
  final TypeReference toType;

  @override
  Expression generateFromFirestore(Expression sourceExpression) =>
      typeReference.call([sourceExpression]);

  @override
  Expression generateToFirestore(Expression sourceExpression) =>
      typeReference.call([sourceExpression]);
}

/// Converter using a specific converter class (handles both generic and non-generic)
class DefaultConverter implements TypeConverter {
  const DefaultConverter({
    required this.reference,
    this.elementConverters = const [],
    required this.fromType,
    required this.toType,
  });

  final Expression reference;
  final TypeReference fromType;
  final List<DefaultConverter> elementConverters;
  final TypeReference toType;

  DefaultConverter.fromClassName({
    required String name,
    required TypeReference fromType,
    required TypeReference toType,
  }) : this(
         reference: TypeReference((b) => b..symbol = name).call([]),
         fromType: fromType,
         toType: toType,
       );

  @override
  Expression generateFromFirestore(Expression sourceExpression) =>
      reference..property('fromFirestore').call([sourceExpression]);

  @override
  Expression generateToFirestore(Expression sourceExpression) =>
      reference.property('toFirestore').call([sourceExpression]);
}

/// Converter for generic types with element converters
class JsonConverterConverter extends GenericConverter {
  final List<TypeConverter> elementConverters;
  final Map<Reference, TypeConverter> typeParameterConverters;
  final TypeReference fromType;
  final TypeReference toType;
  final String? customFromJsonMethod;
  final String? customToJsonMethod;

  @override
  JsonConverterConverter toGeneric(List<GenericTypeConverter> converters) {
    return JsonConverterConverter(
      elementConverters: converters,
      fromType: fromType.rebuild(
        (b) => b..types.replace(converters.map((c) => c.fromType).toList()),
      ),
      toType: toType,
      customFromJsonMethod: customFromJsonMethod,
      customToJsonMethod: customToJsonMethod,
    );
  }

  @override
  JsonConverterConverter applyConverters(
    Map<TypeReference, TypeConverter> converters,
  ) {
    return JsonConverterConverter(
      elementConverters: elementConverters
          .map(
            (converter) => converter is GenericTypeConverter
                ? converters[converter.fromType] ?? converter
                : converter,
          )
          .toList(),
      fromType: fromType,
      toType: toType,
      customFromJsonMethod: customFromJsonMethod,
      customToJsonMethod: customToJsonMethod,
    );
  }

  const JsonConverterConverter({
    required this.fromType,
    required this.toType,
    this.elementConverters = const [],
    this.typeParameterConverters = const {},
    this.customFromJsonMethod,
    this.customToJsonMethod,
  });

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final fromJsonMethod = customFromJsonMethod ?? 'fromJson';
    final converterLambdas = elementConverters.map(
      (converter) => Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = refine(converter).generateFromFirestore(refer('e')).code
          ..lambda = true,
      ).closure,
    );
    return fromType.property(fromJsonMethod).call([
      sourceExpression,
      ...converterLambdas,
    ]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    final toJsonMethod = customToJsonMethod ?? 'toJson';
    final converterLambdas = elementConverters.map(
      (converter) => Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = refine(converter).generateToFirestore(refer('e')).code
          ..lambda = true,
      ).closure,
    );
    return sourceExpression.property(toJsonMethod).call(converterLambdas);
  }
}

/// Converter for custom JsonConverter annotations
class AnnotationConverter implements TypeConverter {
  const AnnotationConverter({
    required this.reference,
    required this.fromType,
    required this.toType,
  });

  final TypeReference reference;
  final TypeReference fromType;
  final TypeReference toType;

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return reference.call([]).property('fromJson').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return reference.call([]).property('toJson').call([sourceExpression]);
  }
}
