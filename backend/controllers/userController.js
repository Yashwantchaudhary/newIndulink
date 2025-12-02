const User = require('../models/User');

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res, next) => {
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

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
exports.updateProfile = async (req, res, next) => {
    try {
        const { firstName, lastName, phone, businessName, businessDescription, businessAddress } = req.body;

        const updateData = {
            firstName,
            lastName,
            phone,
        };

        // Add supplier-specific fields if user is supplier
        if (req.user.role === 'supplier') {
            updateData.businessName = businessName;
            updateData.businessDescription = businessDescription;
            updateData.businessAddress = businessAddress;
        }

        const user = await User.findByIdAndUpdate(req.user.id, updateData, {
            new: true,
            runValidators: true,
        });

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: user,
        });
    } catch (error) {
        next(error);
    }
};

// @ desc   Upload profile image
// @route   POST /api/users/profile/image
// @access  Private
exports.uploadProfileImage = async (req, res, next) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Please upload an image',
            });
        }

        const imageUrl = `/uploads/profiles/${req.file.filename}`;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { profileImage: imageUrl },
            { new: true }
        );

        res.status(200).json({
            success: true,
            message: 'Profile image uploaded successfully',
            data: {
                profileImage: imageUrl,
            },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Add address
// @route   POST /api/users/addresses
// @access  Private
exports.addAddress = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);

        // If this is set as default, unset other defaults
        if (req.body.isDefault) {
            user.addresses.forEach((addr) => (addr.isDefault = false));
        }

        user.addresses.push(req.body);
        await user.save();

        res.status(201).json({
            success: true,
            message: 'Address added successfully',
            data: user.addresses,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update address
// @route   PUT /api/users/addresses/:addressId
// @access  Private
exports.updateAddress = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);
        const address = user.addresses.id(req.params.addressId);

        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found',
            });
        }

        // If setting as default, unset others
        if (req.body.isDefault) {
            user.addresses.forEach((addr) => (addr.isDefault = false));
        }

        Object.assign(address, req.body);
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Address updated successfully',
            data: user.addresses,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete address
// @route   DELETE /api/users/addresses/:addressId
// @access  Private
exports.deleteAddress = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);
        user.addresses.id(req.params.addressId).remove();
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Address deleted successfully',
            data: user.addresses,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Toggle wishlist item
// @route   PUT /api/users/wishlist/:productId
// @access  Private (Customer)
exports.toggleWishlist = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);
        const productId = req.params.productId;

        const index = user.wishlist.indexOf(productId);

        if (index > -1) {
            // Remove from wishlist
            user.wishlist.splice(index, 1);
        } else {
            // Add to wishlist
            user.wishlist.push(productId);
        }

        await user.save();

        res.status(200).json({
            success: true,
            message: index > -1 ? 'Removed from wishlist' : 'Added to wishlist',
            data: { wishlist: user.wishlist },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get wishlist
// @route   GET /api/users/wishlist
// @access  Private (Customer)
exports.getWishlist = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id).populate({
            path: 'wishlist',
            select: 'title price images averageRating stock status',
        });

        res.status(200).json({
            success: true,
            data: user.wishlist,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get all users (Admin only)
// @route   GET /api/users
// @access  Private (Admin)
exports.getUsers = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const filter = {};

        // Filter by role
        if (req.query.role) {
            filter.role = req.query.role;
        }

        // Filter by status
        if (req.query.status) {
            filter.isActive = req.query.status === 'active';
        }

        // Search by name or email
        if (req.query.search) {
            filter.$or = [
                { firstName: { $regex: req.query.search, $options: 'i' } },
                { lastName: { $regex: req.query.search, $options: 'i' } },
                { email: { $regex: req.query.search, $options: 'i' } },
                { businessName: { $regex: req.query.search, $options: 'i' } },
            ];
        }

        const users = await User.find(filter)
            .select('-password -refreshToken')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await User.countDocuments(filter);

        res.status(200).json({
            success: true,
            count: users.length,
            total,
            page,
            pages: Math.ceil(total / limit),
            data: users,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user role/status (Admin only)
// @route   PUT /api/users/:id
// @access  Private (Admin)
exports.updateUser = async (req, res, next) => {
    try {
        const { role, isActive } = req.body;

        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Update fields
        if (role !== undefined) user.role = role;
        if (isActive !== undefined) user.isActive = isActive;

        await user.save();

        // Return user without sensitive data
        const updatedUser = await User.findById(req.params.id).select('-password -refreshToken');

        res.status(200).json({
            success: true,
            message: 'User updated successfully',
            data: updatedUser,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete user (Admin only)
// @route   DELETE /api/users/:id
// @access  Private (Admin)
exports.deleteUser = async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Prevent admin from deleting themselves
        if (user._id.toString() === req.user.id) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete your own account',
            });
        }

        await user.remove();

        res.status(200).json({
            success: true,
            message: 'User deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Register FCM token
// @route   POST /api/users/fcm-token
// @access  Private
exports.registerFCMToken = async (req, res, next) => {
    try {
        const { token, deviceId } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'FCM token is required',
            });
        }

        const user = await User.findById(req.user.id);

        // Add token if not already present
        if (!user.fcmTokens.includes(token)) {
            user.fcmTokens.push(token);

            // Limit to 5 tokens per user (one per device)
            if (user.fcmTokens.length > 5) {
                user.fcmTokens = user.fcmTokens.slice(-5);
            }

            await user.save();
        }

        res.status(200).json({
            success: true,
            message: 'FCM token registered successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Unregister FCM token
// @route   DELETE /api/users/fcm-token
// @access  Private
exports.unregisterFCMToken = async (req, res, next) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: 'FCM token is required',
            });
        }

        const user = await User.findById(req.user.id);

        // Remove token
        user.fcmTokens = user.fcmTokens.filter(t => t !== token);
        await user.save();

        res.status(200).json({
            success: true,
            message: 'FCM token unregistered successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update notification preferences
// @route   PUT /api/users/notification-preferences
// @access  Private
exports.updateNotificationPreferences = async (req, res, next) => {
    try {
        const {
            orderUpdates,
            promotions,
            messages,
            system,
            emailNotifications,
            pushNotifications
        } = req.body;

        const user = await User.findById(req.user.id);

        // Update preferences
        if (orderUpdates !== undefined) user.notificationPreferences.orderUpdates = orderUpdates;
        if (promotions !== undefined) user.notificationPreferences.promotions = promotions;
        if (messages !== undefined) user.notificationPreferences.messages = messages;
        if (system !== undefined) user.notificationPreferences.system = system;
        if (emailNotifications !== undefined) user.notificationPreferences.emailNotifications = emailNotifications;
        if (pushNotifications !== undefined) user.notificationPreferences.pushNotifications = pushNotifications;

        await user.save();

        res.status(200).json({
            success: true,
            message: 'Notification preferences updated successfully',
            data: user.notificationPreferences,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get notification preferences
// @route   GET /api/users/notification-preferences
// @access  Private
exports.getNotificationPreferences = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id).select('notificationPreferences');

        res.status(200).json({
            success: true,
            data: user.notificationPreferences,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update language preference
// @route   PUT /api/users/language
// @access  Private
exports.updateLanguage = async (req, res, next) => {
    try {
        const { language } = req.body;

        // Validate language
        const validLanguages = ['en', 'ne', 'hi'];
        if (!validLanguages.includes(language)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid language. Supported languages: en, ne, hi',
            });
        }

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { language },
            { new: true, runValidators: true }
        ).select('language');

        res.status(200).json({
            success: true,
            message: 'Language preference updated successfully',
            data: { language: user.language },
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get language preference
// @route   GET /api/users/language
// @access  Private
exports.getLanguage = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id).select('language');

        res.status(200).json({
            success: true,
            data: { language: user.language },
        });
    } catch (error) {
        next(error);
    }
};
