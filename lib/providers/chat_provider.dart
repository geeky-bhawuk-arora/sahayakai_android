import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../utils/mock_seeds.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]) {
    _loadInitialData();
  }

  void _loadInitialData() {
    state = SahayakMockSeeds.generate150Messages();
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void addTextMessage(String content, MessageSender sender) {
    final message = ChatMessage(
      id: DateTime.now().toIso8601String(),
      content: content,
      type: MessageType.text,
      sender: sender,
      timestamp: DateTime.now(),
    );
    addMessage(message);
  }
}
