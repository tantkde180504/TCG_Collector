import 'package:flutter/material.dart';
import 'dart:math';
import '../models/chat_message.dart';
import '../services/database_service.dart';

class ChatViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  Future<void> loadMessages() async {
    try {
      _messages = await _db.getMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat: $e');
    }
  }

  Future<void> sendMessage(String text, {required String senderName}) async {
    if (text.trim().isEmpty) return;

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

    // Trigger chatbot response
    _triggerOakResponse(text);
  }

  void _triggerOakResponse(String userText) async {
    _isTyping = true;
    notifyListeners();

    // Simulate Oak thinking and typing
    await Future.delayed(const Duration(milliseconds: 1800));

    String replyText = '';
    final text = userText.toLowerCase();

    if (text.contains('charizard') || text.contains('rồng lửa')) {
      replyText = 'Ah, Charizard! A magnificent Fire-type. We currently have "Charizard ex" in stock for \$120.00. It is a highly coveted card with 330 HP!';
    } else if (text.contains('shipping') || text.contains('giao hàng') || text.contains('ship')) {
      replyText = 'Our standard shipping takes 2-4 business days. Orders above \$150.00 qualify for free express delivery! Otherwise, it is just \$7.99.';
    } else if (text.contains('pikachu') || text.contains('chuột điện')) {
      replyText = 'Pikachu ex is an amazing Lightning-type card with 200 HP. Its "Pika Bolt" attack does 220 damage! It is currently priced at \$95.00.';
    } else if (text.contains('fake') || text.contains('real') || text.contains('uy tín') || text.contains('thật')) {
      replyText = 'Rest assured, Trainer! Every card in our shop undergoes a rigorous 3-step authentication check. We guarantee 100% genuine cards.';
    } else if (text.contains('discount') || text.contains('gỉam giá') || text.contains('coupon')) {
      replyText = 'You can use coupon code "PIKACHU10" to get 10% off your purchase, or "CHARIZARD20" for a whopping 20% off selected products!';
    } else {
      final responses = [
        'An excellent question, Trainer! To build a great collection, you must understand both card rarity and market price trends.',
        'Fascinating! Don\'t forget to check out our physical store map to meet and trade cards with other Pokémon Trainers in your area!',
        'In the world of Pokémon cards, prices rise and fall like waves. Keep an eye on our Market Price History Charts for optimal buying times!',
        'I am working on a new Pokemon Encyclopedia (Pokedex) update! Let me know if you need help with Card stats or placing an order.',
      ];
      final random = Random();
      replyText = responses[random.nextInt(responses.length)];
    }

    final oakMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'support',
      senderName: 'Prof. Oak',
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
    // Clear in db
    final db = await _db.database;
    if (db != null) {
      await db.delete('messages');
    }
    _messages.clear();
    // Re-insert welcome message
    final welcome = ChatMessage(
      id: 'welcome',
      senderId: 'support',
      senderName: 'Prof. Oak',
      text: 'Hello Trainer! Welcome to the Pokémon TCG Collector Support Desk. I am Professor Oak. How can I assist you with your cards, decks, or orders today?',
      timestamp: DateTime.now(),
    );
    _messages.add(welcome);
    notifyListeners();
  }
}
