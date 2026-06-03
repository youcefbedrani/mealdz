import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_routes.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final locale = ref.read(localeProvider);
    if (email.isEmpty || password.isEmpty) {
      _snack(AppTranslations.translate(locale.languageCode, 'fill_all_fields'), Colors.orange);
      return;
    }
    final success =
        await ref.read(authNotifierProvider.notifier).signIn(email, password);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(context, fadeRoute(const HomeScreen()));
    } else {
      final state = ref.read(authNotifierProvider);
      _snack(state.error?.toString() ?? AppTranslations.translate(locale.languageCode, 'login_failed'), Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
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
                const SizedBox(height: 60),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.restaurant_menu,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 32),
                Text(AppTranslations.translate(locale.languageCode, 'welcome_back'),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(AppTranslations.translate(locale.languageCode, 'sign_in_subtitle'),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF888780))),
                const SizedBox(height: 48),
                _label(AppTranslations.translate(locale.languageCode, 'email')),
                const SizedBox(height: 8),
                _field(
                  controller: _emailController,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _label(AppTranslations.translate(locale.languageCode, 'password')),
                const SizedBox(height: 8),
                _field(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  toggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(AppTranslations.translate(locale.languageCode, 'forgot_password'),
                        style: const TextStyle(color: Color(0xFF1D9E75))),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(AppTranslations.translate(locale.languageCode, 'sign_in'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            ref.read(firebaseAvailableProvider.notifier).state = false;
                            final success = await ref
                                .read(authNotifierProvider.notifier)
                                .signIn('offline@example.com', 'offline123');
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pushReplacement(
                                  context, fadeRoute(const HomeScreen()));
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      side: const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(AppTranslations.translate(locale.languageCode, 'continue_offline'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                      style: const TextStyle(color: Color(0xFF888780), fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, slideRightRoute(const RegisterScreen())),
                      child: Text(
                        isAr ? 'سجل الآن' : 'Sign up',
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
