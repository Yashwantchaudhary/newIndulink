#!/usr/bin/env node

/**
 * Manual Cart & Order Testing
 * Step-by-step testing of cart and order functionality
 */

const http = require('http');

const API_BASE = 'http://localhost:5000/api';

function makeRequest(method, url, data = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const options = {
            method: method.toUpperCase(),
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };

        const req = http.request(url, options, (res) => {
            let body = '';

            res.on('data', (chunk) => {
                body += chunk;
            });

            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(body);
                    resolve({
                        status: res.statusCode,
                        data: jsonData,
                        headers: res.headers
                    });
                } catch (e) {
                    resolve({
                        status: res.statusCode,
                        data: body,
                        headers: res.headers
                    });
                }
            });
        });

        req.on('error', (err) => {
            resolve({
                status: 'ERROR',
                error: err.message,
                url: url
            });
        });

        if (data && (method.toUpperCase() === 'POST' || method.toUpperCase() === 'PUT')) {
            req.write(JSON.stringify(data));
        }

        req.setTimeout(10000, () => {
            req.destroy();
            resolve({
                status: 'TIMEOUT',
                error: 'Request timeout',
                url: url
            });
        });

        req.end();
    });
}

async function testCartAndOrderManually() {
    console.log('🛒 Manual Cart & Order Testing\n');
    console.log('This test will guide you through the complete e-commerce flow.\n');

    // Step 1: Check if products exist
    console.log('Step 1: Checking Products');
    console.log('==========================');

    const products = await makeRequest('GET', `${API_BASE}/products`);
    if (products.status === 200 && products.data?.data?.length > 0) {
        console.log('✅ Products available:', products.data.data.length);
        products.data.data.forEach((p, i) => {
            console.log(`   ${i + 1}. ${p.title} - NPR ${p.price} (${p.supplier?.businessName || 'Unknown Supplier'})`);
        });
    } else {
        console.log('❌ No products found');
        return;
    }

    // Step 2: Manual Authentication Test
    console.log('\nStep 2: Authentication Test');
    console.log('===========================');
    console.log('Test these credentials manually:');
    console.log('Customer: customer1@indulink.com / customer123');
    console.log('Supplier: supplier1@indulink.com / supplier123');
    console.log('Admin: admin@indulink.com / admin123');

    console.log('\n🔍 Test Commands:');
    console.log('curl -X POST http://localhost:5000/api/auth/login \\');
    console.log('  -H "Content-Type: application/json" \\');
    console.log('  -d \'{"email":"customer1@indulink.com","password":"customer123"}\'');

    // Step 3: Cart Operations
    console.log('\nStep 3: Cart Operations (After Login)');
    console.log('=====================================');

    console.log('After getting JWT token, test cart operations:');
    console.log('');
    console.log('1. Check empty cart:');
    console.log('curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
    console.log('  http://localhost:5000/api/cart');
    console.log('');

    console.log('2. Add product to cart (use product ID from step 1):');
    console.log('curl -X POST http://localhost:5000/api/cart \\');
    console.log('  -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
    console.log('  -H "Content-Type: application/json" \\');
    console.log('  -d \'{"productId":"PRODUCT_ID_HERE","quantity":2}\'');
    console.log('');

    console.log('3. Verify cart has items:');
    console.log('curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
    console.log('  http://localhost:5000/api/cart');

    // Step 4: Order Creation
    console.log('\nStep 4: Order Creation');
    console.log('======================');

    console.log('Create order from cart:');
    console.log('curl -X POST http://localhost:5000/api/orders \\');
    console.log('  -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
    console.log('  -H "Content-Type: application/json" \\');
    console.log('  -d \'{"paymentMethod":"cash_on_delivery","notes":"Test order"}\'');

    // Step 5: Check Order Flow
    console.log('\nStep 5: Order Flow Verification');
    console.log('===============================');

    console.log('1. Customer order history:');
    console.log('curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
    console.log('  http://localhost:5000/api/orders');
    console.log('');

    console.log('2. Supplier order view (login as supplier1@indulink.com):');
    console.log('curl -H "Authorization: Bearer SUPPLIER_JWT_TOKEN" \\');
    console.log('  http://localhost:5000/api/supplier/orders');
    console.log('');

    console.log('3. Admin order management (login as admin@indulink.com):');
    console.log('curl -H "Authorization: Bearer ADMIN_JWT_TOKEN" \\');
    console.log('  http://localhost:5000/api/admin/orders');

    // Step 6: Database Verification
    console.log('\nStep 6: Database Verification');
    console.log('=============================');

    console.log('Check MongoDB collections:');
    console.log('use indulink');
    console.log('db.users.countDocuments()');
    console.log('db.products.countDocuments()');
    console.log('db.carts.countDocuments()');
    console.log('db.orders.countDocuments()');

    // Summary
    console.log('\n🎯 Manual Testing Checklist');
    console.log('===========================');
    console.log('□ Login with customer account');
    console.log('□ Check initial cart (should be empty)');
    console.log('□ Add product to cart');
    console.log('□ Verify cart has the product');
    console.log('□ Create order from cart');
    console.log('□ Check customer order history');
    console.log('□ Login as supplier');
    console.log('□ Check supplier order view');
    console.log('□ Login as admin');
    console.log('□ Check admin order management');
    console.log('□ Update order status as admin');
    console.log('□ Verify cart is empty after order');

    console.log('\n📊 Expected Results:');
    console.log('===================');
    console.log('✅ Cart persists data in MongoDB');
    console.log('✅ Orders create proper relationships');
    console.log('✅ Suppliers see relevant orders');
    console.log('✅ Admin sees all orders');
    console.log('✅ Order status updates work');
    console.log('✅ Cart clears after order creation');

    console.log('\n🚀 Ready for manual testing!');
    console.log('Copy and run the cURL commands above to test the complete flow.');
}

// Check if server is running
async function checkServerRunning() {
    console.log('🔍 Checking if server is running...');

    try {
        const result = await makeRequest('GET', `${API_BASE.replace('/api', '')}/health`);
        if (result.status === 200) {
            console.log('✅ Server is running and healthy');
            return true;
        } else {
            console.log('❌ Server is not responding correctly');
            return false;
        }
    } catch (error) {
        console.log('❌ Cannot connect to server');
        console.log('   Make sure the server is running on port 5000');
        return false;
    }
}

async function main() {
    console.log('🛒 Manual Cart & Order Flow Testing Guide\n');

    const serverRunning = await checkServerRunning();

    if (!serverRunning) {
        console.log('\n❌ Cannot proceed - server is not running');
        process.exit(1);
    }

    console.log('');
    await testCartAndOrderManually();

    console.log('\n🎯 Manual testing guide generated successfully!');
    console.log('💡 Follow the steps above to test your complete e-commerce flow.');
}

if (require.main === module) {
    main();
}

module.exports = { testCartAndOrderManually };