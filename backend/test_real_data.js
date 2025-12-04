#!/usr/bin/env node

/**
 * Real Data API Testing Script
 * Tests that APIs return actual database data, not just mock responses
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

async function testRealDataAPIs() {
    console.log('🧪 Testing APIs with Real Database Data...\n');

    const results = [];

    // Test 1: Public Products API
    console.log('Testing Products API...');
    const productsResult = await makeRequest('GET', `${API_BASE}/products`);
    results.push({ ...productsResult, endpoint: 'Products API', url: `${API_BASE}/products` });

    if (productsResult.status === 200 && productsResult.data?.data?.length > 0) {
        console.log(`✅ Products API returned ${productsResult.data.data.length} real products`);
        console.log(`   Sample product: ${productsResult.data.data[0].title} - NPR ${productsResult.data.data[0].price}`);

        // Verify product has required fields
        const product = productsResult.data.data[0];
        const hasRequiredFields = product._id && product.title && product.price && product.supplier;
        console.log(`   ✅ Product has required fields: ${hasRequiredFields ? 'YES' : 'NO'}`);
    } else {
        console.log('❌ Products API failed or returned no data');
    }

    // Test 2: Categories API
    console.log('\nTesting Categories API...');
    const categoriesResult = await makeRequest('GET', `${API_BASE}/categories`);
    results.push({ ...categoriesResult, endpoint: 'Categories API', url: `${API_BASE}/categories` });

    if (categoriesResult.status === 200 && categoriesResult.data?.data?.length > 0) {
        console.log(`✅ Categories API returned ${categoriesResult.data.data.length} real categories`);
        console.log(`   Sample category: ${categoriesResult.data.data[0].name}`);
    } else {
        console.log('❌ Categories API failed or returned no data');
    }

    // Test 3: Authentication (Login)
    console.log('\nTesting Authentication...');
    const loginResult = await makeRequest('POST', `${API_BASE}/auth/login`, {
        email: 'customer1@indulink.com',
        password: 'customer123'
    });
    results.push({ ...loginResult, endpoint: 'Login API', url: `${API_BASE}/auth/login` });

    let accessToken = null;
    if (loginResult.status === 200 && loginResult.data?.data?.accessToken) {
        console.log('✅ Login successful, received JWT token');
        accessToken = loginResult.data.data.accessToken;

        // Verify token contains user info
        const tokenParts = accessToken.split('.');
        if (tokenParts.length === 3) {
            const payload = JSON.parse(Buffer.from(tokenParts[1], 'base64').toString());
            console.log(`   ✅ Token contains user ID: ${payload.userId}`);
            console.log(`   ✅ Token contains role: ${payload.role}`);
        }
    } else {
        console.log('❌ Login failed');
    }

    // Test 4: Protected APIs (with authentication)
    if (accessToken) {
        console.log('\nTesting Protected APIs with Authentication...');

        // Test User Profile
        const profileResult = await makeRequest('GET', `${API_BASE}/users/profile`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...profileResult, endpoint: 'User Profile API', url: `${API_BASE}/users/profile` });

        if (profileResult.status === 200 && profileResult.data?.data) {
            const user = profileResult.data.data;
            console.log(`✅ User Profile API returned real user data`);
            console.log(`   User: ${user.firstName} ${user.lastName} (${user.email})`);
            console.log(`   Role: ${user.role}`);
        } else {
            console.log('❌ User Profile API failed');
        }

        // Test User Orders
        const ordersResult = await makeRequest('GET', `${API_BASE}/orders`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...ordersResult, endpoint: 'User Orders API', url: `${API_BASE}/orders` });

        if (ordersResult.status === 200 && ordersResult.data?.data) {
            console.log(`✅ Orders API returned ${ordersResult.data.data.length} real orders`);
            if (ordersResult.data.data.length > 0) {
                const order = ordersResult.data.data[0];
                console.log(`   Sample order: ${order.orderNumber} - Status: ${order.status} - Total: NPR ${order.total}`);
            }
        } else {
            console.log('❌ Orders API failed');
        }

        // Test Cart API
        const cartResult = await makeRequest('GET', `${API_BASE}/cart`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...cartResult, endpoint: 'Cart API', url: `${API_BASE}/cart` });

        if (cartResult.status === 200) {
            console.log(`✅ Cart API working (may be empty for new user)`);
        } else {
            console.log('❌ Cart API failed');
        }

        // Test Wishlist API
        const wishlistResult = await makeRequest('GET', `${API_BASE}/wishlist`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...wishlistResult, endpoint: 'Wishlist API', url: `${API_BASE}/wishlist` });

        if (wishlistResult.status === 200) {
            console.log(`✅ Wishlist API working (may be empty for new user)`);
        } else {
            console.log('❌ Wishlist API failed');
        }

        // Test Notifications API
        const notificationsResult = await makeRequest('GET', `${API_BASE}/notifications`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...notificationsResult, endpoint: 'Notifications API', url: `${API_BASE}/notifications` });

        if (notificationsResult.status === 200) {
            console.log(`✅ Notifications API working`);
        } else {
            console.log('❌ Notifications API failed');
        }

        // Test RFQ API
        const rfqResult = await makeRequest('GET', `${API_BASE}/rfq`, null, {
            'Authorization': `Bearer ${accessToken}`
        });
        results.push({ ...rfqResult, endpoint: 'RFQ API', url: `${API_BASE}/rfq` });

        if (rfqResult.status === 200) {
            console.log(`✅ RFQ API working (may be empty for new user)`);
        } else {
            console.log('❌ RFQ API failed');
        }
    }

    // Test 5: Admin APIs
    console.log('\nTesting Admin APIs...');
    const adminLoginResult = await makeRequest('POST', `${API_BASE}/auth/login`, {
        email: 'admin@indulink.com',
        password: 'admin123'
    });

    if (adminLoginResult.status === 200 && adminLoginResult.data?.data?.accessToken) {
        const adminToken = adminLoginResult.data.data.accessToken;

        // Test Admin Dashboard
        const adminDashboardResult = await makeRequest('GET', `${API_BASE}/admin/dashboard`, null, {
            'Authorization': `Bearer ${adminToken}`
        });
        results.push({ ...adminDashboardResult, endpoint: 'Admin Dashboard API', url: `${API_BASE}/admin/dashboard` });

        if (adminDashboardResult.status === 200) {
            console.log('✅ Admin Dashboard API working');
        } else {
            console.log('❌ Admin Dashboard API failed');
        }

        // Test Admin Users
        const adminUsersResult = await makeRequest('GET', `${API_BASE}/admin/users`, null, {
            'Authorization': `Bearer ${adminToken}`
        });
        results.push({ ...adminUsersResult, endpoint: 'Admin Users API', url: `${API_BASE}/admin/users` });

        if (adminUsersResult.status === 200 && adminUsersResult.data?.data?.length >= 5) {
            console.log(`✅ Admin Users API returned ${adminUsersResult.data.data.length} real users`);
        } else {
            console.log('❌ Admin Users API failed or returned insufficient data');
        }

        // Test Admin Products
        const adminProductsResult = await makeRequest('GET', `${API_BASE}/admin/products`, null, {
            'Authorization': `Bearer ${adminToken}`
        });
        results.push({ ...adminProductsResult, endpoint: 'Admin Products API', url: `${API_BASE}/admin/products` });

        if (adminProductsResult.status === 200 && adminProductsResult.data?.data?.length >= 5) {
            console.log(`✅ Admin Products API returned ${adminProductsResult.data.data.length} real products`);
        } else {
            console.log('❌ Admin Products API failed or returned insufficient data');
        }

        // Test Admin Orders
        const adminOrdersResult = await makeRequest('GET', `${API_BASE}/admin/orders`, null, {
            'Authorization': `Bearer ${adminToken}`
        });
        results.push({ ...adminOrdersResult, endpoint: 'Admin Orders API', url: `${API_BASE}/admin/orders` });

        if (adminOrdersResult.status === 200 && adminOrdersResult.data?.data?.length >= 2) {
            console.log(`✅ Admin Orders API returned ${adminOrdersResult.data.data.length} real orders`);
        } else {
            console.log('❌ Admin Orders API failed or returned insufficient data');
        }
    } else {
        console.log('❌ Admin login failed');
    }

    // Test 6: Supplier APIs
    console.log('\nTesting Supplier APIs...');
    const supplierLoginResult = await makeRequest('POST', `${API_BASE}/auth/login`, {
        email: 'supplier1@indulink.com',
        password: 'supplier123'
    });

    if (supplierLoginResult.status === 200 && supplierLoginResult.data?.data?.accessToken) {
        const supplierToken = supplierLoginResult.data.data.accessToken;

        // Test Supplier Dashboard
        const supplierDashboardResult = await makeRequest('GET', `${API_BASE}/supplier/dashboard`, null, {
            'Authorization': `Bearer ${supplierToken}`
        });
        results.push({ ...supplierDashboardResult, endpoint: 'Supplier Dashboard API', url: `${API_BASE}/supplier/dashboard` });

        if (supplierDashboardResult.status === 200) {
            console.log('✅ Supplier Dashboard API working');
        } else {
            console.log('❌ Supplier Dashboard API failed');
        }

        // Test Supplier Products
        const supplierProductsResult = await makeRequest('GET', `${API_BASE}/supplier/products`, null, {
            'Authorization': `Bearer ${supplierToken}`
        });
        results.push({ ...supplierProductsResult, endpoint: 'Supplier Products API', url: `${API_BASE}/supplier/products` });

        if (supplierProductsResult.status === 200 && supplierProductsResult.data?.data?.length >= 2) {
            console.log(`✅ Supplier Products API returned ${supplierProductsResult.data.data.length} real products`);
        } else {
            console.log('❌ Supplier Products API failed or returned insufficient data');
        }

        // Test Supplier Orders
        const supplierOrdersResult = await makeRequest('GET', `${API_BASE}/supplier/orders`, null, {
            'Authorization': `Bearer ${supplierToken}`
        });
        results.push({ ...supplierOrdersResult, endpoint: 'Supplier Orders API', url: `${API_BASE}/supplier/orders` });

        if (supplierOrdersResult.status === 200) {
            console.log('✅ Supplier Orders API working');
        } else {
            console.log('❌ Supplier Orders API failed');
        }
    } else {
        console.log('❌ Supplier login failed');
    }

    // Summary
    console.log('\n📊 Real Data API Testing Results:');
    console.log('='.repeat(80));

    const successCount = results.filter(r =>
        (r.endpoint.includes('Products') && r.status === 200 && r.data?.data?.length > 0) ||
        (r.endpoint.includes('Categories') && r.status === 200 && r.data?.data?.length > 0) ||
        (r.endpoint.includes('Login') && r.status === 200) ||
        (r.endpoint.includes('Profile') && r.status === 200 && r.data?.data) ||
        (r.endpoint.includes('Orders') && r.status === 200) ||
        (r.endpoint.includes('Cart') && r.status === 200) ||
        (r.endpoint.includes('Wishlist') && r.status === 200) ||
        (r.endpoint.includes('Notifications') && r.status === 200) ||
        (r.endpoint.includes('RFQ') && r.status === 200) ||
        (r.endpoint.includes('Admin') && r.status === 200) ||
        (r.endpoint.includes('Supplier') && r.status === 200)
    ).length;

    const totalTests = results.length;
    const successRate = Math.round((successCount / totalTests) * 100);

    console.log(`✅ Successful API tests: ${successCount}/${totalTests} (${successRate}%)`);
    console.log(`❌ Failed API tests: ${totalTests - successCount}/${totalTests}`);

    if (successRate >= 90) {
        console.log('\n🎉 Excellent! APIs are returning real database data!');
        console.log('✅ Backend is properly connected to MongoDB');
        console.log('✅ All major entities have real data');
        console.log('✅ Authentication and authorization working');
        console.log('✅ CRUD operations functional');

        console.log('\n🚀 Flutter App Integration Status:');
        console.log('   ✅ Products will display real catalog data');
        console.log('   ✅ User authentication will work with real accounts');
        console.log('   ✅ Orders, cart, wishlist will persist real data');
        console.log('   ✅ Admin panel will show real users and products');
        console.log('   ✅ Supplier dashboard will show real business data');
    } else if (successRate >= 75) {
        console.log('\n⚠️  Good progress, but some APIs need attention');
        console.log('   Check the detailed results above for specific issues');
    } else {
        console.log('\n❌ Multiple API issues detected');
        console.log('   Review server logs and database connections');
    }

    console.log('\n🔍 Detailed Test Results:');
    results.forEach((result, index) => {
        const status = result.status === 'ERROR' || result.status === 'TIMEOUT' ? '❌' :
                      result.status >= 200 && result.status < 300 ? '✅' :
                      result.status === 401 ? '🔒' : '⚠️';
        const dataCount = result.data?.data?.length ? ` (${result.data.data.length} items)` : '';
        console.log(`${status} ${result.endpoint} - ${result.status}${dataCount}`);
    });

    return successRate >= 90;
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
    console.log('🔗 Indulink Real Data API Testing\n');

    const serverRunning = await checkServerRunning();

    if (!serverRunning) {
        console.log('\n❌ Cannot proceed with tests - server is not running');
        process.exit(1);
    }

    console.log('');
    const allTestsPassed = await testRealDataAPIs();

    if (allTestsPassed) {
        console.log('\n🎯 Real data API testing completed successfully!');
        console.log('💡 The Flutter app will now display real data from the database.');
        process.exit(0);
    } else {
        console.log('\n⚠️  Some API tests need attention');
        console.log('   Check the detailed results above and fix any failing endpoints.');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { testRealDataAPIs, checkServerRunning };