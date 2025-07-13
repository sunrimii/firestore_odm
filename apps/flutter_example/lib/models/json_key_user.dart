import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'json_key_user.freezed.dart';
part 'json_key_user.g.dart';

@freezed
@firestoreOdm
abstract class JsonKeyUser with _$JsonKeyUser {
  const factory JsonKeyUser({
    @DocumentIdField() required String id,
    required String name,
    @JsonKey(name: 'email_address') required String email,
    @JsonKey(name: 'user_age') required int age,
    @JsonKey(includeFromJson: false, includeToJson: false) String? secretField,
    @JsonKey(name: 'is_premium_member') @Default(false) bool isPremium,
    @JsonKey(name: 'account_rating') @Default(0.0) double rating,
    @JsonKey(name: 'created_timestamp') DateTime? createdAt,
    @JsonKey(name: 'last_updated') DateTime? updatedAt,
    @Default([]) List<String> tags,
  }) = _JsonKeyUser;

  factory JsonKeyUser.fromJson(Map<String, dynamic> json) =>
      _$JsonKeyUserFromJson(json);
}
