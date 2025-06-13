# Data Modeling

The ODM is designed to be unopinionated about how you create your data models. It supports a variety of popular modeling styles and packages, allowing you to choose the approach that best fits your project.

## Using `freezed` (Recommended)

We recommend using the [freezed](https://pub.dev/packages/freezed) package to create your models. It generates robust, immutable classes with `copyWith`, `==`, and `toString()` methods, reducing boilerplate and preventing common errors.

```dart
// lib/models/user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Using Plain Dart Classes with `json_serializable`

If you prefer full control, you can use plain Dart classes and rely on the [json_serializable](https://pub.dev/packages/json_serializable) package for serialization.

```dart
// lib/models/task.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  @DocumentIdField()
  final String id;
  final String description;
  final bool isCompleted;

  Task({required this.id, required this.description, this.isCompleted = false});

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
```

## Using `fast_immutable_collections`

For applications requiring high-performance, truly immutable collections, the ODM seamlessly integrates with the [fast_immutable_collections](https://pub.dev/packages/fast_immutable_collections) package. Simply use `IList`, `IMap`, or `ISet` in your models.

```dart
// lib/models/immutable_user.dart
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'immutable_user.freezed.dart';
part 'immutable_user.g.dart';

@freezed
class ImmutableUser with _$ImmutableUser {
  const factory ImmutableUser({
    @DocumentIdField() required String id,
    required String name,
    required IList<String> tags,
    required IMap<String, String> settings,
    required ISet<String> categories,
  }) = _ImmutableUser;

  factory ImmutableUser.fromJson(Map<String, dynamic> json) => _$ImmutableUserFromJson(json);
}
```

## Customizing Field Names with `@JsonKey`

The ODM fully respects `@JsonKey` annotations from the `json_annotation` package. This allows you to use different field names in your Dart models than what is stored in Firestore. This is particularly useful when working with existing databases that have different naming conventions (e.g., `snake_case`).

You can also use `@JsonKey` to ignore fields during serialization.

```dart
// lib/models/json_key_user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'json_key_user.g.dart';

@JsonSerializable()
class JsonKeyUser {
  @DocumentIdField()
  final String id;

  // 'email' in Dart, but 'email_address' in Firestore
  @JsonKey(name: 'email_address')
  final String email;

  // 'isPremium' in Dart, but 'is_premium_member' in Firestore
  @JsonKey(name: 'is_premium_member')
  final bool isPremium;

  // This field will not be saved to or read from Firestore
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? secretField;

  JsonKeyUser({
    required this.id,
    required this.email,
    required this.isPremium,
    this.secretField,
  });

  factory JsonKeyUser.fromJson(Map<String, dynamic> json) => _$JsonKeyUserFromJson(json);
  Map<String, dynamic> toJson() => _$JsonKeyUserToJson(this);
}