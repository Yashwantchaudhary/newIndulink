const PushNotificationService = require('../services/pushNotificationService');

const pushService = new PushNotificationService();

// @desc    Register FCM token for user
// @route   POST /api/notifications/register-token
// @access  Private
exports.registerFCMToken = async (req, res, next) => {
    try {
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({
                success: false,
                message: 'FCM token is required',
            });
        }

        await pushService.updateUserFCMToken(req.user.id, fcmToken);

        res.status(200).json({
            success: true,
            message: 'FCM token registered successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Unregister FCM token for user
// @route   DELETE /api/notifications/unregister-token
// @access  Private
exports.unregisterFCMToken = async (req, res, next) => {
    try {
        await pushService.removeUserFCMToken(req.user.id);

        res.status(200).json({
            success: true,
            message: 'FCM token unregistered successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Test push notification
// @route   POST /api/notifications/test
// @access  Private
exports.testNotification = async (req, res, next) => {
    try {
        const { title, body } = req.body;

        await pushService.sendBroadcastNotification(
            [req.user.id],
            title || 'Test Notification',
            body || 'This is a test push notification',
            { type: 'test' }
        );

        res.status(200).json({
            success: true,
            message: 'Test notification sent',
        });
    } catch (error) {
        next(error);
    }
};
