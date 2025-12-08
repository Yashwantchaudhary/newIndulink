const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
const Order = require('./models/Order');
require('dotenv').config();

async function createOrderDirectly() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to DB');

        // 1. Find Bibek (Supplier)
        const bibek = await User.findOne({
            $or: [{ firstName: /Bibek/i }, { lastName: /Ray/i }],
            role: 'supplier'
        });
        if (!bibek) throw new Error('Bibek not found');
        console.log('Found Supplier:', bibek.email);

        // 2. Find a product by Bibek
        const product = await Product.findOne({ supplier: bibek._id });
        if (!product) throw new Error('Bibek has no products');
        console.log('Found Product:', product.title, product._id);

        // 3. Find Customer (Sanjay)
        const customer = await User.findOne({ email: 'sanjay@gmail.com' });
        if (!customer) throw new Error('Customer Sanjay not found');

        // 4. Create Order Directly
        const order = await Order.create({
            user: customer._id,
            orderNumber: 'ORD-' + Date.now(),
            subtotal: 1500, // Required
            tax: 195, // Required (13%)
            shippingCost: 100, // Required
            total: 1795, // Required (subtotal + tax + shipping)
            status: 'pending',
            paymentStatus: 'pending',
            paymentMethod: 'cash_on_delivery', // Correct enum value
            shippingAddress: {
                fullName: 'Sanjay Customer',
                phoneNumber: '9800000000',
                addressLine1: 'Test Address Direct',
                city: 'Kathmandu',
                state: 'Bagmati',
                zipCode: '44600',
                country: 'Nepal'
            },
            items: [
                {
                    product: product._id,
                    supplier: bibek._id, // Critical for Supplier Dashboard
                    quantity: 1,
                    price: 1500,
                    subtotal: 1500, // Required for item
                    status: 'pending'
                }
            ],
            // Add missing required fields if any based on schema
            supplier: bibek._id, // Some schemas might require this at top level for single-supplier orders
            customer: customer._id // Some schemas might use this alias for user
        });

        console.log('Order created directly in DB:', order.orderNumber);

        // 5. Verify Stats
        const orderCount = await Order.countDocuments({ supplier: bibek._id });
        console.log(`Bibek now has ${orderCount} orders.`);

    } catch (e) {
        console.error('Error:', e);
    } finally {
        await mongoose.disconnect();
    }
}

createOrderDirectly();
