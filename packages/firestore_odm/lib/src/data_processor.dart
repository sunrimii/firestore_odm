
/// Core data processing utilities for Firestore ODM
class FirestoreDataProcessor {
  /// Process Firestore data, converting Timestamps to DateTime strings
  static Map<String, dynamic> processFirestoreData(
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

  /// Ensure all objects are properly serialized for Firestore storage
  static Map<String, dynamic> serializeForFirestore(Map<String, dynamic> json) {
    return _serializeValue(json) as Map<String, dynamic>;
  }

  /// Process any value, converting Timestamps to ISO strings recursively
  static dynamic _processValue(dynamic value) {
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

  /// Process any value for serialization, handling Freezed objects
  static dynamic _serializeValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        result[entry.key] = _serializeValue(entry.value);
      }
      return result;
    } else if (value is List) {
      return value.map((item) => _serializeValue(item)).toList();
    }

    // Handle Freezed objects - check if they have toJson() method
    try {
      // Try to call toJson method
      final json = (value as dynamic).toJson();
      if (json is Map<String, dynamic>) {
        return _serializeValue(json);
      }
    } catch (e) {
      // Not a Freezed object or doesn't have toJson, continue
    }

    // For primitive types and objects without toJson
    return value;
  }

  /// Check if a value is a Firestore Timestamp
  static bool _isTimestamp(dynamic value) {
    if (value == null) return false;

    // First try to call toDate method - most reliable test
    try {
      final result = (value as dynamic).toDate();
      return result is DateTime;
    } catch (e) {
      // If toDate fails, check string representations
      try {
        final runtimeType = value.runtimeType.toString();
        final stringValue = value.toString();
        return runtimeType.contains('Timestamp') ||
            stringValue.contains('Timestamp') ||
            runtimeType == 'Timestamp';
      } catch (e2) {
        return false;
      }
    }
  }

  static T fromJson<T>(
    T Function(Map<String, dynamic>) fromJsonFunction,
    Map<String, dynamic> json, {
    String? documentIdField,
    String? documentId,
  }) {
    // Process the JSON data

    final processedData = processFirestoreData(
      json,
      documentIdField: documentIdField,
      documentId: documentId,
    );
    return fromJsonFunction(processedData);
  }

  static Map<String, dynamic> toJson<T>(
    Map<String, dynamic> Function(T) toJsonFunction,
    T data, {
    String? documentIdField,
    String? documentId,
  }) {
    return serializeForFirestore(
      toJsonAndDocumentId(
        toJsonFunction,
        data,
        documentIdField: documentIdField,
      ).$1,
    );
  }

  static (Map<String, dynamic>, String?) toJsonAndDocumentId<T>(
    Map<String, dynamic> Function(T) toJsonFunction,
    T data, {
    String? documentIdField,
  }) {
    // Process the data to ensure it is ready for Firestore storage
    final mapData = toJsonFunction(data);
    final documentId = DocumentIdHandler.extractDocumentId(
      mapData,
      documentIdField,
    );
    DocumentIdHandler.validateDocumentId(documentId, documentIdField);

    final processedData = DocumentIdHandler.removeDocumentIdField(
      mapData,
      documentIdField,
    );

    // Serialize the data for Firestore storage
    return (serializeForFirestore(processedData), documentId);
  }
}

/// Helper for handling Document ID fields
class DocumentIdHandler {
  /// Extract document ID field value from object JSON
  static String? extractDocumentId(
    Map<String, dynamic> json,
    String? documentIdField,
  ) {
    if (documentIdField == null) return null;
    return json[documentIdField] as String?;
  }

  /// Remove document ID field from JSON for Firestore storage
  static Map<String, dynamic> removeDocumentIdField(
    Map<String, dynamic> json,
    String? documentIdField,
  ) {
    final result = Map<String, dynamic>.from(json);
    if (documentIdField != null) {
      result.remove(documentIdField);
    }
    return result;
  }

  /// Validate document ID for upsert operations
  static void validateDocumentId(String? documentId, String? fieldName) {
    if (fieldName != null && (documentId == null || documentId.isEmpty)) {
      throw ArgumentError(
        'Document ID field \'$fieldName\' must not be null or empty for upsert operation',
      );
    }
  }
}
