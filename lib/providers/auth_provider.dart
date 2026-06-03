import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../main.dart';

final firebaseAvailableProvider = StateProvider<bool>((ref) => isFirebaseAvailable);

final authServiceProvider = Provider<AuthService>((ref) {
  final isAvailable = ref.watch(firebaseAvailableProvider);
  if (isAvailable) {
    return FirebaseAuthService();
  } else {
    return MockAuthService();
  }
});

// Streams the Firebase auth state (null = signed out, User = signed in)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Notifier for login/register operations with loading + error state
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._auth) : super(const AsyncValue.data(null));

  final AuthService _auth;

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.signIn(email, password);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e.toString()), st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.signUp(email, password, name);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e.toString()), st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  static String _friendlyError(String e) {
    if (e.contains('user-not-found')) return 'No account found with this email.';
    if (e.contains('wrong-password')) return 'Incorrect password.';
    if (e.contains('email-already-in-use')) return 'This email is already registered.';
    if (e.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (e.contains('invalid-email')) return 'Please enter a valid email address.';
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
