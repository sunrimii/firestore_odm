import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'firestore_generator.dart';

/// Creates a builder for Firestore ODM code generation
Builder firestoreOdmBuilder(BuilderOptions options) =>
    PartBuilder([const FirestoreGenerator(), FirestoreGenerator3()], '.odm.dart');