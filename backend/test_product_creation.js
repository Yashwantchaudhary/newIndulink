const mongoose = require('mongoose');
const Product = require('./models/Product');
require('dotenv').config();

// Test product creation to verify database flow
async function testProductCreation() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // Sample product data (same structure as supplier creates)
        const testProduct = {
            title: 'Test Product',
            description: 'This is a test product to verify database flow',
            price: 999,
            stock: 10,
            category: '6756bdb90e7b5a4954868fa5', // Replace with a valid category ID from your DB
            supplier: '6756d9eb0e7b5a4954869026', // Replace with a valid supplier ID from your DB
            images: [{
                url: '/uploads/test-image.jpg',
                alt: 'Test Product',
                isPrimary: true
            }],
            isFeatured: false,
            status: 'active'
        };

        console.log('\\n📝 Creating test product with data:', JSON.stringify(testProduct, null, 2));

        // Create product
        const product = await Product.create(testProduct);

        console.log('\\n✅ Product created successfully!');
        console.log('Product ID:', product._id);
        console.log('Product Title:', product.title);
        console.log('Product Status:', product.status);

        // Verify it's in the database
        const foundProduct = await Product.findById(product._id);
        if (foundProduct) {
            console.log('\\n✅ Product verified in database!');
            console.log('Found product:', foundProduct.title);
        }

        // Cleanup - delete test product
        await Product.findByIdAndDelete(product._id);
        console.log('\\n🗑️  Test product cleaned up');

    } catch (error) {
        console.error('\\n❌ Error:', error.message);
        if (error.errors) {
            console.error('\\nValidation errors:');
            Object.keys(error.errors).forEach(key => {
                console.error(`  - ${key}: ${error.errors[key].message}`);
            });
        }
    } finally {
        await mongoose.disconnect();
        console.log('\\n🔌 Disconnected from MongoDB');
    }
}

testProductCreation();
