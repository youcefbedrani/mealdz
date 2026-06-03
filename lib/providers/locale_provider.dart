import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', '')) {
    _loadLocale();
  }

  void _loadLocale() {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final code = box.get('locale_code', defaultValue: 'en') as String;
        state = Locale(code, '');
        return;
      }
    } catch (_) {}
    state = const Locale('en', '');
  }

  Future<void> toggleLocale() async {
    final newCode = state.languageCode == 'en' ? 'ar' : 'en';
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        await box.put('locale_code', newCode);
      }
    } catch (_) {}
    state = Locale(newCode, '');
  }

  Future<void> setLocale(String code) async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        await box.put('locale_code', code);
      }
    } catch (_) {}
    state = Locale(code, '');
  }
}

// Simple localization dictionary helper
class AppTranslations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'meals_logged': 'Meals logged',
      'total_kcal': 'Total kcal',
      'daily_calorie_goal': 'Daily Calorie Goal',
      'update_daily_goal': 'Update Daily Goal',
      'goal_draft': 'Daily target in kcal',
      'save_goal': 'Save Goal',
      'wifi_sync': 'Wi-Fi Database Sync',
      'sync_desc': 'Sync all meal data to your shared Docker database',
      'server_ip': 'Server IP Address',
      'sync_to_db': 'Sync to Database',
      'account': 'Account',
      'email': 'Email',
      'sign_out': 'Sign Out',
      'dashboard': 'Dashboard',
      'history': 'History',
      'profile': 'Profile',
      'scan_meal': 'Scan Meal',
      'ai_recommendations': 'AI Recommendations',
      'ai_advisor': 'AI Health Advisor',
      'chat_placeholder': 'Ask AI about meals, sports, and recommendations...',
      'talk_ai': 'Talk with AI Advisor',
      'send': 'Send',
      'advice_dashboard': 'Daily AI Nutrition Tip:',
      'loading_advice': 'Generating daily advice...',
      'try_again': 'Try again',
      'analysis_result': 'Analysis Result',
      'other_possibilities': 'OTHER POSSIBILITIES',
      'log_meal': 'Log this meal ↗',
      'scan_again': 'Scan again',
      'calorie_goal_hint': 'Enter goal (e.g. 2000)',
      'arabic_users': 'Arabic Language',
      'select_language': 'Language / اللغة',
      'sync_success': 'Successfully synced meals to database!',
      'sync_failed': 'Sync failed',
      'daily_goal_updated': 'Daily goal updated!',
      'saving_meal': 'Saving meal...',
      'meal_saved_success': 'Meal logged successfully!',
      'analysis_failed': 'Analysis failed',
      'model_not_ready': 'The AI model is not loaded yet.',
      'unidentified_food': 'The model could not identify this food.',
      'offline_warning': 'No internet connection. Nutrition lookup offline.',
      'continue_offline': 'Continue Offline',
      'mock_sign_in_failed': 'Sign-in failed. Please try again.',
      'dont_have_account': "Don't have an account? Sign up",
      'already_have_account': 'Already have an account? Sign in',
      'welcome_back': 'Welcome back',
      'sign_in_subtitle': 'Track calories and identify meals instantly',
      'create_account': 'Create account',
      'register_subtitle': 'Start your nutrition tracking journey today',
      'full_name': 'Full name',
      'password': 'Password',
      'confirm_password': 'Confirm password',
      'password_mismatch': 'Passwords do not match',
      'short_password': 'Password must be at least 6 characters',
      'enter_email': 'Please enter your email',
      'enter_password': 'Please enter your password',
      'today_calories': 'Today\'s Calories',
      'target': 'target',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      'today_meals': 'Today\'s Meals',
      'no_meals_today': 'No meals logged today yet. Try scanning one!',
      'all_meals': 'All Meals History',
      'no_history': 'No meals logged yet. Go to the scanner tab to scan a meal!',
      'forgot_password': 'Forgot password?',
      'sign_in': 'Sign in',
      'sign_up': 'Sign up',
      'fill_all_fields': 'Please fill in all fields',
      'login_failed': 'Login failed',
      'registration_failed': 'Registration failed',
      'position_meal_in_frame': 'Position your meal in frame',
      'analyzing_with_ai': 'Analyzing with AI...',
      'please_wait_ai': 'Please wait, AI is classifying...',
      'make_sure_plate_visible': 'Make sure the plate is fully visible',
      'calories': 'Calories',
      'health_conditions': 'Health Conditions',
      'health_conditions_desc': 'Select medical conditions for AI meal suitability alerts:',
      'diabetes': 'Diabetes',
      'hypertension': 'Hypertension',
      'celiac': 'Celiac Disease',
      'lactose': 'Lactose Intolerance',
      'kidney': 'Kidney Disease',
      'cholesterol': 'High Cholesterol',
      'none_healthy': 'None (Healthy)',
      'health_alerts': 'AI Health Warnings',
      'health_alert_safe': 'Safe to consume',
    },
    'ar': {
      'health_conditions': 'الحالة الصحية',
      'health_conditions_desc': 'اختر الحالات الصحية لتلقي تحذيرات الذكاء الاصطناعي:',
      'diabetes': 'السكري',
      'hypertension': 'ارتفاع ضغط الدم',
      'celiac': 'حساسية القمح (السلياك)',
      'lactose': 'حساسية اللاكتوز',
      'kidney': 'أمراض الكلى',
      'cholesterol': 'ارتفاع الكوليسترول',
      'none_healthy': 'لا يوجد (معافى)',
      'health_alerts': 'تحذيرات الذكاء الاصطناعي الصحية',
      'health_alert_safe': 'آمن للاستهلاك',
      'meals_logged': 'الوجبات المسجلة',
      'total_kcal': 'إجمالي السعرات',
      'daily_calorie_goal': 'الهدف اليومي للسعرات',
      'update_daily_goal': 'تحديث الهدف اليومي',
      'goal_draft': 'الهدف اليومي بالسعرات الحرارية',
      'save_goal': 'حفظ الهدف',
      'wifi_sync': 'مزامنة الواي فاي',
      'sync_desc': 'مزامنة جميع بيانات الوجبات مع قاعدة بيانات Docker المشتركة',
      'server_ip': 'عنوان IP الخاص بالخادم',
      'sync_to_db': 'مزامنة مع قاعدة البيانات',
      'account': 'الحساب',
      'email': 'البريد الإلكتروني',
      'sign_out': 'تسجيل الخروج',
      'dashboard': 'لوحة التحكم',
      'history': 'السجل',
      'profile': 'الملف الشخصي',
      'scan_meal': 'مسح وجبة',
      'ai_recommendations': 'توصيات الذكاء الاصطناعي',
      'ai_advisor': 'مستشار الصحة الذكي',
      'chat_placeholder': 'اسأل الذكاء الاصطناعي عن الوجبات، الرياضة، والتوصيات...',
      'talk_ai': 'تحدث مع مستشار الذكاء الاصطناعي',
      'send': 'إرسال',
      'advice_dashboard': 'نصيحة التغذية اليومية من الذكاء الاصطناعي:',
      'loading_advice': 'جاري توليد النصيحة اليومية...',
      'try_again': 'إعادة المحاولة',
      'analysis_result': 'نتيجة التحليل',
      'other_possibilities': 'احتمالات أخرى',
      'log_meal': 'تسجيل هذه الوجبة ↗',
      'scan_again': 'مسح جديد',
      'calorie_goal_hint': 'أدخل الهدف (مثال: 2000)',
      'arabic_users': 'اللغة العربية',
      'select_language': 'Language / اللغة',
      'sync_success': 'تمت مزامنة الوجبات بنجاح إلى قاعدة البيانات!',
      'sync_failed': 'فشلت المزامنة',
      'daily_goal_updated': 'تم تحديث الهدف اليومي بنجاح!',
      'saving_meal': 'جاري حفظ الوجبة...',
      'meal_saved_success': 'تم تسجيل الوجبة بنجاح!',
      'analysis_failed': 'فشل التحليل',
      'model_not_ready': 'نموذج الذكاء الاصطناعي غير محمل بعد.',
      'unidentified_food': 'لم يتمكن النموذج من تحديد هذا الطعام.',
      'offline_warning': 'لا يوجد اتصال بالإنترنت. البحث عن القيم الغذائية محلي.',
      'continue_offline': 'المتابعة دون اتصال',
      'mock_sign_in_failed': 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.',
      'dont_have_account': "ليس لديك حساب؟ سجل الآن",
      'already_have_account': 'لديك حساب بالفعل؟ سجل دخولك',
      'welcome_back': 'مرحباً بك مجدداً',
      'sign_in_subtitle': 'تتبع السعرات الحرارية وتعرف على طعامك فوراً',
      'create_account': 'إنشاء حساب جديد',
      'register_subtitle': 'ابدأ رحلتك لتتبع التغذية اليوم',
      'full_name': 'الاسم الكامل',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'password_mismatch': 'كلمتا المرور غير متطابقتين',
      'short_password': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
      'enter_email': 'يرجى إدخال البريد الإلكتروني',
      'enter_password': 'يرجى إدخال كلمة المرور',
      'today_calories': 'سعرات اليوم',
      'target': 'الهدف',
      'protein': 'البروتين',
      'carbs': 'الكربوهيدرات',
      'fat': 'الدهون',
      'today_meals': 'وجبات اليوم',
      'no_meals_today': 'لم يتم تسجيل أي وجبات اليوم بعد. جرب مسح وجبة!',
      'all_meals': 'تاريخ كل الوجبات',
      'no_history': 'لا توجد وجبات مسجلة بعد. انتقل إلى الكاميرا لمسح وجبة!',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'fill_all_fields': 'يرجى ملء جميع الحقول',
      'login_failed': 'فشل تسجيل الدخول',
      'registration_failed': 'فشل إنشاء الحساب',
      'position_meal_in_frame': 'ضع وجبتك داخل الإطار',
      'analyzing_with_ai': 'جاري التحليل بالذكاء الاصطناعي...',
      'please_wait_ai': 'يرجى الانتظار، جاري تصنيف الوجبة...',
      'make_sure_plate_visible': 'تأكد من أن الطبق مرئي بالكامل',
      'calories': 'السعرات',
    }
  };

  static String translate(String languageCode, String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}

class FoodTranslations {
  static const Map<String, String> _arabicMap = {
    'apple_pie': 'فطيرة التفاح',
    'baby_back_ribs': 'ضلوع مشوية',
    'baklava': 'بقلاوة',
    'beef_carpaccio': 'كارباتشيو لحم البقر',
    'beef_tartare': 'تارتار لحم البقر',
    'beet_salad': 'سلطة الشمندر',
    'beignets': 'بينيه',
    'bibimbap': 'بيبيمباب',
    'bread_pudding': 'بودينغ الخبز',
    'breakfast_burrito': 'بوريتو الفطور',
    'bruschetta': 'بروسكيتا',
    'caesar_salad': 'سلطة سيزر',
    'cannoli': 'كانولي',
    'caprese_salad': 'سلطة كابريزي',
    'carrot_cake': 'كعكة الجزر',
    'ceviche': 'سيفيتشي',
    'cheese_plate': 'طبق الجبن',
    'cheesecake': 'تشيز كيك',
    'chicken_curry': 'كاري الدجاج',
    'chicken_quesadilla': 'كيساديلا الدجاج',
    'chicken_wings': 'أجنحة الدجاج',
    'chocolate_cake': 'كعكة الشوكولاتة',
    'chocolate_mousse': 'موس الشوكولاتة',
    'churros': 'تشوروز',
    'clam_chowder': 'حساء المحار',
    'club_sandwich': 'كلوب ساندوتش',
    'crab_cakes': 'كعك الكابوريا',
    'creme_brulee': 'كريم بروليه',
    'croque_madame': 'كروك مدام',
    'cup_cakes': 'كب كيك',
    'deviled_eggs': 'بيض ديفيلد',
    'donuts': 'دونات',
    'dumplings': 'زلابية',
    'edamame': 'إدامامي',
    'eggs_benedict': 'بيض بينيديكت',
    'escargots': 'حلزون',
    'falafel': 'فلافل',
    'filet_mignon': 'فيليه مينيون',
    'fish_and_chips': 'سمك وبطاطا',
    'foie_gras': 'كبد الأوز',
    'french_fries': 'بطاطس مقلية',
    'french_onion_soup': 'شوربة البصل الفرنسية',
    'french_toast': 'فرنش توست',
    'fried_calamari': 'كالاماري مقلي',
    'fried_rice': 'أرز مقلي',
    'frozen_yogurt': 'لبن مثلج',
    'garlic_bread': 'خبز بالثوم',
    'gnocchi': 'نيوكي',
    'greek_salad': 'سلطة يونانية',
    'grilled_cheese_sandwich': 'ساندوتش جبن مشوي',
    'grilled_salmon': 'سلمون مشوي',
    'guacamole': 'غواكامولي',
    'gyoza': 'غيوزا',
    'hamburger': 'همبرغر',
    'hot_and_sour_soup': 'حساء حامض وحار',
    'hot_dog': 'هوت دوج',
    'huevos_rancheros': 'هويفوس رانتشيروس',
    'hummus': 'حمص',
    'ice_cream': 'آيس كريم',
    'lasagna': 'لازانيا',
    'lobster_bisque': 'حساء جراد البحر',
    'lobster_roll_sandwich': 'ساندوتش جراد البحر',
    'macaroni_and_cheese': 'معكرونة بالجبن',
    'macarons': 'ماكرون',
    'miso_soup': 'حساء الميسو',
    'mussels': 'بلح البحر',
    'nachos': 'ناتشوز',
    'omelette': 'أومليت',
    'onion_rings': 'حلقات البصل',
    'oysters': 'محار',
    'pad_thai': 'باد تاي',
    'paella': 'باييلا',
    'pancakes': 'بان كيك',
    'panna_cotta': 'بانا كوتا',
    'peking_duck': 'بط بكين',
    'pho': 'فو',
    'pizza': 'بيتزا',
    'pork_chop': 'شريحة لحم الخنزير',
    'poutine': 'بوتين',
    'prime_rib': 'ضلع بقري ممتاز',
    'pulled_pork_sandwich': 'ساندوتش لحم مسحب',
    'ramen': 'رامن',
    'ravioli': 'رافيولي',
    'red_velvet_cake': 'كعكة المخمل الأحمر',
    'risotto': 'ريزوتو',
    'samosa': 'سمبوسة',
    'sashimi': 'ساشيمي',
    'scallops': 'اسكالوب',
    'seaweed_salad': 'سلطة الطحالب البحرية',
    'shrimp_and_grits': 'روبيان وجريش',
    'spaghetti_bolognese': 'سباغيتي بولونيز',
    'spaghetti_carbonara': 'سباغيتي كاربونارا',
    'spring_rolls': 'سبرينغ رولز',
    'steak': 'ستيك',
    'strawberry_shortcake': 'كعكة الفراولة القصيرة',
    'sushi': 'سوشي',
    'tacos': 'تاكو',
    'takoyaki': 'تاكوياكي',
    'tiramisu': 'تيراميسو',
    'tuna_tartare': 'تارتار التونة',
    'waffles': 'وافل',
    // aiy food v1 custom classes
    'teriyaki_chicken': 'دجاج ترياكي',
    'unagi': 'أوناغي (أرز بالأنقليس)',
    'bento': 'بنتو (علبة طعام)',
    'sesame_chicken': 'دجاج بالسمسم',
    'meatloaf': 'رغيف اللحم',
    'mashed_potato': 'بطاطس مهروسة',
    'baked_potato': 'بطاطس مشوية',
    'orange_chicken': 'دجاج بالبرتقال',
  };

  static String translate(String languageCode, String englishName) {
    if (languageCode != 'ar') return englishName;
    
    // Normalize key: lowercase, replace spaces and dashes with underscores
    final key = englishName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _arabicMap[key] ?? englishName;
  }
}
