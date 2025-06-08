import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'profile.dart';
import 'story.dart';

part 'user.freezed.dart';
part 'user.g.dart';
part 'user.odm.dart'; // Generated ODM code

@freezed
@CollectionPath('users')
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required int age,
    @Default([]) List<String> tags,
    @Default([]) List<int> scores,
    @Default({}) Map<String, String> settings,
    @Default({}) Map<String, dynamic> metadata,
    required Profile profile, // Nested object
    @Default(0.0) double rating,
    @Default(false) bool isActive,
    @Default(false) bool isPremium,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp fields
    final processedJson = Map<String, dynamic>.from(json);
    
    // Convert Timestamp to DateTime for lastLogin
    if (processedJson['lastLogin'] != null && processedJson['lastLogin'] is! String) {
      final timestamp = processedJson['lastLogin'];
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        processedJson['lastLogin'] = (timestamp as dynamic).toDate().toIso8601String();
      }
    }
    
    // Convert Timestamp to DateTime for createdAt
    if (processedJson['createdAt'] != null && processedJson['createdAt'] is! String) {
      final timestamp = processedJson['createdAt'];
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        processedJson['createdAt'] = (timestamp as dynamic).toDate().toIso8601String();
      }
    }
    
    // Convert Timestamp to DateTime for updatedAt
    if (processedJson['updatedAt'] != null && processedJson['updatedAt'] is! String) {
      final timestamp = processedJson['updatedAt'];
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        processedJson['updatedAt'] = (timestamp as dynamic).toDate().toIso8601String();
      }
    }
    
    return _$UserFromJson(processedJson);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = _$$UserImplToJson(this as _$UserImpl);
    // Ensure nested objects are properly serialized
    if (json['profile'] is Profile) {
      json['profile'] = (json['profile'] as Profile).toJson();
    }
    return json;
  }
}
