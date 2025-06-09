// Core user data models for Morphle
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';
part 'user_data.odm.dart';

@freezed
@Collection('users')
abstract class UserData with _$UserData {
  const factory UserData({
    @DocumentIdField() @Default('') String userId,
    @Default('') String username,
    @Default(1) int currentVocabularyLevel, // 1=4-letter, 2=5-letter, etc.
    @Default(350) int gems, // Main currency for the game economy
    @Default(0) int totalPuzzlesSolved,
    @Default(0) int currentStreakDays,
    @Default(0) int longestStreakDays,
    @Default(0) int currentRealmId,
    @Default(<String>[]) List<String> discoveredWords,
    @Default(<String>[]) List<String> completedPuzzleIds,
    @Default(<String>[]) List<String> unlockedRealms,
    @Default(<String>[]) List<String> earnedAchievements,
    @Default(false) bool hasVipPass,
    @Default(false) bool hasRemovedAds,
    DateTime? lastPlayDate,
    DateTime? vipPassExpiryDate,
    @Default(<String, int>{})
    Map<String, int> realmProgress, // realmId -> completedPuzzles
    @Default(<String, int>{}) Map<String, int> dailyMissionProgress,
    @Default(<String, DateTime>{}) Map<String, DateTime> achievementDates,
  }) = _UserData;

  factory UserData.fromJson(Map<String, Object?> json) =>
      _$UserDataFromJson(json);
}

@freezed
abstract class DailyMission with _$DailyMission {
  const factory DailyMission({
    required String id,
    required String
    type, // complete_puzzles, solve_without_hints, learn_words, etc.
    required String description,
    required int targetCount,
    required int rewardTokens,
    @Default(0) int currentProgress,
    @Default(false) bool isCompleted,
    DateTime? completedDate,
  }) = _DailyMission;

  factory DailyMission.fromJson(Map<String, Object?> json) =>
      _$DailyMissionFromJson(json);
}

@freezed
@Collection('users/*/dailyMissions')
abstract class DailyMissionsDocument with _$DailyMissionsDocument {
  const factory DailyMissionsDocument({
    required String date,
    @Default(<DailyMission>[]) List<DailyMission> missions,
  }) = _DailyMissionsDocument;

  factory DailyMissionsDocument.fromJson(Map<String, Object?> json) =>
      _$DailyMissionsDocumentFromJson(json);
}