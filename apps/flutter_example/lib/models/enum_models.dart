import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum_models.freezed.dart';
part 'enum_models.g.dart';

enum AccountType {
  @JsonValue('free')
  free,
  @JsonValue('pro')
  pro,
  @JsonValue('enterprise')
  enterprise,
}

@freezed
@firestoreOdm
abstract class EnumUser with _$EnumUser {
  const factory EnumUser({
    @DocumentIdField() required String id,
    required String name,
    required AccountType accountType,
    @Default(AccountType.free) AccountType plan,
    AccountType? optional,
  }) = _EnumUser;

  factory EnumUser.fromJson(Map<String, dynamic> json) => _$EnumUserFromJson(json);
}