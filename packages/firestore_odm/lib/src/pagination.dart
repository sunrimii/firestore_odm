import 'package:cloud_firestore/cloud_firestore.dart';
import 'filter_builder.dart' show OrderByField;

/// Represents cursor information for pagination
class PaginationCursor<T> {
  final List<dynamic> values;
  final DocumentSnapshot? documentSnapshot;
  
  const PaginationCursor(this.values, [this.documentSnapshot]);
  
  /// Create cursor from a document snapshot and orderBy fields
  factory PaginationCursor.fromDocument(
    DocumentSnapshot snapshot,
    List<OrderByFieldInfo> orderByFields,
  ) {
    final values = orderByFields.map((field) {
      return snapshot.data() is Map<String, dynamic>
          ? (snapshot.data() as Map<String, dynamic>)[field.fieldPath]
          : null;
    }).toList();
    
    return PaginationCursor<T>(values, snapshot);
  }
  
  /// Create cursor from an object using orderBy field configuration
  factory PaginationCursor.fromObject(
    T object,
    List<OrderByFieldInfo> orderByFields,
    Map<String, dynamic> Function(T) toMap,
  ) {
    final objectMap = toMap(object);
    final values = orderByFields.map((field) {
      return _extractNestedValue(objectMap, field.fieldPath);
    }).toList();
    
    return PaginationCursor<T>(values);
  }
  
  /// Extract nested value from object map using dot notation
  static dynamic _extractNestedValue(Map<String, dynamic> map, String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic current = map;
    
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }
}

/// Information about an orderBy field for pagination
class OrderByFieldInfo {
  final dynamic fieldPath; // Can be String or FieldPath
  final bool descending;
  final Type fieldType;
  
  const OrderByFieldInfo(this.fieldPath, this.descending, this.fieldType);
  
  @override
  String toString() => 'OrderByFieldInfo($fieldPath, desc: $descending, type: $fieldType)';
}

/// Container for orderBy configuration used in pagination
class OrderByConfiguration {
  final List<OrderByFieldInfo> fields;
  
  const OrderByConfiguration(this.fields);
  
  /// Check if this configuration is empty
  bool get isEmpty => fields.isEmpty;
  
  /// Get field types as a tuple-like representation
  List<Type> get fieldTypes => fields.map((f) => f.fieldType).toList();
  
  @override
  String toString() => 'OrderByConfiguration(${fields.join(', ')})';
}

/// Enhanced OrderByField that carries type information
class TypedOrderByField<T, F> {
  final dynamic field;
  final bool descending;
  final Type fieldType;
  
  const TypedOrderByField(this.field, this.fieldType, {this.descending = false});
  
  /// Convert to basic OrderByField for compatibility
  OrderByField<T> toOrderByField() {
    return OrderByField<T>(field, descending: descending);
  }
  
  /// Get field info for pagination
  OrderByFieldInfo toFieldInfo() {
    final fieldPath = field is String ? field as String : field.toString();
    return OrderByFieldInfo(fieldPath, descending, fieldType);
  }
}

/// Result of orderBy operations that carries type information
class OrderByResult<T, O> {
  final List<TypedOrderByField> fields;
  final OrderByConfiguration configuration;
  
  const OrderByResult(this.fields, this.configuration);
  
  /// Add another orderBy field to the chain
  OrderByResult<T, (O, F)> thenBy<F>(TypedOrderByField<T, F> field) {
    final newFields = [...fields, field];
    final newConfig = OrderByConfiguration([
      ...configuration.fields,
      field.toFieldInfo(),
    ]);
    return OrderByResult<T, (O, F)>(newFields, newConfig);
  }
}

/// Helper class for creating typed orderBy fields
class OrderByHelper {
  /// Create a typed field orderBy
  static TypedOrderByField<T, F> field<T, F>(
    String fieldName,
    Type fieldType, {
    bool descending = false,
  }) {
    return TypedOrderByField<T, F>(fieldName, fieldType, descending: descending);
  }
  
  /// Create a typed document ID orderBy
  static TypedOrderByField<T, String> documentId<T>(
    String fieldName, {
    bool descending = false,
  }) {
    return TypedOrderByField<T, String>(fieldName, String, descending: descending);
  }
}