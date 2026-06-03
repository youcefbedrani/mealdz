import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/prediction.dart';
import '../models/nutrition.dart';
import 'nutrition_service.dart';

const _modelAsset  = 'assets/models/food101_mobilenetv2.tflite';
const _labelsAsset = 'assets/labels/aiy_food_V1_labels.txt';
const _inputSize   = 192;
const _numClasses  = 2024;

class ClassifierService {
  static ClassifierService? _instance;
  Interpreter? _interpreter;
  List<String>? _labels;

  ClassifierService._();
  static ClassifierService get instance =>
      _instance ??= ClassifierService._();

  Future<void> load() async {
    if (_interpreter != null) return;

    _interpreter = await Interpreter.fromAsset(_modelAsset);

    final rawLabels = await rootBundle.loadString(_labelsAsset);
    _labels = rawLabels
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (_labels!.isNotEmpty && _labels![0] != '__background__') {
      _labels!.insert(0, '__background__');
    }

    await NutritionService.instance.preload();
  }

  bool get isLoaded => _interpreter != null;

  Future<List<Prediction>> classify(
    Uint8List imageBytes, {
    int topK = 5,
  }) async {
    await load();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Cannot decode image');

    // Bilinear resize to 192x192
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Raw pixels [0, 255] (un-normalized)
    final input = Float32List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final px = resized.getPixel(x, y);
        input[idx++] = px.r.toDouble();
        input[idx++] = px.g.toDouble();
        input[idx++] = px.b.toDouble();
      }
    }

    final inputTensor = input.reshape([1, _inputSize, _inputSize, 3]);
    final outputTensor = List.filled(_numClasses, 0.0)
        .reshape([1, _numClasses]);

    _interpreter!.run(inputTensor, outputTensor);

    final scores = List<double>.from(outputTensor[0] as List);
    final indexed = List.generate(_numClasses, (i) => [i, scores[i]])
      ..sort((a, b) => (b[1] as double).compareTo(a[1] as double));

    final top = indexed.take(topK);
    final predictions = <Prediction>[];

    int rank = 0;
    for (final pair in top) {
      final classIdx = pair[0] as int;
      final confidence = pair[1] as double;
      final label = _labels![classIdx];
      Nutrition? nutrition;
      
      if (rank == 0) {
        nutrition = await NutritionService.instance.lookup(label) ?? Nutrition(
          foodLabel: label,
          calories: 200.0,
          protein: 8.0,
          carbs: 25.0,
          fat: 8.0,
          fiber: 1.5,
          sugar: 3.0,
          servingSize: '100g',
        );
      }
      
      predictions.add(
          Prediction(label: label, confidence: confidence, nutrition: nutrition));
      rank++;
    }
    return predictions;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _instance = null;
  }
}
