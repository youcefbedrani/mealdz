import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/meal.dart';
import '../models/prediction.dart';
import 'providers.dart';

// Today's meals — rebuilt whenever notified
final todayMealsProvider = StateNotifierProvider<MealNotifier, List<Meal>>((ref) {
  return MealNotifier(ref);
});

// All meals (history)
final allMealsProvider = Provider<List<Meal>>((ref) {
  ref.watch(todayMealsProvider); // reacts to saves
  return ref.read(mealRepositoryProvider).getAllMeals();
});

// Weekly data for bar chart: list of 7 doubles (Mon→Sun), calories per day
final weeklyCaloriesProvider = Provider<List<double>>((ref) {
  ref.watch(todayMealsProvider);
  final meals = ref.read(mealRepositoryProvider).getMealsForWeek();
  final now = DateTime.now();
  final week = List<double>.filled(7, 0);
  for (final meal in meals) {
    final diff = now.difference(meal.loggedAt).inDays;
    if (diff < 7) week[6 - diff] += meal.calories;
  }
  return week;
});

class MealNotifier extends StateNotifier<List<Meal>> {
  MealNotifier(this._ref) : super([]) {
    _load();
  }

  final Ref _ref;

  void _load() {
    state = _ref.read(mealRepositoryProvider).getTodayMeals();
  }

  Future<void> logMeal(Prediction prediction, {Uint8List? imageBytes}) async {
    final nutrition = prediction.nutrition;
    if (nutrition == null) return;

    final meal = Meal(
      id: const Uuid().v4(),
      name: prediction.displayName,
      emoji: _emojiFor(prediction.label),
      mealType: _mealTypeForNow(),
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      loggedAt: DateTime.now(),
      foodLabel: prediction.label,
      confidence: prediction.confidence,
    );

    await _ref.read(mealRepositoryProvider).saveMeal(meal, imageBytes: imageBytes);
    _load();
  }

  Future<void> deleteMeal(String id) async {
    await _ref.read(mealRepositoryProvider).deleteMeal(id);
    _load();
  }

  // Nutrient totals for today
  double get totalCalories => state.fold(0, (s, m) => s + m.calories);
  double get totalProtein => state.fold(0, (s, m) => s + m.protein);
  double get totalCarbs => state.fold(0, (s, m) => s + m.carbs);
  double get totalFat => state.fold(0, (s, m) => s + m.fat);

  static String _mealTypeForNow() {
    final h = DateTime.now().hour;
    if (h < 10) return 'Breakfast';
    if (h < 14) return 'Lunch';
    if (h < 18) return 'Snack';
    return 'Dinner';
  }

  static String _emojiFor(String label) {
    const map = {
      'pizza': '🍕', 'hamburger': '🍔', 'sushi': '🍱', 'ice_cream': '🍦',
      'tacos': '🌮', 'ramen': '🍜', 'waffles': '🧇', 'pancakes': '🥞',
      'steak': '🥩', 'grilled_salmon': '🐟', 'caesar_salad': '🥗',
      'french_fries': '🍟', 'donuts': '🍩', 'chocolate_cake': '🎂',
      'cup_cakes': '🧁', 'apple_pie': '🥧', 'macarons': '🍬',
      'tiramisu': '🍮', 'cheesecake': '🍰', 'spaghetti_bolognese': '🍝',
    };
    return map[label] ?? '🍽️';
  }
}
