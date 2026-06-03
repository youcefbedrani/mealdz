import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meal_analyzer/providers/auth_provider.dart';
import 'package:meal_analyzer/services/auth_service.dart';
import 'package:meal_analyzer/screens/login_screen.dart';

class _FakeAuthService extends AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<User?> signIn(String email, String password) async => null;

  @override
  Future<User?> signUp(String email, String password, String name) async => null;

  @override
  Future<void> signOut() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier() : super(_FakeAuthService());
}

Widget _buildUnderTest() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith((_) => _FakeAuthNotifier()),
      authStateProvider.overrideWith((_) => const Stream.empty()),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  group('LoginScreen widget', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Sign in button is present', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('shows snackbar when email is empty', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign in');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      final passwordFields = tester.widgetList<TextField>(find.byType(TextField));
      final passwordField =
          passwordFields.firstWhere((f) => f.obscureText, orElse: () => throw 'No obscure field');
      expect(passwordField.obscureText, true);
    });

    testWidgets('toggle password visibility icon exists', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('Sign up link is present', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();
      expect(find.text('Sign up'), findsOneWidget);
    });
  });
}
