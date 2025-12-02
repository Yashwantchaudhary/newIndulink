const Address = require('../models/Address');

// @desc    Get user addresses
// @route   GET /api/addresses
// @access  Private
exports.getAddresses = async (req, res, next) => {
    try {
        const addresses = await Address.find({ user: req.user.id })
            .sort({ createdAt: -1 });

        // Find default address
        const defaultAddress = addresses.find(addr => addr.isDefault);

        res.status(200).json({
            success: true,
            count: addresses.length,
            defaultAddressId: defaultAddress?._id,
            data: addresses,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Add new address
// @route   POST /api/addresses
// @access  Private
exports.addAddress = async (req, res, next) => {
    try {
        const { fullName, phoneNumber, addressLine1, addressLine2, city, state, zipCode, country, isDefault } = req.body;

        // If this is set as default, unset other defaults
        if (isDefault) {
            await Address.updateMany(
                { user: req.user.id },
                { isDefault: false }
            );
        }

        const address = await Address.create({
            user: req.user.id,
            fullName,
            phoneNumber,
            addressLine1,
            addressLine2,
            city,
            state,
            zipCode,
            country: country || 'Nepal',
            isDefault: isDefault || false,
        });

        res.status(201).json({
            success: true,
            message: 'Address added successfully',
            data: address,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update address
// @route   PUT /api/addresses/:id
// @access  Private
exports.updateAddress = async (req, res, next) => {
    try {
        let address = await Address.findById(req.params.id);

        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found',
            });
        }

        // Check ownership
        if (address.user.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this address',
            });
        }

        const { fullName, phoneNumber, addressLine1, addressLine2, city, state, zipCode, country, isDefault } = req.body;

        // If this is set as default, unset other defaults
        if (isDefault) {
            await Address.updateMany(
                { user: req.user.id, _id: { $ne: req.params.id } },
                { isDefault: false }
            );
        }

        address = await Address.findByIdAndUpdate(
            req.params.id,
            {
                fullName,
                phoneNumber,
                addressLine1,
                addressLine2,
                city,
                state,
                zipCode,
                country,
                isDefault,
            },
            { new: true, runValidators: true }
        );

        res.status(200).json({
            success: true,
            message: 'Address updated successfully',
            data: address,
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Delete address
// @route   DELETE /api/addresses/:id
// @access  Private
exports.deleteAddress = async (req, res, next) => {
    try {
        const address = await Address.findById(req.params.id);

        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found',
            });
        }

        // Check ownership
        if (address.user.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this address',
            });
        }

        await address.remove();

        res.status(200).json({
            success: true,
            message: 'Address deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Set default address
// @route   PUT /api/addresses/:id/set-default
// @access  Private
exports.setDefaultAddress = async (req, res, next) => {
    try {
        const address = await Address.findById(req.params.id);

        if (!address) {
            return res.status(404).json({
                success: false,
                message: 'Address not found',
            });
        }

        // Check ownership
        if (address.user.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this address',
            });
        }

        // Unset all other defaults
        await Address.updateMany(
            { user: req.user.id },
            { isDefault: false }
        );

        // Set this as default
        address.isDefault = true;
        await address.save();

        res.status(200).json({
            success: true,
            message: 'Default address updated successfully',
        });
    } catch (error) {
        next(error);
    }
};