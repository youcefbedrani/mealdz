import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction.dart';
import '../services/classifier_service.dart';

// True once the model has been loaded into memory
final classifierLoadedProvider = FutureProvider<bool>((ref) async {
  await ClassifierService.instance.load();
  return true;
});

// Holds the latest classification result (null = not yet run)
final predictionProvider =
    StateNotifierProvider<PredictionNotifier, AsyncValue<List<Prediction>?>>(
        (ref) => PredictionNotifier());

class PredictionNotifier
    extends StateNotifier<AsyncValue<List<Prediction>?>> {
  PredictionNotifier() : super(const AsyncValue.data(null));

  Future<void> classify(Uint8List imageBytes) async {
    state = const AsyncValue.loading();
    try {
      final results =
          await ClassifierService.instance.classify(imageBytes, topK: 5);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
