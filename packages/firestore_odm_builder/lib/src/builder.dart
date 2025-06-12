import 'package:build/build.dart';
import 'firestore_generator.dart';

/// Creates a builder for Firestore ODM code generation
Builder firestoreOdmBuilder(BuilderOptions options) =>
    const FirestoreOdmBuilder();
