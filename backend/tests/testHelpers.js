/**
 * Setup test environment
 */
const setupTestEnvironment = async () => {
    // Simple test environment setup
    console.log('✅ Test environment setup');
};

/**
 * Cleanup test environment
 */
const cleanupTestEnvironment = async () => {
    console.log('✅ Test environment cleaned up');
};

/**
 * Create test user data
 */
const createTestUser = (overrides = {}) => ({
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    password: 'Test@1234',
    role: 'customer',
    isEmailVerified: true,
    phone: '+9779800000000',
    ...overrides
});

/**
 * Create test admin data
 */
const createTestAdmin = (overrides = {}) => ({
    ...createTestUser(),
    role: 'admin',
    email: 'admin@example.com',
    ...overrides
});

/**
 * Create test supplier data
 */
const createTestSupplier = (overrides = {}) => ({
    ...createTestUser(),
    role: 'supplier',
    email: 'supplier@example.com',
    businessName: 'Test Business',
    businessDescription: 'Test business description',
    ...overrides
});

module.exports = {
    setupTestEnvironment,
    cleanupTestEnvironment,
    createTestUser,
    createTestAdmin,
    createTestSupplier,
    testUser: createTestUser(),
    testAdmin: createTestAdmin(),
    testSupplier: createTestSupplier(),
};