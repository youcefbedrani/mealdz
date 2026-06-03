import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groq_service.dart';
import '../providers/locale_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const ChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWelcomeMessage();
      _scrollToBottom();
    });
  }

  void _initWelcomeMessage() {
    final history = ref.read(chatProvider);
    if (history.isEmpty) {
      final code = ref.read(localeProvider).languageCode;
      final welcome = code == 'ar'
          ? 'مرحباً! أنا مستشارك الذكي للتغذية والرياضة. كيف يمكنني مساعدتك اليوم؟ يمكنك سؤالي عن نصائح الوجبات، السعرات، أو الرياضة المناسبة.'
          : 'Hello! I am your AI Nutrition & Fitness Advisor. How can I help you today? Ask me about meals, calorie goals, workouts, or sports recommendations.';
      ref.read(chatProvider.notifier).addMessage('assistant', welcome);
    }

    if (widget.initialPrompt != null) {
      if (history.isEmpty || history.last['content'] != widget.initialPrompt) {
        _sendUserMessage(widget.initialPrompt!);
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendUserMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    await ref.read(chatProvider.notifier).addMessage('user', content);
    
    setState(() {
      _loading = true;
    });
    _scrollToBottom();

    final code = ref.read(localeProvider).languageCode;
    final todayMeals = ref.read(todayMealsProvider);
    final calorieGoal = ref.read(userPrefsProvider).dailyCalorieGoal;

    final history = ref.read(chatProvider);
    final apiHistory = history.length > 1 ? history.sublist(1) : history;
    
    final reply = await GroqService.chat(
      apiHistory,
      languageCode: code,
      todayMeals: todayMeals,
      calorieGoal: calorieGoal,
    );

    if (!mounted) return;
    
    await ref.read(chatProvider.notifier).addMessage('assistant', reply);
    
    setState(() {
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';
    final messages = ref.watch(chatProvider);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D9E75),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppTranslations.translate(locale.languageCode, 'ai_advisor'),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: isAr ? 'مسح سجل الدردشة' : 'Clear Chat',
              onPressed: () async {
                await ref.read(chatProvider.notifier).clearHistory();
                _initWelcomeMessage();
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];
                  final isUser = msg['role'] == 'user';
                  return _buildMessageBubble(msg['content'] ?? '', isUser);
                },
              ),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment:
                      isAr ? MainAxisAlignment.start : MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1D9E75),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAr ? 'المستشار يكتب...' : 'Advisor is typing...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _buildInputSection(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8, left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                child: const Icon(Icons.psychology,
                    color: Color(0xFF1D9E75), size: 18),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1D9E75) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight:
                      isUser ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF2C2C2A),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.grey, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _sendUserMessage(val);
                    _textCtrl.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'اسأل الذكاء الاصطناعي عن التغذية أو الرياضة...'
                      : 'Ask AI about meals, sports, or fitness...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: const Color(0xFFF6F6F6),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _textCtrl.text;
                if (text.trim().isNotEmpty) {
                  _sendUserMessage(text);
                  _textCtrl.clear();
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D9E75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
