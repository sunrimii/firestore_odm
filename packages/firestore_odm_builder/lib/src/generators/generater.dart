import 'dart:async';

import 'package:code_builder/code_builder.dart';

class Generater {
  final List<Spec> specs = [];

  void write(Spec spec) => specs.add(spec);
}

