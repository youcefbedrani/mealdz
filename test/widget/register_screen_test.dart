import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meal_analyzer/providers/auth_provider.dart';
import 'package:meal_analyzer/services/auth_service.dart';
import 'package:meal_analyzer/screens/register_screen.dart';

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
    child: const MaterialApp(home: RegisterScreen()),
  );
}

void main() {
  group('RegisterScreen widget', () {
    testWidgets('renders all 4 input fields', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
    });

    testWidgets('Create account button is present', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();
      expect(find.text('Create account'), findsWidgets);
    });

    testWidgets('shows validation error when fields empty', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      final createBtn =
          find.widgetWithText(ElevatedButton, 'Create account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), 'password1');
      await tester.enterText(textFields.at(3), 'password2');
      await tester.pump();

      final createBtn =
          find.widgetWithText(ElevatedButton, 'Create account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows short password error', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@test.com');
      await tester.enterText(textFields.at(2), 'abc');
      await tester.enterText(textFields.at(3), 'abc');
      await tester.pump();

      final createBtn =
          find.widgetWithText(ElevatedButton, 'Create account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Sign in link is present', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pump();
      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}
