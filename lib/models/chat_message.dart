class ChatMessage {
  final String id;
  final String senderId; // 'user' or 'support'
  final String senderName; // 'Trainer Red' or 'Professor Oak'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['message_id'] ?? '',
      senderId: map['sender_id'] ?? 'user',
      senderName: map['sender_name'] ?? 'Trainer Red',
      text: map['text'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
