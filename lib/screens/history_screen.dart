import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/locale_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Breakfast', 'Lunch', 'Snack', 'Dinner'];
  String? _expandedId;
  static const _pageSize = 20;
  int _visibleCount = _pageSize;

  String _translateFilter(String filter, String code) {
    if (code == 'ar') {
      const map = {
        'All': 'الكل',
        'Breakfast': 'الفطور',
        'Lunch': 'الغداء',
        'Snack': 'سناك',
        'Dinner': 'العشاء',
      };
      return map[filter] ?? filter;
    }
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    final allMeals = ref.watch(allMealsProvider);
    final weeklyData = ref.watch(weeklyCaloriesProvider);
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    final filtered = (_selectedFilter == 'All'
            ? allMeals
            : allMeals.where((m) => m.mealType == _selectedFilter).toList())
        .take(_visibleCount)
        .toList();
    final totalFiltered = _selectedFilter == 'All'
        ? allMeals.length
        : allMeals.where((m) => m.mealType == _selectedFilter).length;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F2),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(allMeals, locale),
              _buildWeeklyChart(weeklyData, locale),
              _buildFilters(locale),
              Expanded(child: _buildMealList(filtered, totalFiltered, locale)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Meal> meals, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTranslations.translate(locale.languageCode, 'all_meals'),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(isAr ? 'آخر 7 أيام' : 'Last 7 days',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888780))),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: Color(0xFF1D9E75), size: 16),
                const SizedBox(width: 4),
                Text('${meals.length} ${isAr ? "وجبة" : "meals"}',
                    style: const TextStyle(
                        color: Color(0xFF1D9E75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<double> weeklyData, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    final goal = ref.watch(userPrefsProvider).dailyCalorieGoal;
    final dayLabels = isAr ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'] : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxY = weeklyData.fold(goal, (m, v) => v > m ? v : m) * 1.15;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAr ? 'هذا الأسبوع' : 'This week',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cal = rod.toY.round();
                      return BarTooltipItem(
                          '$cal kcal',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        final isToday = i == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isToday
                                    ? const Color(0xFF1D9E75)
                                    : const Color(0xFF888780)),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goal,
                  getDrawingHorizontalLine: (value) => const FlLine(
                      color: Color(0xFFE8E8E4),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isToday = i == 6;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyData[i],
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                        color: isToday
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFF1D9E75).withValues(alpha: 0.3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(Locale locale) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _selectedFilter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedFilter = _filters[i];
              _visibleCount = _pageSize;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1D9E75) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFFE8E8E4)),
              ),
              child: Text(_translateFilter(_filters[i], locale.languageCode),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? Colors.white
                          : const Color(0xFF888780))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealList(List<Meal> meals, int total, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    if (meals.isEmpty) {
      return Center(
        child: Text(AppTranslations.translate(locale.languageCode, 'no_history'),
            style: const TextStyle(color: Color(0xFF888780), fontSize: 14),
            textAlign: TextAlign.center),
      );
    }

    // Group by date
    final grouped = <String, List<Meal>>{};
    for (final meal in meals) {
      final key = DateFormat('EEEE, MMMM d · y', locale.languageCode).format(meal.loggedAt);
      grouped.putIfAbsent(key, () => []).add(meal);
    }

    final hasMore = _visibleCount < total;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: grouped.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == grouped.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: OutlinedButton(
              onPressed: () => setState(() => _visibleCount += _pageSize),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1D9E75)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'تحميل المزيد (المتبقي: ${total - _visibleCount})' : 'Load more  (${total - _visibleCount} remaining)',
                  style: const TextStyle(
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w500)),
            ),
          );
        }

        final dateKey = grouped.keys.elementAt(i);
        final dayMeals = grouped[dateKey]!;
        final dayTotal =
            dayMeals.fold(0.0, (s, m) => s + m.calories).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateKey,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$dayTotal kcal',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D9E75))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...dayMeals.map((m) => _mealCard(m, locale, isAr)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _mealCard(Meal meal, Locale locale, bool isAr) {
    final isExpanded = _expandedId == meal.id;
    return GestureDetector(
      onTap: () =>
          setState(() => _expandedId = isExpanded ? null : meal.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isExpanded
                  ? const Color(0xFF1D9E75)
                  : Colors.transparent,
              width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${meal.calories.round()} kcal',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A))),
                    Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF888780),
                        size: 18),
                  ],
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFF0F0EC), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniMacro(AppTranslations.translate(locale.languageCode, 'protein'), '${meal.protein.toStringAsFixed(0)}g',
                      const Color(0xFF1D9E75)),
                  _miniMacro(AppTranslations.translate(locale.languageCode, 'carbs'), '${meal.carbs.toStringAsFixed(0)}g',
                      const Color(0xFF378ADD)),
                  _miniMacro(AppTranslations.translate(locale.languageCode, 'fat'), '${meal.fat.toStringAsFixed(0)}g',
                      const Color(0xFFEF9F27)),
                ],
              ),
              if (meal.confidence > 0) ...[
                const SizedBox(height: 8),
                Text(
                    '${isAr ? "ثقة الذكاء الاصطناعي" : "AI confidence"}: ${(meal.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888780))),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Color(0xFF888780))),
      ],
    );
  }
}
