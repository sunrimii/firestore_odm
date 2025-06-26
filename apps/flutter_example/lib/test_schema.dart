import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_example/models/list_length_model.dart';
import 'package:flutter_example/models/manual_user2.dart';
import 'package:flutter_example/models/manual_user3.dart';
import 'models/user.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'models/simple_story.dart';
import 'models/shared_post.dart';
import 'models/profile.dart';
import 'models/story.dart';
import 'models/immutable_user.dart';
import 'models/json_key_user.dart';
import 'models/dart_immutable_user.dart';
import 'models/manual_user.dart';
import 'models/task.dart';
import 'models/simple_generic.dart';

part 'test_schema.odm.dart';

/// Test schema that includes all collections used in existing tests.
@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
@Collection<Post>("users/*/posts") // User subcollection
@Collection<User>("users2") // Second User collection WITHOUT posts subcollection
@Collection<Comment>("comments") // Root comments collection
@Collection<Comment>("posts/*/comments") // Comments on posts in main collection
@Collection<Comment>("users/*/posts/*/comments") // Nested: Comments on user posts (DEEP NESTING)
@Collection<SimpleStory>("simpleStories")
@Collection<SharedPost>("sharedPosts") // Different path to avoid conflict
@Collection<SharedPost>("users/*/sharedPosts") // Different subcollection path
@Collection<ImmutableUser>("immutableUsers") // Fast immutable collections test
@Collection<JsonKeyUser>("jsonKeyUsers") // JsonKey annotation test
@Collection<DartImmutableUser>(
  "dartImmutableUsers",
) // Pure Dart immutable + json_serializable test
@Collection<ManualUser>(
  "manualUsers",
) // Manual toJson/fromJson implementation test
@Collection<ManualUser2>(
  "manualUsers2",
) // without toJson/fromJson implementation test
@Collection<ManualUser3<ManualUser3Profile<Book>>>(
  "manualUsers3",
) // complicated generic without toJson/fromJson implementation test

@Collection<ManualUser3<ManualUser3Profile<String>>>(
  "manualUsers3Strings", // different collection name to avoid conflicts
) // complicated generic with different type parameter test

@Collection<Task>("tasks") // Duration field test
@Collection<ListLengthModel>(
  "listLengthModels",
) // IList with JsonConverter test
@Collection<StringGeneric>("stringGenerics") // Generic collection test
final testSchema = _$TestSchema;
