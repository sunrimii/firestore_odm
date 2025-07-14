import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Represents a user in the Firestore database.
@freezed
@firestoreOdm
abstract class User with _$User {
  /// Creates a new User instance.
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    required Profile profile, // Nested object, @Default([]) List<String> tags,
    @Default([]) List<int> scores,
    @Default({}) Map<String, String> settings,
    @Default({}) Map<String, dynamic> metadata,
    @Default(0.0) double rating,
    @Default(false) bool isActive,
    @Default(false) bool isPremium,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  /// Creates a User instance from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
