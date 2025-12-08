const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '.env') });

async function dropIndex() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const collection = mongoose.connection.collection('products');

        // List indexes first
        const indexes = await collection.indexes();
        console.log('Current Indexes:', indexes.map(i => i.name));

        const indexName = 'barcodes_1';
        const exists = indexes.find(i => i.name === indexName);

        if (exists) {
            await collection.dropIndex(indexName);
            console.log(`Dropped index: ${indexName}`);
        } else {
            console.log(`Index ${indexName} does not exist.`);
        }

    } catch (err) {
        console.error('Error dropping index:', err);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected');
    }
}

dropIndex();
