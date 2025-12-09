const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/INDULINK');

const Product = require('./models/Product');
const Notification = require('./models/Notification');

async function cleanup() {
    try {
        console.log('🧹 Cleaning up test data...\n');

        // Delete test products (products with "Test Notification Product" in title)
        const deletedProducts = await Product.deleteMany({
            title: { $regex: /Test Notification Product/i }
        });
        console.log(`✅ Deleted ${deletedProducts.deletedCount} test products`);

        // Delete test notifications
        const deletedNotifications = await Notification.deleteMany({
            $or: [
                { title: { $regex: /Test Notification/i } },
                { body: { $regex: /Test Notification Product/i } }
            ]
        });
        console.log(`✅ Deleted ${deletedNotifications.deletedCount} test notifications\n`);

        // Show remaining notifications
        const remainingNotifs = await Notification.countDocuments({ targetRole: 'customer' });
        console.log(`📊 Remaining customer notifications: ${remainingNotifs}`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

cleanup();
