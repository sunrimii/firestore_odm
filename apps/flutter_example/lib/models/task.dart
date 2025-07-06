import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';
part 'task.odm.dart';

@freezed
@firestoreOdm
abstract class Task with _$Task {
  const factory Task({
    @DocumentIdField() required String id,
    required String title,
    required String description,
    required Duration estimatedDuration,
    Duration? actualDuration,
    @Default(false) bool isCompleted,
    @Default(0) int priority,
    DateTime? startedAt,
    DateTime? completedAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}