# Document ID

A critical feature of this ODM is its seamless and automatic handling of Firestore document IDs.

## The Role of the Document ID

Every document in Firestore has a unique ID. In your data model, you need a corresponding field to hold this ID. This is essential for the ODM to know which document to create, read, update, or delete.

By default, the ODM assumes this field is named `id`.

## The `@DocumentIdField` Annotation

You can designate any `String` field in your model as the document ID container by using the `@DocumentIdField()` annotation.

```dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    // This field will now be used as the document ID
    @DocumentIdField() required String uid,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Automatic Synchronization

The most important concept to understand is that the value of the field annotated with `@DocumentIdField` is **never actually stored within the Firestore document's data**.

The ODM handles the synchronization for you automatically:

-   **When writing data (e.g., `insert`, `upsert`)**: The ODM takes the value from your annotated field (e.g., `uid: 'jane-doe'`) and uses it as the actual Firestore document ID. The `uid` field itself is not saved in the document's `fields`.
-   **When reading data (e.g., `get`, `stream`)**: The ODM fetches the document, reads its actual Firestore ID, and automatically populates the annotated field in your model object.

This ensures that your model always has access to the document ID, but you never store redundant data in Firestore, keeping your database clean and efficient.