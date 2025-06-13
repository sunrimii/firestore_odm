# Schema Definition

The foundation of the ODM is the **Schema**. The schema is a central definition of your database structure, telling the ODM which collections exist and what data models they use.

## How to Define a Schema

You create a single schema file that defines all your collections. You do this by creating a top-level variable and annotating it with `@Schema()` and one or more `@Collection<Model>(collectionPath)` annotations.

```dart
// lib/schema.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'models/user.dart';
import 'models/post.dart';

part 'schema.odm.dart';

@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
final firestoreDatabase = _$FirestoreDatabase; // The variable name can be anything
```

After defining your schema and models, run the build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates the necessary code to create a type-safe API for your database.

## Using the ODM Instance

You then create an instance of your ODM, which gives you access to your collections.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart'; // Your schema file

final firestore = FirebaseFirestore.instance;

// Create the ODM instance
final db = FirestoreODM(firestoreDatabase, firestore: firestore);

// Now you can access your collections with type-safety
final usersCollection = db.users;
final postsCollection = db.posts;