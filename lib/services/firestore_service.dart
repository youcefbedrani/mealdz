import 'package:cloud_firestore/cloud_firestore.dart';

// Legacy service — kept for reference; MealRepository is the primary sync path.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> saveMeal({
    required String userId,
    required String mealName,
    required String emoji,
    required String mealType,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required List<Map<String, dynamic>> ingredients,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _db.collection('meals').add({
        'userId': userId,
        'mealName': mealName,
        'emoji': emoji,
        'mealType': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'ingredients': ingredients,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
      return docRef.id;
    } catch (_) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getMeals(String userId) {
    return _db
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getTodayMeals(String userId) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _db
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMeal(String mealId) async {
    try {
      await _db.collection('meals').doc(mealId).delete();
    } catch (_) {}
  }
}
