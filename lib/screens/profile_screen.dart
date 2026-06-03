import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/locale_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late double _goalDraft;
  bool _saving = false;
  final _ipCtrl = TextEditingController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _goalDraft = ref.read(userPrefsProvider).dailyCalorieGoal;
    final box = Hive.box('settings');
    _ipCtrl.text = box.get('wifi_sync_ip', defaultValue: '') as String;
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    setState(() => _saving = true);
    await ref.read(userPrefsProvider.notifier).setCalorieGoal(_goalDraft);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Daily goal updated!'),
      backgroundColor: Color(0xFF1D9E75),
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final meals = ref.watch(allMealsProvider);
    final totalLogged = meals.length;
    final totalCal = meals.fold(0.0, (s, m) => s + m.calories);
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F2),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(user?.displayName ?? 'User', user?.email ?? ''),
                const SizedBox(height: 20),
                _buildStatsRow(totalLogged, totalCal, locale),
                const SizedBox(height: 20),
                _buildLanguageSection(locale),
                const SizedBox(height: 20),
                _buildGoalSection(locale),
                const SizedBox(height: 20),
                _buildDiseasesSection(locale),
                const SizedBox(height: 20),
                _buildWifiSyncSection(locale),
                const SizedBox(height: 20),
                _buildAccountSection(user?.email ?? '', locale),
                const SizedBox(height: 32),
                _buildSignOutButton(locale),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF1D9E75), size: 22),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.translate(locale.languageCode, 'select_language'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: !isAr,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(localeProvider.notifier).setLocale('en');
                      }
                    },
                    selectedColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF1D9E75),
                    labelStyle: TextStyle(
                      color: !isAr ? const Color(0xFF1D9E75) : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('العربية', style: TextStyle(fontWeight: FontWeight.w600)),
                    selected: isAr,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(localeProvider.notifier).setLocale('ar');
                      }
                    },
                    selectedColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF1D9E75),
                    labelStyle: TextStyle(
                      color: isAr ? const Color(0xFF1D9E75) : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Color(0xFF1D9E75),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(email,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, double totalCal, Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(AppTranslations.translate(locale.languageCode, 'meals_logged'), '$total', Icons.restaurant_rounded),
          const SizedBox(width: 12),
          _statCard(AppTranslations.translate(locale.languageCode, 'total_kcal'), '${totalCal.round()}', Icons.local_fire_department_rounded),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1D9E75), size: 22),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888780))),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection(Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.translate(locale.languageCode, 'daily_calorie_goal'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(isAr ? 'اسحب لتحديد هدفك بالسعرات' : 'Swipe to set your target',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_goalDraft.round()} ${isAr ? "سعرة" : "kcal"}',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D9E75)),
              ),
            ),
            Slider(
              value: _goalDraft,
              min: 1200,
              max: 4000,
              divisions: 56,
              activeColor: const Color(0xFF1D9E75),
              inactiveColor: const Color(0xFFE8E8E4),
              onChanged: (v) => setState(() => _goalDraft = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? '1200 سعرة' : '1200 kcal',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(isAr ? '4000 سعرة' : '4000 kcal',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(AppTranslations.translate(locale.languageCode, 'save_goal'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(String email, Locale locale) {
    final isAr = locale.languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _infoTile(Icons.email_outlined, AppTranslations.translate(locale.languageCode, 'email'), email),
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0EC)),
            _infoTile(Icons.shield_outlined, isAr ? 'نوع الحساب' : 'Account type', isAr ? 'البريد وكلمة المرور' : 'Email & Password'),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D9E75), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888780))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: Text(AppTranslations.translate(locale.languageCode, 'sign_out'),
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Future<void> _syncToWifi() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a server IP address'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final box = Hive.box('settings');
    await box.put('wifi_sync_ip', ip);

    setState(() => _syncing = true);

    try {
      final meals = ref.read(allMealsProvider);
      final list = meals.map((m) => m.toJson()).toList();

      final url = Uri.parse('http://$ip:8000/sync');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(list),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = json.decode(res.body);
        final count = body['synced_count'] ?? meals.length;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Successfully synced $count meals to database!'),
          backgroundColor: const Color(0xFF1D9E75),
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sync failed: Server returned ${res.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sync failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Widget _buildWifiSyncSection(Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.translate(locale.languageCode, 'wifi_sync'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(AppTranslations.translate(locale.languageCode, 'sync_desc'),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            TextField(
              controller: _ipCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.100',
                labelText: AppTranslations.translate(locale.languageCode, 'server_ip'),
                prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF1D9E75)),
                filled: true,
                fillColor: const Color(0xFFF8F8F6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _syncing ? null : _syncToWifi,
                icon: _syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.sync_rounded),
                label: Text(AppTranslations.translate(locale.languageCode, 'sync_to_db'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseasesSection(Locale locale) {
    final prefs = ref.watch(userPrefsProvider);
    final notifier = ref.read(userPrefsProvider.notifier);

    final diseaseKeys = ['diabetes', 'hypertension', 'celiac', 'lactose', 'kidney', 'cholesterol'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined, color: Color(0xFF1D9E75), size: 22),
                const SizedBox(width: 10),
                Text(
                  AppTranslations.translate(locale.languageCode, 'health_conditions'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppTranslations.translate(locale.languageCode, 'health_conditions_desc'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
          ],
        ),
      ),
    );
  }
}
