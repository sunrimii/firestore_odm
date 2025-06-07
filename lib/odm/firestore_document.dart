import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hero_ai/controllers/hero_controller.dart';
import 'package:hero_ai/odm/firestore_collection.dart';
import 'package:json_diff/json_diff.dart';

class FirestoreDocument<T> {
  final FirestoreCollection<T> collection;
  final String id;

  Map<String, dynamic>? _cache;

  static Map<String, dynamic> _diff(
      Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    final differ = JsonDiffer.fromJson(oldData, newData);
    final diff = differ.diff();

    final result = <String, dynamic>{};
    diff.forEachAdded((key, value) {
      result[key as String] = value;
    });
    diff.forEachRemoved((key, value) {
      result[key as String] = FieldValue.delete();
    });
    diff.forEachChanged((key, value) {
      final [_, newValue] = value;
      result[key as String] = newValue;
    });
    return result;
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  get isSubscribing => _subscription != null;

  final StreamController<T?> _controller = StreamController.broadcast();

  Stream<T?> get changes => _controller.stream;

  DocumentReference<Map<String, dynamic>> get ref => collection.ref.doc(id);

  FirestoreDocument(this.collection, this.id) {
    _controller.onListen = () {
      log('listening to data changes');
      _subscription = ref.snapshots().skip(1).listen((event) {
        log('data changed: ${event.data()}');
        _cache = event.data();
        _controller.add(_fromJson(_cache));
      });
    };
    _controller.onCancel = () {
      log('cancelling data changes');
      _subscription?.cancel();
    };
  }

  T? _fromJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    data['id'] = id;
    return collection.fromJson(data);
  }

  Future<bool> exists() async {
    return await get() != null;
  }

  Future<T?> get() async {
    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('getting with transaction');
      final value = await transaction.get(ref);
      _cache = value.data();
      return _fromJson(_cache);
    } else {
      // if we are not subscribing, we need to pull the data
      if (!isSubscribing) {
        log('pulling data');
        final value = await ref.get();
        _cache = value.data();
      }
      return _fromJson(_cache);
    }
  }

  Future<T> getOrCreate(
    T Function() create,
  ) async {
    final value = await get();
    if (value != null) return value;
    await set(create());
    return create();
  }

  Future<void> set(T state) async {
    final transaction = Zone.current[#transaction] as Transaction?;
    final data = collection.toJson(state);
    if (transaction != null) {
      log('setting with transaction: $data');
      transaction.set(ref, data);
      Zone.current[#onSuccess](() {
        _cache = data;
      });
    } else {
      log('setting without transaction: $data');
      await ref.set(data);
      _cache = data;
    }
  }

  Future<void> update(
    T Function(T state) cb,
  ) async {
    final oldState = await get();
    if (oldState == null) {
      throw HeroNotFoundException(id);
    }
    final newState = cb(oldState);
    final newData = collection.toJson(newState);
    final data = _diff(_cache ?? {}, newData);

    final transaction = Zone.current[#transaction] as Transaction?;
    if (transaction != null) {
      log('updating with transaction: $data');
      transaction.set(ref, data, SetOptions(merge: true));
      Zone.current[#onSuccess](() {
        _cache = newData;
      });
    } else {
      log('updating without transaction: $data');
      await ref.set(data, SetOptions(merge: true));
      _cache = newData;
    }
  }
}
