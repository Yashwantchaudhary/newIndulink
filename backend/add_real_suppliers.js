#!/usr/bin/env node

/**
 * Add Real Suppliers to InduLink Platform
 * Script to onboard actual construction suppliers with their products
 */

const mongoose = require('mongoose');
const User = require('./models/User');
const Product = require('./models/Product');
const Category = require('./models/Category');

async function addRealSuppliers() {
    try {
        // Connect to database
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/indulink', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        console.log('✅ Connected to MongoDB');

        // Sample real suppliers data - replace with actual supplier information
        const realSuppliers = [
            {
                firstName: 'Rajesh',
                lastName: 'Sharma',
                email: 'rajesh.sharma@globalbuilders.com',
                password: 'supplier123',
                phone: '+9779812345678',
                role: 'supplier',
                businessName: 'Global Builders Pvt Ltd',
                businessDescription: 'Leading construction materials supplier in Nepal, providing high-quality cement, steel, and building materials since 2010.',
                businessAddress: 'Kathmandu, Nepal',
                businessLicense: 'LIC123456789',
                addresses: [{
                    label: 'work',
                    fullName: 'Rajesh Sharma',
                    phone: '+9779812345678',
                    addressLine1: '123 Industrial Area',
                    city: 'Kathmandu',
                    state: 'Bagmati',
                    postalCode: '44600',
                    country: 'Nepal',
                    isDefault: true
                }],
                products: [
                    {
                        title: 'Premium Portland Cement',
                        description: 'High-quality OPC cement for all construction needs',
                        price: 650,
                        stock: 2000,
                        sku: 'OPC-53-001',
                        category: 'Building Materials',
                        tags: ['cement', 'construction', 'building'],
                        isFeatured: true
                    },
                    {
                        title: 'Steel Reinforcement Bars',
                        description: 'Grade 60 steel rebar for concrete reinforcement',
                        price: 85,
                        stock: 500,
                        sku: 'REBAR-12MM-002',
                        category: 'Building Materials',
                        tags: ['steel', 'rebar', 'reinforcement'],
                        isFeatured: false
                    },
                    {
                        title: 'Copper Electrical Wire',
                        description: 'Pure copper wire for residential and commercial wiring',
                        price: 450,
                        stock: 300,
                        sku: 'WIRE-CU-1.5MM-003',
                        category: 'Electrical Supplies',
                        tags: ['electrical', 'wire', 'copper'],
                        isFeatured: false
                    }
                ]
            },
            {
                firstName: 'Priya',
                lastName: 'Thapa',
                email: 'priya.thapa@eliteconstruction.com',
                password: 'supplier123',
                phone: '+9779823456789',
                role: 'supplier',
                businessName: 'Elite Construction Supplies',
                businessDescription: 'Trusted supplier of bricks, pipes, and plumbing materials with 15+ years of experience.',
                businessAddress: 'Pokhara, Nepal',
                businessLicense: 'LIC987654321',
                addresses: [{
                    label: 'work',
                    fullName: 'Priya Thapa',
                    phone: '+9779823456789',
                    addressLine1: '456 Commercial Zone',
                    city: 'Pokhara',
                    state: 'Gandaki',
                    postalCode: '33700',
                    country: 'Nepal',
                    isDefault: true
                }],
                products: [
                    {
                        title: 'Red Clay Bricks',
                        description: 'Traditional red clay bricks for construction',
                        price: 12,
                        stock: 50000,
                        sku: 'BRICK-RED-004',
                        category: 'Building Materials',
                        tags: ['bricks', 'clay', 'traditional'],
                        isFeatured: true
                    },
                    {
                        title: 'PVC Drainage Pipes',
                        description: 'Durable PVC pipes for drainage and plumbing',
                        price: 180,
                        stock: 1000,
                        sku: 'PVC-PIPE-4IN-005',
                        category: 'Plumbing Materials',
                        tags: ['pipes', 'pvc', 'drainage'],
                        isFeatured: true
                    },
                    {
                        title: 'Ceramic Floor Tiles',
                        description: 'High-quality ceramic tiles for flooring',
                        price: 250,
                        stock: 2000,
                        sku: 'TILE-CERAMIC-006',
                        category: 'Building Materials',
                        tags: ['tiles', 'ceramic', 'flooring'],
                        isFeatured: false
                    }
                ]
            }
        ];

        console.log('🏢 Adding Real Suppliers...\n');

        for (const supplierData of realSuppliers) {
            try {
                // Check if supplier already exists
                const existingSupplier = await User.findOne({ email: supplierData.email });
                if (existingSupplier) {
                    console.log(`⚠️  Supplier ${supplierData.businessName} already exists, skipping...`);
                    continue;
                }

                // Create supplier user
                const supplier = new User({
                    firstName: supplierData.firstName,
                    lastName: supplierData.lastName,
                    email: supplierData.email,
                    password: supplierData.password,
                    phone: supplierData.phone,
                    role: supplierData.role,
                    businessName: supplierData.businessName,
                    businessDescription: supplierData.businessDescription,
                    businessAddress: supplierData.businessAddress,
                    businessLicense: supplierData.businessLicense,
                    addresses: supplierData.addresses,
                    isEmailVerified: true,
                    isActive: true
                });

                await supplier.save();
                console.log(`✅ Created supplier: ${supplier.businessName}`);

                // Get category references
                const categories = {};
                for (const product of supplierData.products) {
                    if (!categories[product.category]) {
                        let category = await Category.findOne({ name: product.category });
                        if (!category) {
                            category = new Category({
                                name: product.category,
                                description: `${product.category} for construction`,
                                isActive: true
                            });
                            await category.save();
                            console.log(`📁 Created category: ${product.category}`);
                        }
                        categories[product.category] = category;
                    }
                }

                // Add products for this supplier
                for (const productData of supplierData.products) {
                    const category = categories[productData.category];

                    const product = new Product({
                        title: productData.title,
                        description: productData.description,
                        price: productData.price,
                        stock: productData.stock,
                        sku: productData.sku,
                        category: category._id,
                        supplier: supplier._id,
                        tags: productData.tags,
                        status: 'active',
                        isFeatured: productData.isFeatured,
                        images: [{
                            url: `/uploads/products/${productData.sku.toLowerCase()}.jpg`,
                            alt: productData.title,
                            isPrimary: true
                        }]
                    });

                    await product.save();
                    console.log(`   📦 Added product: ${product.title} - NPR ${product.price}`);
                }

                console.log(`🎉 Supplier ${supplier.businessName} onboarded with ${supplierData.products.length} products\n`);

            } catch (error) {
                console.error(`❌ Error adding supplier ${supplierData.businessName}:`, error.message);
            }
        }

        // Summary
        const totalSuppliers = await User.countDocuments({ role: 'supplier' });
        const totalProducts = await Product.countDocuments({ status: 'active' });
        const totalCategories = await Category.countDocuments({ isActive: true });

        console.log('📊 Onboarding Summary:');
        console.log('========================');
        console.log(`🏢 Total Suppliers: ${totalSuppliers}`);
        console.log(`📦 Total Products: ${totalProducts}`);
        console.log(`📁 Total Categories: ${totalCategories}`);

        console.log('\n🔑 Supplier Login Credentials:');
        console.log('===============================');
        realSuppliers.forEach(supplier => {
            console.log(`${supplier.businessName}:`);
            console.log(`  Email: ${supplier.email}`);
            console.log(`  Password: ${supplier.password}`);
            console.log(`  Products: ${supplier.products.length}`);
            console.log('');
        });

        console.log('🎯 Next Steps:');
        console.log('==============');
        console.log('1. Test supplier login in Flutter app');
        console.log('2. Verify products appear in catalog');
        console.log('3. Test order fulfillment workflow');
        console.log('4. Add more suppliers using this script');

        await mongoose.disconnect();
        console.log('\n✅ Supplier onboarding completed!');

    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Template for adding new suppliers
const newSupplierTemplate = {
    firstName: 'Supplier',
    lastName: 'Name',
    email: 'supplier@company.com',
    password: 'supplier123',
    phone: '+97798XXXXXXX',
    role: 'supplier',
    businessName: 'Company Name Pvt Ltd',
    businessDescription: 'Brief description of business',
    businessAddress: 'City, Nepal',
    businessLicense: 'LICXXXXXXXXX',
    addresses: [{
        label: 'business',
        fullName: 'Supplier Name',
        phone: '+97798XXXXXXX',
        addressLine1: 'Business Address',
        city: 'City',
        state: 'State',
        postalCode: 'XXXXX',
        country: 'Nepal',
        isDefault: true
    }],
    products: [
        {
            title: 'Product Name',
            description: 'Product description',
            price: 100,
            stock: 1000,
            sku: 'SKU-XXX-001',
            category: 'Building Materials',
            tags: ['tag1', 'tag2'],
            isFeatured: false
        }
        // Add more products...
    ]
};

if (require.main === module) {
    console.log('🏢 InduLink Real Supplier Onboarding\n');
    addRealSuppliers();
}

module.exports = { addRealSuppliers, newSupplierTemplate };