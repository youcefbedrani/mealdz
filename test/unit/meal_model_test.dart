import 'package:flutter_test/flutter_test.dart';
import 'package:meal_analyzer/models/meal.dart';

void main() {
  group('Meal model', () {
    final baseTime = DateTime(2026, 5, 5, 12, 30);

    Meal makeMeal({bool synced = false, String? imageUrl}) => Meal(
          id: 'test-id-1',
          name: 'Grilled Salmon',
          emoji: '🐟',
          mealType: 'Lunch',
          calories: 206.0,
          protein: 28.0,
          carbs: 0.0,
          fat: 10.0,
          loggedAt: baseTime,
          foodLabel: 'grilled_salmon',
          confidence: 0.94,
          synced: synced,
          imageUrl: imageUrl,
        );

    test('constructor stores all fields correctly', () {
      final meal = makeMeal();
      expect(meal.id, 'test-id-1');
      expect(meal.name, 'Grilled Salmon');
      expect(meal.emoji, '🐟');
      expect(meal.mealType, 'Lunch');
      expect(meal.calories, 206.0);
      expect(meal.protein, 28.0);
      expect(meal.carbs, 0.0);
      expect(meal.fat, 10.0);
      expect(meal.loggedAt, baseTime);
      expect(meal.foodLabel, 'grilled_salmon');
      expect(meal.confidence, 0.94);
      expect(meal.synced, false);
    });

    test('toFirestore contains all required keys', () {
      final map = makeMeal().toFirestore();
      expect(map['id'], 'test-id-1');
      expect(map['name'], 'Grilled Salmon');
      expect(map['emoji'], '🐟');
      expect(map['mealType'], 'Lunch');
      expect(map['calories'], 206.0);
      expect(map['protein'], 28.0);
      expect(map['carbs'], 0.0);
      expect(map['fat'], 10.0);
      expect(map.containsKey('loggedAt'), true);
      expect(map['foodLabel'], 'grilled_salmon');
      expect(map['confidence'], 0.94);
    });

    test('toFirestore.loggedAt is ISO-8601 string', () {
      final map = makeMeal().toFirestore();
      expect(map['loggedAt'], isA<String>());
      final parsed = DateTime.parse(map['loggedAt'] as String);
      expect(parsed.year, 2026);
      expect(parsed.month, 5);
      expect(parsed.day, 5);
    });

    test('fromFirestore round-trips through toFirestore', () {
      final original = makeMeal(synced: true, imageUrl: 'https://example.com/img.jpg');
      final map = original.toFirestore();
      final restored = Meal.fromFirestore(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.emoji, original.emoji);
      expect(restored.mealType, original.mealType);
      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.carbs, original.carbs);
      expect(restored.fat, original.fat);
      expect(restored.foodLabel, original.foodLabel);
      expect(restored.confidence, original.confidence);
      expect(restored.synced, true); // fromFirestore always sets synced=true
    });

    test('copyWith synced=true preserves other fields', () {
      final original = makeMeal();
      final updated = original.copyWith(synced: true);
      expect(updated.synced, true);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.calories, original.calories);
    });

    test('copyWith imageUrl updates imageUrl only', () {
      final original = makeMeal();
      final updated = original.copyWith(imageUrl: 'https://new.url/img.jpg');
      expect(updated.imageUrl, 'https://new.url/img.jpg');
      expect(updated.synced, original.synced);
    });

    test('fromFirestore handles missing optional fields gracefully', () {
      final minimal = {
        'id': 'min-id',
        'name': 'Pizza',
        'mealType': 'Dinner',
        'calories': 266,
        'protein': 11.0,
        'carbs': 33.0,
        'fat': 10.0,
        'loggedAt': DateTime(2026, 5, 1).toIso8601String(),
      };
      final meal = Meal.fromFirestore(minimal);
      expect(meal.emoji, '🍽️');      // default fallback
      expect(meal.foodLabel, isNull); // absent key → null
      expect(meal.confidence, 0.0);
    });
  });
}
