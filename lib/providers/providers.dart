import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../repositories/meal_repository.dart';
import 'auth_provider.dart';

// Core singletons
final localStorageProvider = Provider<LocalStorageService>((_) => LocalStorageService());

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(
    ref.read(localStorageProvider),
    ref.read(authServiceProvider),
  );
});
