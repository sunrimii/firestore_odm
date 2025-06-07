import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

/// Example demonstrating RxDB-style API usage
void main() async {
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('user123');

  // Example 1: incrementalModify - automatically uses atomic operations
  await userDoc.incrementalModify((user) {
    // This will use FieldValue.increment(1) automatically
    user = user.copyWith(age: user.age + 1);
    
    // This will use FieldValue.arrayUnion(['flutter']) automatically
    user = user.copyWith(tags: [...user.tags, 'flutter']);
    
    return user;
  });

  // Example 2: modify - only computes differences, no atomic operations
  await userDoc.modify((user) {
    return user.copyWith(
      name: 'Updated Name',
      email: 'new@email.com',
    );
  });

  // Example 3: Strong-typed update (like copyWith but for Firestore)
  await userDoc.update(
    name: 'John Doe',
    age: 30,
    tags: ['developer', 'flutter'],
  );

  // Example 4: Manual field updates with FieldValue operations
  await userDoc.updateFields({
    'age': FieldValue.increment(5),
    'tags': FieldValue.arrayUnion(['dart']),
    'lastLogin': FieldValue.serverTimestamp(),
  });

  // Example 5: Get document data
  final user = await userDoc.get();
  print('User: ${user?.name}, Age: ${user?.age}');

  // Example 6: Listen to real-time changes
  userDoc.changes.listen((user) {
    if (user != null) {
      print('User updated: ${user.name}');
    }
  });
}

/// Advanced examples showing atomic operation detection
void atomicOperationExamples() async {
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('user456');

  // These will be automatically converted to atomic operations:
  
  await userDoc.incrementalModify((user) {
    // ✅ Numeric increment: age + 1 → FieldValue.increment(1)
    user = user.copyWith(age: user.age + 1);
    
    // ✅ Array addition: [...tags, 'new'] → FieldValue.arrayUnion(['new'])
    user = user.copyWith(tags: [...user.tags, 'newbie']);
    
    // ✅ Array removal: tags.where((t) => t != 'old') → FieldValue.arrayRemove(['old'])
    user = user.copyWith(tags: user.tags.where((t) => t != 'beginner').toList());
    
    return user;
  });

  // These will use regular field updates:
  
  await userDoc.modify((user) {
    // Regular field update (no atomic operation)
    return user.copyWith(
      name: 'New Name',
      email: 'updated@email.com',
    );
  });
}

/// Comparison with traditional Firestore operations
void comparisonExample() async {
  final odm = FirestoreODM();
  final userDoc = odm.users.doc('comparison');

  // ❌ Traditional Firestore way (error-prone, no type safety)
  // await userDoc.ref.update({
  //   'age': FieldValue.increment(1),
  //   'tags': FieldValue.arrayUnion(['flutter']),
  //   'nam': 'John', // ← Typo! No compile-time checking
  // });

  // ✅ RxDB-style way (type-safe, automatic atomic operations)
  await userDoc.incrementalModify((user) {
    return user.copyWith(
      age: user.age + 1,  // Automatically becomes FieldValue.increment(1)
      tags: [...user.tags, 'flutter'],  // Automatically becomes FieldValue.arrayUnion(['flutter'])
      name: 'John',  // Compile-time type checking!
    );
  });

  // ✅ Strong-typed updates (like copyWith for Firestore)
  await userDoc.update(
    name: 'John Doe',  // Type-safe field names
    age: 30,          // Correct types enforced
    // email: 123,    // ← This would be a compile error!
  );
}