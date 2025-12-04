#!/usr/bin/env node

/**
 * Comprehensive Service Testing Script
 * Tests all backend services to ensure they are working properly
 */

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const supertest = require('supertest');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

// Import your app
const app = require('./server');

let mongoServer;
let server;
let request;

async function setupTestEnvironment() {
    console.log('🚀 Setting up test environment...');

    // Start in-memory MongoDB
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();

    // Connect to test database
    await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
    });

    // Start the server
    server = app.listen(3001, () => {
        console.log('✅ Test server started on port 3001');
    });

    request = supertest(server);
}

async function teardownTestEnvironment() {
    console.log('🧹 Cleaning up test environment...');

    if (server) {
        server.close();
    }

    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
    await mongoServer.stop();
}

async function testAuthService() {
    console.log('\n🔐 Testing Authentication Service...');

    try {
        // Test user registration
        const registerResponse = await request
            .post('/api/auth/register')
            .send({
                firstName: 'Test',
                lastName: 'User',
                email: 'test@example.com',
                password: 'password123',
                phone: '+9779800000000',
                role: 'customer'
            });

        console.log(`   📝 Registration: ${registerResponse.status === 201 ? '✅' : '❌'} (${registerResponse.status})`);

        if (registerResponse.status === 201) {
            // Test login
            const loginResponse = await request
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'password123',
                    role: 'customer'
                });

            console.log(`   🔑 Login: ${loginResponse.status === 200 ? '✅' : '❌'} (${loginResponse.status})`);

            if (loginResponse.status === 200) {
                const token = loginResponse.body.data?.token;
                return token;
            }
        }
    } catch (error) {
        console.log(`   ❌ Auth Service Error: ${error.message}`);
    }
    return null;
}

async function testProductService(token) {
    console.log('\n📦 Testing Product Service...');

    try {
        // Test get products
        const productsResponse = await request
            .get('/api/products')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📋 Get Products: ${productsResponse.status === 200 ? '✅' : '❌'} (${productsResponse.status})`);

        // Test get categories
        const categoriesResponse = await request
            .get('/api/categories')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📂 Get Categories: ${categoriesResponse.status === 200 ? '✅' : '❌'} (${categoriesResponse.status})`);

    } catch (error) {
        console.log(`   ❌ Product Service Error: ${error.message}`);
    }
}

async function testCartService(token) {
    console.log('\n🛒 Testing Cart Service...');

    try {
        // Test get cart
        const cartResponse = await request
            .get('/api/cart')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📋 Get Cart: ${cartResponse.status === 200 ? '✅' : '❌'} (${cartResponse.status})`);

    } catch (error) {
        console.log(`   ❌ Cart Service Error: ${error.message}`);
    }
}

async function testOrderService(token) {
    console.log('\n📋 Testing Order Service...');

    try {
        // Test get orders
        const ordersResponse = await request
            .get('/api/orders')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📋 Get Orders: ${ordersResponse.status === 200 ? '✅' : '❌'} (${ordersResponse.status})`);

    } catch (error) {
        console.log(`   ❌ Order Service Error: ${error.message}`);
    }
}

async function testRFQService(token) {
    console.log('\n📄 Testing RFQ Service...');

    try {
        // Test get RFQs
        const rfqResponse = await request
            .get('/api/rfq')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📋 Get RFQs: ${rfqResponse.status === 200 ? '✅' : '❌'} (${rfqResponse.status})`);

    } catch (error) {
        console.log(`   ❌ RFQ Service Error: ${error.message}`);
    }
}

async function testDashboardService(token) {
    console.log('\n📊 Testing Dashboard Service...');

    try {
        // Test supplier dashboard
        const dashboardResponse = await request
            .get('/api/supplier/dashboard')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📊 Get Dashboard: ${dashboardResponse.status === 200 || dashboardResponse.status === 403 ? '✅' : '❌'} (${dashboardResponse.status})`);

    } catch (error) {
        console.log(`   ❌ Dashboard Service Error: ${error.message}`);
    }
}

async function testNotificationService(token) {
    console.log('\n🔔 Testing Notification Service...');

    try {
        // Test get notifications
        const notificationsResponse = await request
            .get('/api/notifications')
            .set('Authorization', `Bearer ${token}`);

        console.log(`   📋 Get Notifications: ${notificationsResponse.status === 200 ? '✅' : '❌'} (${notificationsResponse.status})`);

    } catch (error) {
        console.log(`   ❌ Notification Service Error: ${error.message}`);
    }
}

async function runServiceTests() {
    console.log('🧪 Starting Comprehensive Service Tests...\n');

    let token = null;

    try {
        // Test Authentication
        token = await testAuthService();

        if (token) {
            // Test all other services with authentication
            await testProductService(token);
            await testCartService(token);
            await testOrderService(token);
            await testRFQService(token);
            await testDashboardService(token);
            await testNotificationService(token);
        } else {
            console.log('\n❌ Cannot test other services without authentication token');
        }

        console.log('\n🎉 Service testing completed!');

    } catch (error) {
        console.error('❌ Test execution failed:', error);
    }
}

// Main execution
async function main() {
    try {
        await setupTestEnvironment();
        await runServiceTests();
    } catch (error) {
        console.error('❌ Test setup failed:', error);
    } finally {
        await teardownTestEnvironment();
        process.exit(0);
    }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🛑 Received SIGINT, shutting down gracefully...');
    await teardownTestEnvironment();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
    await teardownTestEnvironment();
    process.exit(0);
});

// Run the tests
if (require.main === module) {
    main();
}

module.exports = { runServiceTests };