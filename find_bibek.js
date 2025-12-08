const mongoose = require('mongoose');
const User = require('./backend/models/User');
const Product = require('./backend/models/Product');
const Order = require('./backend/models/Order');
require('dotenv').config({ path: './backend/.env' });

async function checkBibek() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to DB');

        const bibek = await User.findOne({
            $or: [
                { firstName: /Bibek/i },
                { lastName: /Ray/i }
            ],
            role: 'supplier'
        });

        if (!bibek) {
            console.log('Bibek Ray not found as Supplier.');
            // Check ANY supplier
            const anySupplier = await User.findOne({ role: 'supplier' });
            if (anySupplier) {
                console.log('Found another supplier:', anySupplier.email);
            }
        } else {
            console.log('Found Bibek:', bibek.email, bibek._id);

            // Check products
            const products = await Product.find({ supplier: bibek._id });
            console.log(`Bibek has ${products.length} products.`);
            if (products.length > 0) {
                console.log('Example Product ID:', products[0]._id);
                console.log('Example Product Title:', products[0].title);
            }

            // Check orders
            const orders = await Order.find({ 'items.supplier': bibek._id });
            console.log(`Bibek has ${orders.length} orders.`);
        }

    } catch (e) {
        console.error(e);
    } finally {
        await mongoose.disconnect();
    }
}

checkBibek();
