import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_routes.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final locale = ref.read(localeProvider);

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _snack(AppTranslations.translate(locale.languageCode, 'fill_all_fields'), Colors.orange);
      return;
    }
    if (password.length < 6) {
      _snack(AppTranslations.translate(locale.languageCode, 'short_password'), Colors.orange);
      return;
    }
    if (password != confirm) {
      _snack(AppTranslations.translate(locale.languageCode, 'password_mismatch'), Colors.red);
      return;
    }

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signUp(email, password, name);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(context, fadeRoute(const HomeScreen()));
    } else {
      final state = ref.read(authNotifierProvider);
      _snack(state.error?.toString() ?? AppTranslations.translate(locale.languageCode, 'registration_failed'), Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F2),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.restaurant_menu,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 24),
                Text(AppTranslations.translate(locale.languageCode, 'create_account'),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(AppTranslations.translate(locale.languageCode, 'register_subtitle'),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF888780))),
                const SizedBox(height: 36),
                _label(AppTranslations.translate(locale.languageCode, 'full_name')),
                const SizedBox(height: 8),
                _field(controller: _nameCtrl, hint: 'Sara Ahmed',
                    icon: Icons.person_outline,
                    caps: TextCapitalization.words),
                const SizedBox(height: 18),
                _label(AppTranslations.translate(locale.languageCode, 'email')),
                const SizedBox(height: 8),
                _field(controller: _emailCtrl, hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 18),
                _label(AppTranslations.translate(locale.languageCode, 'password')),
                const SizedBox(height: 8),
                _field(controller: _passwordCtrl, hint: 'Min. 6 characters',
                    icon: Icons.lock_outline, obscure: _obscurePass,
                    toggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass)),
                const SizedBox(height: 18),
                _label(AppTranslations.translate(locale.languageCode, 'confirm_password')),
                const SizedBox(height: 8),
                _field(
                    controller: _confirmCtrl,
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline,
                    obscure: _obscureConfirm,
                    toggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(AppTranslations.translate(locale.languageCode, 'create_account'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                      style: const TextStyle(color: Color(0xFF888780), fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context, slideRightRoute(const LoginScreen())),
                      child: Text(
                        isAr ? 'سجل دخولك' : 'Sign in',
                        style: const TextStyle(
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF1D9E75)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: caps,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
        prefixIcon: Icon(icon, color: const Color(0xFF888780)),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF888780)),
                onPressed: toggleObscure)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F8F6),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF1D9E75), width: 1.5)),
      ),
    );
  }
}
