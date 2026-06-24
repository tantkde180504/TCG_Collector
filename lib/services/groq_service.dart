import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/chat_message.dart';

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPromptPrefix = '''
You are Professor Oak, the friendly Pokémon TCG expert assistant for the Pokémon TCG Collector shop app.
Help trainers with card recommendations, deck building, shipping info, and order questions.

Use ONLY the catalog and shop data below when answering about products, prices, stats, or availability.
If a card is not listed, say it is not currently in the shop catalog.

Respond in the same language the user writes in (Vietnamese or English).
Keep answers concise, warm, and helpful — like a real Pokémon professor.
''';

  static const _modelCandidates = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];

  Future<String> generateReply(
    String userMessage,
    List<ChatMessage> history, {
    required String catalogContext,
  }) async {
    if (Secrets.groqApiKey.isEmpty ||
        Secrets.groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw GroqUnavailableException('Groq API key chưa được cấu hình.');
    }

    final messages = _buildMessages(history, catalogContext);
    Object? lastError;

    for (final model in _modelCandidates) {
      try {
        return await _callGroq(model: model, messages: messages);
      } catch (e) {
        lastError = e;
        debugPrint('Groq model $model failed: $e');

        if (!_isRetryableError(e)) {
          rethrow;
        }

        await Future.delayed(const Duration(seconds: 2));
        try {
          return await _callGroq(model: model, messages: messages);
        } catch (retryError) {
          lastError = retryError;
          debugPrint('Groq retry on $model failed: $retryError');
        }
      }
    }

    throw GroqUnavailableException(
      lastError?.toString() ?? 'Tất cả model Groq đều không khả dụng.',
    );
  }

  List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String catalogContext,
  ) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': '$_systemPromptPrefix\n\n$catalogContext',
      },
    ];

    final recentHistory = history
        .where((m) => m.id != 'welcome')
        .toList()
        .reversed
        .take(20)
        .toList()
        .reversed
        .toList();

    for (final msg in recentHistory) {
      messages.add({
        'role': msg.senderId == 'user' ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    return messages;
  }

  Future<String> _callGroq({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer ${Secrets.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Groq không trả về nội dung phản hồi.');
      }
      final text = (choices.first as Map<String, dynamic>)['message']
          ?['content'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Groq không trả về nội dung phản hồi.');
      }
      return text.trim();
    }

    final body = response.body;
    if (response.statusCode == 429 || body.toLowerCase().contains('rate')) {
      throw Exception('Groq rate limit: $body');
    }
    throw Exception('Groq API error (${response.statusCode}): $body');
  }

  bool _isRetryableError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('429') ||
        message.contains('rate') ||
        message.contains('quota') ||
        message.contains('overloaded');
  }
}

class GroqUnavailableException implements Exception {
  GroqUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}
