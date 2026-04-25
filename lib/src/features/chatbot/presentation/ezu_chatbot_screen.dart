import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ezu_gemini_service.dart';

class EzuChatbotScreen extends ConsumerStatefulWidget {
  const EzuChatbotScreen({super.key});

  @override
  ConsumerState<EzuChatbotScreen> createState() => _EzuChatbotScreenState();
}

class _EzuChatbotScreenState extends ConsumerState<EzuChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hello! I am Ezu 👋 — your Philippine legal assistant inside eSumbong.\n\n'
          'I can answer general legal questions, summarize Republic Acts (RA 9262, RA 7160, RA 7610, RA 10173, RA 9344), and explain the Katarungang Pambarangay process.\n\n'
          'What would you like to know?',
      isUser: false,
      isError: false,
    ),
  ];

  bool _isTyping = false;

  static const List<String> _quickPrompts = <String>[
    'Summarize RA 9262',
    'Summarize RA 7160',
    'What is Katarungang Pambarangay?',
    'What is VAWC?',
    'Summarize RA 9344',
    'Summarize RA 10173',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _send([String? prompt]) async {
    final input = (prompt ?? _controller.text).trim();
    if (input.isEmpty || _isTyping) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final gemini = ref.read(ezuGeminiServiceProvider);
      final response = await gemini.send(input);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text:
              '⚠️ Ezu could not reach the server. Please check your connection and try again.\n\nError: $e',
          isUser: false,
          isError: true,
        ));
      });
    }

    _scrollToBottom();
  }

  void _resetChat() {
    ref.read(ezuGeminiServiceProvider).resetConversation();
    setState(() {
      _messages
        ..clear()
        ..add(const _ChatMessage(
          text:
              'Conversation reset. How can I help you with Philippine law today?',
          isUser: false,
        ));
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        // ── Header ────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: <Widget>[
              // Logo image
              Image.asset(
                'lib/src/assets/esumbong_logo.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Image.asset(
                      'lib/src/assets/esumbong_text.png',
                      height: 20,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ask Ezu — Philippine Legal Assistant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reset conversation',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _resetChat,
              ),
            ],
          ),
        ),

        // ── Quick prompts ─────────────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return ActionChip(
                label: Text(prompt),
                onPressed: _isTyping ? null : () => _send(prompt),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ── Message list ──────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              // Typing indicator bubble at the end
              if (_isTyping && index == _messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: _TypingIndicator(),
                );
              }

              final message = _messages[index];
              final isUser = message.isUser;

              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? theme.colorScheme.errorContainer
                        : isUser
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFD6DEEA)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isError
                          ? theme.colorScheme.onErrorContainer
                          : isUser
                              ? Colors.white
                              : null,
                      height: 1.45,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_isTyping,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _isTyping
                          ? 'Ezu is typing…'
                          : 'Ask Ezu a Philippine law question…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isTyping ? null : _send,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  child: _isTyping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: const Color(0xFFD6DEEA)),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Dot(opacity: _animation.value),
            const SizedBox(width: 4),
            _Dot(opacity: (1.0 - _animation.value).clamp(0.3, 1.0)),
            const SizedBox(width: 4),
            _Dot(opacity: _animation.value),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Message model ─────────────────────────────────────────────────────────────

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}
