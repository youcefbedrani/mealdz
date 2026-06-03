import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ChatNotifier extends StateNotifier<List<Map<String, String>>> {
  ChatNotifier() : super([]) {
    _loadMessages();
  }

  static const _boxName = 'settings';
  static const _keyChat = 'chat_history_v1';

  void _loadMessages() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final listStr = box.get(_keyChat) as String?;
        if (listStr != null) {
          final List<dynamic> decoded = json.decode(listStr);
          state = decoded.map((m) => Map<String, String>.from(m as Map)).toList();
          return;
        }
      }
    } catch (_) {}
    state = [];
  }

  Future<void> addMessage(String role, String content) async {
    state = [...state, {'role': role, 'content': content}];
    await _saveMessages();
  }

  Future<void> clearHistory() async {
    state = [];
    await _saveMessages();
  }

  Future<void> _saveMessages() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_keyChat, json.encode(state));
      }
    } catch (_) {}
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<Map<String, String>>>((ref) {
  return ChatNotifier();
});
