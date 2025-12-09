const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');

async function updateFeaturedProducts() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const result = await Product.updateMany(
            { sku: { $in: ['BT-001', 'DT-001', 'WD-001', 'PP-001', 'PC-001', 'SR-001', 'CT-001', 'AW-001'] } },
            { isFeatured: true }
        );

        console.log(`Updated ${result.modifiedCount} products to be featured`);

    } catch (err) {
        console.error('Error updating products:', err);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected');
    }
}

updateFeaturedProducts();