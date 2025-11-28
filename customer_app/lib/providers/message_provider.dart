import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/firebase_chat_service.dart';
import '../services/api_service.dart';

// Message Provider
final messageProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier();
});

// Message State
class MessageState {
  final List<Conversation> conversations;
  final List<Message> messages;
  final Conversation? selectedConversation;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? pagination;
  final List<Map<String, dynamic>> typingUsers;
  final Map<String, Map<String, dynamic>> messageReactions;

  MessageState({
    this.conversations = const [],
    this.messages = const [],
    this.selectedConversation,
    this.isLoading = false,
    this.error,
    this.pagination,
    this.typingUsers = const [],
    this.messageReactions = const {},
  });

  MessageState copyWith({
    List<Conversation>? conversations,
    List<Message>? messages,
    Conversation? selectedConversation,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? pagination,
    List<Map<String, dynamic>>? typingUsers,
    Map<String, Map<String, dynamic>>? messageReactions,
    bool clearSelectedConversation = false,
  }) {
    return MessageState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selectedConversation: clearSelectedConversation
          ? null
          : (selectedConversation ?? this.selectedConversation),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
      typingUsers: typingUsers ?? this.typingUsers,
      messageReactions: messageReactions ?? this.messageReactions,
    );
  }
}

// Message Notifier
class MessageNotifier extends StateNotifier<MessageState> {
  MessageNotifier() : super(MessageState());

  final FirebaseChatService _firebaseService = FirebaseChatService();
  final ApiService _apiService = ApiService(); // For user data and validation

  // Get conversations
  Future<void> getConversations(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final conversations = await _firebaseService.getConversations(userId);

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get messages
  Future<void> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final messages =
          await _firebaseService.getMessages(conversationId, limit: limit);

      state = state.copyWith(
        messages: loadMore ? [...state.messages, ...messages] : messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Send message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    List<String>? attachments,
  }) async {
    try {
      final message = await _firebaseService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        attachments: attachments ?? [],
      );

      // Add message to local state
      state = state.copyWith(
        messages: [...state.messages, message],
      );

      // Update conversation's last message
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == message.conversationId) {
          return conv.copyWith(
            lastMessage: message,
            updatedAt: message.createdAt,
          );
        }
        return conv;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _firebaseService.markAsRead(conversationId, userId);

      // Update local state
      final updatedMessages = state.messages.map((message) {
        if (message.conversationId == conversationId &&
            message.receiverId == userId) {
          return message.copyWith(isRead: true);
        }
        return message;
      }).toList();

      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return conv.copyWith(unreadCount: 0);
        }
        return conv;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        conversations: updatedConversations,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _firebaseService.deleteMessage(conversationId, messageId);

      // Remove from local state
      final updatedMessages =
          state.messages.where((message) => message.id != messageId).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Search conversations (still uses backend API for user search)
  Future<void> searchConversations(String query) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // For search, we still use the backend API since Firebase doesn't have full-text search
      // In a real implementation, you might want to implement search differently
      final response = await _apiService.get(
        '/messages/conversations/search',
        queryParameters: {'query': query},
      );

      final conversations = (response.data['data'] as List)
          .map((json) => Conversation.fromJson(json))
          .toList();

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Select conversation
  void selectConversation(Conversation conversation) {
    state = state.copyWith(selectedConversation: conversation);
  }

  // Clear selected conversation
  void clearSelectedConversation() {
    state = state.copyWith(clearSelectedConversation: true);
  }

  // Add incoming message (for real-time updates)
  void addIncomingMessage(Message message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );

    // Update conversation
    final updatedConversations = state.conversations.map((conv) {
      if (conv.id == message.conversationId) {
        return conv.copyWith(
          lastMessage: message,
          unreadCount: (conv.unreadCount?['count'] ?? 0) + 1,
          updatedAt: message.createdAt,
        );
      }
      return conv;
    }).toList();

    state = state.copyWith(conversations: updatedConversations);
  }

  // Listen to real-time conversation updates
  Stream<List<Conversation>> listenToConversations(String userId) {
    return _firebaseService.listenToConversations(userId);
  }

  // Listen to real-time message updates
  Stream<List<Message>> listenToMessages(String conversationId) {
    return _firebaseService.listenToMessages(conversationId);
  }

  // Start listening to conversations (call this when entering messages screen)
  void startListeningToConversations(String userId) {
    // Cancel any existing subscription
    _conversationsSubscription?.cancel();

    _conversationsSubscription = listenToConversations(userId).listen(
      (conversations) {
        state = state.copyWith(conversations: conversations);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  // Start listening to messages in a conversation
  void startListeningToMessages(String conversationId) {
    // Cancel any existing subscription
    _messagesSubscription?.cancel();

    _messagesSubscription = listenToMessages(conversationId).listen(
      (messages) {
        state = state.copyWith(messages: messages);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  // Stop listening to conversations
  void stopListeningToConversations() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = null;
  }

  // Stop listening to messages
  void stopListeningToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Typing indicators
  Future<void> setTypingStatus(
      String conversationId, String userId, bool isTyping) async {
    try {
      await _firebaseService.setTypingStatus(conversationId, userId, isTyping);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void startListeningToTyping(String conversationId) {
    // Cancel any existing subscription
    _typingSubscription?.cancel();

    _typingSubscription =
        _firebaseService.listenToTypingStatus(conversationId).listen(
      (typingUsers) {
        state = state.copyWith(typingUsers: typingUsers);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  void stopListeningToTyping() {
    _typingSubscription?.cancel();
    _typingSubscription = null;
  }

  // Message reactions
  Future<void> addReaction(String conversationId, String messageId,
      String userId, String emoji) async {
    try {
      await _firebaseService.addReaction(
          conversationId, messageId, userId, emoji);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> removeReaction(
      String conversationId, String messageId, String userId) async {
    try {
      await _firebaseService.removeReaction(conversationId, messageId, userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void startListeningToReactions(String conversationId) {
    // Cancel any existing subscription
    _reactionsSubscription?.cancel();

    _reactionsSubscription =
        _firebaseService.listenToReactions(conversationId).listen(
      (messageReactions) {
        state = state.copyWith(messageReactions: messageReactions);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  void stopListeningToReactions() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = null;
  }

  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _typingSubscription;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _reactionsSubscription;
}
