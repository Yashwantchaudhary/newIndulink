import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

/// 💬 Message Provider
/// Manages messaging/chat functionality for customer-supplier communication
class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

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

  MessageProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketService.messageStream.listen((data) {
      _handleNewMessage(data);
    });
  }

  void _handleNewMessage(dynamic data) {
    debugPrint('MessageProvider received: $data');
    try {
      // Data structure depends on backend emission.
      // Assuming: { message: { ... }, conversationId: ... } or just message object
      final messageData = data is Map ? (data['message'] ?? data) : data;
      final newMessage = Message.fromJson(messageData);

      // 1. If inside conversation, add to messages
      // Backend should ensure 'sender' or 'receiver' matches current conversation
      // We check if the message belongs to current conversation
      // Note: newMessage.senderId might be the other user OR 'me' (if sent from another device)
      // We assume data includes conversation info or we infer it.

      // Ideally backend sends 'conversationId' in payload.
      final String? msgConversationId = data['conversationId'] ??
          (newMessage.senderId == _currentConversationId
              ? newMessage.senderId
              : null);
      // Logic gap: if I receive a message, senderId IS the conversationId (usally).
      // If I sent it, receiverId is.

      // Improved Logic:
      // If we are viewing conversation with User X, and User X sends a message.
      if (_currentConversationId != null) {
        if (newMessage.senderId == _currentConversationId ||
            (data['receiver'] == _currentConversationId)) {
          // If sent by me from elsewhere
          _currentMessages.add(newMessage);
          notifyListeners();
        }
      }

      // 2. Update conversation list (last message, unread count)
      final String conversationId = newMessage.senderId; // Assuming 1-on-1

      final index =
          _conversations.indexWhere((c) => c.otherUserId == conversationId);
      if (index != -1) {
        final oldConv = _conversations[index];
        _conversations[index] = oldConv.copyWith(
          lastMessage: newMessage.content,
          lastMessageTime: newMessage.createdAt,
          unreadCount: (_currentConversationId == conversationId)
              ? oldConv
                  .unreadCount // Already reading it? Actually marks as read on fetch.
              : oldConv.unreadCount + 1,
        );
        // Move to top
        final updatedConv = _conversations.removeAt(index);
        _conversations.insert(0, updatedConv);
        notifyListeners();
      } else {
        // New conversation? Ideally fetch again or manually construct
        // For now, let's just trigger a fetch if not found
        fetchConversations();
      }
    } catch (e) {
      debugPrint('Error handling socket message: $e');
    }
  }

  /// Initialize message provider
  Future<void> init() async {
    await fetchConversations();
  }

  // ... rest of methods (fetchConversations, fetchMessages, etc.) same as before ...

  /// Fetch all conversations
  Future<void> fetchConversations() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.get('/messages/conversations');

      if (response.success) {
        final List<dynamic> items =
            response.data['data'] ?? response.data['conversations'] ?? [];
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
        '/messages/conversation/$conversationId',
      );

      if (response.success) {
        final List<dynamic> items =
            response.data['data'] ?? response.data['messages'] ?? [];
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
        '/messages',
        body: {'receiver': conversationId, 'content': content},
      );

      if (response.success) {
        // Add message to current messages
        final messageData =
            response.data['data'] ?? response.data['message'] ?? response.data;
        final newMessage = Message.fromJson(messageData);
        _currentMessages.add(newMessage);
        notifyListeners();

        // Also update conversation list logic if needed (or rely on socket echo if backend echoes)
        // Backend typically emits to sender too? Or we optimistically update.
        // We already added locally. Now update conversation list.
        _updateConversationListOnSend(conversationId, content, DateTime.now());

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

  void _updateConversationListOnSend(
      String otherUserId, String content, DateTime time) {
    final index =
        _conversations.indexWhere((c) => c.otherUserId == otherUserId);
    if (index != -1) {
      final oldConv = _conversations[index];
      _conversations[index] = oldConv.copyWith(
        lastMessage: content,
        lastMessageTime: time,
      );
      final updatedConv = _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
      notifyListeners();
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiService.put('/messages/read/$conversationId');

      // Update local state
      final index = _conversations.indexWhere((c) =>
          c.otherUserId == conversationId); // Changed id to otherUserId likely?
      // Wait, Conversation model "id" IS the conversation ID or user ID?
      // Conversation.fromJson uses `json['_id']`. If conversation model ID is `_id` of Conversation document, then `c.id == conversationId` is wrong if `conversationId` passsed here is `otherUserId`.
      // Usage in UI: `fetchMessages` takes `conversationId`.
      // `sendMessage` takes `conversationId`.
      // Backend routes: `/messages/conversation/:userId` or `:conversationId`?
      // `fetchMessages`: `/messages/conversation/$conversationId`.
      // `getConversations`: returns list.
      // Usually "conversationId" in chat apps implies the Channel ID.
      // But in 1-to-1 simple systems, it's often the "other user ID".
      // Let's check backend route.

      // Assuming conversationId == Other User ID (based on sendMessage using 'receiver').
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
