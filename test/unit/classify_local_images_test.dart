import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_analyzer/services/classifier_service.dart';

void main() {
  // Ensure Flutter binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Classifier Integration Test on User Images', () {
    bool isTfliteAvailable = true;

    setUpAll(() async {
      try {
        await ClassifierService.instance.load();
      } catch (e) {
        isTfliteAvailable = false;
        print('TFLite library loading failed. Skipping tests: $e');
      }
    });

    test('Classify 1-meal.jpg', () async {
      if (!isTfliteAvailable) {
        markTestSkipped('TFLite library not available on this platform.');
        return;
      }
      final file = File('/home/badran/Downloads/GENZ_ONE/ai-master/meal_analyzer/1-meal.jpg');
      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      final predictions = await ClassifierService.instance.classify(bytes);
      print('Predictions for 1-meal.jpg:');
      for (final p in predictions) {
        print('  - ${p.displayName} (${(p.confidence * 100).toStringAsFixed(1)}%)');
      }
    });

    test('Classify 2-meal.jpeg', () async {
      if (!isTfliteAvailable) {
        markTestSkipped('TFLite library not available on this platform.');
        return;
      }
      final file = File('/home/badran/Downloads/GENZ_ONE/ai-master/meal_analyzer/2-meal.jpeg');
      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      final predictions = await ClassifierService.instance.classify(bytes);
      print('Predictions for 2-meal.jpeg:');
      for (final p in predictions) {
        print('  - ${p.displayName} (${(p.confidence * 100).toStringAsFixed(1)}%)');
      }
    });

    test('Classify 3-meal.jpeg', () async {
      if (!isTfliteAvailable) {
        markTestSkipped('TFLite library not available on this platform.');
        return;
      }
      final file = File('/home/badran/Downloads/GENZ_ONE/ai-master/meal_analyzer/3-meal.jpeg');
      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      final predictions = await ClassifierService.instance.classify(bytes);
      print('Predictions for 3-meal.jpeg:');
      for (final p in predictions) {
        print('  - ${p.displayName} (${(p.confidence * 100).toStringAsFixed(1)}%)');
      }
    });
  });
}
