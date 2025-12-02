const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true,
    },
    fullName: {
        type: String,
        required: [true, 'Please add a full name'],
        trim: true,
        maxlength: [50, 'Name cannot be more than 50 characters'],
    },
    phoneNumber: {
        type: String,
        required: [true, 'Please add a phone number'],
        trim: true,
    },
    addressLine1: {
        type: String,
        required: [true, 'Please add address line 1'],
        trim: true,
        maxlength: [100, 'Address line 1 cannot be more than 100 characters'],
    },
    addressLine2: {
        type: String,
        trim: true,
        maxlength: [100, 'Address line 2 cannot be more than 100 characters'],
    },
    city: {
        type: String,
        required: [true, 'Please add a city'],
        trim: true,
        maxlength: [50, 'City cannot be more than 50 characters'],
    },
    state: {
        type: String,
        required: [true, 'Please add a state/province'],
        trim: true,
        maxlength: [50, 'State cannot be more than 50 characters'],
    },
    zipCode: {
        type: String,
        required: [true, 'Please add a zip/postal code'],
        trim: true,
        maxlength: [20, 'Zip code cannot be more than 20 characters'],
    },
    country: {
        type: String,
        default: 'Nepal',
        trim: true,
    },
    isDefault: {
        type: Boolean,
        default: false,
    },
}, {
    timestamps: true,
});

// Index for faster queries
addressSchema.index({ user: 1, isDefault: -1 });

// Static method to get default address for a user
addressSchema.statics.getDefaultAddress = function(userId) {
    return this.findOne({ user: userId, isDefault: true });
};

// Instance method to set as default (unsets others)
addressSchema.methods.setAsDefault = function() {
    return this.constructor.updateMany(
        { user: this.user, _id: { $ne: this._id } },
        { isDefault: false }
    ).then(() => {
        this.isDefault = true;
        return this.save();
    });
};

module.exports = mongoose.model('Address', addressSchema);