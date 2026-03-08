enum MessageType { text, voice }
enum MessageSender { user, bot }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? audioUrl;
  final List<String>? actionItems;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.audioUrl,
    this.actionItems,
  });
}
