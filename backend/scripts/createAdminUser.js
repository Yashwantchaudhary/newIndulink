// Script to create default admin user for testing
// Run this with: node scripts/createAdminUser.js

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Import User model
const User = require('../models/User');

const createAdminUser = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Check if admin already exists
        const existingAdmin = await User.findOne({ email: 'admin@gmail.com' });

        if (existingAdmin) {
            console.log('⚠️  Admin user already exists!');
            console.log('Email: admin@gmail.com');
            console.log('You can update the password if needed.');

            // Update password
            const hashedPassword = await bcrypt.hash('admin123', 10);
            existingAdmin.password = hashedPassword;
            existingAdmin.isActive = true;
            await existingAdmin.save();
            console.log('✅ Admin password updated successfully!');
        } else {
            // Create new admin user
            const hashedPassword = await bcrypt.hash('admin123', 10);

            const adminUser = new User({
                firstName: 'Admin',
                lastName: 'User',
                email: 'admin@gmail.com',
                password: hashedPassword,
                role: 'admin',
                isActive: true,
                isEmailVerified: true,
            });

            await adminUser.save();
            console.log('✅ Admin user created successfully!');
        }

        console.log('\n📋 Default Admin Credentials:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Email:    admin@gmail.com');
        console.log('Password: admin123');
        console.log('Role:     admin');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        process.exit(0);
    } catch (error) {
        console.error('❌ Error creating admin user:', error);
        process.exit(1);
    }
};

createAdminUser();
