import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/generators/converter_service.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';
import 'package:firestore_odm_builder/src/utils/nameUtil.dart';

/// Functional converter interface for type conversions
sealed class TypeConverter {
  Expression generateFromFirestore(Expression sourceExpression);
  Expression generateToFirestore(Expression sourceExpression);
}

/// Direct converter for primitive types (no conversion needed)
class DirectConverter implements TypeConverter {
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
  final Reference variableName;

  const VariableConverterClassConverter(this.variableName);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return variableName.property('fromFirestore').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return variableName.property('toFirestore').call([sourceExpression]);
  }
}

class GenericTypeConverter implements TypeConverter {
  final Reference typeParameter;
  const GenericTypeConverter(this.typeParameter);

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return sourceExpression;
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return sourceExpression;
  }
}

class CustomConverter implements TypeConverter {
  final InterfaceElement element;
  final Map<Reference, TypeConverter> typeParameterConverters;

  const CustomConverter(
    this.element, [
    this.typeParameterConverters = const {},
  ]);

  TypeConverter _refine(FieldInfo field) {
    final converter = field.converter;
    if (converter is GenericTypeConverter) {
      if (typeParameterConverters.containsKey(converter.typeParameter)) {
        return typeParameterConverters[converter.typeParameter]!;
      } else {
        // throw Warning if no specific converter found
        print(
          'Warning: No specific converter found for type parameter ${converter.typeParameter}. Using generic converter.',
        );
        return converter; // Return as-is if no specific converter found
      }
    }

    final converterService = converterServiceSignal.get();
    final analysis = ModelAnalyzer.analyze(field.dartType, field.element);
    return converterService.get(analysis);
  }

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
              (expression) => _refine(field).generateFromFirestore(expression),
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
                      _refine(field).generateToFirestore(expression),
                ),
              ),
            ),
      ),
    );
  }
}

/// Converter using a specific converter class (handles both generic and non-generic)
class DefaultConverter implements TypeConverter {
  final Expression instance;
  final TypeReference toType;

  const DefaultConverter(this.instance, this.toType);

  DefaultConverter.fromClassName(
    String converterClassName,
    TypeReference fieldType,
  ) : this(refer(converterClassName).call([]), fieldType);

  @override
  Expression generateFromFirestore(Expression sourceExpression) =>
      instance.property('fromFirestore').call([sourceExpression]);

  @override
  Expression generateToFirestore(Expression sourceExpression) =>
      instance.property('toFirestore').call([sourceExpression]);
}

/// Converter for generic types with element converters
class JsonConverterConverter implements TypeConverter {
  final TypeReference dartType;
  final List<TypeConverter> elementConverters;
  final String? customFromJsonMethod;
  final String? customToJsonMethod;
  final TypeReference? toType;

  const JsonConverterConverter(
    this.dartType,
    this.elementConverters, {
    this.customFromJsonMethod,
    this.customToJsonMethod,
    this.toType,
  });

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    final fromJsonMethod = customFromJsonMethod ?? 'fromJson';
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateFromFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return dartType.property(fromJsonMethod).call([
      sourceExpression,
      ...converterLambdas,
    ]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    final toJsonMethod = customToJsonMethod ?? 'toJson';
    if (elementConverters.isEmpty) {
      return sourceExpression.property(toJsonMethod).call([]);
    }
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateToFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return sourceExpression.property(toJsonMethod).call(converterLambdas);
  }
}

/// Converter for custom JsonConverter annotations
class AnnotationConverter implements TypeConverter {
  final TypeReference reference;
  final TypeReference toType;

  const AnnotationConverter(this.reference, {required this.toType});

  @override
  Expression generateFromFirestore(Expression sourceExpression) {
    return reference.call([]).property('fromJson').call([sourceExpression]);
  }

  @override
  Expression generateToFirestore(Expression sourceExpression) {
    return reference.call([]).property('toJson').call([sourceExpression]);
  }
}
