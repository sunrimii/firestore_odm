import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// Required for generated extension

part 'shared_post.freezed.dart';
part 'shared_post.g.dart';
part 'shared_post.odm.dart';

/// A Post model that can be used in multiple collections
/// - Standalone collection: @Collection('posts') -> odm.posts
/// - User subcollection: @Collection('users/*/posts') -> odm.users('userId').posts
@freezed
@firestoreOdm
abstract class SharedPost with _$SharedPost {
  const factory SharedPost({
    @DocumentIdField() required String id,
    required String title,
    required String content,
    required String authorId,
    required int likes,
    required bool published,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<String> tags,
  }) = _SharedPost;

  factory SharedPost.fromJson(Map<String, dynamic> json) =>
      _$SharedPostFromJson(json);
}
