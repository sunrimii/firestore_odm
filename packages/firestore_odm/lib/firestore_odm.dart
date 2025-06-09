/// Type-safe Firestore ODM with code generation support
library firestore_odm;

// Re-export cloud_firestore for convenience
export 'package:cloud_firestore/cloud_firestore.dart';

export 'src/firestore_collection.dart';
export 'src/firestore_document.dart';
export 'src/firestore_odm.dart';
export 'src/firestore_query.dart';
export 'src/filter_builder.dart';
export 'src/data_processor.dart';
export 'src/update_operations_mixin.dart';
export 'src/update_builder.dart' hide NumericFieldBuilder, DateTimeFieldBuilder, ListFieldBuilder, OrderByField, UpdateBuilder;

// New interfaces
export 'src/interfaces/query_operations.dart';
export 'src/interfaces/update_operations.dart';
export 'src/interfaces/subscribe_operations.dart';
export 'src/interfaces/document_operations.dart';

// New services
export 'src/services/update_operations_service.dart';
export 'src/services/query_operations_service.dart';
export 'src/services/subscription_service.dart';

// Re-export annotations for convenience
export 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
