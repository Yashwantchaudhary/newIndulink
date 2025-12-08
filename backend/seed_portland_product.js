const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load env vars
dotenv.config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');
const User = require('./models/User');
const Category = require('./models/Category');

async function seedPortlandProduct() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Find a supplier
        const supplier = await User.findOne({ role: 'supplier' });
        if (!supplier) {
            console.log('No supplier found. Please create a supplier first.');
            return;
        }
        console.log(`Found supplier: ${supplier.firstName} ${supplier.lastName}`);

        // Find or create Cement category
        let cementCategory = await Category.findOne({ name: { $regex: /cement/i } });
        if (!cementCategory) {
            // If no Cement category, use first available or create one
            cementCategory = await Category.findOne({});
            if (!cementCategory) {
                cementCategory = await Category.create({
                    name: 'Cement',
                    slug: 'cement',
                    description: 'All types of cement for construction',
                    isActive: true
                });
                console.log('Created Cement category');
            }
        }
        console.log(`Using category: ${cementCategory.name}`);

        const portlandProduct = {
            title: 'Portland Cement Premium Grade',
            description: 'Premium quality Portland cement for all construction needs. Ideal for foundations, columns, beams, and general masonry work. This OPC 53 grade cement provides excellent strength and durability for your projects. Made from high-quality limestone and clay, ensuring consistent performance and optimal hydration.',
            price: 550,
            compareAtPrice: 650,
            stock: 1000,
            category: cementCategory._id,
            supplier: supplier._id,
            sku: 'PORT-CEM-001',
            barcodes: ['BAR-PORT-001'],
            images: [
                {
                    url: '/uploads/products/portland.jpg',
                    alt: 'Portland Cement Premium Grade',
                    isPrimary: true
                }
            ],
            status: 'active',
            isFeatured: true,
            averageRating: 4.5,
            totalReviews: 128,
            tags: ['cement', 'portland', 'construction', 'building', 'OPC', 'premium'],
            weight: {
                value: 50,
                unit: 'kg'
            },
            viewCount: 1245,
            purchaseCount: 342
        };

        // Check if product exists
        const existing = await Product.findOne({ sku: portlandProduct.sku });
        if (existing) {
            // Update existing product with the image
            await Product.findByIdAndUpdate(existing._id, portlandProduct);
            console.log(`✅ Updated existing Portland Cement product with image`);
        } else {
            await Product.create(portlandProduct);
            console.log(`✅ Created Portland Cement Premium Grade product`);
        }

        console.log('\n📦 Product Details:');
        console.log(`   Title: ${portlandProduct.title}`);
        console.log(`   Price: Rs. ${portlandProduct.price}`);
        console.log(`   Compare At: Rs. ${portlandProduct.compareAtPrice}`);
        console.log(`   Stock: ${portlandProduct.stock} bags`);
        console.log(`   Featured: ${portlandProduct.isFeatured}`);
        console.log(`   Image: ${portlandProduct.images[0].url}`);

    } catch (err) {
        console.error('Error seeding Portland product:', err);
    } finally {
        await mongoose.connection.close();
        console.log('\nDisconnected from MongoDB');
    }
}

seedPortlandProduct();
