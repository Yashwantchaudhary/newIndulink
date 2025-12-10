const User = require('../models/User');
const { validationResult } = require('express-validator');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { checkPasswordStrength } = require('../middleware/securityMiddleware');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            console.error('Registration validation errors:', errors.array());
            return res.status(400).json({
                success: false,
                errors: errors.array(),
            });
        }

        const { firstName, lastName, email, password, phone, role, businessName, businessDescription } = req.body;

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
            });
        }

        // Create user
        const userData = {
            firstName,
            lastName,
            email,
            password,
            phone,
            role: role || 'customer',
        };

        // Add supplier-specific fields
        if (role === 'supplier') {
            userData.businessName = businessName;
            userData.businessDescription = businessDescription;
        }

        // Create user with enhanced security
        const user = await User.create(userData);

        // Generate email verification token
        const emailVerificationToken = user.generateEmailVerificationToken();
        await user.save();

        // Generate tokens
        const accessToken = user.generateAccessToken();
        const refreshToken = user.generateRefreshToken();

        // Save refresh token
        user.refreshToken = refreshToken;
        await user.save();

        // Remove sensitive data
        user.password = undefined;
        user.refreshToken = undefined;

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: {
                user,
                accessToken,
                refreshToken,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide email and password',
                code: 'MISSING_CREDENTIALS'
            });
        }

        // Check if user exists
        const user = await User.findOne({ email }).select('+password +loginAttempts +accountLockUntil');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials',
                code: 'INVALID_CREDENTIALS'
            });
        }

        // Check if account is locked
        if (user.isAccountLocked()) {
            return res.status(403).json({
                success: false,
                message: 'Account is temporarily locked due to too many failed login attempts',
                lockedUntil: user.accountLockUntil,
                code: 'ACCOUNT_LOCKED'
            });
        }

        // Check if user is active
        if (!user.isActive) {
            return res.status(401).json({
                success: false,
                message: 'Account is deactivated',
                code: 'ACCOUNT_DEACTIVATED'
            });
        }

        // Check if password matches
        const isPasswordMatch = await user.comparePassword(password);

        if (!isPasswordMatch) {
            // Increment login attempts
            user.loginAttempts += 1;

            // Lock account after 5 failed attempts
            if (user.loginAttempts >= 5) {
                user.accountLockUntil = Date.now() + 30 * 60 * 1000; // 30 minutes lock
                await user.save();

                return res.status(403).json({
                    success: false,
                    message: 'Account is temporarily locked due to too many failed login attempts',
                    lockedUntil: user.accountLockUntil,
                    code: 'ACCOUNT_LOCKED'
                });
            }

            await user.save();

            return res.status(401).json({
                success: false,
                message: 'Invalid credentials',
                attemptsRemaining: 5 - user.loginAttempts,
                code: 'INVALID_CREDENTIALS'
            });
        }

        // Reset login attempts on successful login
        user.loginAttempts = 0;
        user.accountLockUntil = null;
        user.lastLogin = Date.now();
        await user.save();

        // Generate tokens
        const accessToken = user.generateAccessToken();
        const refreshToken = user.generateRefreshToken();

        // Save refresh token
        user.refreshToken = refreshToken;
        await user.save();

        // Remove sensitive data
        user.password = undefined;
        user.refreshToken = undefined;

        res.status(200).json({
            success: true,
            message: 'Login successful',
            data: {
                user,
                accessToken,
                refreshToken,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Refresh access token
// @route   POST /api/auth/refresh
// @access  Public
exports.refreshToken = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token is required',
                code: 'MISSING_REFRESH_TOKEN'
            });
        }

        // Enhanced refresh token validation
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, {
            algorithms: ['HS256'],
            maxAge: process.env.JWT_REFRESH_EXPIRE || '7d',
            clockTolerance: 30
        });

        // Check if refresh token is valid
        if (!decoded.id || !decoded.jti) {
            return res.status(401).json({
                success: false,
                message: 'Invalid refresh token structure',
                code: 'INVALID_REFRESH_TOKEN_STRUCTURE'
            });
        }

        // Find user with this refresh token
        const user = await User.findById(decoded.id).select('+refreshToken');

        if (!user || user.refreshToken !== refreshToken) {
            return res.status(401).json({
                success: false,
                message: 'Invalid refresh token',
                code: 'INVALID_REFRESH_TOKEN'
            });
        }

        // Check if user account is active
        if (!user.isActive) {
            return res.status(401).json({
                success: false,
                message: 'Account is deactivated',
                code: 'ACCOUNT_DEACTIVATED'
            });
        }

        // Check if account is locked
        if (user.isAccountLocked()) {
            return res.status(403).json({
                success: false,
                message: 'Account is temporarily locked',
                lockedUntil: user.accountLockUntil,
                code: 'ACCOUNT_LOCKED'
            });
        }

        // Generate new access token
        const newAccessToken = user.generateAccessToken();

        res.status(200).json({
            success: true,
            data: {
                accessToken: newAccessToken,
            },
        });
    } catch (error) {
        console.error('Refresh token error:', error);
        let statusCode = 401;
        let message = 'Invalid or expired refresh token';
        let code = 'INVALID_REFRESH_TOKEN';

        if (error.name === 'TokenExpiredError') {
            message = 'Refresh token expired';
            code = 'REFRESH_TOKEN_EXPIRED';
        } else if (error.name === 'JsonWebTokenError') {
            message = 'Invalid refresh token format';
            code = 'INVALID_REFRESH_TOKEN_FORMAT';
        }

        return res.status(statusCode).json({
            success: false,
            message,
            code
        });
    }
};

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Private
exports.logout = async (req, res, next) => {
    try {
        // Clear refresh token
        req.user.refreshToken = null;
        await req.user.save();

        res.status(200).json({
            success: true,
            message: 'Logout successful',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);

        res.status(200).json({
            success: true,
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update password
// @route   PUT /api/auth/update-password
// @access  Private
exports.updatePassword = async (req, res, next) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Please provide current and new password',
                code: 'MISSING_PASSWORD_FIELDS'
            });
        }

        // Validate new password strength
        const passwordCheck = checkPasswordStrength(newPassword);
        if (passwordCheck.rating === 'weak') {
            return res.status(400).json({
                success: false,
                message: 'New password is too weak',
                suggestions: passwordCheck.suggestions,
                code: 'WEAK_NEW_PASSWORD'
            });
        }

        // Get user with password
        const user = await User.findById(req.user.id).select('+password');

        // Check current password
        const isMatch = await user.comparePassword(currentPassword);

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect',
            });
        }

        // Update password
        user.password = newPassword;
        await user.save();

        // Send real-time notification to user about password change
        try {
            const { createAndSendNotification } = require('../services/notificationService');
            await createAndSendNotification({
                userId: user._id.toString(),
                type: 'security',
                title: 'Password Changed',
                message: 'Your password was successfully updated. If this was not you, please contact support immediately.',
                data: {
                    securityAlert: true,
                    actionRequired: true,
                    timestamp: new Date().toISOString()
                },
            });
        } catch (notificationError) {
            console.error('Error sending password change notification:', notificationError);
            // Don't fail the password change if notification fails
        }

        // Send real-time WebSocket update if available
        try {
            if (req.app.get('webSocketService')) {
                const webSocketService = req.app.get('webSocketService');
                webSocketService.notifyUserDataChange(
                    user._id.toString(),
                    'user',
                    'password_updated',
                    {
                        message: 'Password updated successfully',
                        timestamp: new Date().toISOString(),
                        securityEvent: true
                    }
                );
            }
        } catch (websocketError) {
            console.error('Error sending WebSocket password update:', websocketError);
            // Don't fail the password change if WebSocket fails
        }

        res.status(200).json({
            success: true,
            message: 'Password updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Forgot password - Send reset email
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email, oldPassword, newPassword } = req.body;

        if (!email || !oldPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Please provide email, current password, and new password',
            });
        }

        // Check if user exists
        const user = await User.findOne({ email }).select('+password');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'No account found with this email address',
            });
        }

        // Verify old password matches
        const isPasswordCorrect = await user.comparePassword(oldPassword);

        if (!isPasswordCorrect) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect',
            });
        }

        // Update to new password
        user.password = newPassword;
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Password reset successfully',
        });
    } catch (error) {
        next(error);
    }
};


// @desc    Reset password with token
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res, next) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Please provide reset token and new password',
            });
        }

        // Find user with valid reset token
        const user = await User.findOne({
            passwordResetToken: token,
            passwordResetExpiry: { $gt: Date.now() },
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Invalid or expired reset token',
            });
        }

        // Update password with enhanced security
        user.password = newPassword;
        user.passwordResetToken = undefined;
        user.passwordResetExpiry = undefined;
        user.loginAttempts = 0; // Reset login attempts
        user.accountLockUntil = null; // Unlock account
        await user.save();

        // Send real-time notification about password reset
        try {
            const { createAndSendNotification } = require('../services/notificationService');
            await createAndSendNotification({
                userId: user._id.toString(),
                type: 'security',
                title: 'Password Reset Successful',
                message: 'Your password has been reset successfully. Your account is now secure.',
                data: {
                    securityEvent: true,
                    passwordReset: true,
                    timestamp: new Date().toISOString()
                },
            });
        } catch (notificationError) {
            console.error('Error sending password reset notification:', notificationError);
            // Don't fail the password reset if notification fails
        }

        // Send real-time WebSocket update if available
        try {
            if (req.app.get('webSocketService')) {
                const webSocketService = req.app.get('webSocketService');
                webSocketService.notifyUserDataChange(
                    user._id.toString(),
                    'user',
                    'password_reset',
                    {
                        message: 'Password reset successfully',
                        timestamp: new Date().toISOString(),
                        securityEvent: true
                    }
                );
            }
        } catch (websocketError) {
            console.error('Error sending WebSocket password reset update:', websocketError);
            // Don't fail the password reset if WebSocket fails
        }

        res.status(200).json({
            success: true,
            message: 'Password reset successfully',
        });
    } catch (error) {
        next(error);
    }
};
// @desc    Verify email
// @route   POST /api/auth/verify-email
// @access  Public
exports.verifyEmail = async (req, res, next) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'Verification token is required',
            });
        }

        const crypto = require('crypto');
        const hashedToken = crypto
            .createHash('sha256')
            .update(token)
            .digest('hex');

        const user = await User.findOne({
            emailVerificationToken: hashedToken,
            emailVerificationExpire: { $gt: Date.now() },
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: 'Invalid or expired verification token',
            });
        }

        user.isEmailVerified = true;
        user.emailVerificationToken = undefined;
        user.emailVerificationExpire = undefined;
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Email verified successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete account
// @route   POST /api/auth/delete-account
// @access  Private
exports.deleteAccount = async (req, res, next) => {
    try {
        const { password } = req.body;

        if (!password) {
            return res.status(400).json({
                success: false,
                message: 'Password is required to delete account',
            });
        }

        const user = await User.findById(req.user.id).select('+password');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Verify password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Incorrect password',
            });
        }

        await user.deleteOne();

        res.status(200).json({
            success: true,
            message: 'Account deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Google Sign-In
// @route   POST /api/auth/google
// @access  Public
exports.googleLogin = async (req, res, next) => {
    try {
        console.log('Google Login Request Body:', req.body);
        const { idToken, accessToken: googleAccessToken, email, displayName, photoUrl, role } = req.body;

        if (!idToken && !googleAccessToken) {
            return res.status(400).json({
                success: false,
                message: 'Google ID token or Access token is required',
            });
        }

        console.log('🔐 Google Sign-In attempt for:', email);
        console.log('👤 Requested Role:', role);

        let verifiedEmail = email;

        // Verify token
        if (idToken) {
            // TODO: Implement proper ID token verification using google-auth-library
            // For now, we are trusting the email if idToken is present (should be verified in production)
            // const ticket = await client.verifyIdToken({ idToken, audience: CLIENT_ID });
            // const payload = ticket.getPayload();
            // verifiedEmail = payload.email;
        } else if (googleAccessToken) {
            // Verify access token by fetching user info using native https
            try {
                const https = require('https');

                await new Promise((resolve, reject) => {
                    const options = {
                        hostname: 'www.googleapis.com',
                        path: '/oauth2/v3/userinfo',
                        method: 'GET',
                        headers: {
                            'Authorization': `Bearer ${googleAccessToken}`
                        }
                    };

                    const req = https.request(options, (res) => {
                        let data = '';
                        res.on('data', (chunk) => { data += chunk; });
                        res.on('end', () => {
                            if (res.statusCode === 200) {
                                const responseData = JSON.parse(data);
                                if (responseData.email !== email) {
                                    reject(new Error('Email mismatch'));
                                } else {
                                    verifiedEmail = responseData.email;
                                    console.log('✅ Access Token verified via Google API');
                                    resolve();
                                }
                            } else {
                                reject(new Error('Invalid token'));
                            }
                        });
                    });

                    req.on('error', (e) => {
                        reject(e);
                    });

                    req.end();
                });
            } catch (err) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid access token or email mismatch',
                });
            }
        }

        // Check if user exists
        const User = require('../models/User'); // Ensure User model is available
        let user = await User.findOne({ email });

        if (!user) {
            // Create new user from Google account
            console.log('✨ Creating new user from Google account with role:', role);

            const nameParts = displayName ? displayName.split(' ') : ['User', ''];
            const crypto = require('crypto');
            user = await User.create({
                firstName: nameParts[0] || 'User',
                lastName: nameParts.slice(1).join(' ') || '',
                email: email,
                password: crypto.randomBytes(16).toString('hex'), // Generate random password
                role: role || 'customer', // Use requested role or default to customer
                isEmailVerified: true, // Google accounts are pre-verified
                profileImage: photoUrl || undefined,
                authProvider: 'google',
            });

            console.log('✅ New user created via Google:', user._id);
        } else {
            console.log('✅ Existing user found:', user._id, 'Role:', user.role);

            // Validate Role
            if (role && user.role !== role) {
                console.log(`❌ Role mismatch! Existing: ${user.role}, Requested: ${role}`);
                return res.status(403).json({
                    success: false,
                    message: `This email is registered as a ${user.role}. Please sign in from the ${user.role} login page.`
                });
            }

            // Update profile image if changed
            if (photoUrl && user.profileImage !== photoUrl) {
                user.profileImage = photoUrl;
                user.isEmailVerified = true;
                await user.save();
            }
        }

        // Reset login attempts
        user.loginAttempts = 0;
        user.accountLockUntil = undefined;
        user.lastLogin = new Date();
        await user.save();

        // Generate tokens
        const accessToken = user.generateAccessToken(); // Use correct method name from User model
        const refreshToken = user.generateRefreshToken();

        // Save refresh token
        user.refreshToken = refreshToken; // Use correct field name from User model (refreshToken vs refreshTokens)
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Google sign-in successful',
            data: {
                user: user.toJSON(), // Returns complete user object with all fields including timestamps
                token: accessToken,
                accessToken,
                refreshToken,
            },
        });
    } catch (error) {
        console.error('❌ Google login error:', error);
        next(error);
    }
};
