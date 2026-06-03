import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/meal.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../main.dart';

class MealRepository {
  final LocalStorageService _local;
  final AuthService _auth;
  final FirebaseFirestore? _db;
  final FirebaseStorage? _storage;

  MealRepository(this._local, this._auth)
      : _db = isFirebaseAvailable ? FirebaseFirestore.instance : null,
        _storage = isFirebaseAvailable ? FirebaseStorage.instance : null;

  Future<void> saveMeal(Meal meal, {Uint8List? imageBytes}) async {
    await _local.saveMeal(meal);
    if (isFirebaseAvailable && _auth is! MockAuthService) {
      _syncToCloud(meal, imageBytes: imageBytes);
    }
  }

  Future<void> deleteMeal(String id) async {
    await _local.deleteMeal(id);
    if (isFirebaseAvailable && _auth is! MockAuthService && _db != null) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db!.collection('users').doc(uid).collection('meals').doc(id).delete();
      }
    }
  }

  List<Meal> getTodayMeals() => _local.getMealsForDate(DateTime.now());

  List<Meal> getAllMeals() => _local.getAllMeals();

  List<Meal> getMealsForWeek() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _local.getAllMeals()
        .where((m) => m.loggedAt.isAfter(cutoff))
        .toList();
  }

  Future<void> _syncToCloud(Meal meal, {Uint8List? imageBytes}) async {
    if (!isFirebaseAvailable || _auth is MockAuthService || _db == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      String imageUrl = '';
      if (imageBytes != null && _storage != null) {
        final ref = _storage!.ref('meals/$uid/${meal.id}.jpg');
        await ref.putData(imageBytes);
        imageUrl = await ref.getDownloadURL();
        await _local.markSynced(meal.id, imageUrl: imageUrl);
      } else {
        await _local.markSynced(meal.id);
      }

      final data = meal.toFirestore();
      if (imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;

      await _db!
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(meal.id)
          .set(data);
    } catch (_) {
      // Silently fail — local data is the source of truth; sync retried next session
    }
  }

  Future<void> syncPending() async {
    if (!isFirebaseAvailable || _auth is MockAuthService) return;
    final pending = _local.getUnsyncedMeals();
    for (final meal in pending) {
      await _syncToCloud(meal);
    }
  }
}
