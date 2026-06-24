import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Bạn có Charizard không?',
    'Phí giao hàng bao nhiêu?',
    'Mã giảm giá nào đang có?',
    'Thông tin thẻ Pikachu ex',
    'Thẻ có chính hãng không?',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ChatViewModel>().loadMessages().then((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();

    chatVM.sendMessage(text, senderName: authVM.displayName);
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendSuggestion(String suggestion) {
    final authVM = context.read<AuthViewModel>();
    final chatVM = context.read<ChatViewModel>();
    chatVM.sendMessage(suggestion, senderName: authVM.displayName);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();

    if (chatVM.isTyping) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: const Color(0xFF1A1A1A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      chatVM.usingOfflineMode
                          ? Icons.cloud_off
                          : Icons.auto_awesome,
                      color: chatVM.usingOfflineMode
                          ? Colors.orangeAccent
                          : Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatVM.usingOfflineMode
                          ? 'Prof. Oak · Offline (Groq không khả dụng)'
                          : 'Prof. Oak · Powered by Groq AI',
                      style: TextStyle(
                        color: chatVM.usingOfflineMode
                            ? Colors.orangeAccent
                            : Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: chatVM.isTyping ? null : () => chatVM.clearChatHistory(),
                  child: const Text(
                    'Clear Chat',
                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: chatVM.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatVM.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatVM.messages[index];
                      final isUser = msg.senderId == 'user';
                      final formattedTime =
                          DateFormat('jm').format(msg.timestamp);

                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade900.withValues(alpha: 0.9)
                                : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser
                                  ? const Radius.circular(12)
                                  : const Radius.circular(0),
                              bottomRight: isUser
                                  ? const Radius.circular(0)
                                  : const Radius.circular(12),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? Colors.blue.shade800
                                  : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.senderName,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.amber
                                      : Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (chatVM.isTyping)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text(
                        'Prof. Oak đang trả lời...',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(suggestion),
                    backgroundColor: const Color(0xFF1E1E1E),
                    labelStyle: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: chatVM.isTyping
                        ? null
                        : () => _sendSuggestion(suggestion),
                  ),
                );
              },
            ),
          ),
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !chatVM.isTyping,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Hỏi Professor Oak về thẻ bài...',
                          hintStyle:
                              TextStyle(color: Colors.white30, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: chatVM.isTyping ? null : _handleSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: chatVM.isTyping
                            ? Colors.amber.withValues(alpha: 0.4)
                            : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send, color: Colors.black, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
