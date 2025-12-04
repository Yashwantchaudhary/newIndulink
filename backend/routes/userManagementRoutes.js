const express = require('express');
const router = express.Router();
const {
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
} = require('../controllers/userManagementController');
const { protect } = require('../middleware/authMiddleware');
const { rbacMiddleware } = require('../middleware/rbacMiddleware');
const { adminRouteSecurity } = require('../middleware/securityMiddleware');

// Admin-only routes with enhanced security
router.use(adminRouteSecurity);

// User management routes with RBAC
router.get('/',
    protect,
    rbacMiddleware([], ['admin', 'superadmin']),
    getAllUsers
);

router.get('/:id',
    protect,
    rbacMiddleware([], ['admin', 'superadmin']),
    getUserById
);

router.post('/',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    createUser
);

router.put('/:id',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    updateUser
);

router.put('/:id/password',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    updateUserPassword
);

router.delete('/:id',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    deleteUser
);

router.put('/bulk-update',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    bulkUpdateUsers
);

router.get('/:id/activity',
    protect,
    rbacMiddleware([], ['admin', 'superadmin']),
    getUserActivity
);

router.post('/:id/unlock',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    unlockUserAccount
);

router.get('/stats',
    protect,
    rbacMiddleware(['view_analytics'], ['admin', 'superadmin']),
    getUserStatistics
);

router.get('/export',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    exportUserData
);

router.get('/search',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    searchUsers
);

router.get('/:id/permissions',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    getUserPermissions
);

router.put('/:id/permissions',
    protect,
    rbacMiddleware(['manage_users'], ['admin', 'superadmin']),
    updateUserPermissions
);

module.exports = router;