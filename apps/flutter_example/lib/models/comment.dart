import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    @DocumentIdField() required String id,
    required String content,
    required String authorId,
    required String authorName,
    required String postId,
    @Default(0) int likes,
    @Default(false) bool isEdited,
    DateTime? editedAt,
    required DateTime createdAt,
    List<String>? mentions,
    String? parentCommentId, // For nested replies
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}