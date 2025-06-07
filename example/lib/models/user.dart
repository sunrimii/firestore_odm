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

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
