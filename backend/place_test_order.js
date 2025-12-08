const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
const Order = require('./models/Order');
const axios = require('axios');
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

        // 3. Login as Customer (Sanjay) to get Token
        // Assuming local server is running at localhost:5000
        const loginRes = await axios.post('http://localhost:5000/api/auth/login', {
            email: 'sanjay@gmail.com',
            password: 'sanjay@123'
        });
        const token = loginRes.data.token;
        console.log('Customer Logged In. Token acquired.');

        // 4. Create Order via API
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
            paymentMethod: 'Cash on Delivery',
            items: [
                {
                    product: product._id,
                    quantity: 1
                }
            ],
            // Note: The API usually takes items from Cart. 
            // If the endpoint /api/orders creates from cart, we need to add to cart first.
            // Let's check api/orders endpoint.
        };

        // Checking if create order API requires items in body or takes from cart.
        // Usually it takes from cart.
        // Let's Add to Cart first.
        await axios.post('http://localhost:5000/api/cart', {
            productId: product._id,
            quantity: 1
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('Added to Cart');

        // Now Place Order
        const orderRes = await axios.post('http://localhost:5000/api/orders', {
            shippingAddress: orderData.shippingAddress,
            paymentMethod: 'Cash on Delivery',
            notes: 'Test Order for Bibek Verification'
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('Order Placed!', orderRes.data);

    } catch (e) {
        console.error('Error:', e.response ? e.response.data : e.message);
    } finally {
        await mongoose.disconnect();
    }
}

placeOrderForBibek();
