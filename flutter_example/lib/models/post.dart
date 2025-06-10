import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
abstract class Post with _$Post {
  const factory Post({
    @DocumentIdField() required String id,
    required String title,
    required String content,
    required String authorId,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    @Default(0) int likes,
    @Default(0) int views,
    @Default(false) bool published,
    DateTime? publishedAt,
    DateTime? updatedAt,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
