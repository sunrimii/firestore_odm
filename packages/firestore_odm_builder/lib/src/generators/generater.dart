import 'dart:async';

import 'package:code_builder/code_builder.dart';

class Generater {
  final StreamController<Spec> _specController = StreamController<Spec>(sync: true);

  Stream<Spec> get specs => _specController.stream;

  void write(Spec spec) => _specController.add(spec);
}

