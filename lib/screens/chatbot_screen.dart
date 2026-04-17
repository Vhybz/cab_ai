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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTwi ? 'Kabeji Mmoawa' : 'Cabbage Assistant', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.grey[50],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (provider.isChatLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator(isDark);
                  }

                  final msg = _messages[index];
                  final isBot = msg['role'] == 'bot';
                  return _buildMessageBubble(msg['text']!, isBot, isDark, theme);
                },
              ),
            ),
            _buildInputArea(provider, isTwi, isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, bool isDark, ThemeData theme) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBot 
              ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
              : (isDark ? theme.colorScheme.primary.withOpacity(0.8) : Colors.green[100]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 0 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          text,
          style: TextStyle(
            color: isBot 
                ? (isDark ? Colors.white.withOpacity(0.9) : Colors.black87)
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.zero,
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.greenAccent : Colors.green),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider, bool isTwi, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !provider.isChatLoading,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: isTwi ? 'Bisa asɛm bi...' : 'Ask a question...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: provider.isChatLoading ? null : _sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Colors.greenAccent : Colors.green,
              child: provider.isChatLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
