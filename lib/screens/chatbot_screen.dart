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

    return Scaffold(
      appBar: AppBar(
        title: Text(isTwi ? 'Kabeji Mmoawa' : 'Cabbage Assistant'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (provider.isChatLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12).copyWith(
                          bottomLeft: Radius.zero,
                        ),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.grey[200] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomLeft: isBot ? Radius.zero : const Radius.circular(12),
                        bottomRight: isBot ? const Radius.circular(12) : Radius.zero,
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isBot ? Colors.black87 : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !provider.isChatLoading,
                    decoration: InputDecoration(
                      hintText: isTwi ? 'Bisa asɛm bi...' : 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: provider.isChatLoading ? null : _sendMessage,
                  icon: provider.isChatLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
