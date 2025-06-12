import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_builder/src/generators/schema_generator.dart';
import 'package:firestore_odm_builder/src/utils/model_analyzer.dart';

class FirestoreGenerator extends GeneratorForAnnotation<Schema> {
  const FirestoreGenerator();

  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        'Schema can only be applied to top-level variables.',
        element: element,
      );
    }

    final library = LibraryReader(element.library!);
    final resolver = await buildStep.resolver;

    // 1. Extract all @Collection annotations from this schema variable
    final collections = _extractCollectionAnnotations(element);
    
    // 2. Extract model types from Collection generics
    final rootModelTypes = collections.map((c) => c.modelTypeName).toSet();
    
    // 3. Discover all nested types (two-pass approach)
    final allModelTypes = await _discoverAllRequiredTypesAsync(library, rootModelTypes, resolver);
    
    // 4. Analyze all model types
    final Map<String, ClassElement> allModelClassElements = {};
    final Map<String, ModelAnalysis> allModelAnalyses = {};
    
    for (final typeName in allModelTypes) {
      final classElement = await _findClassElementWithResolver(library, typeName, resolver);
      if (classElement != null) {
        allModelClassElements[typeName] = classElement;
        
        final analysis = ModelAnalyzer.analyzeModel(classElement);
        if (analysis != null) {
          allModelAnalyses[typeName] = analysis;
        }
      }
    }

    // 5. Generate schema code with all types
    return SchemaGenerator.generateSchemaCodeWithoutConverters(
      element,
      collections,
      allModelClassElements,
      allModelAnalyses,
    );
  }

  /// Extract @Collection annotations from a schema variable
  List<SchemaCollectionInfo> _extractCollectionAnnotations(TopLevelVariableElement element) {
    final collections = <SchemaCollectionInfo>[];
    final collectionChecker = TypeChecker.fromRuntime(Collection);

    for (final annotation in element.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue != null && collectionChecker.isExactlyType(annotationValue.type!)) {
        // Extract path from @Collection("path")
        final path = annotationValue.getField('path')!.toStringValue()!;
        
        // Extract model type from @Collection<ModelType>
        final collectionType = annotationValue.type!;
        if (collectionType is ParameterizedType && collectionType.typeArguments.isNotEmpty) {
          final modelType = collectionType.typeArguments.first;
          final modelTypeName = modelType.getDisplayString(withNullability: false);
          final isSubcollection = path.contains('*');
          
          collections.add(SchemaCollectionInfo(
            modelTypeName: modelTypeName,
            path: path,
            isSubcollection: isSubcollection,
          ));
        }
      }
    }

    return collections;
  }

  /// Discover all types that need analysis (including nested custom types)
  Set<String> _discoverAllRequiredTypes(LibraryReader library, Set<String> rootTypes) {
    final discovered = <String>{};
    final toProcess = <String>[...rootTypes];
    final processed = <String>{};

    while (toProcess.isNotEmpty) {
      final currentType = toProcess.removeAt(0);
      
      if (processed.contains(currentType)) {
        continue;
      }
      processed.add(currentType);
      discovered.add(currentType);

      // Find and analyze this type to discover its dependencies
      final classElement = _findClassElement(library, currentType);
      if (classElement != null) {
        final analysis = ModelAnalyzer.analyzeModel(classElement);
        if (analysis != null) {
          // Look for nested custom types in fields
          for (final field in analysis.fields.values) {
            final fieldTypeName = field.dartType.getDisplayString(withNullability: false);
            
            // Check if this is a custom type defined in the same library
            if (_findClassElement(library, fieldTypeName) != null &&
                !processed.contains(fieldTypeName) &&
                !toProcess.contains(fieldTypeName)) {
              toProcess.add(fieldTypeName);
            }
          }
        }
      }
    }

    return discovered;
  }

  /// Discover all types that need analysis (including nested custom types) - ASYNC VERSION
  Future<Set<String>> _discoverAllRequiredTypesAsync(LibraryReader library, Set<String> rootTypes, Resolver resolver) async {
    final discovered = <String>{};
    final toProcess = <String>[...rootTypes];
    final processed = <String>{};

    while (toProcess.isNotEmpty) {
      final currentType = toProcess.removeAt(0);
      
      if (processed.contains(currentType)) {
        continue;
      }
      processed.add(currentType);
      discovered.add(currentType);

      // Find and analyze this type to discover its dependencies
      final classElement = await _findClassElementWithResolver(library, currentType, resolver);
      if (classElement != null) {
        final analysis = ModelAnalyzer.analyzeModel(classElement);
        if (analysis != null) {
          // Look for nested custom types in fields
          for (final field in analysis.fields.values) {
            final fieldTypeName = field.dartType.getDisplayString(withNullability: false);
            
            // Check if this is a custom type that can be resolved
            final nestedElement = await _findClassElementWithResolver(library, fieldTypeName, resolver);
            if (nestedElement != null &&
                !processed.contains(fieldTypeName) &&
                !toProcess.contains(fieldTypeName)) {
              toProcess.add(fieldTypeName);
            }
          }
        }
      }
    }

    return discovered;
  }

  /// Find a class element by name using the resolver to access imports
  Future<ClassElement?> _findClassElementWithResolver(
    LibraryReader library,
    String className,
    Resolver resolver,
  ) async {
    try {
      // First try to find in the current library
      final result = library.findType(className);
      if (result != null) {
        return result;
      }
      // If result is null, fall through to search imported libraries
    } catch (e) {
      // Continue to search in imported libraries
    }
    
    // Search through imported libraries
    try {
      final libraryElement = library.element;
      
      // Search through all accessible libraries using resolver
      final allLibraries = await resolver.libraries.toList();
      
      for (final lib in allLibraries) {
        try {
          final libReader = LibraryReader(lib);
          final libClasses = libReader.classes;
          
          // Check if this library has the class we're looking for
          for (final classElement in libClasses) {
            if (classElement.name == className) {
              return classElement;
            }
          }
          
          // Also try direct lookup
          try {
            final classElement = libReader.findType(className);
            if (classElement != null) {
              return classElement;
            }
          } catch (e) {
            // Expected for most libraries
          }
        } catch (e) {
          // Continue searching - this is expected for some libraries
        }
      }
      
    } catch (e) {
      // Search failed
    }
    
    return null;
  }

  /// Find a class element by name in the library and its imports (legacy method)
  ClassElement? _findClassElement(LibraryReader library, String className) {
    try {
      // First try to find in the current library
      return library.findType(className);
    } catch (e) {
      // If not found, search through all classes in the library
      try {
        final allClasses = library.classes;
        print('DEBUG: Available classes in library: ${allClasses.map((c) => c.name).toList()}');
        
        for (final classElement in allClasses) {
          if (classElement.name == className) {
            print('DEBUG: Found $className in current library classes');
            return classElement;
          }
        }
        
        // Try to find the type through top level elements
        final element = library.element;
        for (final topLevelElement in element.topLevelElements) {
          if (topLevelElement is ClassElement && topLevelElement.name == className) {
            print('DEBUG: Found $className in top level elements');
            return topLevelElement;
          }
        }
        
      } catch (e) {
        print('DEBUG: Error searching for $className: $e');
      }
      
      print('DEBUG: Could not find $className in any accessible scope');
      return null;
    }
  }
}
