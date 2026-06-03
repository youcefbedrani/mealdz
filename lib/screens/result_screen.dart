import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction.dart';
import '../models/nutrition.dart';
import '../providers/classifier_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../utils/app_routes.dart';
import '../services/groq_service.dart';
import '../services/nutrition_service.dart';
import 'home_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final Uint8List imageBytes;

  const ResultScreen({super.key, required this.imageBytes});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _logging = false;
  Prediction? _customPrediction;
  double _portionScale = 1.0;

  // AI custom health advice & adjuster states
  Future<Map<String, String>?>? _healthReviewFuture;
  final TextEditingController _adjusterCtrl = TextEditingController();
  bool _isAdjusting = false;
  bool _isLoadingNutrition = false;

  void _initPrediction(Prediction top, Locale locale) {
    if (_customPrediction == null) {
      _customPrediction = Prediction(
        label: top.label,
        confidence: top.confidence,
        nutrition: top.nutrition ?? Nutrition(
          foodLabel: top.label,
          calories: 200.0,
          protein: 8.0,
          carbs: 25.0,
          fat: 8.0,
          fiber: 1.5,
          sugar: 3.0,
          servingSize: '100g',
        ),
      );
      _healthReviewFuture = _getHealthReview(_customPrediction!.displayName, _customPrediction!.nutrition!, locale);
    }
  }

  Future<void> _selectPrediction(Prediction selected, Locale locale) async {
    if (_customPrediction?.label == selected.label && _customPrediction?.nutrition != null) return;

    if (selected.nutrition != null) {
      setState(() {
        _customPrediction = selected;
        _healthReviewFuture = _getHealthReview(selected.displayName, selected.nutrition!, locale);
      });
      return;
    }

    setState(() {
      _isLoadingNutrition = true;
      _customPrediction = Prediction(
        label: selected.label,
        confidence: selected.confidence,
        nutrition: null,
      );
    });

    final nutrition = await NutritionService.instance.lookup(selected.label) ?? Nutrition(
      foodLabel: selected.label,
      calories: 200.0,
      protein: 8.0,
      carbs: 25.0,
      fat: 8.0,
      fiber: 1.5,
      sugar: 3.0,
      servingSize: '100g',
    );

    setState(() {
      _isLoadingNutrition = false;
      _customPrediction = Prediction(
        label: selected.label,
        confidence: selected.confidence,
        nutrition: nutrition,
      );
      _healthReviewFuture = _getHealthReview(selected.displayName, nutrition, locale);
    });
  }

  Future<Map<String, String>?> _getHealthReview(String foodName, Nutrition nutrition, Locale locale) async {
    try {
      final isAr = locale.languageCode == 'ar';
      final prefs = ref.read(userPrefsProvider);
      
      String diseaseContext = '';
      if (prefs.diseases.isNotEmpty) {
        diseaseContext = isAr
            ? '\nيعاني المستخدم من الحالات الصحية التالية: ${prefs.diseases.join(', ')}. يرجى تقييم ملاءمة هذا الطعام لحالته الصحية. إذا كان الطعام غير مناسب له (مثلاً غني بالسكريات لمرضى السكري، أو الصوديوم لمرض ضغط الدم/الكلى، أو الجلوتين للسيلياك، أو الكوليسترول)، يرجى خفض التقييم إلى C أو D، والبدء بكلمة "تحذير: " أو "تنبيه: " مع شرح الخطر بوضوح وبإيجاز.'
            : '\nThe user has the following medical conditions: ${prefs.diseases.join(', ')}. Please evaluate if this meal is safe or highly hazardous/problematic for their specific conditions (e.g. sugar for diabetes, sodium for hypertension/kidney disease, gluten for celiac, lactose for lactose intolerance, high cholesterol). If unsafe, reduce the grade to C or D and start the review with the word "WARNING: " explaining the exact health hazard concisely.';
      } else {
        diseaseContext = isAr
            ? '\nالمستخدم لا يعاني من أي حالات صحية خاصة.'
            : '\nThe user has no chronic health conditions.';
      }

      final prompt = 'The food item is "$foodName" with nutrition facts per 100g: '
          '${nutrition.calories} kcal, ${nutrition.protein}g protein, ${nutrition.carbs}g carbs, ${nutrition.fat}g fat. '
          'Give a very short 1-sentence health advice and review for a user eating this meal. '
          'Also provide a letter grade (like A+, A, B+, B, C, D) representing how healthy it is. '
          'Format the output as a simple JSON object: {"grade": "string", "review": "string"}. '
          '$diseaseContext '
          '${isAr ? "The review MUST be in Arabic language." : "The review MUST be in English."}';
      
      final reply = await GroqService.chat(
        [{'role': 'user', 'content': prompt}],
        systemPromptOverride: 'You are a professional nutrition and sports dietitian. Return ONLY a raw JSON object with fields "grade" and "review". Do not write anything else, no formatting, markdown, or code block syntax.',
      );
      
      final cleanJson = reply.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson) as Map<String, dynamic>;
      
      return {
        'grade': (data['grade'] as String?) ?? 'B',
        'review': (data['review'] as String?) ?? (isAr ? 'وجبة متوازنة ومغذية.' : 'A balanced meal choice.'),
      };
    } catch (_) {
      final isAr = locale.languageCode == 'ar';
      return {
        'grade': 'B',
        'review': isAr ? 'وجبة متوازنة ومغذية. خيار ممتاز ليومك!' : 'Balanced nutrition profile. Great choice for daily fueling!',
      };
    }
  }

  Future<void> _recalculateMacros(Locale locale) async {
    final text = _adjusterCtrl.text.trim();
    if (text.isEmpty) return;
    if (_customPrediction?.nutrition == null) return;

    setState(() => _isAdjusting = true);

    try {
      final base = _customPrediction!.nutrition!;
      final isAr = locale.languageCode == 'ar';
      final prompt = 'The original food is "${_customPrediction!.displayName}" with the following nutrition facts per 100g: '
          'Calories: ${base.calories} kcal, Protein: ${base.protein}g, Carbs: ${base.carbs}g, Fat: ${base.fat}g, Fiber: ${base.fiber}g, Sugar: ${base.sugar}g. '
          'The user describes these modifications to their meal: "$text". '
          'Recalculate the adjusted nutrition facts for 100g of this modified meal. '
          'Return ONLY a raw JSON object matching this format exactly: '
          '{"calories": double, "protein": double, "carbs": double, "fat": double, "fiber": double, "sugar": double}';

      final reply = await GroqService.chat(
        [{'role': 'user', 'content': prompt}],
        systemPromptOverride: 'You are a precise nutrition calculator API. Respond ONLY with a raw JSON object matching the requested format. Do not write any explanations, code blocks, or markdown.',
      );

      final cleanJson = reply.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = json.decode(cleanJson) as Map<String, dynamic>;

      final newNut = Nutrition(
        foodLabel: base.foodLabel,
        calories: (data['calories'] as num?)?.toDouble() ?? base.calories,
        protein: (data['protein'] as num?)?.toDouble() ?? base.protein,
        carbs: (data['carbs'] as num?)?.toDouble() ?? base.carbs,
        fat: (data['fat'] as num?)?.toDouble() ?? base.fat,
        fiber: (data['fiber'] as num?)?.toDouble() ?? base.fiber,
        sugar: (data['sugar'] as num?)?.toDouble() ?? base.sugar,
        servingSize: base.servingSize,
      );

      setState(() {
        _customPrediction = Prediction(
          label: _customPrediction!.label,
          confidence: _customPrediction!.confidence,
          nutrition: newNut,
        );
        _adjusterCtrl.clear();
        _healthReviewFuture = _getHealthReview(_customPrediction!.displayName, newNut, locale);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم إعادة الحساب بالذكاء الاصطناعي بنجاح!' : 'AI successfully recalculated macros!'),
          backgroundColor: const Color(0xFF1D9E75),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(locale.languageCode == 'ar' ? 'حدث خطأ أثناء إعادة الحساب.' : 'Error recalculating macros.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    } finally {
      setState(() => _isAdjusting = false);
    }
  }

  Future<void> _logMeal(List<Prediction> predictions, Locale locale) async {
    if (predictions.isEmpty) return;
    _initPrediction(predictions.first, locale);
    if (_customPrediction?.nutrition == null) return;
    setState(() => _logging = true);

    final baseNut = _customPrediction!.nutrition!;
    final finalNut = Nutrition(
      foodLabel: baseNut.foodLabel,
      calories: baseNut.calories * _portionScale,
      protein: baseNut.protein * _portionScale,
      carbs: baseNut.carbs * _portionScale,
      fat: baseNut.fat * _portionScale,
      fiber: baseNut.fiber * _portionScale,
      sugar: baseNut.sugar * _portionScale,
      servingSize: '${(_portionScale * 100).round()}g',
    );

    final finalPred = Prediction(
      label: _customPrediction!.label,
      confidence: _customPrediction!.confidence,
      nutrition: finalNut,
    );

    await ref
        .read(todayMealsProvider.notifier)
        .logMeal(finalPred, imageBytes: widget.imageBytes);
    
    setState(() => _logging = false);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppTranslations.translate(locale.languageCode, 'meal_saved_success')),
        backgroundColor: const Color(0xFF1D9E75),
        duration: const Duration(seconds: 2)));
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      fadeRoute(const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final predState = ref.watch(predictionProvider);
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: predState.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFFF5F5F2),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75))),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: const Color(0xFFF5F5F2),
          body: _buildErrorState(e.toString(), locale),
        ),
        data: (predictions) {
          if (predictions == null || predictions.isEmpty) {
            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F2),
              body: _buildErrorState('empty', locale),
            );
          }
          _initPrediction(predictions.first, locale);
          return _buildResult(predictions, locale);
        },
      ),
    );
  }

  Widget _buildErrorState(String message, Locale locale) {
    final friendly = _friendlyError(message, locale);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.search_off_rounded,
                  color: Colors.red, size: 40),
            ),
            const SizedBox(height: 24),
            Text(AppTranslations.translate(locale.languageCode, 'analysis_failed'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            Text(friendly,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888780),
                    height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(AppTranslations.translate(locale.languageCode, 'try_again'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(String raw, Locale locale) {
    if (raw.contains('network') || raw.contains('SocketException') || raw.contains('connection')) {
      return AppTranslations.translate(locale.languageCode, 'offline_warning');
    }
    if (raw.contains('tflite') || raw.contains('Interpreter') || raw.contains('model')) {
      return AppTranslations.translate(locale.languageCode, 'model_not_ready');
    }
    if (raw.contains('identify') || raw.contains('prediction') || raw.contains('empty')) {
      return AppTranslations.translate(locale.languageCode, 'unidentified_food');
    }
    return locale.languageCode == 'ar'
        ? 'حدث خطأ ما. يرجى المحاولة مرة أخرى.'
        : 'Something went wrong. Please try scanning again.';
  }

  Widget _buildResult(List<Prediction> predictions, Locale locale) {
    final top = predictions.first;
    _initPrediction(top, locale);
    final baseNut = _customPrediction?.nutrition;
    
    final displayNut = baseNut == null ? null : Nutrition(
      foodLabel: baseNut.foodLabel,
      calories: baseNut.calories * _portionScale,
      protein: baseNut.protein * _portionScale,
      carbs: baseNut.carbs * _portionScale,
      fat: baseNut.fat * _portionScale,
      fiber: baseNut.fiber * _portionScale,
      sugar: baseNut.sugar * _portionScale,
      servingSize: '${(_portionScale * 100).round()}g',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildHero(predictions.first, displayNut, locale),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPortionCard(locale),
                    const SizedBox(height: 16),
                    _buildMacroGrid(displayNut, locale),
                    const SizedBox(height: 20),
                    if (displayNut != null) ...[
                      _buildAiButtonsRow(_customPrediction ?? predictions.first, locale),
                      const SizedBox(height: 16),
                      _buildAiAdjusterCard(locale),
                      const SizedBox(height: 16),
                      _buildAiHealthReviewCard(locale),
                      const SizedBox(height: 20),
                    ],
                    _buildAlternatives(predictions, locale),
                    const SizedBox(height: 28),
                    _buildLogButton(predictions, locale),
                    const SizedBox(height: 12),
                    _buildScanAgainButton(locale),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(Prediction top, dynamic nutrition, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final current = _customPrediction ?? top;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1D9E75),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(AppTranslations.translate(locale.languageCode, 'analysis_result'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(14)),
                child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(FoodTranslations.translate(locale.languageCode, current.displayName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        '${(current.confidence * 100).toStringAsFixed(1)}% ${isAr ? "ثقة" : "confidence"} · ${nutrition?.servingSize ?? "100g"}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortionCard(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final weight = (_portionScale * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'تعديل الحصة والجرام' : 'Adjust Portion Size',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '$weight g',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D9E75), fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _portionScale,
            min: 0.2,
            max: 3.0,
            divisions: 28,
            activeColor: const Color(0xFF1D9E75),
            inactiveColor: Colors.grey[200],
            onChanged: (val) {
              setState(() {
                _portionScale = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiButtonsRow(Prediction top, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showEditMacrosDialog(locale),
            icon: const Icon(Icons.edit_note, size: 18),
            label: Text(
              isAr ? 'تعديل القيم' : 'Edit Macros',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1D9E75),
              side: const BorderSide(color: Color(0xFF1D9E75), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAiRecipeSheet(top.displayName, locale),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(
              isAr ? 'بدائل ووصفة' : 'AI Advice & Recipe',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditMacrosDialog(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final baseNut = _customPrediction!.nutrition!;
    
    final caloriesCtrl = TextEditingController(text: baseNut.calories.round().toString());
    final proteinCtrl = TextEditingController(text: baseNut.protein.round().toString());
    final carbsCtrl = TextEditingController(text: baseNut.carbs.round().toString());
    final fatCtrl = TextEditingController(text: baseNut.fat.round().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(isAr ? 'تعديل قيم 100 جرام' : 'Edit Facts (per 100g)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(isAr ? 'السعرات (kcal)' : 'Calories (kcal)', caloriesCtrl),
                  _dialogField(isAr ? 'البروتين (g)' : 'Protein (g)', proteinCtrl),
                  _dialogField(isAr ? 'الكربوهيدرات (g)' : 'Carbs (g)', carbsCtrl),
                  _dialogField(isAr ? 'الدهون (g)' : 'Fat (g)', fatCtrl),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _customPrediction = Prediction(
                      label: _customPrediction!.label,
                      confidence: _customPrediction!.confidence,
                      nutrition: Nutrition(
                        foodLabel: baseNut.foodLabel,
                        calories: double.tryParse(caloriesCtrl.text) ?? baseNut.calories,
                        protein: double.tryParse(proteinCtrl.text) ?? baseNut.protein,
                        carbs: double.tryParse(carbsCtrl.text) ?? baseNut.carbs,
                        fat: double.tryParse(fatCtrl.text) ?? baseNut.fat,
                        fiber: baseNut.fiber,
                        sugar: baseNut.sugar,
                        servingSize: baseNut.servingSize,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white),
                child: Text(isAr ? 'حفظ' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  void _showAiRecipeSheet(String foodName, Locale locale) {
    final isAr = locale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? sheetText;
        bool sheetLoading = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (sheetText == null && sheetLoading) {
              final prompt = locale.languageCode == 'ar'
                  ? 'لقد قام المستخدم بمسح الوجبة التالية: $foodName. أعط المستخدم بسرعة بديلين صحيين لهذه الوجبة مع وصفة صحية واحدة موجزة جداً باللغة العربية. استخدم تنسيق مبسط ومنظم.'
                  : 'The user scanned this meal: $foodName. Please recommend 2 healthy alternative meal options and 1 very brief, healthy recipe for this food. Keep it concise, engaging, and well-formatted.';

              GroqService.chat([{'role': 'user', 'content': prompt}], languageCode: locale.languageCode).then((reply) {
                setModalState(() {
                  sheetText = reply;
                  sheetLoading = false;
                });
              }).catchError((_) {
                setModalState(() {
                  sheetText = locale.languageCode == 'ar' ? 'فشل تحميل النصائح.' : 'Failed to load advice.';
                  sheetLoading = false;
                });
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollCtrl) {
                return Directionality(
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        Text(
                          isAr ? 'بدائل صحية ووصفة من الذكاء الاصطناعي 💡' : 'AI Alternatives & Healthy Recipe 💡',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollCtrl,
                            child: sheetLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 40),
                                      child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
                                    ),
                                  )
                                : Text(
                                    sheetText ?? '',
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A), height: 1.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMacroGrid(dynamic nutrition, Locale locale) {
    if (nutrition == null) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1D9E75)),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: [
        _macroCard('${nutrition.calories.round()}', 'kcal', AppTranslations.translate(locale.languageCode, 'calories'),
            const Color(0xFF1D9E75)),
        _macroCard('${nutrition.protein.toStringAsFixed(0)}g', '',
            AppTranslations.translate(locale.languageCode, 'protein'), const Color(0xFF378ADD)),
        _macroCard('${nutrition.carbs.toStringAsFixed(0)}g', '', AppTranslations.translate(locale.languageCode, 'carbs'),
            const Color(0xFFEF9F27)),
        _macroCard('${nutrition.fat.toStringAsFixed(0)}g', '', AppTranslations.translate(locale.languageCode, 'fat'),
            const Color(0xFFD85A30)),
      ],
    );
  }

  Widget _buildAlternatives(List<Prediction> predictions, Locale locale) {
    if (predictions.length <= 1) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppTranslations.translate(locale.languageCode, 'other_possibilities'),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888780),
                letterSpacing: 0.8)),
        const SizedBox(height: 12),
        ...predictions.map((p) => _altTile(p, locale)),
      ],
    );
  }

  Widget _altTile(Prediction p, Locale locale) {
    final isSelected = _customPrediction?.label == p.label;
    
    return GestureDetector(
      onTap: () => _selectPrediction(p, locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D9E75) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                FoodTranslations.translate(locale.languageCode, p.displayName),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF1A1A1A),
                )
              )
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 16)
            else
              Text(
                '${(p.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 13, color: Color(0xFF888780))
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAdjusterCard(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'معدل الذكاء الاصطناعي للمكونات 🧪' : 'AI Ingredient Adjuster 🧪',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            isAr 
                ? 'أدخل التعديلات على وجبتك (مثال: "أضفت بيضة مقلية"، "بدون صلصة") وسيعيد الذكاء الاصطناعي حساب السعرات والمغذيات تلقائياً!'
                : 'Describe changes (e.g. "added 1 fried egg", "no cheese", "double rice") and AI will recalculate the macros!',
            style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _adjusterCtrl,
                  decoration: InputDecoration(
                    hintText: isAr ? 'مثال: أضفت ملعقة زيت زيتون...' : 'e.g., added 1 tbsp olive oil...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1D9E75)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              _isAdjusting
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1D9E75)),
                      ),
                    )
                  : InkWell(
                      onTap: () => _recalculateMacros(locale),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiHealthReviewCard(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return FutureBuilder<Map<String, String>?>(
      future: _healthReviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                ),
                const SizedBox(width: 14),
                Text(
                  isAr ? 'جاري تحليل التقييم الصحي بالذكاء الاصطناعي...' : 'Analyzing health rating with AI...',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) return const SizedBox();

        final grade = data['grade'] ?? 'B';
        final review = data['review'] ?? '';

        final isWarning = review.toUpperCase().contains('WARNING') || review.contains('تحذير') || review.contains('تنبيه');

        Color gradeColor = const Color(0xFF1D9E75);
        if (isWarning) {
          gradeColor = const Color(0xFFD85A30);
        } else if (grade.startsWith('A')) {
          gradeColor = const Color(0xFF1D9E75);
        } else if (grade.startsWith('B')) {
          gradeColor = const Color(0xFF378ADD);
        } else if (grade.startsWith('C')) {
          gradeColor = const Color(0xFFEF9F27);
        } else {
          gradeColor = const Color(0xFFD85A30);
        }

        final cardBackground = isWarning ? const Color(0xFFFFF3F3) : Colors.white;
        final cardBorder = isWarning ? Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5) : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            border: cardBorder,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isWarning)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    isWarning ? Icons.warning_amber_rounded : Icons.health_and_safety_rounded,
                    color: gradeColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWarning
                          ? (isAr ? 'تنبيه صحي هام ⚠️' : 'AI Safety Health Alert ⚠️')
                          : (isAr ? 'تقييم كوتش الذكاء الاصطناعي 🥗' : 'AI Coach Rating & Review 🥗'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isWarning ? const Color(0xFFB71C1C) : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review,
                      style: TextStyle(
                        fontSize: 13,
                        color: isWarning ? const Color(0xFF7F0000) : Colors.grey[700],
                        height: 1.4,
                        fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isWarning) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogButton(List<Prediction> predictions, Locale locale) {
    final enabled = !_logging && !_isLoadingNutrition && _customPrediction?.nutrition != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? () => _logMeal(predictions, locale) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF1D9E75).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _logging
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)),
                  const SizedBox(width: 12),
                  Text(AppTranslations.translate(locale.languageCode, 'saving_meal'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              )
            : Text(AppTranslations.translate(locale.languageCode, 'log_meal'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildScanAgainButton(Locale locale) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(AppTranslations.translate(locale.languageCode, 'scan_again'),
            style: const TextStyle(
                color: Color(0xFF1D9E75),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _macroCard(String value, String unit, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          if (unit.isNotEmpty)
            Text(unit,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF888780))),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Color(0xFF888780))),
        ],
      ),
    );
  }
}
