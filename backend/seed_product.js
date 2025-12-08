const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');
const User = require('./models/User');
const Category = require('./models/Category');

async function seedWithCategory() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const categories = await Category.find();
        if (!categories || categories.length === 0) {
            console.log('No categories found. Cannot create product.');
            return;
        }

        const supplier = await User.findOne({ email: 'bibek@gmail.com' });
        if (!supplier) {
            console.log('Supplier not found');
            return;
        }

        const productsToSeed = [
            {
                title: 'High Strength Cement',
                description: 'Premium quality cement for strong foundations.',
                price: 850,
                stock: 500,
                category: categories[0]._id,
                sku: 'CEM-005',
                barcodes: ['BAR-CEM-005']
            },
            {
                title: 'Steel Rebar (12mm)',
                description: 'TMT bars for construction reinforcement.',
                price: 1200,
                stock: 200,
                category: categories.length > 1 ? categories[1]._id : categories[0]._id,
                sku: 'STL-005',
                barcodes: ['BAR-STL-005']
            },
            {
                title: 'Red Bricks (Class A)',
                description: 'Standard red clay bricks, burnt and durable.',
                price: 25,
                stock: 5000,
                category: categories[0]._id,
                sku: 'BRK-005',
                barcodes: ['BAR-BRK-005']
            },
            {
                title: 'Sand (River Bed)',
                description: 'Clean river sand for plastering and concrete.',
                price: 4000,
                stock: 100,
                category: categories.length > 1 ? categories[1]._id : categories[0]._id,
                sku: 'SND-005',
                barcodes: ['BAR-SND-005']
            }
        ];

        for (const p of productsToSeed) {
            const existing = await Product.findOne({ sku: p.sku });
            if (existing) {
                console.log(`Skipping existing product: ${p.title} (${p.sku})`);
                continue;
            }

            await Product.create({
                ...p,
                supplier: supplier._id,
                images: [{ url: 'https://via.placeholder.com/300', isPrimary: true }],
                status: 'active'
            });
            console.log(`Created: ${p.title}`);
        }

    } catch (err) {
        console.error('Error seeding products:', err);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected');
    }
}

seedWithCategory();
