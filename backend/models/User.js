const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const validator = require('validator');

const addressSchema = new mongoose.Schema({
    label: {
        type: String,
        enum: ['home', 'work', 'other'],
        default: 'home',
    },
    fullName: {
        type: String,
        required: true,
    },
    phone: {
        type: String,
        required: true,
    },
    addressLine1: {
        type: String,
        required: true,
    },
    addressLine2: String,
    city: {
        type: String,
        required: true,
    },
    state: {
        type: String,
        required: true,
    },
    postalCode: {
        type: String,
        required: true,
    },
    country: {
        type: String,
        required: true,
        default: 'Nepal',
    },
    isDefault: {
        type: Boolean,
        default: false,
    },
});

const userSchema = new mongoose.Schema(
    {
        firstName: {
            type: String,
            required: [true, 'First name is required'],
            trim: true,
        },
        lastName: {
            type: String,
            required: [true, 'Last name is required'],
            trim: true,
        },
        email: {
            type: String,
            required: [true, 'Email is required'],
            unique: true,
            lowercase: true,
            trim: true,
            match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email address'],
        },
        password: {
            type: String,
            required: [true, 'Password is required'],
            minlength: [6, 'Password must be at least 6 characters'],
            select: false, // Don't include password in queries by default
        },
        phone: {
            type: String,
            trim: true,
        },
        role: {
            type: String,
            enum: ['customer', 'supplier', 'admin', 'superadmin'],
            default: 'customer',
            required: true,
        },
        permissions: [{
            type: String,
            enum: [
                'create_products', 'edit_products', 'delete_products',
                'manage_users', 'manage_orders', 'view_analytics',
                'manage_settings', 'manage_content', 'view_reports',
                'manage_payments', 'manage_shipping', 'manage_inventory'
            ]
        }],
        profileImage: {
            type: String,
            default: null,
        },
        // Customer-specific fields
        wishlist: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Product',
            },
        ],
        // Supplier-specific fields
        businessName: {
            type: String,
            trim: true,
        },
        businessDescription: {
            type: String,
        },
        businessAddress: {
            type: String,
        },
        businessLicense: {
            type: String,
        },
        services: [{
            type: String,
            trim: true
        }],
        certifications: [{
            type: String,
            trim: true
        }],
        // Common fields
        addresses: [addressSchema],
        isEmailVerified: {
            type: Boolean,
            default: false,
        },
        isActive: {
            type: Boolean,
            default: true,
        },
        emailVerificationToken: {
            type: String,
            select: false,
        },
        emailVerificationExpiry: {
            type: Date,
            select: false,
        },
        lastLogin: {
            type: Date,
            default: null,
        },
        loginAttempts: {
            type: Number,
            default: 0,
        },
        accountLockUntil: {
            type: Date,
            default: null,
        },
        passwordChangedAt: {
            type: Date,
            default: null,
        },
        passwordResetToken: {
            type: String,
            select: false,
        },
        passwordResetExpiry: {
            type: Date,
            select: false,
        },
        twoFactorAuthEnabled: {
            type: Boolean,
            default: false,
        },
        twoFactorAuthSecret: {
            type: String,
            select: false,
        },
        twoFactorAuthBackupCodes: [{
            code: String,
            used: { type: Boolean, default: false },
            usedAt: { type: Date, default: null }
        }],
        refreshToken: {
            type: String,
            select: false,
        },
        // Password reset fields
        resetPasswordToken: {
            type: String,
            select: false,
        },
        resetPasswordExpiry: {
            type: Date,
            select: false,
        },
        // FCM tokens for push notifications
        fcmTokens: [{
            type: String,
            trim: true,
        }],
        // Notification preferences
        notificationPreferences: {
            orderUpdates: {
                type: Boolean,
                default: true,
            },
            promotions: {
                type: Boolean,
                default: true,
            },
            messages: {
                type: Boolean,
                default: true,
            },
            system: {
                type: Boolean,
                default: true,
            },
            emailNotifications: {
                type: Boolean,
                default: true,
            },
            pushNotifications: {
                type: Boolean,
                default: true,
            },
        },
        // Language preference
        language: {
            type: String,
            enum: ['en', 'ne', 'hi'], // English, Nepali, Hindi
            default: 'en',
        },
    },
    {
        timestamps: true, // Automatically manage createdAt and updatedAt fields
    });

// Hash password before saving
userSchema.pre('save', async function (next) {
    // Only hash the password if it has been modified (or is new)
    if (!this.isModified('password')) return next();

    try {
        // Hash password with enhanced cost of 14 for better security
        const salt = await bcrypt.genSalt(14);
        this.password = await bcrypt.hash(this.password, salt);

        // Update password changed timestamp
        if (!this.isNew) {
            this.passwordChangedAt = Date.now();
        }
        next();
    } catch (error) {
        next(error);
    }
});

// Email validation before saving
userSchema.pre('save', function (next) {
    if (this.isModified('email') && !validator.isEmail(this.email)) {
        const error = new Error('Invalid email format');
        return next(error);
    }
    next();
});

// Generate email verification token
userSchema.methods.generateEmailVerificationToken = function () {
    const verificationToken = crypto.randomBytes(32).toString('hex');
    this.emailVerificationToken = crypto.createHash('sha256').update(verificationToken).digest('hex');
    this.emailVerificationExpiry = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
    return verificationToken;
};

// Check if password was changed after token was issued
userSchema.methods.isPasswordChangedAfterTokenIssued = function (tokenIssuedAt) {
    if (this.passwordChangedAt) {
        const changedTimestamp = parseInt(this.passwordChangedAt.getTime() / 1000, 10);
        return tokenIssuedAt < changedTimestamp;
    }
    return false;
};

// Check if account is locked
userSchema.methods.isAccountLocked = function () {
    if (this.accountLockUntil && this.accountLockUntil > Date.now()) {
        return true;
    }
    return false;
};

// Generate two-factor authentication secret
userSchema.methods.generateTwoFactorAuthSecret = function () {
    return crypto.randomBytes(32).toString('hex');
};

// Generate two-factor authentication backup codes
userSchema.methods.generateTwoFactorBackupCodes = function () {
    const codes = [];
    for (let i = 0; i < 5; i++) {
        codes.push({
            code: crypto.randomBytes(3).toString('hex').toUpperCase(),
            used: false,
            usedAt: null
        });
    }
    return codes;
};

// Validate two-factor authentication code
userSchema.methods.validateTwoFactorCode = function (code) {
    // In a real implementation, this would validate against TOTP
    // For this example, we'll use a simple validation
    return this.twoFactorAuthBackupCodes.some(backupCode =>
        backupCode.code === code && !backupCode.used
    );
};

// Mark backup code as used
userSchema.methods.markBackupCodeAsUsed = function (code) {
    const backupCode = this.twoFactorAuthBackupCodes.find(c => c.code === code);
    if (backupCode) {
        backupCode.used = true;
        backupCode.usedAt = Date.now();
    }
};

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

// Generate JWT access token with enhanced security
userSchema.methods.generateAccessToken = function () {
    return jwt.sign(
        {
            id: this._id,
            email: this.email,
            role: this.role,
            permissions: this.permissions,
            iss: 'indulink-api',
            aud: 'indulink-client',
            iat: Math.floor(Date.now() / 1000),
        },
        process.env.JWT_SECRET,
        {
            algorithm: 'HS256',
            expiresIn: process.env.JWT_EXPIRE || '24h',
        }
    );
};

// Generate JWT refresh token with enhanced security
userSchema.methods.generateRefreshToken = function () {
    return jwt.sign(
        {
            id: this._id,
            email: this.email,
            iss: 'indulink-api',
            aud: 'indulink-client',
            iat: Math.floor(Date.now() / 1000),
            jti: crypto.randomBytes(16).toString('hex') // Unique identifier for refresh token
        },
        process.env.JWT_REFRESH_SECRET,
        {
            algorithm: 'HS256',
            expiresIn: process.env.JWT_REFRESH_EXPIRE || '7d',
        }
    );
};

// Generate password reset token with enhanced security
userSchema.methods.generatePasswordResetToken = function () {
    const resetToken = crypto.randomBytes(32).toString('hex');
    this.passwordResetToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    this.passwordResetExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes
    return resetToken;
};

// Get user's full name
userSchema.virtual('fullName').get(function () {
    return `${this.firstName} ${this.lastName}`;
});

// Ensure virtuals are included in JSON
userSchema.set('toJSON', {
    virtuals: true,
    transform: function (doc, ret) {
        // Remove sensitive data
        delete ret.password;
        delete ret.refreshToken;
        delete ret.emailVerificationToken;
        delete ret.passwordResetToken;
        delete ret.twoFactorAuthSecret;
        delete ret.twoFactorAuthBackupCodes;
        return ret;
    }
});
userSchema.set('toObject', {
    virtuals: true,
    transform: function (doc, ret) {
        // Remove sensitive data
        delete ret.password;
        delete ret.refreshToken;
        delete ret.emailVerificationToken;
        delete ret.passwordResetToken;
        delete ret.twoFactorAuthSecret;
        delete ret.twoFactorAuthBackupCodes;
        return ret;
    }
});

// Add indexes for better performance
userSchema.index({ role: 1 });
userSchema.index({ isActive: 1 });
userSchema.index({ isEmailVerified: 1 });

module.exports = mongoose.model('User', userSchema);
