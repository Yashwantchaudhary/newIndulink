const { rbacMiddleware, RolePermissionManager } = require('../../middleware/rbacMiddleware');
const User = require('../../models/User');

describe('RBAC Middleware Tests', () => {
    let mockRequest;
    let mockResponse;
    let nextFunction;

    beforeEach(() => {
        mockRequest = {
            user: {
                id: 'user123',
                role: 'customer',
                permissions: ['view_products', 'add_to_cart']
            }
        };

        mockResponse = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        nextFunction = jest.fn();
    });

    describe('rbacMiddleware - Basic Functionality', () => {
        it('should allow access when user has required role', async () => {
            mockRequest.user.role = 'admin';

            const middleware = rbacMiddleware([], ['admin']);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(nextFunction).toHaveBeenCalled();
            expect(mockResponse.status).not.toHaveBeenCalled();
        });

        it('should deny access when user lacks required role', async () => {
            const middleware = rbacMiddleware([], ['admin']);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(mockResponse.status).toHaveBeenCalledWith(403);
            expect(mockResponse.json).toHaveBeenCalledWith(
                expect.objectContaining({
                    success: false,
                    code: 'INSUFFICIENT_ROLE'
                })
            );
            expect(nextFunction).not.toHaveBeenCalled();
        });

        it('should allow access when user has required permission', async () => {
            mockRequest.user.permissions = ['manage_products'];

            const middleware = rbacMiddleware(['manage_products']);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(nextFunction).toHaveBeenCalled();
            expect(mockResponse.status).not.toHaveBeenCalled();
        });

        it('should deny access when user lacks required permission', async () => {
            const middleware = rbacMiddleware(['manage_users']);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(mockResponse.status).toHaveBeenCalledWith(403);
            expect(mockResponse.json).toHaveBeenCalledWith(
                expect.objectContaining({
                    success: false,
                    code: 'INSUFFICIENT_PERMISSIONS'
                })
            );
            expect(nextFunction).not.toHaveBeenCalled();
        });
    });

    describe('RolePermissionManager - Permission Management', () => {
        let testUser;

        beforeEach(async () => {
            testUser = await User.create({
                firstName: 'Test',
                lastName: 'User',
                email: 'test-rbac@example.com',
                password: 'Test@1234',
                role: 'admin',
                permissions: ['manage_users', 'view_analytics']
            });
        });

        afterEach(async () => {
            await User.deleteMany({});
        });

        it('should get user permissions', async () => {
            const permissions = await RolePermissionManager.getUserPermissions(testUser._id);

            expect(permissions).toContain('manage_users');
            expect(permissions).toContain('view_analytics');
        });

        it('should check if user has specific permission', async () => {
            const hasPermission = await RolePermissionManager.userHasPermission(
                testUser._id,
                'manage_users'
            );

            expect(hasPermission).toBe(true);
        });

        it('should return false for non-existent permission', async () => {
            const hasPermission = await RolePermissionManager.userHasPermission(
                testUser._id,
                'nonexistent_permission'
            );

            expect(hasPermission).toBe(false);
        });

        it('should get user role level', () => {
            const level = RolePermissionManager.getUserRoleLevel('admin');
            expect(level).toBe(3);
        });

        it('should check role hierarchy access', () => {
            const canAccess = RolePermissionManager.canAccessByRoleHierarchy('admin', 'customer');
            expect(canAccess).toBe(true);
        });

        it('should deny access based on role hierarchy', () => {
            const canAccess = RolePermissionManager.canAccessByRoleHierarchy('customer', 'admin');
            expect(canAccess).toBe(false);
        });
    });

    describe('RBAC Middleware - Edge Cases', () => {
        it('should allow superadmin access regardless of permissions', async () => {
            mockRequest.user.role = 'superadmin';
            mockRequest.user.permissions = [];

            const middleware = rbacMiddleware(['nonexistent_permission']);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(nextFunction).toHaveBeenCalled();
            expect(mockResponse.status).not.toHaveBeenCalled();
        });

        it('should deny access for unauthenticated users', async () => {
            mockRequest.user = null;

            const middleware = rbacMiddleware([]);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(mockResponse.status).toHaveBeenCalledWith(401);
            expect(mockResponse.json).toHaveBeenCalledWith(
                expect.objectContaining({
                    success: false,
                    code: 'UNAUTHENTICATED'
                })
            );
        });

        it('should deny access for deactivated users', async () => {
            mockRequest.user.isActive = false;

            const middleware = rbacMiddleware([]);
            await middleware(mockRequest, mockResponse, nextFunction);

            expect(mockResponse.status).toHaveBeenCalledWith(403);
            expect(mockResponse.json).toHaveBeenCalledWith(
                expect.objectContaining({
                    success: false,
                    code: 'ACCOUNT_DEACTIVATED'
                })
            );
        });
    });
});

describe('RBAC Integration Tests', () => {
    let adminUser;
    let customerUser;
    let adminToken;
    let customerToken;

    beforeAll(async () => {
        // Create test users
        adminUser = await User.create({
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin-rbac@example.com',
            password: 'Admin@1234',
            role: 'admin',
            permissions: ['manage_users', 'view_analytics']
        });

        customerUser = await User.create({
            firstName: 'Customer',
            lastName: 'User',
            email: 'customer-rbac@example.com',
            password: 'Customer@1234',
            role: 'customer'
        });

        adminToken = adminUser.generateAccessToken();
        customerToken = customerUser.generateAccessToken();
    });

    afterAll(async () => {
        await User.deleteMany({});
    });

    it('should allow admin to access admin-only routes', async () => {
        const mockRequest = {
            user: adminUser,
            path: '/admin/users'
        };

        const mockResponse = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        const nextFunction = jest.fn();

        const middleware = rbacMiddleware([], ['admin']);
        await middleware(mockRequest, mockResponse, nextFunction);

        expect(nextFunction).toHaveBeenCalled();
    });

    it('should deny customer access to admin-only routes', async () => {
        const mockRequest = {
            user: customerUser,
            path: '/admin/users'
        };

        const mockResponse = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };

        const nextFunction = jest.fn();

        const middleware = rbacMiddleware([], ['admin']);
        await middleware(mockRequest, mockResponse, nextFunction);

        expect(mockResponse.status).toHaveBeenCalledWith(403);
        expect(nextFunction).not.toHaveBeenCalled();
    });
});