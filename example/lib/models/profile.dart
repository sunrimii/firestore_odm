import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String bio,
    required String avatar,
    required Map<String, String> socialLinks,
    required List<String> interests,
    @Default(0) int followers,
    DateTime? lastActive,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
