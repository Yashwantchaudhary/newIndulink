const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

/**
 * Enhanced Security Middleware
 * Provides comprehensive security features for authentication and authorization
 */

// Enhanced rate limiting for authentication routes
const authRateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Limit each IP to 5 login attempts per windowMs
    message: {
        success: false,
        message: 'Too many login attempts from this IP, please try again after 15 minutes',
        code: 'RATE_LIMIT_EXCEEDED'
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        // Use IP address for rate limiting
        return req.ip;
    },
    handler: (req, res, next, options) => {
        // Enhanced rate limit response with security headers
        res.setHeader('X-RateLimit-Limit', options.max);
        res.setHeader('X-RateLimit-Remaining', 0);
        res.setHeader('X-RateLimit-Reset', Math.ceil(options.windowMs / 1000));
        res.status(options.statusCode).json(options.message);
    }
});

// Registration rate limiting
const registerRateLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3, // Limit each IP to 3 registration attempts per hour
    message: {
        success: false,
        message: 'Too many registration attempts from this IP, please try again after 1 hour',
        code: 'REGISTRATION_RATE_LIMIT_EXCEEDED'
    }
});

// Password reset rate limiting
const passwordResetRateLimiter = rateLimit({
    windowMs: 30 * 60 * 1000, // 30 minutes
    max: 2, // Limit each IP to 2 password reset attempts per 30 minutes
    message: {
        success: false,
        message: 'Too many password reset attempts from this IP, please try again after 30 minutes',
        code: 'PASSWORD_RESET_RATE_LIMIT_EXCEEDED'
    }
});

// Enhanced password validation
const passwordValidationRules = [
    body('password')
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
        .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
        .matches(/[a-z]/).withMessage('Password must contain at least one lowercase letter')
        .matches(/[0-9]/).withMessage('Password must contain at least one number')
        .matches(/[!@#$%^&*(),.?":{}|<>]/).withMessage('Password must contain at least one special character')
        .not().isIn(['password', '12345678', 'qwerty', 'admin123']).withMessage('Password is too common')
];

// Email validation with enhanced security
const emailValidationRules = [
    body('email')
        .isEmail().withMessage('Please provide a valid email address')
        .normalizeEmail() // Normalize email to prevent duplicate accounts
        .trim()
];

// Enhanced security headers
const securityHeaders = helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
            imgSrc: ["'self'", "data:", "https:", "blob:"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            connectSrc: ["'self'", "http://localhost:*", "https://api.example.com"],
            frameSrc: ["'self'", "https://www.google.com"],
            objectSrc: ["'none'"],
            upgradeInsecureRequests: []
        }
    },
    crossOriginResourcePolicy: { policy: "same-site" },
    crossOriginOpenerPolicy: { policy: "same-origin-allow-popups" },
    crossOriginEmbedderPolicy: { policy: "require-corp" },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    referrerPolicy: { policy: "strict-origin-when-cross-origin" },
    permissionsPolicy: {
        geolocation: ["'self'"],
        microphone: ["'none'"],
        camera: ["'none'"],
        payment: ["'self'"]
    }
});

// Enhanced CORS with security headers
const securityCors = (req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'SAMEORIGIN');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
    res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https: blob:; font-src 'self' https://fonts.gstatic.com; connect-src 'self' http://localhost:* https://api.example.com; frame-src 'self' https://www.google.com; object-src 'none'; upgrade-insecure-requests");
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('Feature-Policy', "geolocation 'self'; microphone 'none'; camera 'none'; payment 'self'");
    next();
};

// Enhanced JWT validation with additional security checks
const enhancedJwtValidation = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required',
            code: 'MISSING_AUTH_HEADER'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        // Verify JWT with enhanced validation
        const decoded = jwt.verify(token, process.env.JWT_SECRET, {
            algorithms: ['HS256'], // Explicitly specify algorithm
            maxAge: process.env.JWT_EXPIRE || '24h',
            clockTolerance: 15 // Allow 15 seconds clock skew
        });

        // Additional security checks
        if (!decoded.id || !decoded.email || !decoded.role) {
            return res.status(401).json({
                success: false,
                message: 'Invalid token structure',
                code: 'INVALID_TOKEN_STRUCTURE'
            });
        }

        // Check if token is expired
        if (decoded.exp && decoded.exp < Date.now() / 1000) {
            return res.status(401).json({
                success: false,
                message: 'Token expired',
                code: 'TOKEN_EXPIRED'
            });
        }

        req.user = decoded;
        next();
    } catch (error) {
        console.error('JWT Validation Error:', error);

        let statusCode = 401;
        let message = 'Invalid authentication token';
        let code = 'INVALID_TOKEN';

        if (error.name === 'TokenExpiredError') {
            message = 'Token expired';
            code = 'TOKEN_EXPIRED';
        } else if (error.name === 'JsonWebTokenError') {
            message = 'Invalid token format';
            code = 'INVALID_TOKEN_FORMAT';
        } else if (error.name === 'NotBeforeError') {
            message = 'Token not yet valid';
            code = 'TOKEN_NOT_YET_VALID';
        }

        res.status(statusCode).json({
            success: false,
            message,
            code
        });
    }
};

// Enhanced refresh token validation
const enhancedRefreshTokenValidation = (req, res, next) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(400).json({
            success: false,
            message: 'Refresh token is required',
            code: 'MISSING_REFRESH_TOKEN'
        });
    }

    try {
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, {
            algorithms: ['HS256'],
            maxAge: process.env.JWT_REFRESH_EXPIRE || '7d',
            clockTolerance: 30 // Allow 30 seconds clock skew for refresh tokens
        });

        if (!decoded.id) {
            return res.status(401).json({
                success: false,
                message: 'Invalid refresh token structure',
                code: 'INVALID_REFRESH_TOKEN_STRUCTURE'
            });
        }

        req.refreshTokenData = decoded;
        next();
    } catch (error) {
        console.error('Refresh Token Validation Error:', error);

        let statusCode = 401;
        let message = 'Invalid refresh token';
        let code = 'INVALID_REFRESH_TOKEN';

        if (error.name === 'TokenExpiredError') {
            message = 'Refresh token expired';
            code = 'REFRESH_TOKEN_EXPIRED';
        } else if (error.name === 'JsonWebTokenError') {
            message = 'Invalid refresh token format';
            code = 'INVALID_REFRESH_TOKEN_FORMAT';
        }

        res.status(statusCode).json({
            success: false,
            message,
            code
        });
    }
};

// Enhanced password strength checker
const checkPasswordStrength = (password) => {
    let strength = 0;

    // Length check
    if (password.length >= 12) strength += 2;
    else if (password.length >= 8) strength += 1;

    // Character variety checks
    if (/[A-Z]/.test(password)) strength += 1;
    if (/[a-z]/.test(password)) strength += 1;
    if (/[0-9]/.test(password)) strength += 1;
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) strength += 1;

    // Common password check
    const commonPasswords = ['password', '12345678', 'qwerty', 'admin123', 'welcome', 'letmein'];
    if (commonPasswords.some(pw => password.toLowerCase().includes(pw))) {
        strength = Math.max(0, strength - 2);
    }

    return {
        strength,
        rating: strength >= 4 ? 'strong' : strength >= 2 ? 'medium' : 'weak',
        suggestions: getPasswordSuggestions(password, strength)
    };
};

// Password strength suggestions
const getPasswordSuggestions = (password, strength) => {
    const suggestions = [];

    if (password.length < 12) {
        suggestions.push('Use at least 12 characters');
    }

    if (!/[A-Z]/.test(password)) {
        suggestions.push('Add uppercase letters');
    }

    if (!/[a-z]/.test(password)) {
        suggestions.push('Add lowercase letters');
    }

    if (!/[0-9]/.test(password)) {
        suggestions.push('Add numbers');
    }

    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
        suggestions.push('Add special characters');
    }

    if (strength < 2) {
        suggestions.push('Avoid common words and patterns');
    }

    return suggestions;
};

// Enhanced security middleware for sensitive routes
const sensitiveRouteSecurity = (req, res, next) => {
    // Check for suspicious activity patterns
    const userAgent = req.headers['user-agent'] || '';
    const ip = req.ip;

    // Basic bot detection
    if (userAgent.includes('bot') || userAgent.includes('crawler') || userAgent.includes('spider')) {
        console.warn(`Potential bot activity detected from IP: ${ip}, User-Agent: ${userAgent}`);
        // Could add additional bot mitigation here
    }

    // Check for suspicious headers
    if (req.headers['x-forwarded-for'] && req.headers['x-forwarded-for'].split(',').length > 3) {
        console.warn(`Potential proxy/VPN usage detected from IP: ${ip}`);
    }

    next();
};

// Enhanced session security
const sessionSecurity = (req, res, next) => {
    // Set secure session headers
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');

    // Set security-related headers
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '0');

    next();
};

// Enhanced CSRF protection (simplified for API)
const csrfProtection = (req, res, next) => {
    // For API, we use JWT tokens which provide some CSRF protection
    // Additional protection can be added with custom headers
    const expectedCsrfToken = req.headers['x-csrf-token'] || req.headers['csrf-token'];
    const userCsrfToken = req.headers['x-user-csrf-token'];

    // For critical operations, require CSRF token
    if (req.method === 'POST' || req.method === 'PUT' || req.method === 'DELETE') {
        if (!expectedCsrfToken) {
            return res.status(403).json({
                success: false,
                message: 'CSRF token required',
                code: 'MISSING_CSRF_TOKEN'
            });
        }

        // In a real implementation, you would validate the token here
        // For this example, we'll just check that it exists
    }

    next();
};

// Enhanced security for file uploads
const fileUploadSecurity = (req, res, next) => {
    if (!req.file) {
        return next();
    }

    // Check file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(req.file.mimetype)) {
        return res.status(400).json({
            success: false,
            message: 'Invalid file type. Only JPG, PNG, GIF, and WebP images are allowed',
            code: 'INVALID_FILE_TYPE'
        });
    }

    // Check file size (10MB limit)
    if (req.file.size > 10 * 1024 * 1024) {
        return res.status(400).json({
            success: false,
            message: 'File size exceeds 10MB limit',
            code: 'FILE_TOO_LARGE'
        });
    }

    next();
};

// Enhanced security for admin routes
const adminRouteSecurity = (req, res, next) => {
    // Additional security checks for admin routes
    const ip = req.ip;
    const userAgent = req.headers['user-agent'] || '';

    // Log admin access attempts
    console.log(`Admin access attempt from IP: ${ip}, User-Agent: ${userAgent}`);

    // Check if request is coming from expected sources
    // In production, you might have IP whitelisting here

    next();
};

// Enhanced security for sensitive data access
const sensitiveDataSecurity = (req, res, next) => {
    // Additional security for routes that access sensitive user data
    res.setHeader('X-Sensitive-Data', 'true');
    res.setHeader('X-Content-Security-Policy', "default-src 'none'; frame-src 'none'; object-src 'none'");

    next();
};

module.exports = {
    authRateLimiter,
    registerRateLimiter,
    passwordResetRateLimiter,
    passwordValidationRules,
    emailValidationRules,
    securityHeaders,
    securityCors,
    enhancedJwtValidation,
    enhancedRefreshTokenValidation,
    checkPasswordStrength,
    sensitiveRouteSecurity,
    sessionSecurity,
    csrfProtection,
    fileUploadSecurity,
    adminRouteSecurity,
    sensitiveDataSecurity
};