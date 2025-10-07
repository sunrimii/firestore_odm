# Firestore ODM Fork - Upgraded Dependencies

This is a fork of [sylphxltd/firestore_odm](https://github.com/sylphxltd/firestore_odm) with upgraded dependencies to resolve version conflicts with modern Flutter apps.

## 🎯 What's Upgraded

### ✅ Successfully Upgraded
- **cloud_firestore**: `^5.0.0` → `^6.0.2` ✨
- **cloud_firestore_platform_interface**: `^6.5.0` → `^7.0.2`
- **Dart SDK**: `^3.8.1` → `^3.9.2`
- **melos**: `^6.3.0` → `^7.1.1`
- **very_good_analysis**: `^9.0.0` → `^10.0.0`

### ⚠️ Known Issues
The codebase currently uses deprecated analyzer APIs (Element → Element2 migration). While the code has deprecation warnings, it **compiles and works correctly**. A full migration to the new analyzer Element2 API is planned but not yet complete.

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  firestore_odm:
    git:
      url: https://github.com/sunrimii/firestore_odm.git
      path: packages/firestore_odm
      ref: main

dev_dependencies:
  firestore_odm_builder:
    git:
      url: https://github.com/sunrimii/firestore_odm.git
      path: packages/firestore_odm_builder
      ref: main
  build_runner: ^2.7.1
```

## 🚀 Usage

Follow the [official documentation](https://sylphxltd.github.io/firestore_odm/guide/getting-started.html) for usage instructions.

### Quick Start

1. Define your model:
```dart
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

2. Define your schema:
```dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

part 'schema.odm.dart';

@Schema()
@Collection<User>("users")
final appSchema = _$AppSchema;
```

3. Generate code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Use it:
```dart
final odm = FirestoreODM(appSchema, firestore: FirebaseFirestore.instance);
await odm.users.insert(User(id: 'user1', name: 'John', email: 'john@example.com'));
final user = await odm.users('user1').get();
```

## ⚙️ Build Configuration

Create a `build.yaml` file in your project root:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

## 🔧 Compatibility

- **Flutter SDK**: `>=3.0.0`
- **Dart SDK**: `^3.9.2`
- **cloud_firestore**: `^6.0.2`

Compatible with apps using:
- `firebase_core: ^4.1.1`
- `firebase_auth: ^6.1.0`
- `freezed: ^3.2.3`
- `json_serializable: ^6.11.1`

## 📝 TODO

- [ ] Complete migration to analyzer Element2 API
- [ ] Upgrade to analyzer ^8.x and source_gen ^4.x
- [ ] Remove all deprecation warnings
- [ ] Add automated tests for the upgraded version

## 🤝 Contributing

This fork is maintained to provide a working version with updated dependencies. Contributions are welcome!

## 📄 License

Same as the original project: BSD-3-Clause

## 🙏 Credits

Original project by [Sylph LTD](https://github.com/sylphxltd/firestore_odm)
