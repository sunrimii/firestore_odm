import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/post.dart';
import 'models/simple_story.dart';
import 'models/shared_post.dart';
import 'models/profile.dart';
import 'models/story.dart';

part 'test_schema.odm.dart';

/// Test schema that includes all collections used in existing tests
@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
@Collection<Post>("users/*/posts") // User subcollection
@Collection<SimpleStory>("simpleStories")
@Collection<SharedPost>("sharedPosts") // Different path to avoid conflict
@Collection<SharedPost>("users/*/sharedPosts") // Different subcollection path
final testSchema = _$TestSchema;
