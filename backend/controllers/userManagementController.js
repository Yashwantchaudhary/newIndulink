const User = require('../models/User');
const { checkPasswordStrength } = require('../middleware/securityMiddleware');
const { RolePermissionManager } = require('../middleware/rbacMiddleware');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

/**
 * Comprehensive User Management Controller
 * Provides enhanced user management capabilities with security features
 */

// @desc    Get all users with enhanced filtering and pagination
// @route   GET /api/admin/users
// @access  Private (Admin)
const getAllUsers = async (req, res, next) => {
    try {
        const {
            page = 1,
            limit = 20,
            role,
            status,
            search,
            sortBy = 'createdAt',
            sortOrder = 'desc',
            emailVerified,
            accountLocked
        } = req.query;

        const skip = (parseInt(page) - 1) * parseInt(limit);
        const filter = {};

        // Role filtering
        if (role) {
            filter.role = role;
        }

        // Status filtering
        if (status) {
            filter.isActive = status === 'active';
        }

        // Email verification filtering
        if (emailVerified) {
            filter.isEmailVerified = emailVerified === 'true';
        }

        // Account lock filtering
        if (accountLocked) {
            filter.accountLockUntil = { $gt: new Date() };
        }

        // Search functionality
        if (search) {
            filter.$or = [
                { firstName: { $regex: search, $options: 'i' } },
                { lastName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } },
                { businessName: { $regex: search, $options: 'i' } },
                { phone: { $regex: search, $options: 'i' } }
            ];
        }

        // Sorting
        const sort = {};
        sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

        const users = await User.find(filter)
            .select('-password -refreshToken -emailVerificationToken -passwordResetToken -twoFactorAuthSecret -twoFactorAuthBackupCodes')
            .sort(sort)
            .skip(skip)
            .limit(parseInt(limit));

        const total = await User.countDocuments(filter);

        res.status(200).json({
            success: true,
            data: users,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / parseInt(limit)),
                limit: parseInt(limit),
                hasMore: skip + users.length < total
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user by ID with enhanced details
// @route   GET /api/admin/users/:id
// @access  Private (Admin)
const getUserById = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id)
            .select('-password -refreshToken -emailVerificationToken -passwordResetToken -twoFactorAuthSecret -twoFactorAuthBackupCodes');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Get user permissions
        const permissions = await RolePermissionManager.getUserPermissions(user._id);

        res.status(200).json({
            success: true,
            data: {
                user,
                permissions,
                roleLevel: RolePermissionManager.getUserRoleLevel(user.role)
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Create user (Admin only)
// @route   POST /api/admin/users
// @access  Private (Admin)
const createUser = async (req, res, next) => {
    try {
        const {
            firstName, lastName, email, password, phone, role,
            businessName, businessDescription, permissions, isActive
        } = req.body;

        // Validate required fields
        if (!firstName || !lastName || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'First name, last name, email, and password are required',
                code: 'MISSING_REQUIRED_FIELDS'
            });
        }

        // Validate password strength
        const passwordCheck = checkPasswordStrength(password);
        if (passwordCheck.rating === 'weak') {
            return res.status(400).json({
                success: false,
                message: 'Password is too weak',
                suggestions: passwordCheck.suggestions,
                code: 'WEAK_PASSWORD'
            });
        }

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'User with this email already exists',
                code: 'USER_ALREADY_EXISTS'
            });
        }

        // Validate role
        const validRoles = ['customer', 'supplier', 'admin'];
        if (role && !validRoles.includes(role)) {
            return res.status(400).json({
                success: false,
                message: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
                code: 'INVALID_ROLE'
            });
        }

        // Create user
        const userData = {
            firstName,
            lastName,
            email,
            password,
            phone: phone || null,
            role: role || 'customer',
            isActive: isActive !== undefined ? isActive : true,
            permissions: permissions || []
        };

        // Add business-specific fields for suppliers
        if (role === 'supplier') {
            userData.businessName = businessName || null;
            userData.businessDescription = businessDescription || null;
        }

        const user = await User.create(userData);

        // Generate email verification token
        user.generateEmailVerificationToken();
        await user.save();

        // Remove sensitive data
        user.password = undefined;

        res.status(201).json({
            success: true,
            message: 'User created successfully',
            data: user
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user (Admin only)
// @route   PUT /api/admin/users/:id
// @access  Private (Admin)
const updateUser = async (req, res, next) => {
    try {
        const {
            firstName, lastName, email, phone, role,
            businessName, businessDescription, permissions, isActive
        } = req.body;

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Update basic fields
        if (firstName) user.firstName = firstName;
        if (lastName) user.lastName = lastName;
        if (phone) user.phone = phone;
        if (isActive !== undefined) user.isActive = isActive;

        // Update role with validation
        if (role) {
            const validRoles = ['customer', 'supplier', 'admin'];
            if (!validRoles.includes(role)) {
                return res.status(400).json({
                    success: false,
                    message: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
                    code: 'INVALID_ROLE'
                });
            }

            // Prevent demoting superadmin
            if (user.role === 'superadmin' && role !== 'superadmin') {
                return res.status(400).json({
                    success: false,
                    message: 'Cannot change superadmin role',
                    code: 'CANNOT_CHANGE_SUPERADMIN_ROLE'
                });
            }

            user.role = role;
        }

        // Update permissions
        if (permissions !== undefined) {
            user.permissions = permissions;
        }

        // Update business fields for suppliers
        if (role === 'supplier' || user.role === 'supplier') {
            if (businessName !== undefined) user.businessName = businessName;
            if (businessDescription !== undefined) user.businessDescription = businessDescription;
        }

        await user.save();

        // Get updated user without sensitive data
        const updatedUser = await User.findById(req.params.id)
            .select('-password -refreshToken -emailVerificationToken -passwordResetToken -twoFactorAuthSecret -twoFactorAuthBackupCodes');

        res.status(200).json({
            success: true,
            message: 'User updated successfully',
            data: updatedUser
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user password (Admin only)
// @route   PUT /api/admin/users/:id/password
// @access  Private (Admin)
const updateUserPassword = async (req, res, next) => {
    try {
        const { newPassword } = req.body;

        if (!newPassword) {
            return res.status(400).json({
                success: false,
                message: 'New password is required',
                code: 'MISSING_NEW_PASSWORD'
            });
        }

        // Validate password strength
        const passwordCheck = checkPasswordStrength(newPassword);
        if (passwordCheck.rating === 'weak') {
            return res.status(400).json({
                success: false,
                message: 'New password is too weak',
                suggestions: passwordCheck.suggestions,
                code: 'WEAK_NEW_PASSWORD'
            });
        }

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Update password
        user.password = newPassword;
        user.loginAttempts = 0;
        user.accountLockUntil = null;
        await user.save();

        // Send security notification
        try {
            const { createAndSendNotification } = require('../services/notificationService');
            await createAndSendNotification({
                userId: user._id.toString(),
                type: 'security',
                title: 'Password Updated by Admin',
                message: 'Your password has been updated by an administrator. If this was not authorized, please contact support immediately.',
                data: {
                    securityAlert: true,
                    actionRequired: true,
                    timestamp: new Date().toISOString()
                },
            });
        } catch (notificationError) {
            console.error('Error sending admin password update notification:', notificationError);
        }

        res.status(200).json({
            success: true,
            message: 'User password updated successfully'
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete user (Admin only)
// @route   DELETE /api/admin/users/:id
// @access  Private (Admin)
const deleteUser = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Prevent deleting superadmin
        if (user.role === 'superadmin') {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete superadmin user',
                code: 'CANNOT_DELETE_SUPERADMIN'
            });
        }

        // Prevent admin from deleting themselves
        if (user._id.toString() === req.user.id) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete your own account',
                code: 'CANNOT_DELETE_SELF'
            });
        }

        await user.remove();

        res.status(200).json({
            success: true,
            message: 'User deleted successfully'
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Bulk update users (Admin only)
// @route   PUT /api/admin/users/bulk-update
// @access  Private (Admin)
const bulkUpdateUsers = async (req, res, next) => {
    try {
        const { userIds, updates } = req.body;

        if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'User IDs array is required',
                code: 'MISSING_USER_IDS'
            });
        }

        if (!updates || Object.keys(updates).length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Updates object is required',
                code: 'MISSING_UPDATES'
            });
        }

        // Validate updates
        const allowedUpdates = ['isActive', 'role', 'permissions'];
        const invalidUpdates = Object.keys(updates).filter(update => !allowedUpdates.includes(update));

        if (invalidUpdates.length > 0) {
            return res.status(400).json({
                success: false,
                message: `Invalid update fields: ${invalidUpdates.join(', ')}`,
                allowedFields: allowedUpdates,
                code: 'INVALID_UPDATE_FIELDS'
            });
        }

        // Process bulk update
        const results = [];
        const errors = [];

        for (const userId of userIds) {
            try {
                const user = await User.findById(userId);
                if (!user) {
                    errors.push({
                        userId,
                        error: 'User not found'
                    });
                    continue;
                }

                // Apply updates
                if (updates.isActive !== undefined) user.isActive = updates.isActive;
                if (updates.role) {
                    const validRoles = ['customer', 'supplier', 'admin'];
                    if (validRoles.includes(updates.role)) {
                        user.role = updates.role;
                    }
                }
                if (updates.permissions) {
                    user.permissions = updates.permissions;
                }

                await user.save();

                results.push({
                    userId: user._id,
                    success: true,
                    message: 'User updated successfully'
                });
            } catch (error) {
                errors.push({
                    userId,
                    error: error.message
                });
            }
        }

        res.status(200).json({
            success: true,
            message: 'Bulk update completed',
            results: {
                successCount: results.length,
                errorCount: errors.length,
                totalProcessed: userIds.length
            },
            details: {
                successfulUpdates: results,
                failedUpdates: errors
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user activity and security logs
// @route   GET /api/admin/users/:id/activity
// @access  Private (Admin)
const getUserActivity = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id)
            .select('lastLogin loginAttempts accountLockUntil passwordChangedAt createdAt');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // In a real implementation, this would query activity logs
        // For this example, we'll return the available security data
        const activityData = {
            lastLogin: user.lastLogin,
            loginAttempts: user.loginAttempts,
            accountStatus: user.accountLockUntil ? 'locked' : 'active',
            lockedUntil: user.accountLockUntil,
            passwordLastChanged: user.passwordChangedAt,
            accountCreated: user.createdAt,
            securityEvents: [] // Would be populated from security logs in real implementation
        };

        res.status(200).json({
            success: true,
            data: activityData
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Unlock user account (Admin only)
// @route   POST /api/admin/users/:id/unlock
// @access  Private (Admin)
const unlockUserAccount = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Reset login attempts and unlock account
        user.loginAttempts = 0;
        user.accountLockUntil = null;
        await user.save();

        res.status(200).json({
            success: true,
            message: 'User account unlocked successfully'
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user statistics and analytics
// @route   GET /api/admin/users/stats
// @access  Private (Admin)
const getUserStatistics = async (req, res, next) => {
    try {
        const stats = {
            totalUsers: await User.countDocuments(),
            activeUsers: await User.countDocuments({ isActive: true }),
            inactiveUsers: await User.countDocuments({ isActive: false }),
            verifiedUsers: await User.countDocuments({ isEmailVerified: true }),
            unverifiedUsers: await User.countDocuments({ isEmailVerified: false }),
            lockedUsers: await User.countDocuments({ accountLockUntil: { $gt: new Date() } }),
            byRole: {},
            recentSignups: []
        };

        // Get user count by role
        const roles = ['customer', 'supplier', 'admin', 'superadmin'];
        for (const role of roles) {
            stats.byRole[role] = await User.countDocuments({ role });
        }

        // Get recent signups (last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const recentUsers = await User.find({
            createdAt: { $gte: sevenDaysAgo }
        }).select('firstName lastName email role createdAt isActive')
         .sort({ createdAt: -1 })
         .limit(10);

        stats.recentSignups = recentUsers;

        res.status(200).json({
            success: true,
            data: stats
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Export user data (Admin only)
// @route   GET /api/admin/users/export
// @access  Private (Admin)
const exportUserData = async (req, res, next) => {
    try {
        const { format = 'json', fields = 'basic' } = req.query;

        let selectFields = 'firstName lastName email role isActive createdAt';

        if (fields === 'extended') {
            selectFields += ' phone businessName isEmailVerified lastLogin';
        }

        const users = await User.find()
            .select(selectFields)
            .sort({ createdAt: -1 });

        if (format === 'json') {
            res.status(200).json({
                success: true,
                data: users,
                count: users.length
            });
        } else if (format === 'csv') {
            // In a real implementation, this would convert to CSV
            res.status(200).json({
                success: true,
                message: 'CSV export would be implemented here',
                data: users
            });
        } else {
            res.status(400).json({
                success: false,
                message: 'Invalid export format. Use "json" or "csv"',
                code: 'INVALID_EXPORT_FORMAT'
            });
        }
    } catch (error) {
        next(error);
    }
};

// @desc    Search users with advanced filtering
// @route   GET /api/admin/users/search
// @access  Private (Admin)
const searchUsers = async (req, res, next) => {
    try {
        const {
            query,
            role,
            status,
            emailVerified,
            dateFrom,
            dateTo,
            sortBy = 'createdAt',
            sortOrder = 'desc',
            page = 1,
            limit = 20
        } = req.query;

        const filter = {};
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const sort = {};
        sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

        // Build filter based on query parameters
        if (query) {
            filter.$or = [
                { firstName: { $regex: query, $options: 'i' } },
                { lastName: { $regex: query, $options: 'i' } },
                { email: { $regex: query, $options: 'i' } },
                { phone: { $regex: query, $options: 'i' } },
                { businessName: { $regex: query, $options: 'i' } }
            ];
        }

        if (role) {
            filter.role = role;
        }

        if (status) {
            filter.isActive = status === 'active';
        }

        if (emailVerified) {
            filter.isEmailVerified = emailVerified === 'true';
        }

        if (dateFrom || dateTo) {
            filter.createdAt = {};
            if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
            if (dateTo) filter.createdAt.$lte = new Date(dateTo);
        }

        const users = await User.find(filter)
            .select('-password -refreshToken -emailVerificationToken -passwordResetToken -twoFactorAuthSecret -twoFactorAuthBackupCodes')
            .sort(sort)
            .skip(skip)
            .limit(parseInt(limit));

        const total = await User.countDocuments(filter);

        res.status(200).json({
            success: true,
            data: users,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / parseInt(limit)),
                limit: parseInt(limit)
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get user permissions and roles
// @route   GET /api/admin/users/:id/permissions
// @access  Private (Admin)
const getUserPermissions = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id)
            .select('role permissions');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Get all available permissions
        const { DEFAULT_ROLE_PERMISSIONS } = require('../middleware/rbacMiddleware');

        res.status(200).json({
            success: true,
            data: {
                userId: user._id,
                role: user.role,
                currentPermissions: user.permissions,
                availablePermissions: Object.values(DEFAULT_ROLE_PERMISSIONS).flat(),
                defaultPermissions: DEFAULT_ROLE_PERMISSIONS[user.role] || [],
                roleHierarchy: RolePermissionManager.ROLE_HIERARCHY
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user permissions (Admin only)
// @route   PUT /api/admin/users/:id/permissions
// @access  Private (Admin)
const updateUserPermissions = async (req, res, next) => {
    try {
        const { permissions } = req.body;

        if (!permissions || !Array.isArray(permissions)) {
            return res.status(400).json({
                success: false,
                message: 'Permissions array is required',
                code: 'MISSING_PERMISSIONS'
            });
        }

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Validate permissions
        const { DEFAULT_ROLE_PERMISSIONS } = require('../middleware/rbacMiddleware');
        const allAvailablePermissions = Object.values(DEFAULT_ROLE_PERMISSIONS).flat();
        const invalidPermissions = permissions.filter(perm => !allAvailablePermissions.includes(perm) && perm !== 'all_permissions');

        if (invalidPermissions.length > 0) {
            return res.status(400).json({
                success: false,
                message: `Invalid permissions: ${invalidPermissions.join(', ')}`,
                code: 'INVALID_PERMISSIONS'
            });
        }

        user.permissions = permissions;
        await user.save();

        res.status(200).json({
            success: true,
            message: 'User permissions updated successfully',
            data: {
                userId: user._id,
                updatedPermissions: user.permissions
            }
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getAllUsers,
    getUserById,
    createUser,
    updateUser,
    updateUserPassword,
    deleteUser,
    bulkUpdateUsers,
    getUserActivity,
    unlockUserAccount,
    getUserStatistics,
    exportUserData,
    searchUsers,
    getUserPermissions,
    updateUserPermissions
};