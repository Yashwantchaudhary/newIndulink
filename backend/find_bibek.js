const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
const Order = require('./models/Order');
require('dotenv').config();

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

            // Check orders
            // Orders where items.supplier is bibek._id
            const orders = await Order.find({ 'items.supplier': bibek._id });
            console.log(`Bibek has ${orders.length} orders.`);

            // Generate 'Live Data' simulation
            console.log('--- SIMULATED DASHBOARD DATA ---');
            console.log('Total Revenue:', orders.reduce((acc, order) => acc + order.totalAmount, 0)); // Approx
            console.log('Total Orders:', orders.length);
            console.log('Total Products:', products.length);
        }

    } catch (e) {
        console.error(e);
    } finally {
        await mongoose.disconnect();
    }
}

checkBibek();
