const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');
const User = require('./models/User');
const Category = require('./models/Category');

async function addNewProducts() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const categories = await Category.find({ isActive: true });
        if (!categories || categories.length === 0) {
            console.log('No active categories found. Cannot create products.');
            return;
        }

        const supplier = await User.findOne({ email: 'bibek@gmail.com' });
        if (!supplier) {
            console.log('Supplier not found');
            return;
        }

        const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;

        const productsToAdd = [
            {
                title: 'Bath Tub',
                description: 'High-quality ceramic bath tub for modern bathrooms. Durable and elegant design.',
                price: 15000,
                stock: 25,
                category: categories[0]._id,
                sku: 'BT-001',
                isFeatured: true,
                images: [{ url: `${baseUrl}/uploads/bathdub.jpg`, isPrimary: true }]
            },
            {
                title: 'Dining Table',
                description: 'Solid wood dining table perfect for family gatherings. Sturdy construction with modern finish.',
                price: 25000,
                stock: 15,
                category: categories[0]._id,
                sku: 'DT-001',
                isFeatured: true,
                images: [{ url: `${baseUrl}/uploads/dining table.jpg`, isPrimary: true }]
            },
            {
                title: 'Wooden Door',
                description: 'Durable wooden door with modern design. Perfect for residential and commercial use.',
                price: 8000,
                stock: 50,
                category: categories[0]._id,
                sku: 'WD-001',
                isFeatured: true,
                images: [{ url: `${baseUrl}/uploads/door.jpg`, isPrimary: true }]
            },
            {
                title: 'PVC Pipe',
                description: 'High-quality PVC pipes for plumbing applications. Corrosion resistant and long-lasting.',
                price: 500,
                stock: 200,
                category: categories[0]._id,
                sku: 'PP-001',
                images: [{ url: `${baseUrl}/uploads/pipe.jpg`, isPrimary: true }]
            },
            {
                title: 'Portland Cement',
                description: 'Premium Portland cement for construction projects. High strength and reliable performance.',
                price: 800,
                stock: 1000,
                category: categories[0]._id,
                sku: 'PC-001',
                images: [{ url: `${baseUrl}/uploads/portland.jpg`, isPrimary: true }]
            },
            {
                title: 'Steel Rod',
                description: 'TMT steel rods for reinforcement in construction. High tensile strength and corrosion resistance.',
                price: 1200,
                stock: 300,
                category: categories[0]._id,
                sku: 'SR-001',
                images: [{ url: `${baseUrl}/uploads/rod.jpg`, isPrimary: true }]
            },
            {
                title: 'Ceramic Tiles',
                description: 'Beautiful ceramic tiles for flooring and wall applications. Available in various designs.',
                price: 200,
                stock: 500,
                category: categories[0]._id,
                sku: 'CT-001',
                images: [{ url: `${baseUrl}/uploads/tiles.jpg`, isPrimary: true }]
            },
            {
                title: 'Aluminum Window',
                description: 'Modern aluminum window frames with excellent thermal insulation. Durable and stylish.',
                price: 12000,
                stock: 30,
                category: categories[0]._id,
                sku: 'AW-001',
                images: [{ url: `${baseUrl}/uploads/window.jpg`, isPrimary: true }]
            }
        ];

        for (const p of productsToAdd) {
            const existing = await Product.findOne({ sku: p.sku });
            if (existing) {
                console.log(`Skipping existing product: ${p.title} (${p.sku})`);
                continue;
            }

            await Product.create({
                ...p,
                supplier: supplier._id,
                status: 'active'
            });
            console.log(`Created: ${p.title}`);
        }

        console.log(`Successfully added ${productsToAdd.length} new products`);

    } catch (err) {
        console.error('Error adding products:', err);
    } finally {
        await mongoose.connection.close();
        console.log('Disconnected');
    }
}

addNewProducts();