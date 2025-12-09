const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/INDULINK');

const Notification = require('./models/Notification');

async function createTestNotification() {
    try {
        console.log('Creating test notification for customers...');

        const notification = await Notification.create({
            title: '🎉 Test Notification',
            body: 'This is a test notification to verify the system works. You should see this in your notification screen!',
            type: 'system',
            targetRole: 'customer',
            data: {
                test: true,
                timestamp: new Date()
            }
        });

        console.log('✅ Notification created:', notification._id);
        console.log('   Title:', notification.title);
        console.log('   targetRole:', notification.targetRole);
        console.log('   createdAt:', notification.createdAt);

        // Query to verify
        const count = await Notification.countDocuments({ targetRole: 'customer' });
        console.log('\n📊 Total customer notifications in DB:', count);

        // Sample query
        const allCustomerNotifs = await Notification.find({ targetRole: 'customer' })
            .sort({ createdAt: -1 })
            .limit(5);

        console.log('\n📋 Sample customer notifications:');
        allCustomerNotifs.forEach(n => {
            console.log(`   - ${n.title} (${n.type}) - ${n.createdAt}`);
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

createTestNotification();
