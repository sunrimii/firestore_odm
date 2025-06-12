import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'models/user.dart';
import 'models/post.dart';
import 'models/simple_story.dart';
import 'models/shared_post.dart';
import 'models/profile.dart';
import 'models/story.dart';
import 'models/immutable_user.dart';
import 'models/json_key_user.dart';
import 'models/dart_immutable_user.dart';
import 'models/manual_user.dart';

part 'test_schema.odm.dart';

/// Test schema that includes all collections used in existing tests.
@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
@Collection<Post>("users/*/posts") // User subcollection
@Collection<SimpleStory>("simpleStories")
@Collection<SharedPost>("sharedPosts") // Different path to avoid conflict
@Collection<SharedPost>("users/*/sharedPosts") // Different subcollection path
@Collection<ImmutableUser>("immutableUsers") // Fast immutable collections test
@Collection<JsonKeyUser>("jsonKeyUsers") // JsonKey annotation test
@Collection<DartImmutableUser>("dartImmutableUsers") // Pure Dart immutable + json_serializable test
@Collection<ManualUser>("manualUsers") // Manual toJson/fromJson implementation test
final testSchema = _$TestSchema;
