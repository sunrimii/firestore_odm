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

    group('📏 ListLengthConverter Tests', () {
      test('should convert IList<String> to int (length) and back', () {
        const converter = ListLengthConverter();
        
        // Test toJson: IList<String> -> int (length)
        final originalList = ['apple', 'banana', 'cherry'].toIList();
        final lengthAsInt = converter.toJson(originalList);
        expect(lengthAsInt, equals(3));
        
        // Test fromJson: int (length) -> IList<String> (with placeholders)
        final reconstructedList = converter.fromJson(3);
        expect(reconstructedList.length, equals(3));
        expect(reconstructedList[0], equals('item_0'));
        expect(reconstructedList[1], equals('item_1'));
        expect(reconstructedList[2], equals('item_2'));
        
        print('✅ Original list: $originalList');
        print('✅ Length as int: $lengthAsInt');
        print('✅ Reconstructed list: $reconstructedList');
      });

      test('should handle empty list conversion', () {
        const converter = ListLengthConverter();
        
        final emptyList = <String>[].toIList();
        final lengthAsInt = converter.toJson(emptyList);
        expect(lengthAsInt, equals(0));
        
        final reconstructedList = converter.fromJson(0);
        expect(reconstructedList.length, equals(0));
        expect(reconstructedList.isEmpty, isTrue);
      });

      test('should handle large list conversion', () {
        const converter = ListLengthConverter();
        
        final largeList = List.generate(100, (i) => 'item_$i').toIList();
        final lengthAsInt = converter.toJson(largeList);
        expect(lengthAsInt, equals(100));
        
        final reconstructedList = converter.fromJson(100);
        expect(reconstructedList.length, equals(100));
        expect(reconstructedList.first, equals('item_0'));
        expect(reconstructedList.last, equals('item_99'));
      });
    });

    group('🧮 ListSumConverter Tests', () {
      test('should convert IList<int> to int (sum) and back', () {
        const converter = ListSumConverter();
        
        // Test toJson: IList<int> -> int (sum)
        final originalNumbers = [10, 20, 30, 40].toIList();
        final sumAsInt = converter.toJson(originalNumbers);
        expect(sumAsInt, equals(100));
        
        // Test fromJson: int (sum) -> IList<int> (single item with sum value)
        final reconstructedList = converter.fromJson(100);
        expect(reconstructedList.length, equals(1));
        expect(reconstructedList.first, equals(100));
        
        print('✅ Original numbers: $originalNumbers');
        print('✅ Sum as int: $sumAsInt');
        print('✅ Reconstructed list: $reconstructedList');
      });

      test('should handle empty numbers list', () {
        const converter = ListSumConverter();
        
        final emptyNumbers = <int>[].toIList();
        final sumAsInt = converter.toJson(emptyNumbers);
        expect(sumAsInt, equals(0));
        
        final reconstructedList = converter.fromJson(0);
        expect(reconstructedList.length, equals(1));
        expect(reconstructedList.first, equals(0));
      });

      test('should handle negative numbers', () {
        const converter = ListSumConverter();
        
        final mixedNumbers = [10, -5, 15, -8].toIList();
        final sumAsInt = converter.toJson(mixedNumbers);
        expect(sumAsInt, equals(12)); // 10 - 5 + 15 - 8 = 12
        
        final reconstructedList = converter.fromJson(12);
        expect(reconstructedList.first, equals(12));
      });
    });

    group('🏗️ Model Creation and Persistence Tests', () {
      test('should create and save ListLengthModel with converters', () async {
        final model = ListLengthModel(
          id: 'test_model_1',
          name: 'Test Model',
          description: 'Testing list length converters',
          items: ['flutter', 'dart', 'firestore'].toIList(),
          numbers: [100, 200, 300].toIList(),
          tags: ['test', 'converter', 'ilist'].toIList(),
          priority: 1,
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await odm.listLengthModels(model.id).update(model);

        // Retrieve and verify
        final retrieved = await odm.listLengthModels(model.id).get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Test Model'));
        expect(retrieved.description, equals('Testing list length converters'));
        
        // Verify helper methods work
        expect(retrieved.itemsLength, equals(3));
        expect(retrieved.numbersSum, equals(600));
        
        // Verify tags (no converter) are preserved exactly
        expect(retrieved.tags.length, equals(3));
        expect(retrieved.tags.contains('test'), isTrue);
        expect(retrieved.tags.contains('converter'), isTrue);
        expect(retrieved.tags.contains('ilist'), isTrue);

        print('✅ Model saved and retrieved successfully');
        print('✅ Items length: ${retrieved.itemsLength}');
        print('✅ Numbers sum: ${retrieved.numbersSum}');
        print('✅ Tags: ${retrieved.tags}');
      });

      test('should verify conversion happens during serialization', () async {
        final model = ListLengthModel(
          id: 'conversion_test',
          name: 'Conversion Test',
          description: 'Testing actual conversion during save/load',
          items: ['a', 'b', 'c', 'd', 'e'].toIList(), // Length = 5
          numbers: [1, 2, 3, 4].toIList(), // Sum = 10
          tags: ['original', 'tags'].toIList(),
          priority: 2,
          isActive: false,
        );

        await odm.listLengthModels(model.id).update(model);

        // Check what's actually stored in Firestore (raw data)
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        
        final rawData = rawDoc.data()!;
        
        // Verify that items is stored as int (length)
        expect(rawData['items'], equals(5));
        
        // Verify that numbers is stored as int (sum)
        expect(rawData['numbers'], equals(10));
        
        // Verify that tags is stored as list (no conversion)
        expect(rawData['tags'], equals(['original', 'tags']));

        // Retrieve through ODM and verify conversion back
        final retrieved = await odm.listLengthModels(model.id).get();
        expect(retrieved, isNotNull);
        
        // Items should be reconstructed as placeholder items
        expect(retrieved!.items.length, equals(5));
        expect(retrieved.items[0], equals('item_0'));
        expect(retrieved.items[4], equals('item_4'));
        
        // Numbers should be reconstructed as single item with sum
        expect(retrieved.numbers.length, equals(1));
        expect(retrieved.numbers.first, equals(10));
        
        // Tags should be preserved exactly
        expect(retrieved.tags.length, equals(2));
        expect(retrieved.tags[0], equals('original'));
        expect(retrieved.tags[1], equals('tags'));

        print('✅ Raw Firestore data - items: ${rawData['items']}');
        print('✅ Raw Firestore data - numbers: ${rawData['numbers']}');
        print('✅ Raw Firestore data - tags: ${rawData['tags']}');
        print('✅ Retrieved items: ${retrieved.items}');
        print('✅ Retrieved numbers: ${retrieved.numbers}');
        print('✅ Retrieved tags: ${retrieved.tags}');
      });
    });

    group('🔄 Model Operations Tests', () {
      test('should handle adding items and see length changes', () async {
        var model = ListLengthModel(
          id: 'operations_test',
          name: 'Operations Test',
          description: 'Testing model operations',
          items: ['initial'].toIList(),
          numbers: [50].toIList(),
          tags: ['tag1'].toIList(),
          priority: 1,
          isActive: true,
        );

        await odm.listLengthModels(model.id).update(model);

        // Add items using helper method
        model = model.addItem('second');
        model = model.addItem('third');
        
        expect(model.itemsLength, equals(3));
        
        await odm.listLengthModels(model.id).update(model);
        
        // Verify in Firestore
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        expect(rawDoc.data()!['items'], equals(3)); // Stored as length

        // Add numbers and verify sum
        model = model.addNumber(25);
        model = model.addNumber(75);
        
        expect(model.numbersSum, equals(150)); // 50 + 25 + 75
        
        await odm.listLengthModels(model.id).update(model);
        
        final updatedRawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        expect(updatedRawDoc.data()!['numbers'], equals(150)); // Stored as sum

        print('✅ Items length after additions: ${model.itemsLength}');
        print('✅ Numbers sum after additions: ${model.numbersSum}');
      });

      test('should demonstrate back and forth conversion', () async {
        // Create initial model
        var model = ListLengthModel(
          id: 'back_forth_test',
          name: 'Back and Forth Test',
          description: 'Testing bidirectional conversion',
          items: ['one', 'two', 'three', 'four'].toIList(),
          numbers: [10, 20, 30].toIList(),
          tags: ['demo'].toIList(),
          priority: 1,
          isActive: true,
        );

        // Save to Firestore (List -> int conversion)
        await odm.listLengthModels(model.id).update(model);
        
        // Verify raw storage
        var rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        var rawData = rawDoc.data()!;
        
        expect(rawData['items'], equals(4)); // Length stored
        expect(rawData['numbers'], equals(60)); // Sum stored
        
        // Retrieve from Firestore (int -> List conversion)
        var retrieved = await odm.listLengthModels(model.id).get();
        expect(retrieved, isNotNull);
        
        // Verify reconstruction
        expect(retrieved!.items.length, equals(4));
        expect(retrieved.items, equals(['item_0', 'item_1', 'item_2', 'item_3'].toIList()));
        expect(retrieved.numbers.length, equals(1));
        expect(retrieved.numbers.first, equals(60));
        
        // Modify and save again (demonstrating round trip)
        retrieved = retrieved.addItem('fifth');
        retrieved = retrieved.addNumber(40);
        
        await odm.listLengthModels(retrieved.id).update(retrieved);
        
        // Verify updated raw storage
        rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        rawData = rawDoc.data()!;
        
        expect(rawData['items'], equals(5)); // Updated length
        expect(rawData['numbers'], equals(100)); // Updated sum (60 + 40)
        
        print('✅ Back and forth conversion successful');
        print('✅ Final items length: ${rawData['items']}');
        print('✅ Final numbers sum: ${rawData['numbers']}');
      });
    });

    group('🎯 Edge Cases and Error Handling', () {
      test('should handle zero values correctly', () {
        const lengthConverter = ListLengthConverter();
        const sumConverter = ListSumConverter();
        
        // Test zero length
        final emptyList = <String>[].toIList();
        expect(lengthConverter.toJson(emptyList), equals(0));
        expect(lengthConverter.fromJson(0), equals(<String>[].toIList()));
        
        // Test zero sum
        final zeroNumbers = <int>[].toIList();
        expect(sumConverter.toJson(zeroNumbers), equals(0));
        expect(sumConverter.fromJson(0).first, equals(0));
      });

      test('should handle large numbers correctly', () {
        const sumConverter = ListSumConverter();
        
        final largeNumbers = [1000000, 2000000, 3000000].toIList();
        final sum = sumConverter.toJson(largeNumbers);
        expect(sum, equals(6000000));
        
        final reconstructed = sumConverter.fromJson(6000000);
        expect(reconstructed.first, equals(6000000));
      });

      test('should maintain immutability of IList operations', () async {
        final model = ListLengthModel(
          id: 'immutability_test',
          name: 'Immutability Test',
          description: 'Testing IList immutability',
          items: ['original'].toIList(),
          numbers: [100].toIList(),
          tags: ['immutable'].toIList(),
          priority: 1,
          isActive: true,
        );

        // Test that operations return new instances
        final originalItems = model.items;
        final newModel = model.addItem('new');
        
        expect(originalItems.length, equals(1));
        expect(newModel.items.length, equals(2));
        expect(originalItems, isNot(same(newModel.items)));
        
        // Verify original model is unchanged
        expect(model.items.length, equals(1));
        expect(model.items.first, equals('original'));
        
        print('✅ Immutability preserved during operations');
      });
    });
  });
}