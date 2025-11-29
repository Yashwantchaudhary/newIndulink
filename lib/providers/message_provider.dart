import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// 💬 Message Provider
/// Manages messaging/chat functionality for customer-supplier communication
class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  int get unreadCount =>
      _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  /// Initialize message provider
  Future<void> init() async {
    await fetchConversations();
  }

  /// Fetch all conversations
  Future<void> fetchConversations() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/messages/conversations');

      if (response.success) {
        final List<dynamic> items = response.data['conversations'] ?? [];
        _conversations =
            items.map((item) => Conversation.fromJson(item)).toList();
      } else {
        _setError(response.message ?? 'Failed to load conversations');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch conversations error: $e');
    }

    _setLoading(false);
  }

  /// Fetch messages for a conversation
  Future<void> fetchMessages(String conversationId) async {
    _currentConversationId = conversationId;
    _isLoadingMessages = true;
    _clearError();
    notifyListeners();

    try {
      final response = await _apiService.get(
        '/messages/conversations/$conversationId/messages',
      );

      if (response.success) {
        final List<dynamic> items = response.data['messages'] ?? [];
        _currentMessages = items.map((item) => Message.fromJson(item)).toList();
      } else {
        _setError(response.message ?? 'Failed to load messages');
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Fetch messages error: $e');
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    _clearError();

    try {
      final response = await _apiService.post(
        '/messages/conversations/$conversationId/messages',
        body: {'content': content},
      );

      if (response.success) {
        // Add message to current messages
        final newMessage = Message.fromJson(response.data['message']);
        _currentMessages.add(newMessage);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to send message');
        return false;
      }
    } catch (e) {
      _setError('An error occurred');
      debugPrint('Send message error: $e');
      return false;
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiService.put('/messages/conversations/$conversationId/read');

      // Update local state
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversationId = null;
    _currentMessages.clear();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

/// Conversation model
class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      otherUserId: json['otherUser']?['_id'] ?? '',
      otherUserName: json['otherUser']?['name'] ?? 'Unknown',
      otherUserAvatar: json['otherUser']?['avatar'],
      lastMessage: json['lastMessage']?['content'] ?? '',
      lastMessageTime: json['lastMessage']?['createdAt'] != null
          ? DateTime.parse(json['lastMessage']['createdAt'])
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Conversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Message model
class Message {
  final String id;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['sender'] is String
          ? json['sender']
          : json['sender']?['_id'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
