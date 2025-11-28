import '../models/message.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _apiService = ApiService();

  // Get all conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiService.get('/messages/conversations');

      return (response.data['data'] as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  // Get messages in a conversation
  Future<Map<String, dynamic>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiService.get(
        '/messages/$conversationId',
        queryParameters: queryParams,
      );

      final messages = (response.data['data'] as List)
          .map((json) => Message.fromJson(json))
          .toList();

      return {
        'messages': messages,
        'pagination': response.data['pagination'],
      };
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send message
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    String? conversationId,
    List<String>? attachments,
  }) async {
    try {
      final response = await _apiService.post('/messages', data: {
        'receiver': receiverId,
        'content': content,
        if (conversationId != null) 'conversation': conversationId,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      });

      return Message.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiService.put('/messages/$conversationId/read', data: {});
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiService.delete('/messages/$messageId');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Search conversations
  Future<List<Conversation>> searchConversations(String query) async {
    try {
      final response = await _apiService.get(
        '/messages/conversations/search',
        queryParameters: {'query': query},
      );

      return (response.data['data'] as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search conversations: $e');
    }
  }
}
