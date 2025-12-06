#!/usr/bin/env node

/**
 * Basic Data Seeder for Testing
 * Creates minimal essential data for testing APIs and Flutter screens
 */

const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('./models/User');
const Category = require('./models/Category');
const Product = require('./models/Product');
const Order = require('./models/Order');
const Cart = require('./models/Cart');
const Review = require('./models/Review');

async function seedBasicData() {
  try {
    console.log('🌱 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/indulink');
    console.log('✅ Connected to MongoDB');

    // Clear existing data (only if collections exist and are small)
    console.log('🧹 Checking existing data...');

    const userCount = await User.countDocuments();
    const categoryCount = await Category.countDocuments();
    const productCount = await Product.countDocuments();

    console.log(`Found: ${userCount} users, ${categoryCount} categories, ${productCount} products`);

    // Only clear if there's minimal data (to avoid deleting important data)
    if (userCount < 10 && categoryCount < 10 && productCount < 20) {
      console.log('🧹 Clearing existing collections...');
      await User.deleteMany({});
      await Category.deleteMany({});
      await Product.deleteMany({});
      await Order.deleteMany({});
      await Cart.deleteMany({});
      await Review.deleteMany({});
      console.log('✅ Collections cleared');
    } else {
      console.log('⚠️  Database has existing data, skipping clear operation');
    }

    // Seed Categories
    console.log('📁 Seeding categories...');
    const categories = await Category.insertMany([
      {
        name: 'Building Materials',
        slug: 'building-materials',
        description: 'Construction materials for buildings',
        image: '/uploads/categories/building-materials.jpg',
        isActive: true
      },
      {
        name: 'Electrical Supplies',
        slug: 'electrical-supplies',
        description: 'Wires, cables, and electrical components',
        image: '/uploads/categories/electrical.jpg',
        isActive: true
      },
      {
        name: 'Plumbing Materials',
        slug: 'plumbing-materials',
        description: 'Pipes, fittings, and plumbing accessories',
        image: '/uploads/categories/plumbing.jpg',
        isActive: true
      }
    ]);
    console.log(`✅ Seeded ${categories.length} categories`);

    // Seed Users (using create() to trigger pre-save hooks for password hashing)
    console.log('👥 Seeding users...');
    const usersData = [
      {
        firstName: 'Admin',
        lastName: 'User',
        email: 'admin@indulink.com',
        password: 'admin123',
        phone: '+9779800000000',
        role: 'admin',
        isActive: true,
        isEmailVerified: true
      },
      {
        firstName: 'John',
        lastName: 'Customer',
        email: 'customer1@indulink.com',
        password: 'customer123',
        phone: '+9779811111111',
        role: 'customer',
        isActive: true,
        isEmailVerified: true
      },
      {
        firstName: 'Jane',
        lastName: 'Customer',
        email: 'customer2@indulink.com',
        password: 'customer123',
        phone: '+9779822222222',
        role: 'customer',
        isActive: true,
        isEmailVerified: true
      },
      {
        firstName: 'Global',
        lastName: 'Builders',
        email: 'supplier1@indulink.com',
        password: 'supplier123',
        phone: '+9779833333333',
        role: 'supplier',
        businessName: 'Global Builders Pvt Ltd',
        businessDescription: 'Premium construction materials supplier',
        businessAddress: 'Kathmandu, Nepal',
        businessRegistrationNumber: '123456789',
        isActive: true,
        isEmailVerified: true
      },
      {
        firstName: 'Elite',
        lastName: 'Construction',
        email: 'supplier2@indulink.com',
        password: 'supplier123',
        phone: '+9779844444444',
        role: 'supplier',
        businessName: 'Elite Construction Supplies',
        businessDescription: 'Quality building materials at competitive prices',
        businessAddress: 'Pokhara, Nepal',
        businessRegistrationNumber: '987654321',
        isActive: true,
        isEmailVerified: true
      }
    ];

    // Use create() instead of insertMany() to trigger pre-save middleware for password hashing
    const users = await User.create(usersData);
    console.log(`✅ Seeded ${users.length} users`);

    // Seed Products
    console.log('🏗️ Seeding products...');
    const suppliers = users.filter(u => u.role === 'supplier');

    const products = await Product.insertMany([
      {
        title: 'Premium Cement',
        description: 'High-quality Portland cement for construction',
        price: 650,
        compareAtPrice: 720,
        stock: 1000,
        sku: 'CEM-PRE-001',
        unit: 'bag',
        weight: { value: 50, unit: 'kg' },
        barcodes: ['8901234567890'],
        supplier: suppliers[0]._id,
        category: categories[0]._id,
        images: [{
          url: '/uploads/products/cement.jpg',
          alt: 'Premium Cement',
          isPrimary: true
        }],
        tags: ['construction', 'building', 'cement'],
        status: 'active',
        isFeatured: true
      },
      {
        title: 'Steel Rebar',
        description: 'Grade 60 steel reinforcement bars',
        price: 85,
        compareAtPrice: 95,
        stock: 500,
        sku: 'REB-STE-002',
        unit: 'kg',
        weight: { value: 12, unit: 'kg' },
        barcodes: ['8901234567891'],
        supplier: suppliers[0]._id,
        category: categories[0]._id,
        images: [{
          url: '/uploads/products/rebar.jpg',
          alt: 'Steel Rebar',
          isPrimary: true
        }],
        tags: ['construction', 'steel', 'rebar'],
        status: 'active',
        isFeatured: false
      },
      {
        title: 'Red Clay Bricks',
        description: 'High-quality red clay bricks for construction',
        price: 12,
        compareAtPrice: 15,
        stock: 10000,
        sku: 'BRI-RED-003',
        unit: 'piece',
        weight: { value: 3, unit: 'kg' },
        barcodes: ['8901234567892'],
        supplier: suppliers[1]._id,
        category: categories[0]._id,
        images: [{
          url: '/uploads/products/bricks.jpg',
          alt: 'Red Clay Bricks',
          isPrimary: true
        }],
        tags: ['construction', 'bricks', 'clay'],
        status: 'active',
        isFeatured: true
      },
      {
        title: 'Electrical Wire',
        description: 'Copper electrical wire for residential wiring',
        price: 450,
        compareAtPrice: 500,
        stock: 200,
        sku: 'WIR-COP-004',
        unit: 'roll',
        weight: { value: 5, unit: 'kg' },
        barcodes: ['8901234567893'],
        supplier: suppliers[0]._id,
        category: categories[1]._id,
        images: [{
          url: '/uploads/products/wire.jpg',
          alt: 'Electrical Wire',
          isPrimary: true
        }],
        tags: ['electrical', 'wire', 'copper'],
        status: 'active',
        isFeatured: false
      },
      {
        title: 'PVC Pipes',
        description: 'Durable PVC pipes for plumbing',
        price: 180,
        compareAtPrice: 200,
        stock: 300,
        sku: 'PVC-PIPE-005',
        unit: 'meter',
        weight: { value: 2, unit: 'kg' },
        barcodes: ['8901234567894'],
        supplier: suppliers[1]._id,
        category: categories[2]._id,
        images: [{
          url: '/uploads/products/pvc-pipes.jpg',
          alt: 'PVC Pipes',
          isPrimary: true
        }],
        tags: ['plumbing', 'pipes', 'pvc'],
        status: 'active',
        isFeatured: true
      }
    ]);
    console.log(`✅ Seeded ${products.length} products`);

    // Seed Orders
    console.log('📋 Seeding orders...');
    const customers = users.filter(u => u.role === 'customer');

    const orders = await Order.insertMany([
      {
        orderNumber: 'ORD-100001',
        customer: customers[0]._id,
        supplier: suppliers[0]._id, // Required field
        items: [{
          product: products[0]._id,
          quantity: 10,
          price: products[0].price,
          subtotal: products[0].price * 10
        }],
        subtotal: products[0].price * 10, // Required field
        tax: 0, // Required field
        shippingCost: 500, // Required field
        total: products[0].price * 10 + 500,
        status: 'delivered',
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'paid',
        shippingAddress: {
          street: '123 Main Street',
          city: 'Kathmandu',
          state: 'Bagmati',
          postalCode: '44600',
          country: 'Nepal'
        }
      },
      {
        orderNumber: 'ORD-100002',
        customer: customers[1]._id,
        supplier: suppliers[1]._id, // Required field
        items: [{
          product: products[2]._id,
          quantity: 500,
          price: products[2].price,
          subtotal: products[2].price * 500
        }],
        subtotal: products[2].price * 500, // Required field
        tax: 0, // Required field
        shippingCost: 1000, // Required field
        total: products[2].price * 500 + 1000,
        status: 'processing',
        paymentMethod: 'cash_on_delivery',
        paymentStatus: 'pending',
        shippingAddress: {
          street: '456 Construction Road',
          city: 'Pokhara',
          state: 'Gandaki',
          postalCode: '33700',
          country: 'Nepal'
        }
      }
    ]);
    console.log(`✅ Seeded ${orders.length} orders`);

    // Seed Reviews
    console.log('⭐ Seeding reviews...');
    const reviews = await Review.insertMany([
      {
        product: products[0]._id,
        customer: customers[0]._id,
        title: 'Excellent Quality',
        comment: 'Great cement, perfect for our construction project. Highly recommended!',
        rating: 5
      },
      {
        product: products[2]._id,
        customer: customers[1]._id,
        title: 'Good Value',
        comment: 'Good quality bricks at reasonable price. Delivery was on time.',
        rating: 4
      }
    ]);
    console.log(`✅ Seeded ${reviews.length} reviews`);

    // Summary
    console.log('\n📊 Database Seeding Summary:');
    console.log('='.repeat(50));
    console.log(`👥 Users: ${users.length} (Admin: 1, Customers: 2, Suppliers: 2)`);
    console.log(`📁 Categories: ${categories.length}`);
    console.log(`🏗️ Products: ${products.length}`);
    console.log(`📋 Orders: ${orders.length}`);
    console.log(`⭐ Reviews: ${reviews.length}`);

    console.log('\n🔑 Test Credentials:');
    console.log('Admin: admin@indulink.com / admin123');
    console.log('Customer: customer1@indulink.com / customer123');
    console.log('Supplier: supplier1@indulink.com / supplier123');

    console.log('\n🎉 Basic data seeding completed successfully!');

  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('📪 Disconnected from MongoDB');
  }
}

if (require.main === module) {
  seedBasicData();
}

module.exports = { seedBasicData };