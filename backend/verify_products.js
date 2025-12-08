const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const User = require('./models/User');
const Product = require('./models/Product');

async function verifyProducts() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // 1. Get all Suppliers
        const suppliers = await User.find({ role: 'supplier' });
        console.log('\n--- Suppliers ---');
        suppliers.forEach(s => {
            console.log(`ID: ${s._id}, Name: ${s.firstName} ${s.lastName}, Email: ${s.email}`);
        });

        // 2. Get all Products
        const products = await Product.find({});
        console.log('\n--- Products ---');
        products.forEach(p => {
            console.log(`ID: ${p._id}, Title: ${p.title}, Supplier: ${p.supplier}`);
        });

        // 3. Check for specific supplier's products
        if (suppliers.length > 0) {
            const firstSupplier = suppliers[0];
            const supplierProducts = await Product.find({ supplier: firstSupplier._id });
            console.log(`\n--- Products for first supplier (${firstSupplier.email}) ---`);
            console.log(`Count: ${supplierProducts.length}`);
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.connection.close();
        console.log('\nDisconnected');
    }
}

verifyProducts();
