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
export 'src/model_converter.dart';
export 'src/schema.dart';
export 'src/count_query.dart';
export 'src/tuple_aggregate.dart' hide AggregateField;
export 'src/pagination.dart' hide OrderByHelper, OrderByFieldInfo, OrderByConfiguration;
export 'src/order_by_selector.dart';
export 'src/interfaces/pagination_operations.dart';
export 'src/update_builder.dart'
    hide
        NumericFieldBuilder,
        DateTimeFieldBuilder,
        ListFieldBuilder,
        OrderByField;

// New interfaces
export 'src/interfaces/query_operations.dart';
export 'src/interfaces/update_operations.dart';
export 'src/interfaces/subscribe_operations.dart';
export 'src/interfaces/document_operations.dart';
export 'src/interfaces/collection_operations.dart';

// New services
export 'src/services/update_operations_service.dart';
export 'src/services/query_operations_service.dart';
export 'src/services/subscription_service.dart';

// Re-export annotations for convenience
export 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
