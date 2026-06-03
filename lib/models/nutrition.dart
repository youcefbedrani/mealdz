import 'package:hive/hive.dart';

part 'nutrition.g.dart';

@HiveType(typeId: 1)
class Nutrition extends HiveObject {
  @HiveField(0)
  final String foodLabel;

  @HiveField(1)
  final double calories;

  @HiveField(2)
  final double protein;

  @HiveField(3)
  final double carbs;

  @HiveField(4)
  final double fat;

  @HiveField(5)
  final double fiber;

  @HiveField(6)
  final double sugar;

  @HiveField(7)
  final String servingSize;

  Nutrition({
    required this.foodLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.servingSize,
  });

  factory Nutrition.fromJson(Map<String, dynamic> j) => Nutrition(
        foodLabel: j['food_label'] as String,
        calories: (j['calories_kcal'] as num).toDouble(),
        protein: (j['protein_g'] as num).toDouble(),
        carbs: (j['carbs_g'] as num).toDouble(),
        fat: (j['fat_g'] as num).toDouble(),
        fiber: (j['fiber_g'] as num).toDouble(),
        sugar: (j['sugar_g'] as num).toDouble(),
        servingSize: j['serving_size'] as String,
      );

  Nutrition copyWith({double? calories, double? protein, double? carbs, double? fat}) =>
      Nutrition(
        foodLabel: foodLabel,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber,
        sugar: sugar,
        servingSize: servingSize,
      );
}
