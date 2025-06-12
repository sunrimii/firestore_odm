import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'immutable_user.freezed.dart';
part 'immutable_user.g.dart';

@freezed
abstract class ImmutableUser with _$ImmutableUser {
  const ImmutableUser._();

  const factory ImmutableUser({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    @Default(IListConst([])) IList<String> tags,
    @Default(IListConst([])) IList<int> scores,
    @Default(IMapConst({})) IMap<String, String> settings,
    @Default(ISetConst({})) ISet<String> categories,
    @Default(0.0) double rating,
    @Default(false) bool isActive,
    DateTime? createdAt,
  }) = _ImmutableUser;

  factory ImmutableUser.fromJson(Map<String, dynamic> json) =>
      _$ImmutableUserFromJson(json);
}
