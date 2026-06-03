import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../config/secrets.dart';

class GroqService {
  static const _apiKey = Secrets.groqApiKey;
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.1-8b-instant';

  static Future<String> chat(
    List<Map<String, String>> messages, {
    String languageCode = 'en',
    List<Meal>? todayMeals,
    double? calorieGoal,
    String? systemPromptOverride,
  }) async {
    try {
      final totalCalories =
          todayMeals?.fold(0.0, (s, m) => s + m.calories) ?? 0.0;
      final totalProtein =
          todayMeals?.fold(0.0, (s, m) => s + m.protein) ?? 0.0;
      final totalCarbs = todayMeals?.fold(0.0, (s, m) => s + m.carbs) ?? 0.0;
      final totalFat = todayMeals?.fold(0.0, (s, m) => s + m.fat) ?? 0.0;
      final mealDetails = todayMeals != null && todayMeals.isNotEmpty
          ? todayMeals.map((m) => '${m.name} (${m.calories} kcal)').join(', ')
          : (languageCode == 'ar' ? 'لا يوجد وجبات بعد' : 'None yet');

      String contextInfo = '';
      if (todayMeals != null && calorieGoal != null) {
        contextInfo = languageCode == 'ar'
            ? '\nمعلومات إضافية عن المستخدم اليوم:\n- الوجبات المسجلة: $mealDetails\n- السعرات الحرارية المستهلكة اليوم: $totalCalories من هدف $calorieGoal سعرة حرارية\n- المغذيات اليومية: البروتين: ${totalProtein}g، الكربوهيدرات: ${totalCarbs}g، الدهون: ${totalFat}g.\nيرجى استخدام هذه المعلومات للإجابة بدقة عن وجباته وسعراته وأهدافه إذا سأل عنها.'
            : '\nAdditional user info for today:\n- Logged meals: $mealDetails\n- Calories consumed today: $totalCalories kcal out of target $calorieGoal kcal\n- Daily macros: Protein: ${totalProtein}g, Carbs: ${totalCarbs}g, Fat: ${totalFat}g.\nPlease use this information to accurately answer questions about their meals, calories, and goals if they ask.';
      }

      final systemPrompt = systemPromptOverride ??
          ((languageCode == 'ar'
                  ? 'أنت مستشار صحي وتغذية ورياضة ذكي وودود. قدم نصائح وتوصيات قصيرة ومباشرة للمستخدم حول وجباته، رياضته، وصحته باللغة العربية.'
                  : 'You are a smart, friendly AI Health & Nutrition Advisor. Give short, direct, actionable advice and recommendations to the user regarding their meals, sports, workouts, and health.') +
              contextInfo);

      final requestMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages
      ];

      debugPrint('Groq chat request to $_endpoint using model $_model');
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: json.encode({
              'model': _model,
              'messages': requestMessages,
              'temperature': 0.7,
              'max_tokens': 500,
            }),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('Groq chat response status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      } else {
        debugPrint('Groq chat error response: ${res.body}');
        return languageCode == 'ar'
            ? 'عذراً، فشل الاتصال بمستشار الذكاء الاصطناعي.'
            : 'Sorry, failed to connect to the AI advisor.';
      }
    } catch (e) {
      debugPrint('Groq chat exception: $e');
      return languageCode == 'ar'
          ? 'عذراً، حدث خطأ أثناء الاتصال بالخادم.'
          : 'Sorry, an error occurred while connecting to the server.';
    }
  }

  static Future<String> getDailyAdvice(
      List<Meal> todayMeals, double calorieGoal,
      {String languageCode = 'en'}) async {
    try {
      final totalCalories = todayMeals.fold(0.0, (s, m) => s + m.calories);
      final totalProtein = todayMeals.fold(0.0, (s, m) => s + m.protein);
      final totalCarbs = todayMeals.fold(0.0, (s, m) => s + m.carbs);
      final totalFat = todayMeals.fold(0.0, (s, m) => s + m.fat);

      final mealDetails = todayMeals
          .map((m) =>
              '${m.name} (${m.calories} kcal, P:${m.protein}g, C:${m.carbs}g, F:${m.fat}g)')
          .join(', ');

      final prompt = languageCode == 'ar'
          ? 'المستخدم سجل وجبات اليوم التالية: $mealDetails. مجموع السعرات: $totalCalories من هدف $calorieGoal سعرة. البروتين: $totalProtein غرام، الكارب: $totalCarbs غرام، الدهون: $totalFat غرام. أعط المستخدم نصيحة تغذية أو رياضة واحدة موجزة للغاية ومباشرة (جملة أو جملتين كحد أقصى) لتساعده اليوم باللغة العربية.'
          : 'The user logged the following meals today: $mealDetails. Total calories: $totalCalories kcal out of target $calorieGoal kcal. Protein: $totalProtein g, Carbs: $totalCarbs g, Fat: $totalFat g. Give the user exactly one very concise, direct health, nutrition, or sports advice (max 1-2 sentences) to help them today.';

      debugPrint('Groq advice request: $prompt');
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: json.encode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.6,
              'max_tokens': 150,
            }),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint('Groq advice response status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        return (data['choices'][0]['message']['content'] as String).trim();
      } else {
        debugPrint('Groq advice error response: ${res.body}');
        return languageCode == 'ar'
            ? 'تناول طعاماً متوازناً وحافظ على نشاطك البدني اليوم!'
            : 'Keep balanced nutrition and stay active today!';
      }
    } catch (e) {
      debugPrint('Groq advice exception: $e');
      return languageCode == 'ar'
          ? 'تناول طعاماً متوازناً وحافظ على نشاطك البدني اليوم!'
          : 'Keep balanced nutrition and stay active today!';
    }
  }
}
