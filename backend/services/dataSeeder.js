/**
 * 🌱 Database Seeder Service
 * Populates MongoDB with realistic test data for development and testing
 */

const User = require('../models/User');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Notification = require('../models/Notification');
const Review = require('../models/Review');
const Wishlist = require('../models/Wishlist');
const Address = require('../models/Address');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const RFQ = require('../models/RFQ');
const Badge = require('../models/Badge');

class DataSeeder {
    constructor() {
        this.models = {
            User, Product, Category, Order, Cart, Notification,
            Review, Wishlist, Address, Conversation, Message, RFQ, Badge
        };
    }

    /**
     * Seed all data collections
     */
    async seedAll() {
        console.log('🌱 Starting database seeding process...');

        try {
            // Clear existing data (optional - can be disabled for production)
            await this.clearCollections();

            // Seed data in logical order
            await this.seedCategories();
            await this.seedUsers();
            await this.seedProducts();
            await this.seedAddresses();
            await this.seedCarts();
            await this.seedWishlists();
            await this.seedOrders();
            await this.seedReviews();
            await this.seedNotifications();
            await this.seedConversations();
            await this.seedRFQs();
            await this.seedBadges();

            console.log('✅ Database seeding completed successfully!');
            console.log('📊 Seeded data summary:');
            console.log(`   - Users: ${await User.countDocuments()}`);
            console.log(`   - Products: ${await Product.countDocuments()}`);
            console.log(`   - Categories: ${await Category.countDocuments()}`);
            console.log(`   - Orders: ${await Order.countDocuments()}`);
            console.log(`   - Reviews: ${await Review.countDocuments()}`);

            return {
                success: true,
                message: 'Database seeded successfully',
                counts: {
                    users: await User.countDocuments(),
                    products: await Product.countDocuments(),
                    categories: await Category.countDocuments(),
                    orders: await Order.countDocuments(),
                    reviews: await Review.countDocuments()
                }
            };
        } catch (error) {
            console.error('❌ Database seeding failed:', error);
            return {
                success: false,
                message: 'Database seeding failed',
                error: error.message
            };
        }
    }

    /**
     * Clear all collections (for development only)
     */
    async clearCollections() {
        if (process.env.NODE_ENV === 'production') {
            console.log('⚠️  Skipping collection clearing in production environment');
            return;
        }

        console.log('🧹 Clearing existing collections...');

        const collections = Object.keys(this.models);
        for (const modelName of collections) {
            try {
                await this.models[modelName].deleteMany({});
                console.log(`   ✅ Cleared ${modelName}`);
            } catch (error) {
                console.error(`   ❌ Error clearing ${modelName}:`, error.message);
            }
        }
    }

    /**
     * Seed categories
     */
    async seedCategories() {
        const categories = [
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
            },
            {
                name: 'Hardware & Tools',
                slug: 'hardware-tools',
                description: 'Nails, screws, power tools, and hand tools',
                image: '/uploads/categories/hardware.jpg',
                isActive: true
            },
            {
                name: 'Painting Supplies',
                slug: 'painting-supplies',
                description: 'Paints, brushes, and painting accessories',
                image: '/uploads/categories/painting.jpg',
                isActive: true
            }
        ];

        await Category.insertMany(categories);
        console.log(`📁 Seeded ${categories.length} categories`);
    }

    /**
     * Seed users (customers, suppliers, admin)
     */
    async seedUsers() {
        const adminUser = await User.create({
            firstName: 'Admin',
            lastName: 'User',
            email: 'admin@indulink.com',
            password: 'admin123',
            phone: '+9779800000000',
            role: 'admin',
            isActive: true,
            isEmailVerified: true
        });

        const supplier1 = await User.create({
            firstName: 'Global',
            lastName: 'Builders',
            email: 'supplier1@indulink.com',
            password: 'supplier123',
            phone: '+9779811111111',
            role: 'supplier',
            businessName: 'Global Builders Pvt Ltd',
            businessDescription: 'Premium construction materials supplier',
            businessAddress: 'Kathmandu, Nepal',
            businessRegistrationNumber: '123456789',
            isActive: true,
            isEmailVerified: true
        });

        const supplier2 = await User.create({
            firstName: 'Elite',
            lastName: 'Construction',
            email: 'supplier2@indulink.com',
            password: 'supplier123',
            phone: '+9779822222222',
            role: 'supplier',
            businessName: 'Elite Construction Supplies',
            businessDescription: 'Quality building materials at competitive prices',
            businessAddress: 'Pokhara, Nepal',
            businessRegistrationNumber: '987654321',
            isActive: true,
            isEmailVerified: true
        });

        // Create 5 sample customers
        const customers = [];
        for (let i = 1; i <= 5; i++) {
            const customer = await User.create({
                firstName: `Customer${i}`,
                lastName: `User${i}`,
                email: `customer${i}@indulink.com`,
                password: 'customer123',
                phone: `+97798${1000000 + i}`,
                role: 'customer',
                isActive: true,
                isEmailVerified: true
            });
            customers.push(customer);
        }

        console.log(`👥 Seeded 1 admin, 2 suppliers, and 5 customers`);
    }

    /**
     * Seed products
     */
    async seedProducts() {
        const categories = await Category.find();
        const suppliers = await User.find({ role: 'supplier' });

        if (categories.length === 0 || suppliers.length === 0) {
            console.log('⚠️  Skipping products - no categories or suppliers found');
            return;
        }

        const products = [];

        // Product templates
        const productTemplates = [
            {
                title: 'Premium Cement',
                description: 'High-quality Portland cement for construction',
                price: 650,
                compareAtPrice: 720,
                stock: 1000,
                sku: 'CEM-PRE-001',
                unit: 'bag',
                weight: { value: 50, unit: 'kg' }
            },
            {
                title: 'Steel Rebar',
                description: 'Grade 60 steel reinforcement bars',
                price: 85,
                compareAtPrice: 95,
                stock: 500,
                sku: 'REB-STE-002',
                unit: 'kg',
                weight: { value: 12, unit: 'kg' }
            },
            {
                title: 'Bricks',
                description: 'Red clay bricks for construction',
                price: 12,
                compareAtPrice: 15,
                stock: 10000,
                sku: 'BRI-RED-003',
                unit: 'piece',
                weight: { value: 3, unit: 'kg' }
            },
            {
                title: 'Sand',
                description: 'Fine river sand for construction',
                price: 1200,
                compareAtPrice: 1500,
                stock: 50,
                sku: 'SAND-FIN-004',
                unit: 'cubic meter',
                weight: { value: 1600, unit: 'kg' }
            },
            {
                title: 'Aggregates',
                description: 'Crushed stone aggregates',
                price: 1800,
                compareAtPrice: 2100,
                stock: 30,
                sku: 'AGG-CRS-005',
                unit: 'cubic meter',
                weight: { value: 1500, unit: 'kg' }
            }
        ];

        // Create products for each supplier
        for (const supplier of suppliers) {
            for (let i = 0; i < 3; i++) {
                const templateIndex = i % productTemplates.length;
                const template = productTemplates[templateIndex];

                const product = await Product.create({
                    ...template,
                    title: `${template.title} - ${supplier.businessName}`,
                    supplier: supplier._id,
                    category: categories[i % categories.length]._id,
                    images: [
                        {
                            url: `/uploads/products/${template.sku.toLowerCase()}.jpg`,
                            alt: template.title,
                            isPrimary: true
                        }
                    ],
                    tags: ['construction', 'building', template.title.toLowerCase().split(' ')[0]],
                    status: 'active',
                    isFeatured: i === 0 // Feature first product of each supplier
                });

                products.push(product);
            }
        }

        console.log(`🏗️ Seeded ${products.length} products`);
    }

    /**
     * Seed addresses
     */
    async seedAddresses() {
        const users = await User.find();

        for (const user of users) {
            if (user.role === 'admin') continue;

            await Address.create({
                user: user._id,
                addressType: 'home',
                street: `${Math.floor(Math.random() * 100) + 1} Main Street`,
                city: user.role === 'supplier' ? 'Kathmandu' : 'Pokhara',
                state: 'Bagmati',
                postalCode: '44600',
                country: 'Nepal',
                isDefault: true
            });
        }

        console.log(`📍 Seeded addresses for all users`);
    }

    /**
     * Seed carts
     */
    async seedCarts() {
        const customers = await User.find({ role: 'customer' });
        const products = await Product.find();

        if (customers.length === 0 || products.length === 0) {
            console.log('⚠️  Skipping carts - no customers or products found');
            return;
        }

        for (const customer of customers) {
            const cartItems = [];

            // Add 1-3 random products to each cart
            const itemCount = Math.floor(Math.random() * 3) + 1;
            const shuffledProducts = [...products].sort(() => 0.5 - Math.random());

            for (let i = 0; i < itemCount; i++) {
                const product = shuffledProducts[i];
                cartItems.push({
                    product: product._id,
                    quantity: Math.floor(Math.random() * 5) + 1,
                    price: product.price
                });
            }

            await Cart.create({
                user: customer._id,
                items: cartItems
            });
        }

        console.log(`🛒 Seeded carts for all customers`);
    }

    /**
     * Seed wishlists
     */
    async seedWishlists() {
        const customers = await User.find({ role: 'customer' });
        const products = await Product.find();

        if (customers.length === 0 || products.length === 0) {
            console.log('⚠️  Skipping wishlists - no customers or products found');
            return;
        }

        for (const customer of customers) {
            const wishlistItems = [];

            // Add 1-5 random products to each wishlist
            const itemCount = Math.floor(Math.random() * 5) + 1;
            const shuffledProducts = [...products].sort(() => 0.5 - Math.random());

            for (let i = 0; i < itemCount; i++) {
                wishlistItems.push({
                    product: shuffledProducts[i]._id,
                    addedAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) // Random date in last 30 days
                });
            }

            await Wishlist.create({
                user: customer._id,
                items: wishlistItems
            });
        }

        console.log(`❤️ Seeded wishlists for all customers`);
    }

    /**
     * Seed orders
     */
    async seedOrders() {
        const customers = await User.find({ role: 'customer' });
        const products = await Product.find();

        if (customers.length === 0 || products.length === 0) {
            console.log('⚠️  Skipping orders - no customers or products found');
            return;
        }

        const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

        for (const customer of customers) {
            // Create 1-3 orders per customer
            const orderCount = Math.floor(Math.random() * 3) + 1;

            for (let i = 0; i < orderCount; i++) {
                const orderItems = [];

                // Add 1-5 items per order
                const itemCount = Math.floor(Math.random() * 5) + 1;
                const shuffledProducts = [...products].sort(() => 0.5 - Math.random());

                let total = 0;

                for (let j = 0; j < itemCount; j++) {
                    const product = shuffledProducts[j];
                    const quantity = Math.floor(Math.random() * 3) + 1;
                    const itemTotal = product.price * quantity;

                    orderItems.push({
                        product: product._id,
                        quantity: quantity,
                        price: product.price,
                        subtotal: itemTotal
                    });

                    total += itemTotal;
                }

                // Random status with delivered being most common
                const statusWeights = [0.1, 0.2, 0.3, 0.35, 0.05]; // Weights for statuses
                let random = Math.random();
                let statusIndex = 0;
                let cumulativeWeight = 0;

                for (let k = 0; k < statusWeights.length; k++) {
                    cumulativeWeight += statusWeights[k];
                    if (random < cumulativeWeight) {
                        statusIndex = k;
                        break;
                    }
                }

                const orderNumber = `ORD-${Math.floor(100000 + Math.random() * 900000)}`;

                await Order.create({
                    orderNumber: orderNumber,
                    customer: customer._id,
                    items: orderItems,
                    total: total,
                    status: statuses[statusIndex],
                    paymentMethod: 'cash_on_delivery',
                    paymentStatus: statusIndex >= 3 ? 'paid' : 'pending',
                    shippingAddress: {
                        street: '123 Delivery Street',
                        city: 'Kathmandu',
                        state: 'Bagmati',
                        postalCode: '44600',
                        country: 'Nepal'
                    },
                    createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000) // Random date in last 90 days
                });
            }
        }

        console.log(`📋 Seeded orders for all customers`);
    }

    /**
     * Seed reviews
     */
    async seedReviews() {
        const customers = await User.find({ role: 'customer' });
        const products = await Product.find();

        if (customers.length === 0 || products.length === 0) {
            console.log('⚠️  Skipping reviews - no customers or products found');
            return;
        }

        const reviewTemplates = [
            {
                title: 'Excellent quality',
                comment: 'Great product, exactly as described. Fast delivery.',
                rating: 5
            },
            {
                title: 'Good value',
                comment: 'Good quality for the price. Would buy again.',
                rating: 4
            },
            {
                title: 'Satisfactory',
                comment: 'Product was okay, delivery took a bit longer than expected.',
                rating: 3
            },
            {
                title: 'Not as expected',
                comment: 'Product quality was not as good as described.',
                rating: 2
            },
            {
                title: 'Poor experience',
                comment: 'Product was damaged and customer service was slow.',
                rating: 1
            }
        ];

        // Create reviews for some products
        const productsToReview = [...products].sort(() => 0.5 - Math.random()).slice(0, 10);

        for (const product of productsToReview) {
            // Each reviewed product gets 1-3 reviews
            const reviewCount = Math.floor(Math.random() * 3) + 1;

            for (let i = 0; i < reviewCount; i++) {
                const templateIndex = Math.floor(Math.random() * reviewTemplates.length);
                const template = reviewTemplates[templateIndex];
                const customer = customers[Math.floor(Math.random() * customers.length)];

                await Review.create({
                    product: product._id,
                    user: customer._id,
                    title: template.title,
                    comment: template.comment,
                    rating: template.rating,
                    createdAt: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000) // Random date in last 60 days
                });
            }
        }

        console.log(`⭐ Seeded reviews for products`);
    }

    /**
     * Seed notifications
     */
    async seedNotifications() {
        const users = await User.find();

        const notificationTypes = [
            {
                type: 'order',
                title: 'Order Update',
                message: 'Your order #ORD12345 has been shipped and is on its way!'
            },
            {
                type: 'system',
                title: 'System Maintenance',
                message: 'Scheduled maintenance on Sunday 10 PM - 12 AM. Brief downtime expected.'
            },
            {
                type: 'promotion',
                title: 'Special Offer',
                message: 'Get 15% off on all cement products this week only!'
            },
            {
                type: 'security',
                title: 'Security Alert',
                message: 'New login detected from a new device. If this was not you, please reset your password.'
            }
        ];

        for (const user of users) {
            // Create 2-5 notifications per user
            const notificationCount = Math.floor(Math.random() * 4) + 2;

            for (let i = 0; i < notificationCount; i++) {
                const templateIndex = Math.floor(Math.random() * notificationTypes.length);
                const template = notificationTypes[templateIndex];

                await Notification.create({
                    userId: user._id,
                    type: template.type,
                    title: template.title,
                    message: template.message,
                    isRead: Math.random() > 0.5, // 50% chance of being read
                    data: {
                        timestamp: new Date(),
                        priority: template.type === 'security' ? 'high' : 'normal'
                    },
                    createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) // Random date in last 30 days
                });
            }
        }

        console.log(`🔔 Seeded notifications for all users`);
    }

    /**
     * Seed conversations and messages
     */
    async seedConversations() {
        const customers = await User.find({ role: 'customer' });
        const suppliers = await User.find({ role: 'supplier' });

        if (customers.length === 0 || suppliers.length === 0) {
            console.log('⚠️  Skipping conversations - no customers or suppliers found');
            return;
        }

        // Create conversations between customers and suppliers
        for (let i = 0; i < Math.min(5, customers.length); i++) {
            const customer = customers[i];
            const supplier = suppliers[i % suppliers.length];

            const conversation = await Conversation.create({
                participants: [customer._id, supplier._id],
                subject: `Inquiry about product #${Math.floor(Math.random() * 1000)}`,
                status: 'open',
                createdAt: new Date(Date.now() - Math.random() * 14 * 24 * 60 * 60 * 1000) // Random date in last 14 days
            });

            // Add 2-5 messages to each conversation
            const messageCount = Math.floor(Math.random() * 4) + 2;

            for (let j = 0; j < messageCount; j++) {
                const sender = j % 2 === 0 ? customer._id : supplier._id;
                const isCustomer = sender.equals(customer._id);

                await Message.create({
                    conversation: conversation._id,
                    sender: sender,
                    content: isCustomer
                        ? `Hello, I have a question about your product. Can you provide more details about the ${j === 0 ? 'specifications' : j === 1 ? 'pricing' : 'delivery options'}?`
                        : `Thank you for your inquiry. Our product has ${j === 0 ? 'premium quality' : j === 1 ? 'competitive pricing' : 'fast delivery options'}. How can I assist you further?`,
                    isRead: Math.random() > 0.3, // 70% chance of being read
                    createdAt: new Date(conversation.createdAt.getTime() + j * 3600000) // Messages spaced 1 hour apart
                });
            }
        }

        console.log(`💬 Seeded conversations and messages`);
    }

    /**
     * Seed RFQs (Request for Quotation)
     */
    async seedRFQs() {
        const customers = await User.find({ role: 'customer' });
        const suppliers = await User.find({ role: 'supplier' });
        const products = await Product.find();

        if (customers.length === 0 || suppliers.length === 0 || products.length === 0) {
            console.log('⚠️  Skipping RFQs - no customers, suppliers, or products found');
            return;
        }

        const rfqStatuses = ['draft', 'sent', 'responded', 'accepted', 'rejected', 'expired'];

        for (let i = 0; i < Math.min(3, customers.length); i++) {
            const customer = customers[i];
            const supplier = suppliers[i % suppliers.length];
            const product = products[Math.floor(Math.random() * products.length)];

            // Create 1-2 RFQs per customer
            const rfqCount = Math.floor(Math.random() * 2) + 1;

            for (let j = 0; j < rfqCount; j++) {
                const statusWeights = [0.1, 0.3, 0.25, 0.2, 0.1, 0.05]; // Weights for statuses
                let random = Math.random();
                let statusIndex = 0;
                let cumulativeWeight = 0;

                for (let k = 0; k < statusWeights.length; k++) {
                    cumulativeWeight += statusWeights[k];
                    if (random < cumulativeWeight) {
                        statusIndex = k;
                        break;
                    }
                }

                const rfqNumber = `RFQ-${Math.floor(10000 + Math.random() * 90000)}`;

                await RFQ.create({
                    rfqNumber: rfqNumber,
                    customer: customer._id,
                    supplier: supplier._id,
                    product: product._id,
                    title: `Request for Quotation: ${product.title}`,
                    description: `Looking for bulk pricing on ${product.title}. Need ${Math.floor(Math.random() * 100) + 50} units.`,
                    quantity: Math.floor(Math.random() * 100) + 50,
                    status: rfqStatuses[statusIndex],
                    expiryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
                    createdAt: new Date(Date.now() - Math.random() * 14 * 24 * 60 * 60 * 1000) // Random date in last 14 days
                });
            }
        }

        console.log(`📝 Seeded RFQs`);
    }

    /**
     * Seed badges/achievements
     */
    async seedBadges() {
        const users = await User.find();

        const badgeTypes = [
            {
                name: 'First Purchase',
                description: 'Made your first purchase',
                type: 'purchase'
            },
            {
                name: 'Loyal Customer',
                description: 'Made 5 or more purchases',
                type: 'purchase'
            },
            {
                name: 'Early Adopter',
                description: 'One of our first 100 customers',
                type: 'membership'
            },
            {
                name: 'Review Contributor',
                description: 'Wrote 3 or more product reviews',
                type: 'community'
            },
            {
                name: 'Top Rated Supplier',
                description: 'Maintained 4.5+ rating as supplier',
                type: 'quality'
            }
        ];

        for (const user of users) {
            // Assign 1-3 badges per user
            const badgeCount = Math.floor(Math.random() * 3) + 1;
            const shuffledBadges = [...badgeTypes].sort(() => 0.5 - Math.random());

            for (let i = 0; i < badgeCount; i++) {
                await Badge.create({
                    user: user._id,
                    name: shuffledBadges[i].name,
                    description: shuffledBadges[i].description,
                    type: shuffledBadges[i].type,
                    awardedAt: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000) // Random date in last 60 days
                });
            }
        }

        console.log(`🏆 Seeded badges for users`);
    }
}

module.exports = new DataSeeder();