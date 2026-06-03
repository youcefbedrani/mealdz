import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 0)
class Meal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String emoji;

  @HiveField(3)
  final String mealType;

  @HiveField(4)
  final double calories;

  @HiveField(5)
  final double protein;

  @HiveField(6)
  final double carbs;

  @HiveField(7)
  final double fat;

  @HiveField(8)
  final DateTime loggedAt;

  @HiveField(9)
  final String? imageUrl;

  @HiveField(10)
  final String? foodLabel;

  @HiveField(11)
  final double confidence;

  @HiveField(12)
  final bool synced;

  Meal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    this.imageUrl,
    this.foodLabel,
    this.confidence = 0.0,
    this.synced = false,
  });

  Meal copyWith({bool? synced, String? imageUrl}) => Meal(
        id: id,
        name: name,
        emoji: emoji,
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        loggedAt: loggedAt,
        imageUrl: imageUrl ?? this.imageUrl,
        foodLabel: foodLabel,
        confidence: confidence,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'loggedAt': loggedAt.toIso8601String(),
        'imageUrl': imageUrl ?? '',
        'foodLabel': foodLabel ?? '',
        'confidence': confidence,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'loggedAt': loggedAt.toIso8601String(),
        'imageUrl': imageUrl ?? '',
      };

  factory Meal.fromFirestore(Map<String, dynamic> doc) => Meal(
        id: doc['id'] as String,
        name: doc['name'] as String,
        emoji: doc['emoji'] as String? ?? '🍽️',
        mealType: doc['mealType'] as String? ?? 'Meal',
        calories: (doc['calories'] as num).toDouble(),
        protein: (doc['protein'] as num).toDouble(),
        carbs: (doc['carbs'] as num).toDouble(),
        fat: (doc['fat'] as num).toDouble(),
        loggedAt: DateTime.parse(doc['loggedAt'] as String),
        imageUrl: doc['imageUrl'] as String?,
        foodLabel: doc['foodLabel'] as String?,
        confidence: (doc['confidence'] as num?)?.toDouble() ?? 0.0,
        synced: true,
      );
}
