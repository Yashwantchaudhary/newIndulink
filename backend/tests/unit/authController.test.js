const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const { setupTestDB, teardownTestDB } = require('../setup');
const { generateTestUser } = require('../mocks/faker');

describe('Authentication Controller - Enhanced Security Tests', () => {
    let testUser;
    let adminUser;
    let authToken;
    let adminToken;

    beforeAll(async () => {
        await setupTestDB();
    });

    afterAll(async () => {
        await teardownTestDB();
    });

    beforeEach(async () => {
        // Create test users
        testUser = await User.create({
            firstName: 'Test',
            lastName: 'User',
            email: 'test@example.com',
            password: 'Test@1234',
            role: 'customer'
        });

        adminUser = await User.create({
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@example.com',
            password: 'Admin@1234',
            role: 'admin'
        });

        // Generate tokens
        authToken = testUser.generateAccessToken();
        adminToken = adminUser.generateAccessToken();
    });

    afterEach(async () => {
        // Clean up
        await User.deleteMany({});
    });

    describe('POST /api/auth/register - Enhanced Registration', () => {
        it('should reject weak passwords', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    firstName: 'John',
                    lastName: 'Doe',
                    email: 'john@example.com',
                    password: 'weak', // Weak password
                    role: 'customer'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('WEAK_PASSWORD');
            expect(response.body.suggestions).toBeDefined();
        });

        it('should accept strong passwords', async () => {
            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    firstName: 'John',
                    lastName: 'Doe',
                    email: 'john@example.com',
                    password: 'Strong@1234', // Strong password
                    role: 'customer'
                });

            expect(response.status).toBe(201);
            expect(response.body.success).toBe(true);
            expect(response.body.data.user.email).toBe('john@example.com');
        });

        it('should reject duplicate emails', async () => {
            // First registration
            await request(app)
                .post('/api/auth/register')
                .send({
                    firstName: 'John',
                    lastName: 'Doe',
                    email: 'duplicate@example.com',
                    password: 'Strong@1234',
                    role: 'customer'
                });

            // Second registration with same email
            const response = await request(app)
                .post('/api/auth/register')
                .send({
                    firstName: 'Jane',
                    lastName: 'Doe',
                    email: 'duplicate@example.com',
                    password: 'Strong@1234',
                    role: 'customer'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.message).toContain('already exists');
        });
    });

    describe('POST /api/auth/login - Enhanced Login Security', () => {
        it('should lock account after 5 failed login attempts', async () => {
            // Make 5 failed login attempts
            for (let i = 0; i < 5; i++) {
                await request(app)
                    .post('/api/auth/login')
                    .send({
                        email: testUser.email,
                        password: 'wrongpassword'
                    });
            }

            // 6th attempt should lock the account
            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'wrongpassword'
                });

            expect(response.status).toBe(403);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('ACCOUNT_LOCKED');
            expect(response.body.lockedUntil).toBeDefined();
        });

        it('should allow login with correct credentials', async () => {
            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'Test@1234'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.accessToken).toBeDefined();
        });

        it('should reject login for deactivated accounts', async () => {
            // Deactivate user
            testUser.isActive = false;
            await testUser.save();

            const response = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'Test@1234'
                });

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('ACCOUNT_DEACTIVATED');
        });
    });

    describe('POST /api/auth/refresh - Enhanced Token Refresh', () => {
        it('should reject invalid refresh tokens', async () => {
            const response = await request(app)
                .post('/api/auth/refresh')
                .send({
                    refreshToken: 'invalidtoken'
                });

            expect(response.status).toBe(401);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('INVALID_REFRESH_TOKEN');
        });

        it('should generate new access token with valid refresh token', async () => {
            // First login to get refresh token
            const loginResponse = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'Test@1234'
                });

            const refreshToken = loginResponse.body.data.refreshToken;

            // Use refresh token
            const response = await request(app)
                .post('/api/auth/refresh')
                .send({
                    refreshToken
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.accessToken).toBeDefined();
        });
    });

    describe('PUT /api/auth/update-password - Password Update', () => {
        it('should reject weak new passwords', async () => {
            const response = await request(app)
                .put('/api/auth/update-password')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    currentPassword: 'Test@1234',
                    newPassword: 'weak'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('WEAK_NEW_PASSWORD');
        });

        it('should update password with strong new password', async () => {
            const response = await request(app)
                .put('/api/auth/update-password')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    currentPassword: 'Test@1234',
                    newPassword: 'NewStrong@1234'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
        });
    });

    describe('POST /api/auth/forgot-password - Password Reset', () => {
        it('should generate password reset token', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({
                    email: testUser.email
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
        });

        it('should not reveal if email exists or not', async () => {
            const response = await request(app)
                .post('/api/auth/forgot-password')
                .send({
                    email: 'nonexistent@example.com'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.message).toContain('If an account with this email exists');
        });
    });

    describe('POST /api/auth/reset-password - Password Reset with Token', () => {
        it('should reset password with valid token', async () => {
            // First request password reset
            await request(app)
                .post('/api/auth/forgot-password')
                .send({
                    email: testUser.email
                });

            // Get the user to find the reset token
            const user = await User.findOne({ email: testUser.email }).select('+passwordResetToken');

            // Reset password
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: user.passwordResetToken,
                    newPassword: 'Reset@1234'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
        });

        it('should reject invalid or expired tokens', async () => {
            const response = await request(app)
                .post('/api/auth/reset-password')
                .send({
                    token: 'invalidtoken',
                    newPassword: 'Reset@1234'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
        });
    });
});

describe('Authentication Rate Limiting Tests', () => {
    it('should limit login attempts', async () => {
        // Make multiple login attempts to trigger rate limiting
        for (let i = 0; i < 6; i++) {
            await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'nonexistent@example.com',
                    password: 'wrongpassword'
                });
        }

        // Should be rate limited
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'nonexistent@example.com',
                password: 'wrongpassword'
            });

        expect(response.status).toBe(429);
        expect(response.body.success).toBe(false);
        expect(response.body.code).toBe('RATE_LIMIT_EXCEEDED');
    }, 10000); // Increase timeout for rate limiting test
});