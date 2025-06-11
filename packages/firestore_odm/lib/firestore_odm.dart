/// Type-safe Firestore ODM with code generation support
library firestore_odm;

// Re-export cloud_firestore for convenience
export 'package:cloud_firestore/cloud_firestore.dart' show FieldPath;

export 'src/firestore_collection.dart';
export 'src/firestore_document.dart';
export 'src/firestore_odm.dart';
export 'src/firestore_query.dart';
export 'src/filter_builder.dart';
export 'src/data_processor.dart';
export 'src/model_converter.dart';
export 'src/schema.dart';
export 'src/count_query.dart';
export 'src/query.dart';

// New interfaces
export 'src/interfaces/document_operations.dart';

// Re-export annotations for convenience
export 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
