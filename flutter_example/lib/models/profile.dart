import 'package:freezed_annotation/freezed_annotation.dart';
import 'story.dart';

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
    Story? story,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp fields
    final processedJson = Map<String, dynamic>.from(json);
    
    // Convert Timestamp to DateTime for lastActive
    if (processedJson['lastActive'] != null && processedJson['lastActive'] is! String) {
      final timestamp = processedJson['lastActive'];
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        processedJson['lastActive'] = (timestamp as dynamic).toDate().toIso8601String();
      }
    }
    
    return _$ProfileFromJson(processedJson);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = _$$ProfileImplToJson(this as _$ProfileImpl);
    // Ensure nested objects are properly serialized
    if (json['story'] is Story) {
      json['story'] = (json['story'] as Story).toJson();
    }
    return json;
  }
}
