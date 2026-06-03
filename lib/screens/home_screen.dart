import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:hive/hive.dart';
import '../models/meal.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/advice_provider.dart';
import '../utils/app_routes.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _waterCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWaterCount();
    _checkDiseasesOnboarding();
  }

  void _checkDiseasesOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Hive.isBoxOpen('settings')) {
          final box = Hive.box('settings');
          final onboardingDone = box.get('has_selected_diseases_v1', defaultValue: false) as bool;
          if (!onboardingDone) {
            _showDiseasesOnboardingDialog();
          }
        }
      } catch (_) {}
    });
  }

  void _showDiseasesOnboardingDialog() {
    final locale = ref.read(localeProvider);
    final isAr = locale.languageCode == 'ar';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final prefs = ref.watch(userPrefsProvider);
            final notifier = ref.read(userPrefsProvider.notifier);
            final diseaseKeys = ['diabetes', 'hypertension', 'celiac', 'lactose', 'kidney', 'cholesterol'];

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    const Icon(Icons.health_and_safety, color: Color(0xFF1D9E75), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppTranslations.translate(locale.languageCode, 'health_conditions'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.translate(locale.languageCode, 'health_conditions_desc'),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: diseaseKeys.map((key) {
                          final isSelected = prefs.diseases.contains(key);
                          return FilterChip(
                            label: Text(
                              AppTranslations.translate(locale.languageCode, key),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1D9E75) : Colors.grey[700],
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                            checkmarkColor: const Color(0xFF1D9E75),
                            backgroundColor: const Color(0xFFF5F5F2),
                            onSelected: (selected) {
                              final current = List<String>.from(prefs.diseases);
                              if (selected) {
                                current.add(key);
                              } else {
                                current.remove(key);
                              }
                              notifier.setDiseases(current);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (Hive.isBoxOpen('settings')) {
                            final box = Hive.box('settings');
                            await box.put('has_selected_diseases_v1', true);
                          }
                        } catch (_) {}
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        isAr ? 'متابعة' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _loadWaterCount() {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        setState(() {
          _waterCount = box.get('water_count_v1_$todayStr', defaultValue: 0) as int;
        });
      }
    } catch (_) {}
  }

  Future<void> _incrementWater() async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final newCount = _waterCount + 1;
        await box.put('water_count_v1_$todayStr', newCount);
        setState(() {
          _waterCount = newCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _decrementWater() async {
    if (_waterCount <= 0) return;
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final newCount = _waterCount - 1;
        await box.put('water_count_v1_$todayStr', newCount);
        setState(() {
          _waterCount = newCount;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F2),
        body: SafeArea(
            child:
                _currentIndex == 0 ? _buildDashboard(locale) : const HistoryScreen()),
        bottomNavigationBar: _buildBottomNav(locale),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, slideUpRoute(const CameraScreen())),
          backgroundColor: const Color(0xFF1D9E75),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.camera_alt),
          label: Text(AppTranslations.translate(locale.languageCode, 'scan_meal'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildDashboard(Locale locale) {
    final meals = ref.watch(todayMealsProvider);
    final notifier = ref.read(todayMealsProvider.notifier);
    final user = ref.watch(authStateProvider).valueOrNull;
    final goalCalories = ref.watch(userPrefsProvider).dailyCalorieGoal;
    final totalCal = notifier.totalCalories;
    final progress = (totalCal / goalCalories).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(user?.displayName ?? 'User', locale),
          const SizedBox(height: 20),
          _buildAdviceSection(locale),
          const SizedBox(height: 20),
          _buildCalorieCard(totalCal, goalCalories, progress, locale),
          const SizedBox(height: 20),
          _buildDeficitSurplusTracker(totalCal, goalCalories, locale),
          const SizedBox(height: 20),
          _buildWaterTracker(locale),
          const SizedBox(height: 20),
          _buildMacroRow(notifier, locale),
          const SizedBox(height: 20),
          _buildMealsSection(meals, locale),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(Locale locale) {
    final adviceState = ref.watch(dailyAdviceProvider);

    return adviceState.when(
      data: (advice) {
        return Container(
          width: double.infinity,
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
              Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF1D9E75), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.translate(locale.languageCode, 'advice_dashboard'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1D9E75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                advice,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A4A4A),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1D9E75),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppTranslations.translate(locale.languageCode, 'loading_advice'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (err, _) => const SizedBox(),
    );
  }

  Widget _buildHeader(String name, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? (isAr ? 'صباح الخير' : 'Good morning')
        : hour < 18
            ? (isAr ? 'مساء الخير' : 'Good afternoon')
            : (isAr ? 'مساء الخير' : 'Good evening');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting, $name! 👋',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, MMMM d · y', locale.languageCode).format(DateTime.now()),
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, slideUpRoute(const ChatScreen())),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Color(0xFF1D9E75), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, slideUpRoute(const ProfileScreen())),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1D9E75),
                child: Text(
                  () {
                    final name = ref.watch(authStateProvider).valueOrNull?.displayName;
                    return (name != null && name.isNotEmpty)
                        ? name.substring(0, 1).toUpperCase()
                        : 'U';
                  }(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalorieCard(
      double totalCal, double goal, double progress, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: const Color(0xFF1D9E75),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppTranslations.translate(locale.languageCode, 'today_calories'),
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalCal.round().toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Text(
                    isAr ? '/ هدف ${goal.round()} سعرة' : '/ ${goal.round()} kcal',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
              isAr
                  ? 'المتبقي: ${(goal - totalCal).clamp(0, goal).round()} سعرة'
                  : '${(goal - totalCal).clamp(0, goal).round()} kcal remaining',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMacroRow(MealNotifier notifier, Locale locale) {
    final macros = [
      {
        'label': AppTranslations.translate(locale.languageCode, 'protein'),
        'value': '${notifier.totalProtein.toStringAsFixed(0)}g',
        'color': const Color(0xFF1D9E75)
      },
      {
        'label': AppTranslations.translate(locale.languageCode, 'carbs'),
        'value': '${notifier.totalCarbs.toStringAsFixed(0)}g',
        'color': const Color(0xFF378ADD)
      },
      {
        'label': AppTranslations.translate(locale.languageCode, 'fat'),
        'value': '${notifier.totalFat.toStringAsFixed(0)}g',
        'color': const Color(0xFFEF9F27)
      },
    ];
    return Row(
      children: macros.map((m) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Text(m['value'] as String,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: m['color'] as Color)),
                const SizedBox(height: 4),
                Text(m['label'] as String,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888780))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealsSection(List<Meal> meals, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppTranslations.translate(locale.languageCode, 'today_meals'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: Text(isAr ? 'عرض الكل' : 'See all',
                  style: const TextStyle(color: Color(0xFF1D9E75))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (meals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Text(AppTranslations.translate(locale.languageCode, 'no_meals_today'),
                  style: const TextStyle(color: Color(0xFF888780), fontSize: 14)),
            ),
          )
        else
          ...meals.map((m) => _mealTile(m, locale)),
      ],
    );
  }

  Widget _mealTile(Meal meal, Locale locale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFF5F5F2),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(meal.emoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(FoodTranslations.translate(locale.languageCode, meal.name),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(
                    '${DateFormat('h:mm a').format(meal.loggedAt)} · ${meal.mealType}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888780))),
              ],
            ),
          ),
          Text('${meal.calories.round()} kcal',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Locale locale) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, AppTranslations.translate(locale.languageCode, 'dashboard'), 0),
            const SizedBox(width: 60),
            _navItem(Icons.history_rounded, AppTranslations.translate(locale.languageCode, 'history'), 1),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: active
                  ? const Color(0xFF1D9E75)
                  : const Color(0xFF888780)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: active
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF888780))),
        ],
      ),
    );
  }

  Widget _buildDeficitSurplusTracker(double totalCal, double goal, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final balance = totalCal - goal;
    final isDeficit = balance <= 0;
    final absBalance = balance.abs().round();

    final cardColor = isDeficit ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final borderColor = isDeficit ? const Color(0xFF81C784) : const Color(0xFFFFB74D);
    final titleColor = isDeficit ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final icon = isDeficit ? Icons.trending_down : Icons.trending_up;
    
    final statusText = isAr
        ? (isDeficit
            ? 'أنت الآن في حالة عجز سعرات حرارية بقيمة $absBalance سعرة. ممتاز لخسارة الدهون!'
            : 'أنت الآن في حالة فائض سعرات حرارية بقيمة $absBalance سعرة. مناسب لبناء العضلات!')
        : (isDeficit
            ? 'You are in a Calorie Deficit of $absBalance kcal. Excellent for fat loss!'
            : 'You are in a Calorie Surplus of $absBalance kcal. Good for muscle gain / bulk!');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: titleColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'حالة التوازن الحراري' : 'Energy Balance Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: titleColor.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_drink_rounded, color: Color(0xFF378ADD), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'مقتفي شرب الماء' : 'Water Intake Tracker',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Text(
                '$_waterCount / 8 ${isAr ? "أكواب" : "cups"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF378ADD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(8, (index) {
                  final filled = index < _waterCount;
                  return Icon(
                    Icons.water_drop,
                    color: filled ? const Color(0xFF378ADD) : Colors.grey[300],
                    size: 20,
                  );
                }),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _decrementWater,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove, color: Colors.grey, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _incrementWater,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF378ADD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
