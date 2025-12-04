const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const { setupTestDB, teardownTestDB } = require('../setup');

describe('User Management Controller Tests', () => {
    let adminUser;
    let customerUser;
    let adminToken;
    let customerToken;

    beforeAll(async () => {
        await setupTestDB();

        // Create admin user
        adminUser = await User.create({
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@management.com',
            password: 'Admin@1234',
            role: 'admin',
            permissions: ['manage_users', 'view_analytics']
        });

        // Create customer user
        customerUser = await User.create({
            firstName: 'Customer',
            lastName: 'User',
            email: 'customer@management.com',
            password: 'Customer@1234',
            role: 'customer'
        });

        adminToken = adminUser.generateAccessToken();
        customerToken = customerUser.generateAccessToken();
    });

    afterAll(async () => {
        await teardownTestDB();
    });

    afterEach(async () => {
        // Clean up users created during tests
        await User.deleteMany({
            email: { $nin: ['admin@management.com', 'customer@management.com'] }
        });
    });

    describe('GET /api/admin/users - User Listing', () => {
        it('should allow admin to get all users', async () => {
            const response = await request(app)
                .get('/api/admin/users')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(Array.isArray(response.body.data)).toBe(true);
        });

        it('should deny customer access to user listing', async () => {
            const response = await request(app)
                .get('/api/admin/users')
                .set('Authorization', `Bearer ${customerToken}`);

            expect(response.status).toBe(403);
            expect(response.body.success).toBe(false);
        });

        it('should filter users by role', async () => {
            const response = await request(app)
                .get('/api/admin/users?role=customer')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.every(user => user.role === 'customer')).toBe(true);
        });
    });

    describe('POST /api/admin/users - User Creation', () => {
        it('should allow admin to create new user', async () => {
            const response = await request(app)
                .post('/api/admin/users')
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    firstName: 'New',
                    lastName: 'User',
                    email: 'newuser@example.com',
                    password: 'NewUser@1234',
                    role: 'customer'
                });

            expect(response.status).toBe(201);
            expect(response.body.success).toBe(true);
            expect(response.body.data.email).toBe('newuser@example.com');
        });

        it('should reject weak passwords during user creation', async () => {
            const response = await request(app)
                .post('/api/admin/users')
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    firstName: 'New',
                    lastName: 'User',
                    email: 'weakpass@example.com',
                    password: 'weak',
                    role: 'customer'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('WEAK_PASSWORD');
        });

        it('should reject duplicate emails', async () => {
            const response = await request(app)
                .post('/api/admin/users')
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    firstName: 'New',
                    lastName: 'User',
                    email: 'admin@management.com', // Duplicate email
                    password: 'NewUser@1234',
                    role: 'customer'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('USER_ALREADY_EXISTS');
        });
    });

    describe('GET /api/admin/users/:id - Get User by ID', () => {
        it('should allow admin to get user details', async () => {
            const response = await request(app)
                .get(`/api/admin/users/${customerUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.user.email).toBe(customerUser.email);
        });

        it('should return 404 for non-existent user', async () => {
            const fakeId = '507f1f77bcf86cd799439011'; // Fake MongoDB ID
            const response = await request(app)
                .get(`/api/admin/users/${fakeId}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(404);
            expect(response.body.success).toBe(false);
        });
    });

    describe('PUT /api/admin/users/:id - Update User', () => {
        it('should allow admin to update user details', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    firstName: 'Updated',
                    lastName: 'Name'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.firstName).toBe('Updated');
        });

        it('should allow admin to update user role', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    role: 'supplier'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.role).toBe('supplier');
        });

        it('should reject invalid role updates', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    role: 'invalidrole'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
        });
    });

    describe('PUT /api/admin/users/:id/password - Update User Password', () => {
        it('should allow admin to update user password', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}/password`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    newPassword: 'Updated@1234'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
        });

        it('should reject weak passwords during admin update', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}/password`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    newPassword: 'weak'
                });

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('WEAK_NEW_PASSWORD');
        });
    });

    describe('DELETE /api/admin/users/:id - Delete User', () => {
        let testUser;

        beforeEach(async () => {
            testUser = await User.create({
                firstName: 'Test',
                lastName: 'User',
                email: 'test-delete@example.com',
                password: 'Test@1234',
                role: 'customer'
            });
        });

        it('should allow admin to delete user', async () => {
            const response = await request(app)
                .delete(`/api/admin/users/${testUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);

            // Verify user is deleted
            const deletedUser = await User.findById(testUser._id);
            expect(deletedUser).toBeNull();
        });

        it('should prevent admin from deleting themselves', async () => {
            const response = await request(app)
                .delete(`/api/admin/users/${adminUser._id}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('CANNOT_DELETE_SELF');
        });

        it('should prevent deleting superadmin users', async () => {
            const superadmin = await User.create({
                firstName: 'Super',
                lastName: 'Admin',
                email: 'superadmin@example.com',
                password: 'Super@1234',
                role: 'superadmin'
            });

            const response = await request(app)
                .delete(`/api/admin/users/${superadmin._id}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(400);
            expect(response.body.success).toBe(false);
            expect(response.body.code).toBe('CANNOT_DELETE_SUPERADMIN');
        });
    });

    describe('PUT /api/admin/users/bulk-update - Bulk User Updates', () => {
        let user1, user2;

        beforeEach(async () => {
            user1 = await User.create({
                firstName: 'Bulk',
                lastName: 'User1',
                email: 'bulk1@example.com',
                password: 'Bulk@1234',
                role: 'customer'
            });

            user2 = await User.create({
                firstName: 'Bulk',
                lastName: 'User2',
                email: 'bulk2@example.com',
                password: 'Bulk@1234',
                role: 'customer'
            });
        });

        it('should allow admin to bulk update users', async () => {
            const response = await request(app)
                .put('/api/admin/users/bulk-update')
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    userIds: [user1._id.toString(), user2._id.toString()],
                    updates: {
                        isActive: true,
                        role: 'supplier'
                    }
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.results.successCount).toBe(2);
        });

        it('should handle bulk update errors gracefully', async () => {
            const fakeId = '507f1f77bcf86cd799439011'; // Fake MongoDB ID
            const response = await request(app)
                .put('/api/admin/users/bulk-update')
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    userIds: [user1._id.toString(), fakeId],
                    updates: {
                        isActive: true
                    }
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.results.successCount).toBe(1);
            expect(response.body.results.errorCount).toBe(1);
        });
    });

    describe('GET /api/admin/users/stats - User Statistics', () => {
        it('should allow admin to get user statistics', async () => {
            const response = await request(app)
                .get('/api/admin/users/stats')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.totalUsers).toBeGreaterThan(0);
            expect(response.body.data.byRole).toBeDefined();
        });
    });

    describe('GET /api/admin/users/search - User Search', () => {
        it('should allow admin to search users', async () => {
            const response = await request(app)
                .get('/api/admin/users/search?query=admin')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(Array.isArray(response.body.data)).toBe(true);
        });
    });

    describe('GET /api/admin/users/:id/permissions - User Permissions', () => {
        it('should allow admin to get user permissions', async () => {
            const response = await request(app)
                .get(`/api/admin/users/${adminUser._id}/permissions`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.currentPermissions).toContain('manage_users');
        });
    });

    describe('PUT /api/admin/users/:id/permissions - Update User Permissions', () => {
        it('should allow admin to update user permissions', async () => {
            const response = await request(app)
                .put(`/api/admin/users/${customerUser._id}/permissions`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({
                    permissions: ['view_products', 'add_to_cart']
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.updatedPermissions).toContain('view_products');
        });
    });
});

describe('User Management Security Tests', () => {
    let customerUser;
    let customerToken;

    beforeAll(async () => {
        customerUser = await User.create({
            firstName: 'Customer',
            lastName: 'Security',
            email: 'security-customer@example.com',
            password: 'Customer@1234',
            role: 'customer'
        });

        customerToken = customerUser.generateAccessToken();
    });

    afterAll(async () => {
        await User.deleteMany({});
    });

    it('should prevent customer from accessing admin routes', async () => {
        const response = await request(app)
            .get('/api/admin/users')
            .set('Authorization', `Bearer ${customerToken}`);

        expect(response.status).toBe(403);
        expect(response.body.success).toBe(false);
    });

    it('should prevent unauthenticated access to admin routes', async () => {
        const response = await request(app)
            .get('/api/admin/users');

        expect(response.status).toBe(401);
        expect(response.body.success).toBe(false);
    });
});