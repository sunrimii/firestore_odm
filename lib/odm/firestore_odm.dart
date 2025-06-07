import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hero_ai/controllers/hero_controller.dart';

import '../controllers/user_controller.dart';
import '../models/hero_state.dart';
import '../models/user_state.dart';
import 'firestore_collection.dart';

class FirestoreODM {
  const FirestoreODM._();

  static const FirestoreODM instance = FirestoreODM._();

  Future<void> runTransaction(
    Future<void> Function() cb,
  ) async {
    final handlers = <FutureOr<void> Function()>[];
    onSuccess(void Function() cb) {
      handlers.add(cb);
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      await runZoned(
        cb,
        zoneValues: {
          #transaction: transaction,
          #onSuccess: onSuccess,
        },
      );
    });

    log('running handlers, count: ${handlers.length}');
    for (final handler in handlers) {
      await handler();
    }
  }
}
