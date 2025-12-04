const express = require('express');
const router = express.Router();
const {
    getConversations,
    getMessages,
    sendMessage,
    markAsRead,
    getUnreadCount,
    searchConversations,
    deleteMessage,
    getMessageStats,
} = require('../controllers/messageController');
const { protect, requireAdmin } = require('../middleware/authMiddleware');

// All message routes require authentication
router.use(protect);

router.get('/conversations', getConversations);
router.get('/conversations/search', searchConversations);
router.get('/conversation/:userId', getMessages);
router.post('/', sendMessage);
router.put('/read/:conversationId', markAsRead);
router.delete('/:messageId', deleteMessage);
router.get('/unread/count', getUnreadCount);
router.get('/stats', requireAdmin, getMessageStats);

module.exports = router;
