const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
require('dotenv').config();

async function placeOrderForBibek() {
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

        // 3. Login as Customer (Sanjay)
        const loginRes = await fetch('http://127.0.0.1:5000/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'sanjay@gmail.com',
                password: 'sanjay@123'
            })
        });
        const loginData = await loginRes.json();
        // console.log('Login Response:', JSON.stringify(loginData, null, 2));
        if (!loginRes.ok) throw new Error(loginData.message || 'Login failed');
        const token = loginData.data.accessToken; // Corrected path
        // console.log('Token extracted:', token);
        console.log('Customer Logged In. Token acquired.');

        // 4. Add to Cart
        const cartRes = await fetch('http://127.0.0.1:5000/api/cart', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                productId: product._id,
                quantity: 1
            })
        });
        if (!cartRes.ok) {
            const err = await cartRes.json();
            throw new Error(err.message || 'Add to cart failed');
        }
        console.log('Added to Cart');

        // 5. Place Order
        const orderData = {
            shippingAddress: {
                fullName: 'Sanjay Customer',
                phoneNumber: '9800000000',
                addressLine1: 'Test Address',
                city: 'Kathmandu',
                state: 'Bagmati',
                zipCode: '44600',
                country: 'Nepal'
            },
            paymentMethod: 'cash_on_delivery', // Ensure lowercase enum match
            notes: 'Test Order for Bibek Verification'
        };

        const orderRes = await fetch('http://127.0.0.1:5000/api/orders', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(orderData)
        });

        const orderResult = await orderRes.json();
        if (!orderRes.ok) throw new Error(orderResult.message || 'Order placement failed');

        console.log('Order Placed!', JSON.stringify(orderResult, null, 2));

    } catch (e) {
        console.error('Error:', e.message);
    } finally {
        await mongoose.disconnect();
    }
}

placeOrderForBibek();
