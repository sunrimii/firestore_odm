
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';

/// Recursively replace special timestamps with FieldValue.serverTimestamp()
Map<String, dynamic> replaceServerTimestamps(Map<String, dynamic> data) {
  final result = <String, dynamic>{};

  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;

    if (value is String && value == FirestoreODM.serverTimestamp.toIso8601String()) {
      result[key] = firestore.FieldValue.serverTimestamp();
    } else if (value is Map<String, dynamic>) {
      result[key] = replaceServerTimestamps(value);
    } else if (value is List) {
      result[key] = value.map((item) {
        if (item is Map<String, dynamic>) {
          return replaceServerTimestamps(item);
        } else if (item is String && item == FirestoreODM.serverTimestamp.toIso8601String()) {
          return firestore.FieldValue.serverTimestamp();
        }
        return item;
      }).toList();
    } else {
      result[key] = value;
    }
  }

  return result;
}