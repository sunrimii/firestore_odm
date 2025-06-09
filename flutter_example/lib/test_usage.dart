import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user_data.dart';

void testUsage() {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(firestore: firestore);

  // 主 collection 訪問
  final usersCollection = odm.users; // ✓ 正確
  
  // Subcollection 訪問 - 現在透過 document extension
  // 先取得一個 user document
  final userDoc = usersCollection('userId123'); // ✓ 使用 call 方法
  
  // 透過 document extension 訪問 subcollection
  final dailyMissionsCollection = userDoc.dailyMissions; // ✓ 正確
  
  print('主 collection: $usersCollection');
  print('子 collection: $dailyMissionsCollection');
}