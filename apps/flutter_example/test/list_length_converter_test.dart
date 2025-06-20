import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_example/models/list_length_model.dart';
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