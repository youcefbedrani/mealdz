import 'package:flutter_test/flutter_test.dart';
import 'package:meal_analyzer/models/prediction.dart';
import 'package:meal_analyzer/models/nutrition.dart';

void main() {
  group('Prediction model', () {
    test('displayName converts underscores to spaces and capitalizes', () {
      const p = Prediction(label: 'grilled_salmon', confidence: 0.94);
      expect(p.displayName, 'Grilled Salmon');
    });

    test('displayName capitalizes first letter of each word', () {
      final cases = {
        'apple_pie': 'Apple Pie',
        'beef_tartare': 'Beef Tartare',
        'hot_and_sour_soup': 'Hot And Sour Soup',
        'macaroni_and_cheese': 'Macaroni And Cheese',
        'spaghetti_carbonara': 'Spaghetti Carbonara',
        'red_velvet_cake': 'Red Velvet Cake',
        'spring_rolls': 'Spring Rolls',
        'waffles': 'Waffles',
        'pizza': 'Pizza',
      };
      for (final entry in cases.entries) {
        final p = Prediction(label: entry.key, confidence: 0.9);
        expect(p.displayName, entry.value,
            reason: 'Label "${entry.key}" → "${entry.value}"');
      }
    });

    test('confidence is stored as provided', () {
      const p = Prediction(label: 'tacos', confidence: 0.876);
      expect(p.confidence, closeTo(0.876, 0.001));
    });

    test('nutrition is nullable and defaults to null', () {
      const p = Prediction(label: 'pizza', confidence: 0.9);
      expect(p.nutrition, isNull);
    });

    test('nutrition is accessible when provided', () {
      final n = Nutrition(
        foodLabel: 'pizza',
        calories: 266,
        protein: 11,
        carbs: 33,
        fat: 10,
        fiber: 2.5,
        sugar: 3.5,
        servingSize: '100g',
      );
      final p = Prediction(label: 'pizza', confidence: 0.95, nutrition: n);
      expect(p.nutrition, isNotNull);
      expect(p.nutrition!.calories, 266);
    });

    test('top-5 list ordering by confidence', () {
      final predictions = [
        const Prediction(label: 'pizza', confidence: 0.85),
        const Prediction(label: 'lasagna', confidence: 0.07),
        const Prediction(label: 'ravioli', confidence: 0.04),
        const Prediction(label: 'spaghetti_bolognese', confidence: 0.02),
        const Prediction(label: 'gnocchi', confidence: 0.01),
      ];
      // Simulate descending sort (as done in classifier)
      final sorted = [...predictions]
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      expect(sorted.first.label, 'pizza');
      expect(sorted.last.label, 'gnocchi');
    });
  });
}
