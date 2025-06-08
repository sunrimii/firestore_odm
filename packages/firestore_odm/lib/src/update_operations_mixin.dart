import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data_processor.dart';

/// **Special constant for server timestamps**
///
/// Use this constant in your DateTime fields when you want to set server timestamp.
/// The system will automatically replace this with FieldValue.serverTimestamp().
///
/// Default: January 1, 1900 at 00:00:10 UTC (a time rarely used in real applications)
///
/// Example:
/// ```dart
/// await userDoc.modify((user) => user.copyWith(
///   lastLogin: FirestoreODM.serverTimestamp, // Becomes server timestamp
/// ));
/// ```
DateTime get serverTimestamp => _currentServerTimestamp;

/// Internal variable to store the current server timestamp constant
DateTime _currentServerTimestamp = DateTime.utc(1900, 1, 1, 0, 0, 10);

/// Mixin for shared update operations that can be used by both documents and queries
mixin UpdateOperationsMixin<T> {
  /// Get the special timestamp that should be replaced with server timestamp
  DateTime get specialTimestamp;
  
  /// Get the toJson function for the model
  Map<String, dynamic> Function(T value) get toJson;
  
  /// Get the fromJson function for the model  
  T Function(Map<String, dynamic> data, [String? documentId]) get fromJson;
  
  /// Process data for updates, replacing special timestamps with server timestamps
  Map<String, dynamic> processUpdateData(Map<String, dynamic> data) {
    return _replaceSpecialTimestamps(data, specialTimestamp);
  }
  
  /// Recursively replace special timestamps with FieldValue.serverTimestamp()
  Map<String, dynamic> _replaceSpecialTimestamps(Map<String, dynamic> data, DateTime specialTimestamp) {
    final result = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is DateTime && value == specialTimestamp) {
        result[key] = FieldValue.serverTimestamp();
      } else if (value is Map<String, dynamic>) {
        result[key] = _replaceSpecialTimestamps(value, specialTimestamp);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _replaceSpecialTimestamps(item, specialTimestamp);
          } else if (item is DateTime && item == specialTimestamp) {
            return FieldValue.serverTimestamp();
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }
  
  /// Compute the difference between old and new data for efficient updates
  Map<String, dynamic> computeDiff(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final result = <String, dynamic>{};

    // Find removed fields
    for (final key in oldData.keys) {
      if (!newData.containsKey(key)) {
        result[key] = FieldValue.delete();
      }
    }

    // Find added or changed fields
    for (final entry in newData.entries) {
      final key = entry.key;
      final newValue = entry.value;

      if (!oldData.containsKey(key) || oldData[key] != newValue) {
        result[key] = newValue;
      }
    }

    return result;
  }

  /// Analyzes changes and converts them to atomic operations where possible
  Map<String, dynamic> computeDiffWithAtomicOperations(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final result = <String, dynamic>{};

    // Find removed fields
    for (final key in oldData.keys) {
      if (!newData.containsKey(key)) {
        result[key] = FieldValue.delete();
      }
    }

    // Find added or changed fields with atomic operation detection
    for (final entry in newData.entries) {
      final key = entry.key;
      final newValue = entry.value;
      final oldValue = oldData[key];

      if (!oldData.containsKey(key)) {
        // New field
        result[key] = newValue;
      } else if (oldValue != newValue) {
        // Changed field - try to detect atomic operations
        final atomicOp = _detectAtomicOperation(oldValue, newValue);
        if (atomicOp != null) {
          result[key] = atomicOp;
        } else if (oldValue is Map && newValue is Map) {
          // Handle nested objects - check if it's an empty map (deletion scenario)
          if (newValue.isEmpty && oldValue.isNotEmpty) {
            // Empty map means we want to clear all nested fields
            result[key] = newValue; // Set to empty map
          } else {
            // For other nested changes, use the new value
            result[key] = newValue;
          }
        } else {
          result[key] = newValue;
        }
      }
    }

    return result;
  }

  /// Detects if a change can be represented as an atomic operation
  dynamic _detectAtomicOperation(dynamic oldValue, dynamic newValue) {
    // Numeric increment detection
    if (oldValue is num && newValue is num) {
      final diff = newValue - oldValue;
      if (diff != 0) {
        return FieldValue.increment(diff);
      }
    }

    // Array operations detection
    if (oldValue is List && newValue is List) {
      final oldSet = Set.from(oldValue);
      final newSet = Set.from(newValue);

      final added = newSet.difference(oldSet).toList();
      final removed = oldSet.difference(newSet).toList();

      // If only additions, use arrayUnion
      if (removed.isEmpty && added.isNotEmpty) {
        return FieldValue.arrayUnion(added);
      }

      // If only removals, use arrayRemove
      if (added.isEmpty && removed.isNotEmpty) {
        return FieldValue.arrayRemove(removed);
      }

      // For mixed operations or when trying to add duplicates, fall back to direct assignment
      // Note: arrayUnion naturally handles duplicates by not adding them again
    }

    // No atomic operation detected
    return null;
  }
  
  /// Recursively serializes nested objects to ensure compatibility with fake_cloud_firestore
  Map<String, dynamic> deepSerialize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result[key] = null;
      } else if (value is Map<String, dynamic>) {
        result[key] = deepSerialize(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return deepSerialize(item);
          } else if (_isFreezedObject(item)) {
            // This is a Freezed object, serialize it
            return deepSerialize(
                (item as dynamic).toJson() as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else if (_isFreezedObject(value)) {
        // This is a Freezed object, serialize it
        result[key] =
            deepSerialize((value as dynamic).toJson() as Map<String, dynamic>);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Check if an object is a Freezed-generated object
  bool _isFreezedObject(dynamic obj) {
    if (obj == null) return false;
    final typeName = obj.runtimeType.toString();
    // Check for Freezed patterns: ends with 'Impl' or contains '$'
    return typeName.contains('Impl') ||
           typeName.contains('\$') ||
           (obj is Object && obj.toString().startsWith('_\$'));
  }
}