// services/firebaseMessageService.js
'use strict';

const { getDatabase } = require('../config/firebase');
const User = require('../models/User');
const PushNotificationService = require('./pushNotificationService');

class FirebaseMessageService {
  constructor() {
    this.db = getDatabase();
    this.pushService = new PushNotificationService();
    if (!this.db) {
      throw new Error('Firebase database not initialized');
    }
  }

  // Conversation id deterministic and stable
  generateConversationId(userId1, userId2) {
    const ids = [String(userId1), String(userId2)].sort();
    return `${ids[0]}_${ids[1]}`;
  }

  // Create message and update conversation metadata
  async sendMessage(senderId, receiverId, content = '', attachments = []) {
    if (!senderId || !receiverId) {
      throw new Error('senderId and receiverId are required');
    }

    const conversationId = this.generateConversationId(senderId, receiverId);
    const createdAt = Date.now(); // numeric timestamp for ordering

    const messageData = {
      senderId,
      receiverId,
      content: content || '',
      attachments: Array.isArray(attachments) ? attachments : [],
      isRead: false,
      createdAt,
      conversationId,
    };

    try {
      // push message
      const messagesRef = this.db.ref(`messages/${conversationId}`);
      const newRef = messagesRef.push();
      await newRef.set(messageData);

      // update conversation metadata (merge with existing)
      await this.updateConversationMetadata(conversationId, senderId, receiverId, {
        text: messageData.content,
        senderId: messageData.senderId,
        timestamp: createdAt,
      });

      const messageResult = {
        id: newRef.key,
        ...messageData,
      };

      // send push notification (non-blocking)
      try {
        await this.pushService.sendMessageNotification(senderId, receiverId, messageResult, conversationId);
      } catch (notificationError) {
        console.error('Push notification failed:', notificationError && notificationError.message ? notificationError.message : notificationError);
      }

      return messageResult;
    } catch (err) {
      console.error('Error sending message to Firebase:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Merge conversation metadata instead of overwriting
  async updateConversationMetadata(conversationId, senderId, receiverId, lastMessage) {
    try {
      const conversationRef = this.db.ref(`conversations/${conversationId}`);
      const snapshot = await conversationRef.once('value');
      const existing = snapshot.val() || {};

      const updateData = {
        participants: [senderId, receiverId],
        lastMessage: {
          text: lastMessage.text || '',
          senderId: lastMessage.senderId,
          timestamp: lastMessage.timestamp,
        },
        updatedAt: lastMessage.timestamp,
      };

      // preserve createdAt if exists
      if (!existing.createdAt) updateData.createdAt = lastMessage.timestamp;

      await conversationRef.update(updateData);
    } catch (err) {
      console.error('Error updating conversation metadata:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Get conversations for a user (returns sorted list with unread counts)
  async getConversations(userId) {
    if (!userId) return [];
    try {
      const conversationsRef = this.db.ref('conversations');
      const snapshot = await conversationsRef.once('value');
      const conversations = snapshot.val() || {};

      const results = [];

      // iterate and collect conversations where user participates
      for (const [conversationId, data] of Object.entries(conversations)) {
        if (Array.isArray(data.participants) && data.participants.includes(userId)) {
          const unreadCount = await this.getUnreadCount(conversationId, userId);
          results.push({
            _id: conversationId,
            participants: data.participants,
            lastMessage: data.lastMessage || null,
            unreadCount: { count: unreadCount },
            createdAt: data.createdAt || null,
            updatedAt: data.updatedAt || null,
          });
        }
      }

      // sort by lastMessage.timestamp or updatedAt
      results.sort((a, b) => {
        const aTime = a.lastMessage?.timestamp ?? a.updatedAt ?? a.createdAt ?? 0;
        const bTime = b.lastMessage?.timestamp ?? b.updatedAt ?? b.createdAt ?? 0;
        return bTime - aTime;
      });

      return results;
    } catch (err) {
      console.error('Error getting conversations from Firebase:', err && err.message ? err.message : err);
      throw err;
    }
  }

  /**
   * Get messages with cursor-based pagination.
   * - conversationId: string
   * - options: { limit: number, before: timestamp }  // before is exclusive; returns messages older than 'before'
   *
   * If before is not provided, returns the latest `limit` messages.
   */
  async getMessages(conversationId, options = {}) {
    const limit = Math.max(1, Math.min(200, options.limit || 50));
    const before = options.before || null; // numeric timestamp

    try {
      const messagesRef = this.db.ref(`messages/${conversationId}`);
      let query = messagesRef.orderByChild('createdAt');

      if (before) {
        // get messages with createdAt < before, then limitToLast
        query = query.endAt(before - 1).limitToLast(limit);
      } else {
        // latest messages
        query = query.limitToLast(limit);
      }

      const snapshot = await query.once('value');
      const messagesObj = snapshot.val() || {};

      // convert to array and sort ascending
      const messagesArray = Object.entries(messagesObj).map(([id, data]) => ({
        _id: id,
        ...data,
      }));
      messagesArray.sort((a, b) => a.createdAt - b.createdAt);

      // compute pagination cursors
      const totalFetched = messagesArray.length;
      const nextBefore = totalFetched ? messagesArray[0].createdAt : null; // older cursor
      const nextAfter = totalFetched ? messagesArray[messagesArray.length - 1].createdAt : null; // newer cursor

      return {
        messages: messagesArray,
        pagination: {
          limit,
          fetched: totalFetched,
          before: before || null,
          nextBefore, // use this as `before` for next page (older messages)
          nextAfter,  // can be used by clients if needed
        },
      };
    } catch (err) {
      console.error('Error getting messages from Firebase:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Mark all messages in conversation as read for a user (batch update)
  async markAsRead(conversationId, userId) {
    if (!conversationId || !userId) return;
    try {
      const messagesRef = this.db.ref(`messages/${conversationId}`);
      const snapshot = await messagesRef.orderByChild('receiverId').equalTo(userId).once('value');
      const messages = snapshot.val() || {};

      const updates = {};
      for (const [messageId, messageData] of Object.entries(messages)) {
        if (!messageData.isRead) {
          updates[`messages/${conversationId}/${messageId}/isRead`] = true;
          updates[`messages/${conversationId}/${messageId}/readAt`] = Date.now();
        }
      }

      if (Object.keys(updates).length > 0) {
        await this.db.ref().update(updates);
      }
    } catch (err) {
      console.error('Error marking messages as read:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Get unread count for a conversation for a user
  async getUnreadCount(conversationId, userId) {
    if (!conversationId || !userId) return 0;
    try {
      const snapshot = await this.db.ref(`messages/${conversationId}`).orderByChild('receiverId').equalTo(userId).once('value');
      const messages = snapshot.val() || {};
      let count = 0;
      for (const msg of Object.values(messages)) {
        if (!msg.isRead) count++;
      }
      return count;
    } catch (err) {
      console.error('Error getting unread count:', err && err.message ? err.message : err);
      return 0;
    }
  }

  // Validate sender and receiver exist and roles are allowed
  async validateMessage(senderId, receiverId) {
    try {
      const [sender, receiver] = await Promise.all([User.findById(senderId), User.findById(receiverId)]);
      if (!sender || !receiver) throw new Error('Sender or receiver not found');

      // customers <-> suppliers only
      if ((sender.role === 'customer' && receiver.role !== 'supplier') ||
          (sender.role === 'supplier' && receiver.role !== 'customer')) {
        throw new Error('Invalid recipient role for messaging');
      }

      return { sender, receiver };
    } catch (err) {
      console.error('Error validating message:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Delete a single message
  async deleteMessage(conversationId, messageId) {
    if (!conversationId || !messageId) return;
    try {
      await this.db.ref(`messages/${conversationId}/${messageId}`).remove();
    } catch (err) {
      console.error('Error deleting message:', err && err.message ? err.message : err);
      throw err;
    }
  }

  // Typing status: set and clear
  async setTypingStatus(conversationId, userId, isTyping) {
    try {
      const typingRef = this.db.ref(`typing/${conversationId}/${userId}`);
      if (isTyping) {
        await typingRef.set({ userId, timestamp: Date.now() });
        // auto-clear after 3s
        setTimeout(() => this.clearTypingStatus(conversationId, userId), 3000);
      } else {
        await this.clearTypingStatus(conversationId, userId);
      }
    } catch (err) {
      console.error('Error setting typing status:', err && err.message ? err.message : err);
      throw err;
    }
  }

  async clearTypingStatus(conversationId, userId) {
    try {
      await this.db.ref(`typing/${conversationId}/${userId}`).remove();
    } catch (err) {
      console.error('Error clearing typing status:', err && err.message ? err.message : err);
    }
  }

  // Listen to typing status; returns unsubscribe function
  listenToTypingStatus(conversationId, callback) {
    const typingRef = this.db.ref(`typing/${conversationId}`);
    const handler = (snapshot) => {
      const val = snapshot.val() || {};
      const typingUsers = Object.entries(val).map(([userId, info]) => ({
        userId,
        timestamp: info.timestamp,
      }));
      callback(typingUsers);
    };
    typingRef.on('value', handler);
    return () => typingRef.off('value', handler);
  }

  // Reactions
  async addReaction(conversationId, messageId, userId, emoji) {
    if (!conversationId || !messageId || !userId || !emoji) return;
    try {
      const reactionRef = this.db.ref(`reactions/${conversationId}/${messageId}/${userId}`);
      await reactionRef.set({ emoji, userId, timestamp: Date.now() });
    } catch (err) {
      console.error('Error adding reaction:', err && err.message ? err.message : err);
      throw err;
    }
  }

  async removeReaction(conversationId, messageId, userId) {
    try {
      const reactionRef = this.db.ref(`reactions/${conversationId}/${messageId}/${userId}`);
      await reactionRef.remove();
    } catch (err) {
      console.error('Error removing reaction:', err && err.message ? err.message : err);
      throw err;
    }
  }

  async getMessageReactions(conversationId, messageId) {
    try {
      const snapshot = await this.db.ref(`reactions/${conversationId}/${messageId}`).once('value');
      const reactions = snapshot.val() || {};
      const counts = {};
      const userReactions = {};
      for (const [userId, r] of Object.entries(reactions)) {
        const emoji = r.emoji;
        counts[emoji] = (counts[emoji] || 0) + 1;
        userReactions[userId] = emoji;
      }
      return { counts, userReactions };
    } catch (err) {
      console.error('Error getting message reactions:', err && err.message ? err.message : err);
      return { counts: {}, userReactions: {} };
    }
  }

  // Listen to reactions for a conversation; returns unsubscribe function
  listenToReactions(conversationId, callback) {
    const reactionsRef = this.db.ref(`reactions/${conversationId}`);
    const handler = (snapshot) => {
      const data = snapshot.val() || {};
      const messageReactions = {};
      for (const [messageId, messageReactionsData] of Object.entries(data)) {
        const counts = {};
        const userReactions = {};
        for (const [userId, reactionData] of Object.entries(messageReactionsData)) {
          const emoji = reactionData.emoji;
          counts[emoji] = (counts[emoji] || 0) + 1;
          userReactions[userId] = emoji;
        }
        messageReactions[messageId] = { counts, userReactions };
      }
      callback(messageReactions);
    };
    reactionsRef.on('value', handler);
    return () => reactionsRef.off('value', handler);
  }
}

module.exports = FirebaseMessageService;
