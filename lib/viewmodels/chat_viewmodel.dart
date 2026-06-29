import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_catalog_context.dart';
import '../services/database_service.dart';
import '../services/groq_service.dart';
import '../services/oak_fallback_service.dart';
import '../viewmodels/settings_viewmodel.dart';

class ChatViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final GroqService _groq = GroqService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _usingOfflineMode = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get usingOfflineMode => _usingOfflineMode;

  Future<void> loadMessages() async {
    try {
      _messages = await _db.getMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat: $e');
    }
  }

  Future<void> sendMessage(String text, {required String senderName, required SettingsViewModel settingsVM}) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user',
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    notifyListeners();

    try {
      await _db.saveMessage(userMsg);
    } catch (e) {
      debugPrint('Error saving user message: $e');
    }

    await _requestReply(text, settingsVM);
  }

  Future<void> _requestReply(String userText, SettingsViewModel settingsVM) async {
    _isTyping = true;
    notifyListeners();

    String replyText;
    String senderLabel;

    final catalog = await _db.getCards();
    final catalogContext = ChatCatalogContext.build(catalog);

    try {
      replyText = await _groq.generateReply(
        userText,
        _messages,
        catalogContext: catalogContext,
        settingsVM: settingsVM,
      );
      senderLabel = 'Prof. Oak (Groq AI)';
      _usingOfflineMode = false;
    } on GroqUnavailableException catch (e) {
      debugPrint('Groq unavailable, using offline fallback: $e');
      replyText = OakFallbackService.reply(userText, catalog);
      senderLabel = 'Prof. Oak (Offline)';
      _usingOfflineMode = true;
    } catch (e) {
      debugPrint('Groq API error: $e');
      replyText = OakFallbackService.reply(userText, catalog);
      senderLabel = 'Prof. Oak (Offline)';
      _usingOfflineMode = true;
    }

    final oakMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'support',
      senderName: senderLabel,
      text: replyText,
      timestamp: DateTime.now(),
    );

    _messages.add(oakMsg);
    _isTyping = false;
    notifyListeners();

    try {
      await _db.saveMessage(oakMsg);
    } catch (e) {
      debugPrint('Error saving bot message: $e');
    }
  }

  Future<void> clearChatHistory() async {
    await _db.clearMessages();
    _messages = await _db.getMessages();
    _usingOfflineMode = false;
    notifyListeners();
  }
}
