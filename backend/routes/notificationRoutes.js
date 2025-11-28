const express = require('express');
const router = express.Router();
const {
    registerFCMToken,
    unregisterFCMToken,
    testNotification,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

// All notification routes require authentication
router.use(protect);

router.post('/register-token', registerFCMToken);
router.delete('/unregister-token', unregisterFCMToken);
router.post('/test', testNotification);

module.exports = router;
