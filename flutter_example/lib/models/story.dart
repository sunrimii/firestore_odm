import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';
part 'story.g.dart';

@freezed
class Story with _$Story {
  const factory Story({
    required String name,
    required String content,
    required Place place,
    @Default([]) List<String> tags,
    DateTime? publishedAt,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$$StoryImplToJson(this as _$StoryImpl);
    // Ensure nested objects are properly serialized
    if (json['place'] is Place) {
      json['place'] = (json['place'] as Place).toJson();
    }
    return json;
  }
}

@freezed
class Place with _$Place {
  const factory Place({
    required String name,
    required String address,
    required Coordinates coordinates,
    @Default({}) Map<String, String> metadata,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$$PlaceImplToJson(this as _$PlaceImpl);
    // Ensure nested objects are properly serialized
    if (json['coordinates'] is Coordinates) {
      json['coordinates'] = (json['coordinates'] as Coordinates).toJson();
    }
    return json;
  }
}

@freezed
class Coordinates with _$Coordinates {
  const factory Coordinates({
    required double latitude,
    required double longitude,
    double? altitude,
  }) = _Coordinates;

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$$CoordinatesImplToJson(this as _$CoordinatesImpl);
}
