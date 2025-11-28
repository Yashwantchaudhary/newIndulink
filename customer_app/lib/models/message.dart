class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final List<Attachment>? attachments;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.attachments,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((a) => Attachment.fromJson(a))
          .toList(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    List<Attachment>? attachments,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Attachment {
  final String type; // 'image', 'document'
  final String url;
  final String? filename;

  Attachment({
    required this.type,
    required this.url,
    this.filename,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      if (filename != null) 'filename': filename,
    };
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final LastMessage? lastMessage;
  final Map<String, int>? unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] != null
          ? Map<String, int>.from(json['unreadCount'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants,
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      if (unreadCount != null) 'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    List<String>? participants,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Handle unreadCount conversion
    Map<String, int>? newUnreadCount;
    if (unreadCount != null) {
      newUnreadCount = {'count': unreadCount};
    }

    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage != null
          ? LastMessage(
              text: lastMessage.text,
              senderId: lastMessage.senderId,
              timestamp: lastMessage.createdAt,
            )
          : this.lastMessage,
      unreadCount: newUnreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text'] ?? '',
      senderId: json['senderId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
