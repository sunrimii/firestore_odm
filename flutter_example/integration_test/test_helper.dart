import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:integration_test/integration_test.dart';

/// Initialize Firebase for integration tests
Future<void> initializeFirebase() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: 'fake-app-id',
        messagingSenderId: 'fake-sender-id',
        projectId: 'demo-project', // This must match emulator project
      ),
    );
  }
  
  final firestore = FirebaseFirestore.instance;
  
  // Configure to use emulator
  try {
    firestore.useFirestoreEmulator('localhost', 8080);
  } catch (e) {
    // Already configured, ignore
  }
}

/// Get configured Firestore instance
FirebaseFirestore getFirestore() => FirebaseFirestore.instance;

/// Clear all collections in Firestore emulator
Future<void> clearFirestoreEmulator([FirebaseFirestore? firestore]) async {
  final targetFirestore = firestore ?? FirebaseFirestore.instance;
  print('🗑️ Clearing Firestore emulator...');
  try {
    // Clear all collections
    final collections = ['users', 'posts', 'profiles', 'simpleStories', 'sharedPosts'];
    
    for (final collectionName in collections) {
      final querySnapshot = await targetFirestore.collection(collectionName).get();
      final batch = targetFirestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Cleared ${querySnapshot.docs.length} documents from $collectionName');
      }
    }
    
    print('✅ Firestore emulator cleared successfully');
  } catch (e) {
    print('❌ Error clearing: $e');
  }
}

/// Wait for documents to be indexed (useful for complex queries)
Future<void> waitForIndexing([Duration delay = const Duration(milliseconds: 500)]) async {
  await Future.delayed(delay);
}