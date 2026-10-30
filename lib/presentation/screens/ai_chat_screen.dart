import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';

/// Модель одного сообщения в чате.
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

/// Полноценный экран AI-чата с финансовым советником.
///
/// Бэкенд (/api/ai/chat) загружает все данные пользователя (транзакции,
/// счета, категории) и передаёт их в Groq API как контекст. ИИ отвечает
/// короткими персонализированными советами.
class AiChatScreen extends StatefulWidget {
  /// Начальное сообщение — если передано, сразу отправляется при открытии.
  /// Используется когда пользователь нажимает "Совет на месяц" из карточки AI.
  final String? initialMessage;

  const AiChatScreen({Key? key, this.initialMessage}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Добавляем приветственное сообщение от AI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<AppStore>();
      setState(() {
        _messages.add(_ChatMessage(text: store.t('ai_welcome'), isUser: false));
      });
      // Если передано начальное сообщение — отправляем сразу
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _sendMessage(widget.initialMessage!);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Отправляет сообщение пользователя и получает ответ от AI.
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _loading) return;

    final store = context.read<AppStore>();
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _loading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final response = await store.sendAiMessage(text.trim());
      setState(() {
        _messages.add(_ChatMessage(text: response['reply'] as String, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: store.t('ai_error'), isUser: false));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1f2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8b5cf6), Color(0xFF6366f1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(store.t('ai_advisor'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1f2937))),
          ],
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(child: _buildMessageList(store)),
          // Быстрые подсказки (показываем только если нет сообщений пользователя)
          if (_messages.where((m) => m.isUser).length == 0 && !_loading)
            _buildSuggestions(store),
          // Индикатор печати
          if (_loading) _buildTypingIndicator(store),
          // Поле ввода
          _buildInputBar(store),
        ],
      ),
    );
  }

  // ── Список сообщений ──────────────────────────────────────────────────────

  Widget _buildMessageList(AppStore store) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return _MessageBubble(text: msg.text, isUser: msg.isUser);
      },
    );
  }

  // ── Быстрые подсказки ─────────────────────────────────────────────────────

  Widget _buildSuggestions(AppStore store) {
    final suggestions = [
      store.t('ai_suggestion_1'),
      store.t('ai_suggestion_2'),
      store.t('ai_suggestion_3'),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8b5cf6).withAlpha(40), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8b5cf6)),
                  const SizedBox(width: 6),
                  Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6d28d9))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Индикатор печати ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator(AppStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
                const SizedBox(width: 8),
                Text(store.t('ai_loading'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af), fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Поле ввода ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(AppStore store) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: store.t('ai_hint'),
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) _sendMessage(v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : () => _sendMessage(_inputCtrl.text),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8b5cf6), Color(0xFF6366f1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: const Color(0xFF8b5cf6).withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(
                  _loading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Пузырь сообщения ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8b5cf6), Color(0xFF6366f1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF16a34a) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isUser ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Анимированная точка для индикатора печати ─────────────────────────────────

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: Container(
        width: 7, height: 7,
        decoration: BoxDecoration(color: const Color(0xFF8b5cf6), borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
