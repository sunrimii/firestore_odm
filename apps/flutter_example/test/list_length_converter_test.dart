import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_example/models/list_length_model.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🔄 List Length Converter Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should convert IList to int and back with JsonConverter', () async {
      // Create model with IList data
      final model = ListLengthModel(
        id: 'converter_test',
        name: 'JsonConverter Test',
        description: 'Testing IList to int conversion',
        items: ['flutter', 'dart', 'firestore'].toIList(), // Length = 3
        numbers: [10, 20, 30].toIList(), // Sum = 60
        tags: ['test', 'converter'].toIList(), // No converter
        priority: 1,
        isActive: true,
      );

      // Save to Firestore
      await odm.listLengthModels(model.id).update(model);

      // Check raw Firestore data to verify conversion
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      // Verify JsonConverter worked: IList -> int
      expect(rawData['items'], equals(3)); // Length stored as int
      expect(rawData['numbers'], equals(60)); // Sum stored as int
      expect(rawData['tags'], equals(['test', 'converter'])); // No conversion

      // Retrieve through ODM to verify back conversion
      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved, isNotNull);

      // Verify JsonConverter worked: int -> IList
      expect(retrieved!.items.length, equals(3));
      expect(retrieved.items, equals(['item_0', 'item_1', 'item_2'].toIList()));
      expect(retrieved.numbers.length, equals(1));
      expect(retrieved.numbers.first, equals(60));
      expect(retrieved.tags, equals(['test', 'converter'].toIList()));

      print('✅ JsonConverter working: List ↔ int conversion successful');
    });

    test('should patch IList fields using chain syntax', () async {
      final model = ListLengthModel(
        id: 'patch_test',
        name: 'Patch Test',
        description: 'Testing patch operations',
        items: ['initial'].toIList(),
        numbers: [50].toIList(),
        tags: ['tag1'].toIList(),
        priority: 1,
        isActive: false,
      );

      await odm.listLengthModels(model.id).update(model);

      // Patch using chain syntax
      await odm.listLengthModels(model.id).patch(($) => [
            $.items(['new', 'items', 'list'].toIList()),
            $.numbers([25, 25, 50].toIList()),
            $.tags(['updated', 'tags'].toIList()),
            $.priority.increment(1),
            $.isActive(true),
          ]);

      // Verify patch worked
      final patched = await odm.listLengthModels(model.id).get();
      expect(patched, isNotNull);
      expect(patched!.priority, equals(2)); // Incremented
      expect(patched.isActive, isTrue);

      // Check raw data to verify JsonConverter during patch
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(3)); // New length
      expect(rawData['numbers'], equals(100)); // New sum (25+25+50)
      expect(rawData['tags'], equals(['updated', 'tags'])); // No conversion

      print('✅ Patch operations with JsonConverter working correctly');
    });

    test('should handle nestedProfiles operations without converter', () async {
      final profile1 = Profile(
        bio: 'Flutter Developer',
        avatar: 'avatar1.jpg',
        socialLinks: {'twitter': '@flutter_dev'},
        interests: ['flutter', 'dart'],
        followers: 100,
      );

      final profile2 = Profile(
        bio: 'Backend Engineer',
        avatar: 'avatar2.jpg',
        socialLinks: {'github': 'backend_guru'},
        interests: ['node', 'python'],
        followers: 200,
      );

      final model = ListLengthModel(
        id: 'nested_profiles_test',
        name: 'Nested Profiles Test',
        description: 'Testing nested profiles operations',
        nestedProfiles: [profile1, profile2].toIList(),
        items: ['item1', 'item2'].toIList(),
        numbers: [10, 20].toIList(),
      );

      await odm.listLengthModels(model.id).update(model);

      // Verify raw data - nestedProfiles should be stored as objects array
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['nestedProfiles'], isA<List>());
      expect(rawData['nestedProfiles'].length, equals(2));
      expect(rawData['items'], equals(2)); // Converted to length
      expect(rawData['numbers'], equals(30)); // Converted to sum

      // Retrieve and verify
      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved!.nestedProfiles.length, equals(2));
      expect(retrieved.nestedProfiles.first.bio, equals('Flutter Developer'));
      expect(retrieved.nestedProfiles[1].followers, equals(200));

      print('✅ NestedProfiles stored and retrieved correctly without conversion');
    });

    test('should demonstrate numbers increment limitation (converter prevents atomic ops)', () async {
      final model = ListLengthModel(
        id: 'increment_test',
        name: 'Increment Test',
        description: 'Testing increment limitations',
        numbers: [100].toIList(),
        priority: 1,
      );

      await odm.listLengthModels(model.id).update(model);

      // This should work fine - priority is a regular int field
      await odm.listLengthModels(model.id).patch(($) => [
            $.priority.increment(5),
          ]);

      final afterPriorityIncrement = await odm.listLengthModels(model.id).get();
      expect(afterPriorityIncrement!.priority, equals(6)); // 1 + 5

      // However, you CANNOT increment numbers because it's converted to sum
      // The following would be conceptually wrong because numbers is converted to int (sum)
      // await odm.listLengthModels(model.id).patch(($) => [
      //   $.numbers.increment(10), // This doesn't make sense - increment a sum?
      // ]);

      print('✅ Priority increment works, but numbers increment not applicable');
      print('⚠️  Numbers field is converted to sum - increment semantics unclear');
    });

    test('should demonstrate array operations limitation on converted fields', () async {
      final model = ListLengthModel(
        id: 'array_ops_test',
        name: 'Array Operations Test',
        description: 'Testing array operation limitations',
        numbers: [10, 20, 30].toIList(),
        tags: ['tag1', 'tag2'].toIList(), // Regular array - supports atomic ops
      );

      await odm.listLengthModels(model.id).update(model);

      // Raw data shows the difference
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['numbers'], equals(60)); // Sum stored as single int
      expect(rawData['tags'], equals(['tag1', 'tag2'])); // Array stored as array

      // You CANNOT do array operations on numbers because it's stored as int
      // await odm.listLengthModels(model.id).patch(($) => [
      //   $.numbers.arrayUnion([40]), // IMPOSSIBLE - numbers is int, not array
      // ]);

      // But you CAN do array operations on tags
      await odm.listLengthModels(model.id).patch(($) => [
            $.tags(['tag1', 'tag2', 'tag3'].toIList()),
          ]);

      final afterTagUpdate = await odm.listLengthModels(model.id).get();
      expect(afterTagUpdate!.tags.length, equals(3));
      expect(afterTagUpdate.tags.contains('tag3'), isTrue);

      print('✅ Tags (regular array) supports modifications');
      print('⚠️  Numbers (converted to sum) cannot use array operations');
      print('⚠️  JSON type mismatch prevents atomic array operations on converted fields');
    });

    test('should handle edge cases in conversion', () async {
      const lengthConverter = ListLengthConverter();
      const sumConverter = ListSumConverter();

      // Test edge cases
      expect(lengthConverter.toJson(<String>[].toIList()), equals(0));
      expect(lengthConverter.fromJson(0), equals(<String>[].toIList()));

      expect(sumConverter.toJson(<int>[].toIList()), equals(0));
      expect(sumConverter.fromJson(0), equals([0].toIList()));

      // Test large numbers
      final largeList = List.generate(1000, (i) => 'item_$i').toIList();
      expect(lengthConverter.toJson(largeList), equals(1000));
      
      final reconstructed = lengthConverter.fromJson(1000);
      expect(reconstructed.length, equals(1000));
      expect(reconstructed.first, equals('item_0'));
      expect(reconstructed.last, equals('item_999'));

      // Test negative sum (edge case)
      final negativeNumbers = [-10, -20, 5].toIList();
      expect(sumConverter.toJson(negativeNumbers), equals(-25));
      expect(sumConverter.fromJson(-25), equals([-25].toIList()));

      print('✅ Edge cases handled correctly in converters');
    });

    test('should handle complex mixed operations with all field types', () async {
      final profile = Profile(
        bio: 'Mixed Operations Test',
        avatar: 'mixed.jpg',
        socialLinks: {'test': 'mixed'},
        interests: ['testing'],
        followers: 999,
      );

      final model = ListLengthModel(
        id: 'mixed_ops_test',
        name: 'Mixed Operations Test',
        description: 'Testing all field types together',
        nestedProfiles: [profile].toIList(),
        items: ['initial'].toIList(),
        numbers: [100, 200].toIList(),
        tags: ['start'].toIList(),
        priority: 10,
        isActive: false,
        createdAt: DateTime.now(),
      );

      await odm.listLengthModels(model.id).update(model);

      // Complex patch with all field types
      final newProfile = Profile(
        bio: 'Updated Profile',
        avatar: 'updated.jpg',
        socialLinks: {'updated': 'profile'},
        interests: ['updated', 'testing'],
        followers: 1500,
      );

      await odm.listLengthModels(model.id).patch(($) => [
            $.nestedProfiles([profile, newProfile].toIList()),
            $.items(['new', 'updated', 'items'].toIList()),
            $.numbers([50, 75, 25].toIList()),
            $.tags(['updated', 'mixed', 'tags'].toIList()),
            $.priority.increment(5),
            $.isActive(true),
            $.updatedAt(DateTime.now()),
          ]);

      final result = await odm.listLengthModels(model.id).get();
      expect(result, isNotNull);

      // Verify all changes
      expect(result!.nestedProfiles.length, equals(2));
      expect(result.nestedProfiles[1].bio, equals('Updated Profile'));
      expect(result.items.length, equals(3)); // Converted back from length
      expect(result.numbers.first, equals(150)); // Converted back from sum (50+75+25=150)
      expect(result.tags.length, equals(3)); // Regular array
      expect(result.priority, equals(15)); // 10 + 5
      expect(result.isActive, isTrue);
      expect(result.updatedAt, isNotNull);

      // Verify raw storage
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['nestedProfiles'], isA<List>());
      expect(rawData['nestedProfiles'].length, equals(2));
      expect(rawData['items'], equals(3)); // Stored as length
      expect(rawData['numbers'], equals(150)); // Stored as sum
      expect(rawData['tags'], equals(['updated', 'mixed', 'tags'])); // Stored as array

      print('✅ Complex mixed operations successful across all field types');
    });

    test('should demonstrate converter reversibility limitations', () async {
      // Important limitation: conversion is lossy for some operations
      final originalItems = ['apple', 'banana', 'cherry'].toIList();
      final originalNumbers = [10, 20, 30, 40].toIList();

      final model = ListLengthModel(
        id: 'reversibility_test',
        name: 'Reversibility Test',
        description: 'Testing conversion limitations',
        items: originalItems,
        numbers: originalNumbers,
      );

      await odm.listLengthModels(model.id).update(model);
      final retrieved = await odm.listLengthModels(model.id).get();

      // Items: lossy conversion - original content lost, only length preserved
      expect(retrieved!.items.length, equals(originalItems.length));
      expect(retrieved.items, equals(['item_0', 'item_1', 'item_2'].toIList()));
      expect(retrieved.items, isNot(equals(originalItems))); // Content lost!

      // Numbers: lossy conversion - individual values lost, only sum preserved
      expect(retrieved.numbers.length, equals(1)); // Reconstructed as single value
      expect(retrieved.numbers.first, equals(100)); // Sum preserved
      expect(retrieved.numbers, isNot(equals(originalNumbers))); // Structure lost!

      print('✅ Converter limitations documented:');
      print('   - Items: Content lost, only length preserved');
      print('   - Numbers: Individual values lost, only sum preserved');
      print('⚠️  These converters are for storage optimization, not data preservation');
    });

    test('should handle large collections efficiently', () async {
      // Generate large collections
      final largeItems = List.generate(10000, (i) => 'large_item_$i').toIList();
      final largeNumbers = List.generate(1000, (i) => i + 1).toIList(); // Sum = 500500
      final largeTags = List.generate(500, (i) => 'tag_$i').toIList();

      final model = ListLengthModel(
        id: 'performance_test',
        name: 'Performance Test',
        description: 'Testing large collections',
        items: largeItems,
        numbers: largeNumbers,
        tags: largeTags,
      );

      final stopwatch = Stopwatch()..start();
      await odm.listLengthModels(model.id).update(model);
      stopwatch.stop();

      print('⏱️  Large collection update took: ${stopwatch.elapsedMilliseconds}ms');

      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      // Verify conversion efficiency
      expect(rawData['items'], equals(10000)); // Massive compression!
      expect(rawData['numbers'], equals(500500)); // Single number instead of 1000
      expect(rawData['tags'], isA<List>()); // Still full array
      expect(rawData['tags'].length, equals(500));

      final retrieveStopwatch = Stopwatch()..start();
      final retrieved = await odm.listLengthModels(model.id).get();
      retrieveStopwatch.stop();

      print('⏱️  Large collection retrieval took: ${retrieveStopwatch.elapsedMilliseconds}ms');

      expect(retrieved!.items.length, equals(10000));
      expect(retrieved.numbers.first, equals(500500));
      expect(retrieved.tags.length, equals(500));

      print('✅ Large collections handled efficiently with conversions');
      print('📊 Storage savings: 10000 items → 1 int, 1000 numbers → 1 int');
    });

    test('should handle null and optional fields correctly', () async {
      final model = ListLengthModel(
        id: 'null_test',
        name: 'Null Test',
        description: 'Testing null handling',
        // Using defaults for optional fields
      );

      await odm.listLengthModels(model.id).update(model);

      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.nestedProfiles.isEmpty, isTrue);
      expect(retrieved.items.isEmpty, isTrue);
      expect(retrieved.numbers.isEmpty, isFalse);
      expect(retrieved.tags.isEmpty, isTrue);
      expect(retrieved.createdAt, isNull);
      expect(retrieved.updatedAt, isNull);

      // Verify raw storage of empty collections
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(0)); // Empty list → 0
      expect(rawData['numbers'], equals(0)); // Empty list → 0
      expect(rawData['tags'], equals([])); // Empty list → []

      print('✅ Null and empty collections handled correctly');
    });
  });

  group('🚨 Model Getters and Methods Issue Tests', () {
    test('should demonstrate generator issue with getters and methods', () {
      // This test documents the issue we discovered:
      // When a Freezed model has getter methods or custom methods,
      // the code generator incorrectly treats them as constructor parameters
      
      const converter = ListLengthConverter();
      
      // Test the converters work independently
      final testList = ['a', 'b', 'c'].toIList();
      final length = converter.toJson(testList);
      expect(length, equals(3));
      
      final reconstructed = converter.fromJson(3);
      expect(reconstructed.length, equals(3));
      
      print('✅ JsonConverters work correctly in isolation');
      print('⚠️  Issue: Model with getters/methods causes generator errors');
      print('⚠️  Error: itemsLength and numbersSum treated as constructor params');
      
      // The actual issue is in the generated code:
      // lib/test_schema.odm.dart tries to use:
      // itemsLength: data['itemsLength'] as int,
      // numbersSum: data['numbersSum'] as int,
      // But these are getter methods, not constructor parameters!
    });

    test('should verify JsonConverter functionality without model issues', () {
      const lengthConverter = ListLengthConverter();
      const sumConverter = ListSumConverter();
      
      // Test ListLengthConverter
      final items = ['flutter', 'dart'].toIList();
      expect(lengthConverter.toJson(items), equals(2));
      expect(lengthConverter.fromJson(2), equals(['item_0', 'item_1'].toIList()));
      
      // Test ListSumConverter  
      final numbers = [10, 20, 30].toIList();
      expect(sumConverter.toJson(numbers), equals(60));
      expect(sumConverter.fromJson(60), equals([60].toIList()));
      
      print('✅ Both JsonConverters work perfectly');
      print('✅ List → int conversion: ✓');
      print('✅ int → List conversion: ✓');
      print('✅ Back and forth conversion: ✓');
    });
  });
}