
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';

class JsonConverterHandler {
  const JsonConverterHandler();

  Expression fromJson(
    TypeReference type,
    Expression source,
    List<TypeConverter> elementConverters,
  ) {
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateFromFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return type.property('fromJson').call([source, ...converterLambdas]);
  }

  Expression toJson(
    TypeReference type,
    Expression source,
    List<TypeConverter> elementConverters,
  ) {
    final toJsonMethod = 'toJson';
    if (elementConverters.isEmpty) {
      return source.property(toJsonMethod).call([]);
    }
    final converterLambdas = elementConverters.map((converter) {
      return Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = converter.generateToFirestore(refer('e')).code
          ..lambda = true,
      ).closure;
    }).toList();
    return source.property(toJsonMethod).call(converterLambdas);
  }
}
