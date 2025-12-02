const mongoose = require('mongoose');
require('dotenv').config();

async function checkCollections() {
    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/indulink');
        console.log('✅ Connected to MongoDB');

        const collections = await mongoose.connection.db.listCollections().toArray();
        console.log('\n📊 All MongoDB Collections:');
        collections.forEach(c => console.log('✅ ' + c.name));
        console.log(`\n📈 Total: ${collections.length} collections`);

        // Get document counts for each collection
        console.log('\n📋 Collection Document Counts:');
        for (const collection of collections) {
            try {
                const count = await mongoose.connection.db.collection(collection.name).countDocuments();
                console.log(`   ${collection.name}: ${count} documents`);
            } catch (err) {
                console.log(`   ${collection.name}: Error counting documents`);
            }
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkCollections();