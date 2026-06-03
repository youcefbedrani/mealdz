import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/nutrition.dart';
import '../config/secrets.dart';
import 'groq_service.dart';

class NutritionService {
  static NutritionService? _instance;
  Map<String, Nutrition>? _cache;

  NutritionService._();
  static NutritionService get instance => _instance ??= NutritionService._();

  Future<void> preload() async {
    if (_cache != null) return;
    final raw =
        await rootBundle.loadString('assets/data/nutrition_food101.json');
    final list = json.decode(raw) as List<dynamic>;
    _cache = {
      for (final item in list)
        (item['food_label'] as String): Nutrition.fromJson(
            item as Map<String, dynamic>)
    };
  }

  Nutrition? lookupLocal(String foodLabel) => _cache?[foodLabel];

  Future<Nutrition?> lookupEdamam(String query) async {
    if (Secrets.edamamAppId == 'YOUR_EDAMAM_APP_ID') return null;
    try {
      final uri = Uri.https('api.edamam.com', '/api/nutrition-data', {
        'app_id': Secrets.edamamAppId,
        'app_key': Secrets.edamamAppKey,
        'ingr': '100g $query',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body) as Map<String, dynamic>;
      final nutrients = body['totalNutrients'] as Map<String, dynamic>?;
      if (nutrients == null) return null;

      double nut(String key) =>
          ((nutrients[key] as Map?)?['quantity'] as num?)?.toDouble() ?? 0.0;

      return Nutrition(
        foodLabel: query,
        calories: nut('ENERC_KCAL'),
        protein: nut('PROCNT'),
        carbs: nut('CHOCDF'),
        fat: nut('FAT'),
        fiber: nut('FIBTG'),
        sugar: nut('SUGAR'),
        servingSize: '100g',
      );
    } catch (_) {
      return null;
    }
  }

  Future<Nutrition?> lookup(String foodLabel) async {
    await preload();
    final local = lookupLocal(foodLabel);
    if (local != null) return local;

    final edamam = await lookupEdamam(foodLabel);
    if (edamam != null) {
      _cache?[foodLabel] = edamam;
      return edamam;
    }

    final groq = await lookupGroq(foodLabel);
    if (groq != null) {
      _cache?[foodLabel] = groq;
    }
    return groq;
  }

  Future<Nutrition?> lookupGroq(String foodLabel) async {
    try {
      final prompt = 'Give the nutrition facts for 100g of "$foodLabel". Return ONLY a raw JSON object matching this format exactly: {"calories": double, "protein": double, "carbs": double, "fat": double, "fiber": double, "sugar": double}';
      final reply = await GroqService.chat(
        [{'role': 'user', 'content': prompt}],
        systemPromptOverride: 'You are a precise nutrition database API. Respond ONLY with a raw JSON object matching the requested format. Do not include any conversational text, markdown wrapping (like ```json), or markdown backticks. If you do not know the food, estimate typical values based on common ingredients.',
      );
      final cleanJson = reply.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson) as Map<String, dynamic>;
      return Nutrition(
        foodLabel: foodLabel,
        calories: (data['calories'] as num?)?.toDouble() ?? 200.0,
        protein: (data['protein'] as num?)?.toDouble() ?? 8.0,
        carbs: (data['carbs'] as num?)?.toDouble() ?? 25.0,
        fat: (data['fat'] as num?)?.toDouble() ?? 8.0,
        fiber: (data['fiber'] as num?)?.toDouble() ?? 1.5,
        sugar: (data['sugar'] as num?)?.toDouble() ?? 3.0,
        servingSize: '100g',
      );
    } catch (_) {
      return null;
    }
  }
}
