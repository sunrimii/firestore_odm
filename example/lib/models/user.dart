import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
