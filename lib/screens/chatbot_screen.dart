import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text': 'Hello! I am your Cabbage Assistant. How can I help you today? You can ask me about diseases, planting, or harvesting.'
    },
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final provider = context.read<AppProvider>();
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || provider.isChatLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _controller.clear();
    });
    _scrollToBottom();

    final response = await provider.askGemini(prompt);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'bot', 'text': response});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTwi = provider.language == 'Twi';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(colorScheme, isTwi),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _messages.length) {
                          return _buildTypingIndicator(isDark, colorScheme);
                        }
                        final msg = _messages[index];
                        final isBot = msg['role'] == 'bot';
                        return _buildMessageBubble(msg['text']!, isBot, isDark, colorScheme);
                      },
                      childCount: _messages.length + (provider.isChatLoading ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildInputArea(provider, isTwi, isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme, bool isTwi) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          isTwi ? 'Kabeji Mmoawa' : 'Farm AI Assistant', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5)
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.forum_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, bool isDark, ColorScheme colorScheme) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isBot 
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isBot ? 4 : 24),
            bottomRight: Radius.circular(isBot ? 24 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Text(
          text,
          style: TextStyle(
            color: isBot 
                ? (isDark ? Colors.white70 : Colors.black87)
                : Colors.white,
            fontSize: 15,
            height: 1.5,
            fontWeight: isBot ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI is thinking', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider, bool isTwi, bool isDark, ColorScheme colorScheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? bottomPadding : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F7F4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                enabled: !provider.isChatLoading,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: isTwi ? 'Bisa asɛm bi...' : 'Ask your farm question...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: provider.isChatLoading ? null : _sendMessage,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: provider.isChatLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
