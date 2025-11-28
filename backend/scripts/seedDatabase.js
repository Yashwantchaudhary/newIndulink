require('dotenv').config();
const mongoose = require('mongoose');
const connectDatabase = require('../config/database');
const SampleDataUtils = require('./sampleDataUtils');

// Import models
const User = require('../models/User');
const Category = require('../models/Category');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Review = require('../models/Review');
const Notification = require('../models/Notification');

class DatabaseSeeder {
    constructor() {
        this.users = [];
        this.categories = [];
        this.products = [];
        this.orders = [];
        this.reviews = [];
        this.notifications = [];
    }

    async connect() {
        await connectDatabase();
        console.log('🔄 Connected to database for seeding...');
    }

    async clearDatabase() {
        console.log('🧹 Clearing existing data...');

        await Promise.all([
            User.deleteMany({}),
            Category.deleteMany({}),
            Product.deleteMany({}),
            Order.deleteMany({}),
            Review.deleteMany({}),
            Notification.deleteMany({})
        ]);

        console.log('✅ Database cleared successfully');
    }

    async seedUsers() {
        console.log('👥 Seeding users...');

        // Create admin users
        const adminUsers = SampleDataUtils.generateUsers(2, 'admin');
        adminUsers[0].firstName = 'Super';
        adminUsers[0].lastName = 'Admin';
        adminUsers[0].email = 'admin@indulink.com';
        adminUsers[1].firstName = 'System';
        adminUsers[1].lastName = 'Administrator';
        adminUsers[1].email = 'sysadmin@indulink.com';

        // Create customers
        const customers = SampleDataUtils.generateUsers(5, 'customer');

        // Create suppliers
        const suppliers = SampleDataUtils.generateUsers(3, 'supplier');

        // Insert all users
        const allUsers = [...adminUsers, ...customers, ...suppliers];
        this.users = await User.insertMany(allUsers);

        console.log(`✅ Created ${this.users.length} users (${adminUsers.length} admins, ${customers.length} customers, ${suppliers.length} suppliers)`);

        return {
            admins: this.users.filter(u => u.role === 'admin'),
            customers: this.users.filter(u => u.role === 'customer'),
            suppliers: this.users.filter(u => u.role === 'supplier')
        };
    }

    async seedCategories() {
        console.log('📂 Seeding categories...');

        const categories = SampleDataUtils.generateCategories();
        this.categories = await Category.insertMany(categories);

        // Update parent references for subcategories
        const mainCategories = this.categories.filter(cat => cat.level === 0);
        const subCategories = this.categories.filter(cat => cat.level === 1);

        for (const subCat of subCategories) {
            // Find parent by name pattern (subcategory names are unique within their domain)
            const parent = mainCategories.find(mainCat =>
                subCat.name.includes(mainCat.name.split(' ')[0]) ||
                ['Electronics', 'Clothing', 'Home & Garden', 'Sports & Outdoors', 'Books & Media', 'Health & Beauty', 'Automotive', 'Toys & Games']
                    .some(keyword => subCat.name.includes(keyword.split(' ')[0]))
            );
            if (parent) {
                await Category.findByIdAndUpdate(subCat._id, { parent: parent._id });
            }
        }

        // Refresh categories with updated parent references
        this.categories = await Category.find({});

        console.log(`✅ Created ${this.categories.length} categories (${mainCategories.length} main, ${subCategories.length} subcategories)`);

        return this.categories;
    }

    async seedProducts() {
        console.log('📦 Seeding products...');

        const suppliers = this.users.filter(u => u.role === 'supplier');
        const products = SampleDataUtils.generateProducts(this.categories, suppliers, 20);

        this.products = await Product.insertMany(products);

        // Update category product counts
        await this.updateCategoryProductCounts();

        console.log(`✅ Created ${this.products.length} products`);

        return this.products;
    }

    async seedOrders() {
        console.log('🛒 Seeding orders...');

        const customers = this.users.filter(u => u.role === 'customer');
        const suppliers = this.users.filter(u => u.role === 'supplier');

        const orders = SampleDataUtils.generateOrders(customers, this.products, suppliers, 10);
        this.orders = await Order.insertMany(orders);

        console.log(`✅ Created ${this.orders.length} orders`);

        return this.orders;
    }

    async seedReviews() {
        console.log('⭐ Seeding reviews...');

        const customers = this.users.filter(u => u.role === 'customer');
        const reviews = SampleDataUtils.generateReviews(customers, this.products, this.orders, 15);

        this.reviews = await Review.insertMany(reviews);

        console.log(`✅ Created ${this.reviews.length} reviews`);

        return this.reviews;
    }

    async seedNotifications() {
        console.log('🔔 Seeding notifications...');

        const notifications = SampleDataUtils.generateNotifications(this.users, this.orders, this.products, 20);
        this.notifications = await Notification.insertMany(notifications);

        console.log(`✅ Created ${this.notifications.length} notifications`);

        return this.notifications;
    }

    async updateCategoryProductCounts() {
        console.log('🔄 Updating category product counts...');

        for (const category of this.categories) {
            const productCount = await Product.countDocuments({ category: category._id });
            await Category.findByIdAndUpdate(category._id, { productCount });
        }

        console.log('✅ Category product counts updated');
    }

    async seedAll() {
        try {
            console.log('🌱 Starting database seeding process...\n');

            await this.connect();
            await this.clearDatabase();

            // Seed in order of dependencies
            const { customers, suppliers } = await this.seedUsers();
            await this.seedCategories();
            await this.seedProducts();
            await this.seedOrders();
            await this.seedReviews();
            await this.seedNotifications();

            console.log('\n🎉 Database seeding completed successfully!');
            console.log('📊 Summary:');
            console.log(`   👥 Users: ${this.users.length}`);
            console.log(`   📂 Categories: ${this.categories.length}`);
            console.log(`   📦 Products: ${this.products.length}`);
            console.log(`   🛒 Orders: ${this.orders.length}`);
            console.log(`   ⭐ Reviews: ${this.reviews.length}`);
            console.log(`   🔔 Notifications: ${this.notifications.length}`);

        } catch (error) {
            console.error('❌ Error during seeding:', error);
            throw error;
        } finally {
            await mongoose.connection.close();
            console.log('🔌 Database connection closed');
        }
    }

    // Individual seeding methods for API endpoints
    async seedUsersOnly() {
        await this.connect();
        const result = await this.seedUsers();
        await mongoose.connection.close();
        return result;
    }

    async seedCategoriesOnly() {
        await this.connect();
        const result = await this.seedCategories();
        await mongoose.connection.close();
        return result;
    }

    async seedProductsOnly() {
        await this.connect();
        await this.seedCategories(); // Ensure categories exist
        const suppliers = await User.find({ role: 'supplier' });
        if (suppliers.length === 0) {
            await this.seedUsers(); // Ensure suppliers exist
        }
        const result = await this.seedProducts();
        await mongoose.connection.close();
        return result;
    }

    async seedOrdersOnly() {
        await this.connect();
        const customers = await User.find({ role: 'customer' });
        const suppliers = await User.find({ role: 'supplier' });
        const products = await Product.find({});

        if (customers.length === 0 || suppliers.length === 0 || products.length === 0) {
            console.log('⚠️  Missing dependencies. Seeding users and products first...');
            await this.seedUsers();
            await this.seedCategories();
            await this.seedProducts();
        }

        const result = await this.seedOrders();
        await mongoose.connection.close();
        return result;
    }

    async seedReviewsOnly() {
        await this.connect();
        const customers = await User.find({ role: 'customer' });
        const products = await Product.find({});
        const orders = await Order.find({});

        if (customers.length === 0 || products.length === 0 || orders.length === 0) {
            console.log('⚠️  Missing dependencies. Seeding required data first...');
            await this.seedUsers();
            await this.seedCategories();
            await this.seedProducts();
            await this.seedOrders();
        }

        const result = await this.seedReviews();
        await mongoose.connection.close();
        return result;
    }

    async seedNotificationsOnly() {
        await this.connect();
        const users = await User.find({});
        const orders = await Order.find({});
        const products = await Product.find({});

        if (users.length === 0) {
            await this.seedUsers();
        }
        if (orders.length === 0) {
            await this.seedOrders();
        }
        if (products.length === 0) {
            await this.seedProducts();
        }

        const result = await this.seedNotifications();
        await mongoose.connection.close();
        return result;
    }
}

// CLI execution
if (require.main === module) {
    const seeder = new DatabaseSeeder();

    // Check for command line arguments
    const args = process.argv.slice(2);
    if (args.length > 0) {
        const command = args[0];
        switch (command) {
            case 'users':
                seeder.seedUsersOnly().catch(console.error);
                break;
            case 'categories':
                seeder.seedCategoriesOnly().catch(console.error);
                break;
            case 'products':
                seeder.seedProductsOnly().catch(console.error);
                break;
            case 'orders':
                seeder.seedOrdersOnly().catch(console.error);
                break;
            case 'reviews':
                seeder.seedReviewsOnly().catch(console.error);
                break;
            case 'notifications':
                seeder.seedNotificationsOnly().catch(console.error);
                break;
            default:
                console.log('Usage: node seedDatabase.js [users|categories|products|orders|reviews|notifications]');
                console.log('Or run without arguments to seed everything');
                process.exit(1);
        }
    } else {
        seeder.seedAll().catch(console.error);
    }
}

module.exports = DatabaseSeeder;