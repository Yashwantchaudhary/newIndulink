const mongoose = require('mongoose');
const User = require('../models/User');

/**
 * Enhanced Role-Based Access Control (RBAC) Middleware
 * Provides fine-grained permission management and role-based authorization
 */

// Role hierarchy definition
const ROLE_HIERARCHY = {
    'superadmin': 4,
    'admin': 3,
    'supplier': 2,
    'customer': 1
};

// Permission definitions by role
const DEFAULT_ROLE_PERMISSIONS = {
    'customer': [
        'view_products', 'add_to_cart', 'checkout',
        'view_orders', 'manage_profile', 'view_wishlist',
        'manage_addresses', 'view_notifications'
    ],
    'supplier': [
        'manage_products', 'view_orders', 'manage_inventory',
        'view_analytics', 'manage_profile', 'manage_addresses',
        'view_notifications', 'manage_rfqs'
    ],
    'admin': [
        'manage_users', 'manage_products', 'manage_orders',
        'view_analytics', 'manage_settings', 'view_reports',
        'manage_content', 'manage_payments', 'manage_shipping',
        'manage_categories', 'manage_reviews'
    ],
    'superadmin': [
        'all_permissions', 'manage_admins', 'manage_roles',
        'manage_permissions', 'view_audit_logs', 'manage_system'
    ]
};

// Enhanced RBAC middleware
const rbacMiddleware = (requiredPermissions = [], requiredRoles = []) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            // Check if user is authenticated
            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Check if user account is active
            if (!user.isActive) {
                console.warn('[RBAC] Blocking request because user.isActive flag is falsy', {
                    userId: user.id || user._id,
                    role: user.role,
                    isActive: user.isActive
                });
                return res.status(403).json({
                    success: false,
                    message: 'Account is deactivated',
                    code: 'ACCOUNT_DEACTIVATED'
                });
            }

            // Check if account is locked
            if (user.isAccountLocked && user.isAccountLocked()) {
                return res.status(403).json({
                    success: false,
                    message: 'Account is temporarily locked',
                    lockedUntil: user.accountLockUntil,
                    code: 'ACCOUNT_LOCKED'
                });
            }

            // Check role-based access
            if (requiredRoles.length > 0) {
                const hasRequiredRole = requiredRoles.includes(user.role);

                if (!hasRequiredRole) {
                    return res.status(403).json({
                        success: false,
                        message: `Role '${user.role}' is not authorized to access this resource`,
                        requiredRoles,
                        userRole: user.role,
                        code: 'INSUFFICIENT_ROLE'
                    });
                }
            }

            // Check permission-based access
            if (requiredPermissions.length > 0) {
                // Get user's permissions (from database or default)
                const userPermissions = user.permissions && user.permissions.length > 0
                    ? user.permissions
                    : DEFAULT_ROLE_PERMISSIONS[user.role] || [];

                // Check if user has superadmin role (bypass permission check)
                if (user.role === 'superadmin') {
                    // Superadmin has all permissions
                    return next();
                }

                // Check if user has any of the required permissions
                const hasRequiredPermission = requiredPermissions.some(perm =>
                    userPermissions.includes(perm) || userPermissions.includes('all_permissions')
                );

                if (!hasRequiredPermission) {
                    return res.status(403).json({
                        success: false,
                        message: `Insufficient permissions to access this resource`,
                        requiredPermissions,
                        userPermissions,
                        code: 'INSUFFICIENT_PERMISSIONS'
                    });
                }
            }

            // User has required access, proceed
            next();
        } catch (error) {
            console.error('RBAC Middleware Error:', error);
            res.status(500).json({
                success: false,
                message: 'Authorization check failed',
                code: 'AUTHORIZATION_ERROR'
            });
        }
    };
};

// Role-based access control with hierarchy
const roleBasedAccess = (minRoleLevel) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            const userRoleLevel = ROLE_HIERARCHY[user.role] || 0;

            if (userRoleLevel < minRoleLevel) {
                return res.status(403).json({
                    success: false,
                    message: `Insufficient role level. Minimum required: ${getRoleByLevel(minRoleLevel)}`,
                    userRole: user.role,
                    userRoleLevel,
                    requiredRoleLevel: minRoleLevel,
                    code: 'INSUFFICIENT_ROLE_LEVEL'
                });
            }

            next();
        } catch (error) {
            console.error('Role-Based Access Error:', error);
            res.status(500).json({
                success: false,
                message: 'Role access check failed',
                code: 'ROLE_ACCESS_ERROR'
            });
        }
    };
};

// Helper function to get role by level
const getRoleByLevel = (level) => {
    for (const [role, roleLevel] of Object.entries(ROLE_HIERARCHY)) {
        if (roleLevel === level) return role;
    }
    return 'unknown';
};

// Permission-based access control
const permissionBasedAccess = (requiredPermission) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Get user's permissions
            const userPermissions = user.permissions && user.permissions.length > 0
                ? user.permissions
                : DEFAULT_ROLE_PERMISSIONS[user.role] || [];

            // Check if user has the required permission
            const hasPermission = userPermissions.includes(requiredPermission) ||
                                 userPermissions.includes('all_permissions') ||
                                 user.role === 'superadmin';

            if (!hasPermission) {
                return res.status(403).json({
                    success: false,
                    message: `Permission '${requiredPermission}' required`,
                    userPermissions,
                    code: 'MISSING_PERMISSION'
                });
            }

            next();
        } catch (error) {
            console.error('Permission-Based Access Error:', error);
            res.status(500).json({
                success: false,
                message: 'Permission check failed',
                code: 'PERMISSION_CHECK_ERROR'
            });
        }
    };
};

// Enhanced admin access control
const adminAccessControl = (resource, action) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Check if user is admin or superadmin
            if (!['admin', 'superadmin'].includes(user.role)) {
                return res.status(403).json({
                    success: false,
                    message: 'Admin access required',
                    code: 'ADMIN_ACCESS_REQUIRED'
                });
            }

            // Check resource-specific permissions for non-superadmins
            if (user.role === 'admin') {
                const requiredPermission = `${action}_${resource}`;

                const userPermissions = user.permissions && user.permissions.length > 0
                    ? user.permissions
                    : DEFAULT_ROLE_PERMISSIONS[user.role] || [];

                const hasPermission = userPermissions.includes(requiredPermission) ||
                                     userPermissions.includes('all_permissions');

                if (!hasPermission) {
                    return res.status(403).json({
                        success: false,
                        message: `Admin permission '${requiredPermission}' required`,
                        code: 'ADMIN_PERMISSION_REQUIRED'
                    });
                }
            }

            next();
        } catch (error) {
            console.error('Admin Access Control Error:', error);
            res.status(500).json({
                success: false,
                message: 'Admin access check failed',
                code: 'ADMIN_ACCESS_ERROR'
            });
        }
    };
};

// Enhanced ownership verification middleware
const verifyOwnership = (model, idField = '_id') => {
    return async (req, res, next) => {
        try {
            const user = req.user;
            const resourceId = req.params[idField || 'id'];

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Find the resource
            const Model = require(`../models/${model}`);
            const resource = await Model.findById(resourceId);

            if (!resource) {
                return res.status(404).json({
                    success: false,
                    message: 'Resource not found',
                    code: 'RESOURCE_NOT_FOUND'
                });
            }

            // Check if user owns the resource or is admin
            const isOwner = resource.userId && resource.userId.toString() === user.id;
            const isAdmin = ['admin', 'superadmin'].includes(user.role);

            if (!isOwner && !isAdmin) {
                return res.status(403).json({
                    success: false,
                    message: 'You do not have permission to access this resource',
                    code: 'OWNERSHIP_VERIFICATION_FAILED'
                });
            }

            // Attach resource to request for convenience
            req.resource = resource;
            next();
        } catch (error) {
            console.error('Ownership Verification Error:', error);
            res.status(500).json({
                success: false,
                message: 'Ownership verification failed',
                code: 'OWNERSHIP_VERIFICATION_ERROR'
            });
        }
    };
};

// Enhanced role and permission management
const RolePermissionManager = {
    // Get all permissions for a user
    getUserPermissions: async (userId) => {
        try {
            const readyState = mongoose.connection ? mongoose.connection.readyState : undefined;
            if (readyState !== 1) {
                console.warn('[RBAC] getUserPermissions invoked while Mongo connection is not ready', {
                    readyState
                });
            }

            const user = await User.findById(userId).select('role permissions');
            if (!user) return [];

            return user.permissions && user.permissions.length > 0
                ? user.permissions
                : DEFAULT_ROLE_PERMISSIONS[user.role] || [];
        } catch (error) {
            console.error('Error getting user permissions:', {
                message: error.message,
                readyState: mongoose.connection ? mongoose.connection.readyState : undefined
            });
            return [];
        }
    },

    // Check if user has specific permission
    userHasPermission: async (userId, permission) => {
        try {
            const readyState = mongoose.connection ? mongoose.connection.readyState : undefined;
            if (readyState !== 1) {
                console.warn('[RBAC] userHasPermission invoked while Mongo connection is not ready', {
                    readyState
                });
            }

            const permissions = await RolePermissionManager.getUserPermissions(userId);
            return permissions.includes(permission) || permissions.includes('all_permissions');
        } catch (error) {
            console.error('Error checking user permission:', {
                message: error.message,
                readyState: mongoose.connection ? mongoose.connection.readyState : undefined
            });
            return false;
        }
    },

    // Get user's role level
    getUserRoleLevel: (role) => {
        return ROLE_HIERARCHY[role] || 0;
    },

    // Check if user can access resource based on role hierarchy
    canAccessByRoleHierarchy: (userRole, requiredRole) => {
        const userLevel = ROLE_HIERARCHY[userRole] || 0;
        const requiredLevel = ROLE_HIERARCHY[requiredRole] || 0;
        return userLevel >= requiredLevel;
    }
};

// Enhanced multi-role access control
const multiRoleAccess = (roleOptions) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Check if user's role matches any of the allowed roles for the route
            const routeRoles = roleOptions[req.path] || roleOptions[req.originalUrl] || [];

            if (routeRoles.length > 0 && !routeRoles.includes(user.role)) {
                return res.status(403).json({
                    success: false,
                    message: `Role '${user.role}' cannot access this route`,
                    allowedRoles: routeRoles,
                    code: 'ROLE_ACCESS_DENIED'
                });
            }

            next();
        } catch (error) {
            console.error('Multi-Role Access Error:', error);
            res.status(500).json({
                success: false,
                message: 'Multi-role access check failed',
                code: 'MULTI_ROLE_ACCESS_ERROR'
            });
        }
    };
};

// Enhanced context-aware access control
const contextAwareAccess = (contextChecker) => {
    return async (req, res, next) => {
        try {
            const user = req.user;

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required',
                    code: 'UNAUTHENTICATED'
                });
            }

            // Execute context checker function
            const accessGranted = await contextChecker(req, user);

            if (!accessGranted) {
                return res.status(403).json({
                    success: false,
                    message: 'Access denied based on context',
                    code: 'CONTEXT_ACCESS_DENIED'
                });
            }

            next();
        } catch (error) {
            console.error('Context-Aware Access Error:', error);
            res.status(500).json({
                success: false,
                message: 'Context-aware access check failed',
                code: 'CONTEXT_ACCESS_ERROR'
            });
        }
    };
};

module.exports = {
    rbacMiddleware,
    roleBasedAccess,
    permissionBasedAccess,
    adminAccessControl,
    verifyOwnership,
    RolePermissionManager,
    multiRoleAccess,
    contextAwareAccess,
    ROLE_HIERARCHY,
    DEFAULT_ROLE_PERMISSIONS
};