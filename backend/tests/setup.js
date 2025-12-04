const { setupTestEnvironment } = require('./testHelpers');

module.exports = async () => {
    // Setup test environment
    await setupTestEnvironment();

    // Mock any external services if needed
    jest.mock('../services/notificationService', () => ({
        sendOrderStatusNotification: jest.fn().mockResolvedValue(true)
    }));
};