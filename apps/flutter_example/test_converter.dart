import 'dart:convert';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'lib/models/immutable_user.dart';
import 'lib/test_schema.dart';

void main() {
  print('🧪 Testing ImmutableUser toFirestore conversion...\n');
  
  // 測試 ImmutableUser 的 toFirestore 轉換
  final user = ImmutableUser(
    id: 'test123',
    name: 'Test User',
    email: 'test@example.com',
    age: 25,
    tags: IList(['tag1', 'tag2']),
    scores: IList([100, 200]),
    settings: IMap({'theme': 'dark', 'lang': 'en'}),
    categories: ISet(['cat1', 'cat2']),
    rating: 4.5,
    isActive: true,
    createdAt: DateTime.now(),
  );

  final converter = ImmutableUserConverter();
  final firestoreData = converter.toFirestore(user);
  
  print('📋 Original data:');
  print('  IList tags: ${user.tags} (${user.tags.runtimeType})');
  print('  IList scores: ${user.scores} (${user.scores.runtimeType})');
  print('  IMap settings: ${user.settings} (${user.settings.runtimeType})');
  print('  ISet categories: ${user.categories} (${user.categories.runtimeType})');
  
  print('\n🔄 Converted data:');
  print('  tags: ${firestoreData['tags']} (${firestoreData['tags'].runtimeType})');
  print('  scores: ${firestoreData['scores']} (${firestoreData['scores'].runtimeType})');
  print('  settings: ${firestoreData['settings']} (${firestoreData['settings'].runtimeType})');
  print('  categories: ${firestoreData['categories']} (${firestoreData['categories'].runtimeType})');
  
  // 測試是否可以 JSON 序列化
  try {
    final jsonString = jsonEncode(firestoreData);
    print('\n✅ JSON serialization successful!');
    print('📄 JSON preview: ${jsonString.substring(0, 150)}...');
    
    // 測試反序列化
    final decoded = jsonDecode(jsonString);
    final restoredUser = converter.fromFirestore(decoded);
    print('\n✅ Round-trip conversion successful!');
    print('🔄 Restored user: ${restoredUser.name} with ${restoredUser.tags.length} tags');
    
  } catch (e) {
    print('\n❌ JSON serialization failed: $e');
  }
}