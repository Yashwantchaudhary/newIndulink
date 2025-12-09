const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');
const Cart = require('./models/Cart');

async function deleteAllProducts() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const result = await Product.deleteMany({});
        console.log(`Deleted ${result.deletedCount} products from database`);

        // Clear all cart items since products no longer exist
        const cartResult = await Cart.updateMany(
            {},
            { $set: { items: [] } }
        );
        console.log(`Cleared cart items from ${cartResult.modifiedCount} carts`);

    } catch (err) {
        console.error('Error deleting products:', err);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected');
    }
}

deleteAllProducts();