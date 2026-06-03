# MealScan AI

**Mobile Solution for Automated Meal Analysis Using Computer Vision**  

## Stack

Flutter 3.27 · Dart 3.6 · MVVM + Riverpod · MobileNetV2 TFLite · Hive · Firebase

## Quick start

```bash
# 1. Secrets (Edamam optional — local JSON is primary)
cp lib/config/secrets.example.dart lib/config/secrets.dart

# 2. Place google-services.json in android/app/

# 3. Train model on Colab → copy outputs:
#    assets/models/food101_mobilenetv2.tflite
#    assets/labels/food101_labels.txt

# 4. Run / build
flutter pub get
flutter run
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
```

## Model (thesis Ch. 2)

| | |
|---|---|
| Architecture | MobileNetV2 + 2-layer head |
| Dataset | Food-101 · 101 classes · 750 train / 250 test per class |
| Preprocessing | resize 224×224 bilinear · normalize `(px/127.5)−1` |
| Training | Phase 1: head lr=1e-3 10 ep · Phase 2: fine-tune lr=1e-5 20 ep |
| Export | TFLite float16 ≈ 7 MB |
| Notebook | `notebooks/train_mobilenetv2_food101.ipynb` |

## Structure

```
lib/
  main.dart
  config/      secrets.example.dart
  models/      Meal · Nutrition · Prediction + Hive adapters
  providers/   auth · classifier · meal · weekly chart (Riverpod)
  repositories/ MealRepository (Hive + Firestore cloud sync)
  screens/     splash · login · register · home · camera · result · history
  services/    auth · classifier_service (TFLite) · nutrition · local_storage
assets/
  models/  food101_mobilenetv2.tflite
  data/    nutrition_food101.json  (101 USDA entries)
  labels/  food101_labels.txt
notebooks/ train_mobilenetv2_food101.ipynb
```
