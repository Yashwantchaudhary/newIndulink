const mongoose = require('mongoose');
require('dotenv').config();

async function checkUsers() {
    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/indulink');
        console.log('Connected to MongoDB');

        const User = require('./models/User');
        const users = await User.find({}, 'email firstName lastName role createdAt isActive');

        console.log('\n=== Users in Database ===\n');
        if (users.length === 0) {
            console.log('No users found in database!');
        } else {
            console.log(`Found ${users.length} user(s):\n`);
            users.forEach((u, i) => {
                console.log(`${i + 1}. Email: ${u.email}`);
                console.log(`   Name: ${u.firstName} ${u.lastName}`);
                console.log(`   Role: ${u.role}`);
                console.log(`   Active: ${u.isActive}`);
                console.log(`   Created: ${u.createdAt}`);
                console.log('');
            });
        }

        await mongoose.disconnect();
        console.log('Disconnected from MongoDB');
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

checkUsers();
