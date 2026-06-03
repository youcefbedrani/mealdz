import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groq_service.dart';
import 'meal_provider.dart';
import 'user_prefs_provider.dart';
import 'locale_provider.dart';

final dailyAdviceProvider = FutureProvider<String>((ref) async {
  final meals = ref.watch(todayMealsProvider);
  final goal = ref.watch(userPrefsProvider).dailyCalorieGoal;
  final locale = ref.watch(localeProvider);
  
  return GroqService.getDailyAdvice(meals, goal, languageCode: locale.languageCode);
});
