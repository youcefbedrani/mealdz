import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../models/nutrition.dart';

const _mealsBox = 'meals';

class LocalStorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(NutritionAdapter());
    await Hive.openBox<Meal>(_mealsBox);
    await Hive.openBox('settings');
  }

  Box<Meal> get _box => Hive.box<Meal>(_mealsBox);

  Future<void> saveMeal(Meal meal) => _box.put(meal.id, meal);

  Future<void> deleteMeal(String id) => _box.delete(id);

  List<Meal> getAllMeals() => _box.values.toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  List<Meal> getMealsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _box.values
        .where((m) => m.loggedAt.isAfter(start) && m.loggedAt.isBefore(end))
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  List<Meal> getUnsyncedMeals() =>
      _box.values.where((m) => !m.synced).toList();

  Future<void> markSynced(String id, {String? imageUrl}) async {
    final meal = _box.get(id);
    if (meal != null) {
      await _box.put(id, meal.copyWith(synced: true, imageUrl: imageUrl));
    }
  }
}
