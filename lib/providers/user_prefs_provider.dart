import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserPrefs {
  final double dailyCalorieGoal;
  final List<String> diseases;

  const UserPrefs({
    this.dailyCalorieGoal = 2000,
    this.diseases = const [],
  });

  UserPrefs copyWith({double? dailyCalorieGoal, List<String>? diseases}) =>
      UserPrefs(
        dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
        diseases: diseases ?? this.diseases,
      );
}

class UserPrefsNotifier extends StateNotifier<UserPrefs> {
  UserPrefsNotifier() : super(const UserPrefs()) {
    _load();
  }

  static const _boxName = 'settings';
  static const _keyGoal = 'dailyCalorieGoal';
  static const _keyDiseases = 'selectedDiseases';

  void _load() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final goal = (box.get(_keyGoal, defaultValue: 2000.0) as num).toDouble();
        final rawDiseases = box.get(_keyDiseases, defaultValue: <String>[]) as List<dynamic>;
        final diseases = rawDiseases.cast<String>().toList();
        state = UserPrefs(dailyCalorieGoal: goal, diseases: diseases);
        return;
      }
    } catch (_) {}
    state = const UserPrefs(dailyCalorieGoal: 2000.0, diseases: []);
  }

  Future<void> setCalorieGoal(double goal) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_keyGoal, goal);
      }
    } catch (_) {}
    state = state.copyWith(dailyCalorieGoal: goal);
  }

  Future<void> setDiseases(List<String> diseases) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_keyDiseases, diseases);
      }
    } catch (_) {}
    state = state.copyWith(diseases: diseases);
  }
}

final userPrefsProvider =
    StateNotifierProvider<UserPrefsNotifier, UserPrefs>((ref) {
  return UserPrefsNotifier();
});
