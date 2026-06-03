import 'package:flutter_test/flutter_test.dart';
import 'package:meal_analyzer/models/nutrition.dart';

void main() {
  group('Nutrition model', () {
    final sampleJson = {
      'food_label': 'pizza',
      'calories_kcal': 266,
      'protein_g': 11.0,
      'carbs_g': 33.0,
      'fat_g': 10.0,
      'fiber_g': 2.5,
      'sugar_g': 3.5,
      'serving_size': '100g',
    };

    test('fromJson parses all fields correctly', () {
      final n = Nutrition.fromJson(sampleJson);
      expect(n.foodLabel, 'pizza');
      expect(n.calories, 266.0);
      expect(n.protein, 11.0);
      expect(n.carbs, 33.0);
      expect(n.fat, 10.0);
      expect(n.fiber, 2.5);
      expect(n.sugar, 3.5);
      expect(n.servingSize, '100g');
    });

    test('fromJson handles integer values as doubles', () {
      final n = Nutrition.fromJson(sampleJson);
      expect(n.calories, isA<double>());
      expect(n.protein, isA<double>());
    });

    test('copyWith updates only specified fields', () {
      final original = Nutrition.fromJson(sampleJson);
      final updated = original.copyWith(calories: 300.0, protein: 15.0);
      expect(updated.calories, 300.0);
      expect(updated.protein, 15.0);
      // unchanged fields
      expect(updated.carbs, original.carbs);
      expect(updated.fat, original.fat);
      expect(updated.foodLabel, original.foodLabel);
    });

    test('copyWith with no arguments returns equivalent nutrition', () {
      final original = Nutrition.fromJson(sampleJson);
      final copy = original.copyWith();
      expect(copy.calories, original.calories);
      expect(copy.protein, original.protein);
      expect(copy.carbs, original.carbs);
      expect(copy.fat, original.fat);
    });

    test('fromJson handles fractional gram values', () {
      final fractional = {
        'food_label': 'sashimi',
        'calories_kcal': 127,
        'protein_g': 20.5,
        'carbs_g': 0.0,
        'fat_g': 4.9,
        'fiber_g': 0.0,
        'sugar_g': 0.0,
        'serving_size': '100g',
      };
      final n = Nutrition.fromJson(fractional);
      expect(n.protein, 20.5);
      expect(n.fat, 4.9);
      expect(n.carbs, 0.0);
    });
  });
}
