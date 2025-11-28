import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';

class FirebaseChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Generate conversation ID (same as backend)
  String generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send message to Firebase Realtime Database
  Future<Message> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    List<String> attachments = const [],
  }) async {
    final conversationId = generateConversationId(senderId, receiverId);

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'attachments': attachments,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
      'conversationId': conversationId,
    };

    // Create message reference
    final messageRef = _database.ref('messages/$conversationId').push();
    await messageRef.set(messageData);

    // Update conversation metadata
    await _updateConversationMetadata(
        conversationId, senderId, receiverId, messageData);

    return Message.fromJson({
      '_id': messageRef.key,
      ...messageData,
    });
  }

  // Update conversation metadata
  Future<void> _updateConversationMetadata(
    String conversationId,
    String senderId,
    String receiverId,
    Map<String, dynamic> lastMessage,
  ) async {
    final conversationRef = _database.ref('conversations/$conversationId');

    // Get current conversation data
    final snapshot = await conversationRef.get();
    final existingData = snapshot.value as Map<dynamic, dynamic>? ?? {};

    final updateData = {
      'participants': [senderId, receiverId],
      'lastMessage': {
        'text': lastMessage['content'],
        'senderId': lastMessage['senderId'],
        'timestamp': lastMessage['createdAt'],
      },
      'updatedAt': lastMessage['createdAt'],
      'createdAt': existingData['createdAt'] ?? lastMessage['createdAt'],
    };

    await conversationRef.set(updateData);
  }

  // Get conversations for user
  Future<List<Conversation>> getConversations(String userId) async {
    final conversationsRef = _database.ref('conversations');
    final snapshot = await conversationsRef.get();

    if (!snapshot.exists) return [];

    final conversations = <Conversation>[];
    final data = snapshot.value as Map<dynamic, dynamic>;

    for (final entry in data.entries) {
      final conversationId = entry.key as String;
      final conversationData = entry.value as Map<dynamic, dynamic>;

      final participants = (conversationData['participants'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [];

      if (participants.contains(userId)) {
        // Get unread count
        final unreadCount = await getUnreadCount(conversationId, userId);

        conversations.add(Conversation(
          id: conversationId,
          participants: participants,
          lastMessage: conversationData['lastMessage'] != null
              ? LastMessage(
                  text: conversationData['lastMessage']['text'] ?? '',
                  senderId: conversationData['lastMessage']['senderId'] ?? '',
                  timestamp: DateTime.parse(conversationData['lastMessage']
                          ['timestamp'] ??
                      DateTime.now().toIso8601String()),
                )
              : null,
          unreadCount: {'count': unreadCount},
          createdAt: DateTime.parse(conversationData['createdAt'] ??
              DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(conversationData['updatedAt'] ??
              DateTime.now().toIso8601String()),
        ));
      }
    }

    // Sort by last message timestamp
    conversations.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? a.createdAt;
      final bTime = b.lastMessage?.timestamp ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  // Get messages in conversation
  Future<List<Message>> getMessages(String conversationId,
      {int limit = 50}) async {
    final messagesRef = _database.ref('messages/$conversationId');
    final snapshot = await messagesRef.get();

    if (!snapshot.exists) return [];

    final messages = <Message>[];
    final data = snapshot.value as Map<dynamic, dynamic>;

    for (final entry in data.entries) {
      final messageId = entry.key as String;
      final messageData = entry.value as Map<dynamic, dynamic>;

      messages.add(Message.fromJson({
        '_id': messageId,
        ...messageData,
      }));
    }

    // Sort by createdAt
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Apply limit (get latest messages)
    if (messages.length > limit) {
      return messages.sublist(messages.length - limit);
    }

    return messages;
  }

  // Listen to real-time messages in conversation
  Stream<List<Message>> listenToMessages(String conversationId) {
    final messagesRef = _database.ref('messages/$conversationId');

    return messagesRef.onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final messages = <Message>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final messageId = entry.key as String;
        final messageData = entry.value as Map<dynamic, dynamic>;

        messages.add(Message.fromJson({
          '_id': messageId,
          ...messageData,
        }));
      }

      // Sort by createdAt
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  // Listen to conversations updates
  Stream<List<Conversation>> listenToConversations(String userId) {
    final conversationsRef = _database.ref('conversations');

    return conversationsRef.onValue.asyncMap((event) async {
      if (!event.snapshot.exists) return [];

      final conversations = <Conversation>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final conversationId = entry.key as String;
        final conversationData = entry.value as Map<dynamic, dynamic>;

        final participants =
            (conversationData['participants'] as List<dynamic>?)
                    ?.map((p) => p.toString())
                    .toList() ??
                [];

        if (participants.contains(userId)) {
          // Get unread count
          final unreadCount = await getUnreadCount(conversationId, userId);

          conversations.add(Conversation(
            id: conversationId,
            participants: participants,
            lastMessage: conversationData['lastMessage'] != null
                ? LastMessage(
                    text: conversationData['lastMessage']['text'] ?? '',
                    senderId: conversationData['lastMessage']['senderId'] ?? '',
                    timestamp: DateTime.parse(conversationData['lastMessage']
                            ['timestamp'] ??
                        DateTime.now().toIso8601String()),
                  )
                : null,
            unreadCount: {'count': unreadCount},
            createdAt: DateTime.parse(conversationData['createdAt'] ??
                DateTime.now().toIso8601String()),
            updatedAt: DateTime.parse(conversationData['updatedAt'] ??
                DateTime.now().toIso8601String()),
          ));
        }
      }

      // Sort by last message timestamp
      conversations.sort((a, b) {
        final aTime = a.lastMessage?.timestamp ?? a.createdAt;
        final bTime = b.lastMessage?.timestamp ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      return conversations;
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    final messagesRef = _database.ref('messages/$conversationId');
    final snapshot = await messagesRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};

    for (final entry in data.entries) {
      final messageId = entry.key as String;
      final messageData = entry.value as Map<dynamic, dynamic>;

      if (messageData['receiverId'] == userId &&
          !(messageData['isRead'] ?? false)) {
        updates['messages/$conversationId/$messageId/isRead'] = true;
        updates['messages/$conversationId/$messageId/readAt'] =
            DateTime.now().toIso8601String();
      }
    }

    if (updates.isNotEmpty) {
      await _database.ref().update(updates);
    }
  }

  // Get unread count for conversation
  Future<int> getUnreadCount(String conversationId, String userId) async {
    final messagesRef = _database.ref('messages/$conversationId');
    final snapshot = await messagesRef.get();

    if (!snapshot.exists) return 0;

    final data = snapshot.value as Map<dynamic, dynamic>;
    int count = 0;

    for (final messageData in data.values) {
      if (messageData['receiverId'] == userId &&
          !(messageData['isRead'] ?? false)) {
        count++;
      }
    }

    return count;
  }

  // Get total unread count for user
  Future<int> getTotalUnreadCount(String userId) async {
    final conversations = await getConversations(userId);
    int total = 0;

    for (final conversation in conversations) {
      total += conversation.unreadCount?['count'] ?? 0;
    }

    return total;
  }

  // Delete message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _database.ref('messages/$conversationId/$messageId').remove();
  }

  // Typing indicators
  Future<void> setTypingStatus(
      String conversationId, String userId, bool isTyping) async {
    final typingRef = _database.ref('typing/$conversationId/$userId');
    if (isTyping) {
      await typingRef.set({
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      await typingRef.remove();
    }
  }

  // Listen to typing indicators
  Stream<List<Map<String, dynamic>>> listenToTypingStatus(
      String conversationId) {
    final typingRef = _database.ref('typing/$conversationId');
    return typingRef.onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final typingData = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final typingUsers = <Map<String, dynamic>>[];

      typingData.forEach((userId, typingInfo) {
        if (typingInfo is Map) {
          typingUsers.add({
            'userId': userId,
            'timestamp': typingInfo['timestamp'],
          });
        }
      });

      return typingUsers;
    });
  }

  // Message reactions
  Future<void> addReaction(String conversationId, String messageId,
      String userId, String emoji) async {
    final reactionRef =
        _database.ref('reactions/$conversationId/$messageId/$userId');
    await reactionRef.set({
      'emoji': emoji,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeReaction(
      String conversationId, String messageId, String userId) async {
    final reactionRef =
        _database.ref('reactions/$conversationId/$messageId/$userId');
    await reactionRef.remove();
  }

  Future<Map<String, dynamic>> getMessageReactions(
      String conversationId, String messageId) async {
    final reactionsRef = _database.ref('reactions/$conversationId/$messageId');
    final snapshot = await reactionsRef.get();

    if (!snapshot.exists) {
      return {'counts': <String, int>{}, 'userReactions': <String, String>{}};
    }

    final reactionsData = snapshot.value as Map<dynamic, dynamic>? ?? {};
    final reactionCounts = <String, int>{};
    final userReactions = <String, String>{};

    reactionsData.forEach((userId, reactionData) {
      if (reactionData is Map) {
        final emoji = reactionData['emoji'] as String;
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
        userReactions[userId] = emoji;
      }
    });

    return {
      'counts': reactionCounts,
      'userReactions': userReactions,
    };
  }

  // Listen to reactions for a conversation
  Stream<Map<String, Map<String, dynamic>>> listenToReactions(
      String conversationId) {
    final reactionsRef = _database.ref('reactions/$conversationId');
    return reactionsRef.onValue.map((event) {
      if (!event.snapshot.exists) return {};

      final reactionsData =
          event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final messageReactions = <String, Map<String, dynamic>>{};

      reactionsData.forEach((messageId, messageReactionsData) {
        if (messageReactionsData is Map) {
          final reactionCounts = <String, int>{};
          final userReactions = <String, String>{};

          messageReactionsData.forEach((userId, reactionData) {
            if (reactionData is Map) {
              final emoji = reactionData['emoji'] as String;
              reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
              userReactions[userId] = emoji;
            }
          });

          messageReactions[messageId] = {
            'counts': reactionCounts,
            'userReactions': userReactions,
          };
        }
      });

      return messageReactions;
    });
  }
}
