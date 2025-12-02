/**
 * Role-based access control middleware
 * Provides role authorization for protected routes
 */

/**
 * Middleware to require specific roles for route access
 * @param {string[]} allowedRoles - Array of allowed role names
 * @returns {Function} Express middleware function
 */
const requireRole = (allowedRoles) => {
    return (req, res, next) => {
        try {
            // Check if user is authenticated
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    message: 'Authentication required'
                });
            }

            // Check if user has required role
            if (!allowedRoles.includes(req.user.role)) {
                return res.status(403).json({
                    success: false,
                    message: 'Insufficient permissions',
                    requiredRoles: allowedRoles,
                    userRole: req.user.role
                });
            }

            // User has required role, proceed
            next();
        } catch (error) {
            console.error('Role middleware error:', error);
            res.status(500).json({
                success: false,
                message: 'Authorization check failed'
            });
        }
    };
};

/**
 * Middleware to require customer role
 */
const requireCustomer = (req, res, next) => {
    return requireRole(['customer'])(req, res, next);
};

/**
 * Middleware to require supplier role
 */
const requireSupplier = (req, res, next) => {
    return requireRole(['supplier'])(req, res, next);
};

/**
 * Middleware to require admin role
 */
const requireAdmin = (req, res, next) => {
    return requireRole(['admin'])(req, res, next);
};

/**
 * Middleware to allow multiple roles (customer or supplier)
 */
const requireCustomerOrSupplier = (req, res, next) => {
    return requireRole(['customer', 'supplier'])(req, res, next);
};

/**
 * Middleware to allow business roles (supplier or admin)
 */
const requireBusinessRole = (req, res, next) => {
    return requireRole(['supplier', 'admin'])(req, res, next);
};

module.exports = {
    requireRole,
    requireCustomer,
    requireSupplier,
    requireAdmin,
    requireCustomerOrSupplier,
    requireBusinessRole
};