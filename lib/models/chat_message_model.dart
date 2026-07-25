/// Lightweight model for persisting chat messages in SQLite.
/// Separate from the full ChatProvider.ChatMessage to avoid circular imports
/// between database_service.dart and chat_provider.dart.
class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isUser': isUser ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        id: map['id'] as String,
        text: map['text'] as String,
        isUser: (map['isUser'] as int) == 1,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
