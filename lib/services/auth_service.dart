import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

abstract class AuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<User?> signUp(String email, String password, String name);
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthService extends AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> signUp(String email, String password, String name) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'dailyGoal': 2000,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      try {
        await user.updateDisplayName(name);
      } catch (_) {}
    }
    return user;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class MockUser implements User {
  final String _uid;
  final String? _email;
  final String? _displayName;

  MockUser({required String uid, String? email, String? displayName})
      : _uid = uid,
        _email = email,
        _displayName = displayName;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  Future<void> updateDisplayName(String? name) async {
    // mock updateDisplayName
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService extends AuthService {
  final _controller = StreamController<User?>.broadcast();
  static const _boxName = 'settings';

  MockAuthService() {
    scheduleMicrotask(() {
      _controller.add(currentUser);
    });
  }

  @override
  User? get currentUser {
    final box = Hive.box(_boxName);
    final uid = box.get('mock_user_uid');
    if (uid == null) return null;
    return MockUser(
      uid: uid,
      email: box.get('mock_user_email'),
      displayName: box.get('mock_user_name'),
    );
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signUp(String email, String password, String name) async {
    final box = Hive.box(_boxName);
    final uid = 'mock_uid_${email.hashCode}';
    await box.put('mock_user_uid', uid);
    await box.put('mock_user_email', email);
    await box.put('mock_user_name', name);
    final user = MockUser(uid: uid, email: email, displayName: name);
    _controller.add(user);
    return user;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    final box = Hive.box(_boxName);
    final storedEmail = box.get('mock_user_email');
    if (storedEmail != null && storedEmail != email) {
      throw Exception('user-not-found');
    }
    final uid = box.get('mock_user_uid') ?? 'mock_uid_${email.hashCode}';
    final name = box.get('mock_user_name') ?? email.split('@')[0];
    await box.put('mock_user_uid', uid);
    await box.put('mock_user_email', email);
    await box.put('mock_user_name', name);
    final user = MockUser(uid: uid, email: email, displayName: name);
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final box = Hive.box(_boxName);
    await box.delete('mock_user_uid');
    await box.delete('mock_user_email');
    await box.delete('mock_user_name');
    _controller.add(null);
  }
}
