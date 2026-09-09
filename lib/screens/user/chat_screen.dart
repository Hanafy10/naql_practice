import 'package:flutter/material.dart';
import '../../l10n/app_locale.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = List.from(sampleMessages);
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _showFaq = true;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        fromDriver: false,
        text: text,
        time: 'Now',
      ));
    });
    _ctrl.clear();
    _showFaq = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _askFaq(FaqItem faq) {
    final s = S.of(context);
    final answer = s.t(faq.answerEn, faq.answerAr);
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        fromDriver: false,
        text: s.t(faq.en, faq.ar),
        time: 'Now',
      ));
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        fromDriver: true,
        text: answer,
        time: 'Now',
        suggestions: sampleFaq
            .where((f) => f != faq)
            .map((f) => s.t(f.en, f.ar))
            .take(3)
            .toList(),
      ));
    });
    _showFaq = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: kUserBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kUserSurface,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: sampleFaq.map((faq) {
                  return GestureDetector(
                    onTap: () => _askFaq(faq),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kUserSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        s.t(faq.en, faq.ar),
                        style: interStyle(size: 12, color: kUserText),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
