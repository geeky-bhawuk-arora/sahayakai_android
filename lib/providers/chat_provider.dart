import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../utils/mock_seeds.dart';
import '../services/api_client.dart';
import 'package:dio/dio.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
  // In a real app, add interceptors here
  return ApiClient(dio);
});

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(apiClientProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiClient _apiClient;

  ChatNotifier(this._apiClient) : super([]) {
    _initializeHistory();
  }

  Future<void> _initializeHistory() async {
    // 1. Load the massive 150-item mock seed first for hackathon scale
    final seeds = SahayakMockSeeds.generate150Messages();
    
    // 2. Fetch "persistent" history from local DB/PostgreSQL mock
    final persistentHistory = await _apiClient.fetchSessionHistory();
    
    // 3. Merge and sync
    state = [...seeds]; // In a real app, merge based on timestamps
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
