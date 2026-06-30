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

    final response = await provider.askAi(prompt);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTwi = provider.language == 'Twi';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  pinned: true,
                  backgroundColor: colorScheme.primary,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  centerTitle: true,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      (isTwi ? 'Kabeji Mmoawa' : 'AI Assistant').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.primary.withValues(alpha: 0.8), colorScheme.primary],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.psychology_rounded, color: Colors.white),
                      onSelected: (value) => provider.setAiModel(value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Gemini', child: Text('Google Gemini')),
                        const PopupMenuItem(value: 'Llama', child: Text('Meta Llama 3')),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    child: Center(
                      child: Text(
                        'Using: ${provider.selectedAiModel}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _messages.length) {
                          return _buildTypingIndicator(colorScheme);
                        }
                        final msg = _messages[index];
                        final isBot = msg['role'] == 'bot';
                        return _buildMessageBubble(msg['text']!, isBot, theme, colorScheme);
                      },
                      childCount: _messages.length + (provider.isChatLoading ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildInputArea(provider, isTwi, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, ThemeData theme, ColorScheme colorScheme) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isBot ? theme.cardColor : colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 0 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? colorScheme.onSurface : Colors.white,
            fontSize: 15,
            height: 1.5,
            fontWeight: isBot ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          'Thinking...',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider, bool isTwi, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                enabled: !provider.isChatLoading,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: isTwi ? 'Bisa asɛm bi...' : 'Ask your question...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
            child: IconButton(
              onPressed: provider.isChatLoading ? null : _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
