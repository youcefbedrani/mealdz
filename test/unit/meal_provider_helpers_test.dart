import 'package:flutter_test/flutter_test.dart';

// Testing the static helper logic that would live in MealNotifier
// Extracted here to enable pure Dart testing without Firebase/Hive.

String mealTypeForHour(int hour) {
  if (hour < 10) return 'Breakfast';
  if (hour < 14) return 'Lunch';
  if (hour < 18) return 'Snack';
  return 'Dinner';
}

const _emojiMap = {
  'pizza': '🍕', 'hamburger': '🍔', 'sushi': '🍱', 'ice_cream': '🍦',
  'tacos': '🌮', 'ramen': '🍜', 'waffles': '🧇', 'pancakes': '🥞',
  'steak': '🥩', 'grilled_salmon': '🐟', 'caesar_salad': '🥗',
  'french_fries': '🍟', 'donuts': '🍩', 'chocolate_cake': '🎂',
  'cup_cakes': '🧁', 'apple_pie': '🥧', 'macarons': '🍬',
  'tiramisu': '🍮', 'cheesecake': '🍰', 'spaghetti_bolognese': '🍝',
};

String emojiFor(String label) => _emojiMap[label] ?? '🍽️';

void main() {
  group('mealTypeForHour', () {
    test('hour 0-9 → Breakfast', () {
      for (int h = 0; h <= 9; h++) {
        expect(mealTypeForHour(h), 'Breakfast', reason: 'hour=$h');
      }
    });

    test('hour 10-13 → Lunch', () {
      for (int h = 10; h <= 13; h++) {
        expect(mealTypeForHour(h), 'Lunch', reason: 'hour=$h');
      }
    });

    test('hour 14-17 → Snack', () {
      for (int h = 14; h <= 17; h++) {
        expect(mealTypeForHour(h), 'Snack', reason: 'hour=$h');
      }
    });

    test('hour 18-23 → Dinner', () {
      for (int h = 18; h <= 23; h++) {
        expect(mealTypeForHour(h), 'Dinner', reason: 'hour=$h');
      }
    });
  });

  group('emojiFor', () {
    test('known labels return correct emoji', () {
      expect(emojiFor('pizza'), '🍕');
      expect(emojiFor('hamburger'), '🍔');
      expect(emojiFor('sushi'), '🍱');
      expect(emojiFor('ramen'), '🍜');
      expect(emojiFor('tacos'), '🌮');
      expect(emojiFor('waffles'), '🧇');
      expect(emojiFor('steak'), '🥩');
      expect(emojiFor('grilled_salmon'), '🐟');
    });

    test('unknown label returns default emoji', () {
      expect(emojiFor('unknown_food'), '🍽️');
      expect(emojiFor(''), '🍽️');
      expect(emojiFor('xyz'), '🍽️');
    });

    test('all 20 mapped labels return non-default emoji', () {
      for (final label in _emojiMap.keys) {
        expect(emojiFor(label), isNot('🍽️'),
            reason: '"$label" should have a custom emoji');
      }
    });
  });

  group('Preprocessing formula', () {
    test('normalizes 0 → -1.0', () {
      expect((0 / 127.5) - 1.0, closeTo(-1.0, 0.001));
    });

    test('normalizes 255 → +1.0', () {
      expect((255 / 127.5) - 1.0, closeTo(1.0, 0.001));
    });

    test('normalizes 127 → ~0.0', () {
      expect((127 / 127.5) - 1.0, closeTo(-0.004, 0.001));
    });

    test('normalizes 128 → ~+0.004', () {
      expect((128 / 127.5) - 1.0, closeTo(0.004, 0.001));
    });

    test('full pixel range stays within [-1, +1]', () {
      for (int px = 0; px <= 255; px++) {
        final normalized = (px / 127.5) - 1.0;
        expect(normalized, greaterThanOrEqualTo(-1.001));
        expect(normalized, lessThanOrEqualTo(1.001));
      }
    });
  });

  group('Top-K selection', () {
    test('selects highest confidence scores', () {
      final scores = [0.01, 0.85, 0.05, 0.07, 0.02];
      final indexed = List.generate(scores.length, (i) => [i, scores[i]])
        ..sort((a, b) => (b[1] as double).compareTo(a[1] as double));
      expect(indexed.first[0], 1); // index 1 has score 0.85
      expect(indexed[1][0], 3);    // index 3 has 0.07
    });

    test('top-1 confidence is always the max', () {
      final scores = [0.03, 0.12, 0.72, 0.08, 0.05];
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final indexed = List.generate(scores.length, (i) => [i, scores[i]])
        ..sort((a, b) => (b[1] as double).compareTo(a[1] as double));
      expect(indexed.first[1], maxScore);
    });
  });
}
