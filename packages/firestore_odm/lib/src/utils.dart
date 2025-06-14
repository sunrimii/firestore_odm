import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/model_converter.dart';

T fromFirestoreData<T>(
  JsonDeserializer<T> fromJsonFunction,
  Map<String, dynamic> json,
  String documentIdField,
  String documentId,
) {
  // Process the JSON data

  final processedData = processFirestoreData(
    json,
    documentIdField: documentIdField,
    documentId: documentId,
  );
  return fromJsonFunction(processedData);
}

Map<String, dynamic> processFirestoreData(
  Map<String, dynamic> data, {
  String? documentIdField,
  String? documentId,
}) {
  final result = Map<String, dynamic>.from(data);

  // Add document ID field if specified
  if (documentIdField != null && documentId != null) {
    result[documentIdField] = documentId;
  }

  // Process all values recursively to convert Timestamps
  return _processValue(result) as Map<String, dynamic>;
}

dynamic _processValue(dynamic value) {
  if (value == null) {
    return null;
  }

  // Try to convert any potential Timestamp first
  try {
    // Try calling toDate() on any object - if it works, it's a Timestamp
    final dateTime = (value as dynamic).toDate() as DateTime;
    return dateTime.toIso8601String();
  } catch (e) {
    // Not a Timestamp, continue with other processing
  }

  // Try string detection as fallback
  try {
    final runtimeType = value.runtimeType.toString();
    final stringValue = value.toString();
    if (runtimeType.contains('Timestamp') ||
        stringValue.contains('Timestamp')) {
      final timestamp = value as dynamic;
      final dateTime = timestamp.toDate() as DateTime;
      return dateTime.toIso8601String();
    }
  } catch (e) {
    // Continue with normal processing
  }

  if (value is Map<String, dynamic>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      result[entry.key] = _processValue(entry.value);
    }
    return result;
  } else if (value is List) {
    return value.map((item) => _processValue(item)).toList();
  } else {
    return value;
  }
}

Map<String, dynamic> toFirestoreData<T>(
  JsonSerializer<T> toJsonFunction,
  T data, {
  String? documentIdField,
}) {
  final mapData = toJsonFunction(data);
  return removeDocumentIdField(mapData, documentIdField);
}

(Map<String, dynamic>, String) processObject<T>(
  JsonSerializer<T> toJsonFunction,
  T data, {
  String? documentIdField,
}) {
  // Process the data to ensure it is ready for Firestore storage
  final mapData = toJsonFunction(data);
  final documentId = extractDocumentId(mapData, documentIdField);
  final processedData = removeDocumentIdField(mapData, documentIdField);

  // Serialize the data for Firestore storage
  return (processedData, documentId);
}

String extractDocumentId(Map<String, dynamic> json, String? documentIdField) {
  if (documentIdField == null) return '';
  return json[documentIdField] as String? ?? '';
}

void validateDocumentId(
  String? documentId,
  String? fieldName, {
  bool isInsert = false,
}) {
  // if it is an insert operation, allow empty string for auto ID generation
  if (isInsert && documentId == null) {
    return; // Allow null for insert operation
  }

  // Validate that the document ID is not null or empty
  if (fieldName != null && (documentId == null || documentId.isEmpty)) {
    throw ArgumentError(
      'Document ID field \'$fieldName\' must not be null or empty for upsert operation',
    );
  }
}

Map<String, dynamic> removeDocumentIdField(
  Map<String, dynamic> json,
  String? documentIdField,
) {
  final result = Map<String, dynamic>.from(json);
  if (documentIdField != null) {
    result.remove(documentIdField);
  }
  return result;
}

// Map<String, dynamic> serializeForFirestore(Map<String, dynamic> json) {
//   return _serializeValue(json) as Map<String, dynamic>;
// }

// dynamic _serializeValue(dynamic value) {
//   if (value == null) {
//     return null;
//   }

//   if (value is Map<String, dynamic>) {
//     final result = <String, dynamic>{};
//     for (final entry in value.entries) {
//       result[entry.key] = _serializeValue(entry.value);
//     }
//     return result;
//   } else if (value is List) {
//     return value.map((item) => _serializeValue(item)).toList();
//   }

//   // Handle Freezed objects - check if they have toJson() method
//   try {
//     // Try to call toJson method
//     final json = (value as dynamic).toJson();
//     if (json is Map<String, dynamic>) {
//       return _serializeValue(json);
//     }
//   } catch (e) {
//     // Not a Freezed object or doesn't have toJson, continue
//   }

//   // For primitive types and objects without toJson
//   return value;
// }

List<T> processQuerySnapshot<T>(
  firestore.QuerySnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromMap,
  String documentIdField,
) {
  if (snapshot.docs.isEmpty) return [];
  return snapshot.docs
      .map((doc) => processDocumentSnapshot<T>(doc, fromMap, documentIdField))
      .toList();
}

T processDocumentSnapshot<T>(
  firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromMap,
  String documentIdField,
) {
  if (!snapshot.exists) {
    throw StateError('Document does not exist: ${snapshot.id}');
  }
  return fromFirestoreData<T>(
    fromMap,
    snapshot.data()!,
    documentIdField,
    snapshot.id,
  );
}

T resolveJsonWithParts<T>(Map<String, dynamic> json, List<String> parts) {
  dynamic current = json;

  for (final part in parts) {
    if (current == null) {
      throw ArgumentError(
        'Cannot resolve path ${parts.join(".")} - null encountered at "$part"',
      );
    }

    // Check if it's a numeric index (array access)
    if (RegExp(r'^\d+$').hasMatch(part)) {
      final index = int.parse(part);
      if (current is List) {
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          throw RangeError(
            'Index $index out of bounds for array of length ${current.length} at path ${parts.join(".")}',
          );
        }
      } else {
        throw ArgumentError(
          'Expected List but found ${current.runtimeType} when accessing index "$part" in path ${parts.join(".")}',
        );
      }
    } else {
      // 字符串鍵 (object access)
      if (current is Map<String, dynamic>) {
        if (current.containsKey(part)) {
          current = current[part];
        } else {
          throw ArgumentError(
            'Key "$part" not found in object at path ${parts.join(".")}',
          );
        }
      } else {
        throw ArgumentError(
          'Expected Map but found ${current.runtimeType} when accessing key "$part" in path ${parts.join(".")}',
        );
      }
    }
  }

  // 類型檢查並轉換
  if (current is T) {
    return current;
  } else {
    throw ArgumentError(
      'Expected type $T but found ${current.runtimeType} at path ${parts.join(".")}. Value: $current',
    );
  }
}

T defaultValue<T>() {
  // 處理 nullable 類型
  if (null is T) return null as T;

  // 數字類型
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == num) return 0 as T;

  // 布爾類型
  if (T == bool) return false as T;

  // 字符串類型
  if (T == String) return '' as T;

  // 集合類型 - 使用反射檢查
  final typeString = T.toString();
  if (typeString.startsWith('List<')) return <dynamic>[] as T;
  if (typeString.startsWith('Set<')) return <dynamic>{} as T;
  if (typeString.startsWith('Map<')) return <String, dynamic>{} as T;

  // DateTime
  if (T == DateTime) return DateTime.fromMillisecondsSinceEpoch(0) as T;

  // Duration
  if (T == Duration) return Duration.zero as T;

  // 無法處理的類型
  throw UnsupportedError('Cannot create default value for type $T');
}
