import 'package:flutter/material.dart';

class EzuChatbotScreen extends StatefulWidget {
  const EzuChatbotScreen({super.key});

  @override
  State<EzuChatbotScreen> createState() => _EzuChatbotScreenState();
}

class _EzuChatbotScreenState extends State<EzuChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Hello, I am Ezu. I can answer general legal questions in the Philippines and summarize Republic Acts such as RA 9262, RA 7160, RA 7610, RA 10173, and RA 9344.',
      isUser: false,
    ),
  ];

  static const List<String> _quickPrompts = <String>[
    'Summarize RA 9262',
    'Summarize RA 7160',
    'What is Katarungang Pambarangay?',
    'What is VAWC?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final input = (prompt ?? _controller.text).trim();
    if (input.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _messages.add(_ChatMessage(text: _buildResponse(input), isUser: false));
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF0F766E), Color(0xFF155E75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ask Ezu about Philippine laws and Republic Acts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final prompt = _quickPrompts[index];
              return ActionChip(
                label: Text(prompt),
                onPressed: () => _send(prompt),
              );
            },
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemCount: _quickPrompts.length,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isUser = message.isUser;

              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFD6DEEA)),
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
                    maxLines: 3,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Ask Ezu...'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _send,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(46, 46),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildResponse(String input) {
    final lower = input.toLowerCase();
    final match = RegExp(r'ra\s*([0-9]{3,5})').firstMatch(lower);
    final ra = match?.group(1);

    if (lower.contains('summarize') ||
        lower.contains('summary') ||
        ra != null) {
      final summary = _summarizeRa(ra);
      if (summary != null) {
        return summary;
      }
      return 'I do not have that RA in my local knowledge yet. Try RA 9262, RA 7160, RA 7610, RA 10173, or RA 9344.';
    }

    if (lower.contains('katarungang pambarangay') ||
        lower.contains('barangay justice')) {
      return 'Katarungang Pambarangay is a community-based dispute resolution system under the Local Government Code. It generally requires mediation/conciliation at the barangay level before certain civil disputes and minor offenses can proceed in court.';
    }

    if (lower.contains('vawc')) {
      return 'VAWC refers to violence against women and their children under RA 9262. It covers physical, sexual, psychological, and economic abuse committed by a spouse, former spouse, partner, or person with whom the woman has a child.';
    }

    if (lower.contains('not legal advice') || lower.contains('lawyer')) {
      return 'I provide general legal information only. For legal strategy, representation, or case-specific advice, consult a licensed attorney in the Philippines.';
    }

    return 'I can help with legal-law overviews and Republic Act summaries. Try asking: "Summarize RA 9262" or "What is Katarungang Pambarangay?"';
  }

  String? _summarizeRa(String? ra) {
    switch (ra) {
      case '9262':
        return 'RA 9262 (Anti-VAWC Act): Protects women and children from violence in intimate or family relationships. It defines physical, sexual, psychological, and economic abuse, and provides protection orders plus criminal penalties.';
      case '7160':
        return 'RA 7160 (Local Government Code of 1991): Defines local government powers, decentralization, revenue allotments, and barangay governance including Katarungang Pambarangay mechanisms for local dispute resolution.';
      case '7610':
        return 'RA 7610 (Special Protection of Children Against Abuse, Exploitation and Discrimination Act): Provides special safeguards for children against abuse, trafficking, exploitation, and harmful labor conditions, with corresponding penalties.';
      case '10173':
        return 'RA 10173 (Data Privacy Act of 2012): Protects personal information in government and private sector processing. It sets data subject rights, lawful processing rules, security requirements, and penalties for violations.';
      case '9344':
        return 'RA 9344 (Juvenile Justice and Welfare Act): Establishes a child-sensitive justice system, diversion, intervention, and rehabilitation for children in conflict with the law while protecting their rights.';
      default:
        return null;
    }
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
