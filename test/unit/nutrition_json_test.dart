import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_analyzer/models/nutrition.dart';

void main() {
  group('nutrition_food101.json', () {
    late List<dynamic> raw;

    setUpAll(() {
      final file = File(
          'assets/data/nutrition_food101.json');
      raw = json.decode(file.readAsStringSync()) as List<dynamic>;
    });

    test('contains exactly 101 entries', () {
      expect(raw.length, 101);
    });

    test('all entries parse without error', () {
      for (final item in raw) {
        expect(
          () => Nutrition.fromJson(item as Map<String, dynamic>),
          returnsNormally,
          reason: 'Failed for label: ${(item as Map)["food_label"]}',
        );
      }
    });

    test('all food_label values are non-empty strings', () {
      for (final item in raw) {
        final label = (item as Map)['food_label'] as String?;
        expect(label, isNotNull);
        expect(label!.isNotEmpty, true);
      }
    });

    test('all calorie values are positive numbers', () {
      for (final item in raw) {
        final cal = (item as Map)['calories_kcal'] as num;
        expect(cal, greaterThan(0),
            reason:
                'Calories ≤ 0 for label: ${item["food_label"]}');
      }
    });

    test('no duplicate food_label values', () {
      final labels = raw.map((e) => (e as Map)['food_label'] as String).toList();
      final unique = labels.toSet();
      expect(unique.length, labels.length,
          reason: 'Duplicate labels found: '
              '${labels.where((l) => labels.where((x) => x == l).length > 1).toSet()}');
    });

    test('all macros are non-negative', () {
      for (final item in raw) {
        final m = item as Map;
        for (final key in ['protein_g', 'carbs_g', 'fat_g', 'fiber_g', 'sugar_g']) {
          final val = m[key] as num;
          expect(val, greaterThanOrEqualTo(0),
              reason: '$key < 0 for label: ${m["food_label"]}');
        }
      }
    });

    test('contains key food classes from Food-101', () {
      final labels =
          raw.map((e) => (e as Map)['food_label'] as String).toSet();
      for (final expected in [
        'pizza', 'hamburger', 'sushi', 'ramen', 'tacos',
        'steak', 'waffles', 'pancakes', 'donuts', 'ice_cream',
      ]) {
        expect(labels.contains(expected), true,
            reason: '"$expected" missing from nutrition JSON');
      }
    });
  });
}
