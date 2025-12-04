// middleware/auth.js
'use strict';

const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Extract JWT from request:
 * - Authorization: Bearer <token>
 * - Cookie: token=<jwt>
 * - X-Access-Token header
 * - Query param: ?token=<jwt>
 */
const extractToken = (req) => {
  // Authorization header (case-insensitive)
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && typeof authHeader === 'string') {
    const parts = authHeader.split(' ');
    if (parts.length === 2 && /^Bearer$/i.test(parts[0])) {
      return parts[1].trim();
    }
  }

  // Cookie (requires cookie-parser middleware)
  if (req.cookies && req.cookies.token) {
    return req.cookies.token;
  }

  // X-Access-Token header
  if (req.headers['x-access-token']) {
    return String(req.headers['x-access-token']).trim();
  }

  // Query parameter fallback
  if (req.query && req.query.token) {
    return String(req.query.token).trim();
  }

  return null;
};

/**
 * Protect routes - verify JWT token and attach req.user
 *
 * Expectations:
 * - process.env.JWT_SECRET must be set
 * - token payload should include { id } (user id)
 * - optional: tokenVersion in payload and user model for revocation
 */
exports.protect = async (req, res, next) => {
  try {
    if (!process.env.JWT_SECRET) {
      return res.status(500).json({
        success: false,
        message: 'Server configuration error: JWT secret not set'
      });
    }

    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized: missing token'
      });
    }

    let decoded;
    try {
      // Verify token. If you want clock skew tolerance, pass options like { clockTolerance: 5 } if supported.
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      // TokenExpiredError and JsonWebTokenError are common
      if (err && err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Token expired' });
      }
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }

    // Ensure payload contains user id
    const userId = decoded && (decoded.id || decoded.userId || decoded.sub);
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Invalid token payload' });
    }

    // Fetch user and exclude sensitive fields
    const user = await User.findById(userId).select('-password -refreshToken');
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    // Check account status
    if (user.isActive === false) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    // Optional: enforce email verification (uncomment if required)
    // if (!user.isEmailVerified) {
    //   return res.status(403).json({ success: false, message: 'Email not verified' });
    // }

    // Optional: token revocation via tokenVersion
    // If your User model stores tokenVersion and you include tokenVersion in JWT payload,
    // uncomment the block below to reject tokens when versions mismatch.
    /*
    if (typeof user.tokenVersion === 'number' && typeof decoded.tokenVersion === 'number') {
      if (decoded.tokenVersion !== user.tokenVersion) {
        return res.status(401).json({ success: false, message: 'Token revoked' });
      }
    }
    */

    // Attach user and decoded token to request for downstream handlers
    req.user = user;
    req.auth = { tokenPayload: decoded };

    return next();
  } catch (error) {
    // Unexpected server error - forward to error handler
    // Log minimal info to avoid leaking sensitive data
    console.error('Auth protect error:', error && error.message ? error.message : error);
    return next(error);
  }
};

/**
 * Role-based authorization guard
 * Usage: authorize('admin'), authorize('supplier', 'admin')
 */
exports.authorize = (...allowedRoles) => {
  return (req, res, next) => {
    // If protect wasn't run, deny access
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated'
      });
    }

    const userRole = req.user.role || 'unknown';
    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        message: `Role '${userRole}' is not authorized to access this route`
      });
    }

    return next();
  };
};

/**
 * Convenience role middlewares
 * - requireCustomer: customer, admin, superadmin
 * - requireSupplier: supplier, admin, superadmin
 * - requireAdmin: admin, superadmin
 * - requireSuperadmin: superadmin
 */
exports.requireCustomer = exports.authorize('customer', 'admin', 'superadmin');
exports.requireSupplier = exports.authorize('supplier', 'admin', 'superadmin');
exports.requireAdmin = exports.authorize('admin', 'superadmin');
exports.requireSuperadmin = exports.authorize('superadmin');

/**
 * Optional helper to create JWT for a user (useful in tests or auth flows)
 * Not exported by default; uncomment to export if needed.
 */
/*
exports.signToken = (payload, options = {}) => {
  if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET not set');
  // default expiry can be set via options.expiresIn
  return jwt.sign(payload, process.env.JWT_SECRET, options);
};
*/

