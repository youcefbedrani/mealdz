import 'nutrition.dart';

class Prediction {
  final String label;
  final double confidence;
  final Nutrition? nutrition;

  const Prediction({
    required this.label,
    required this.confidence,
    this.nutrition,
  });

  String get displayName => label
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
