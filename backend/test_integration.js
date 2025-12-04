#!/usr/bin/env node

/**
 * Node.js to Flutter Integration Test Script
 * Tests all API endpoints that Flutter app uses
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

async function testIntegrationEndpoints() {
    console.log('🔗 Testing Node.js to Flutter Integration...\n');

    const results = [];

    // Test 1: Health Check
    console.log('Testing health check endpoint...');
    const healthResult = await makeRequest('GET', `${API_BASE.replace('/api', '')}/health`);
    results.push({ ...healthResult, endpoint: 'Health Check', url: `${API_BASE.replace('/api', '')}/health` });

    if (healthResult.status === 200) {
        console.log('✅ Health check passed');
    } else {
        console.log('❌ Health check failed');
    }

    // Test 2: API Root
    console.log('\nTesting API root endpoint...');
    const apiResult = await makeRequest('GET', API_BASE.replace('/api', '/api'));
    results.push({ ...apiResult, endpoint: 'API Root', url: API_BASE.replace('/api', '/api') });

    if (apiResult.status === 200) {
        console.log('✅ API root accessible');
    } else {
        console.log('❌ API root not accessible');
    }

    // Test 3: Public Endpoints (no auth required)
    console.log('\nTesting public endpoints...');

    const publicEndpoints = [
        { method: 'GET', path: '/products', description: 'Get Products' },
        { method: 'GET', path: '/categories', description: 'Get Categories' },
        { method: 'POST', path: '/auth/login', description: 'User Login', data: { email: 'test@example.com', password: 'test123' } },
        { method: 'POST', path: '/auth/register', description: 'User Registration', data: { firstName: 'Test', lastName: 'User', email: 'test@example.com', password: 'test123' } },
    ];

    for (const endpoint of publicEndpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path}`);

        try {
            const result = await makeRequest(endpoint.method, url, endpoint.data);
            results.push({ ...result, endpoint: endpoint.description, url });

            // Login should return 400 (validation error) or 401 (invalid credentials)
            // Register should return 201 (success), 400 (validation error), or 409 (user exists)
            // Products and categories should return 200 or 401 (if auth required)
            const expectedStatuses = endpoint.description.includes('Registration') ?
                [201, 400, 409, 422] : [200, 400, 401, 404, 422];
            if (expectedStatuses.includes(result.status)) {
                console.log(`    ✅ ${result.status} - ${endpoint.description}`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (unexpected status)`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint: endpoint.description, url });
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Test 4: Protected Endpoints (should return 401 without auth)
    console.log('\nTesting protected endpoints (should return 401)...');

    const protectedEndpoints = [
        { method: 'GET', path: '/users/profile', description: 'User Profile' },
        { method: 'GET', path: '/cart', description: 'User Cart' },
        { method: 'GET', path: '/orders', description: 'User Orders' },
        { method: 'GET', path: '/wishlist', description: 'User Wishlist' },
        { method: 'GET', path: '/notifications', description: 'User Notifications' },
        { method: 'GET', path: '/rfq', description: 'User RFQs' },
    ];

    for (const endpoint of protectedEndpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path}`);

        try {
            const result = await makeRequest(endpoint.method, url);
            results.push({ ...result, endpoint: endpoint.description, url });

            if (result.status === 401) {
                console.log(`    ✅ ${result.status} - ${endpoint.description} (properly protected)`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (should be 401, got ${result.status})`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint: endpoint.description, url });
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Test 5: Admin Endpoints (should return 401 without auth)
    console.log('\nTesting admin endpoints (should return 401)...');

    const adminEndpoints = [
        { method: 'GET', path: '/admin/dashboard', description: 'Admin Dashboard' },
        { method: 'GET', path: '/admin/users', description: 'Admin Users' },
        { method: 'GET', path: '/admin/products', description: 'Admin Products' },
        { method: 'GET', path: '/admin/orders', description: 'Admin Orders' },
        { method: 'GET', path: '/admin/analytics', description: 'Admin Analytics' },
    ];

    for (const endpoint of adminEndpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path}`);

        try {
            const result = await makeRequest(endpoint.method, url);
            results.push({ ...result, endpoint: endpoint.description, url });

            if (result.status === 401) {
                console.log(`    ✅ ${result.status} - ${endpoint.description} (properly protected)`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (should be 401, got ${result.status})`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint: endpoint.description, url });
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Test 6: Supplier Endpoints (should return 401 without auth)
    console.log('\nTesting supplier endpoints (should return 401)...');

    const supplierEndpoints = [
        { method: 'GET', path: '/supplier/dashboard', description: 'Supplier Dashboard' },
        { method: 'GET', path: '/supplier/products', description: 'Supplier Products' },
        { method: 'GET', path: '/supplier/orders', description: 'Supplier Orders' },
        { method: 'GET', path: '/supplier/analytics', description: 'Supplier Analytics' },
    ];

    for (const endpoint of supplierEndpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path}`);

        try {
            const result = await makeRequest(endpoint.method, url);
            results.push({ ...result, endpoint: endpoint.description, url });

            if (result.status === 401) {
                console.log(`    ✅ ${result.status} - ${endpoint.description} (properly protected)`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (should be 401, got ${result.status})`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint: endpoint.description, url });
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Summary
    console.log('\n📊 Integration Test Results:');
    console.log('='.repeat(80));

    const successCount = results.filter(r =>
        (r.endpoint === 'Health Check' && r.status === 200) ||
        (r.endpoint === 'API Root' && r.status === 200) ||
        (r.endpoint.includes('Login') && [200, 400, 401, 422].includes(r.status)) ||
        (r.endpoint.includes('Registration') && [201, 400, 409, 422].includes(r.status)) ||
        (r.endpoint.includes('Products') && [200, 401].includes(r.status)) ||
        (r.endpoint.includes('Categories') && [200, 401].includes(r.status)) ||
        (r.endpoint.includes('protected') || r.endpoint.includes('Admin') || r.endpoint.includes('Supplier')) && r.status === 401
    ).length;

    const errorCount = results.filter(r =>
        r.status === 'ERROR' || r.status === 'TIMEOUT'
    ).length;

    console.log(`✅ Successful tests: ${successCount}/${results.length}`);
    console.log(`❌ Failed tests: ${errorCount}/${results.length}`);

    if (successCount === results.length) {
        console.log('\n🎉 All Node.js to Flutter integration tests passed!');
        console.log('✅ Backend API is ready for Flutter app integration.');
        console.log('\n🚀 Next Steps:');
        console.log('   1. Start Flutter development server');
        console.log('   2. Test authentication flow');
        console.log('   3. Test product browsing and cart functionality');
        console.log('   4. Test order placement and management');
        console.log('   5. Test user profile and settings');
    } else if (successCount >= results.length * 0.8) {
        console.log('\n⚠️  Most integration tests passed, but some need attention.');
        console.log('   Check the detailed results above for specific issues.');
    } else {
        console.log('\n❌ Multiple integration issues detected.');
        console.log('   Review the detailed results above and fix failing endpoints.');
    }

    console.log('\n🔍 Detailed Results:');
    results.forEach((result, index) => {
        const status = result.status === 'ERROR' || result.status === 'TIMEOUT' ? '❌' :
                      result.status >= 200 && result.status < 300 ? '✅' :
                      result.status === 401 ? '🔒' : '⚠️';
        console.log(`${status} ${result.endpoint} - ${result.status} (${result.url})`);
    });

    return successCount === results.length;
}

// Check if server is running
async function checkServerRunning() {
    console.log('🔍 Checking if server is running...');

    try {
        const result = await makeRequest('GET', `${API_BASE.replace('/api', '')}/health`);
        if (result.status === 200) {
            console.log('✅ Server is running and healthy');
            console.log(`   Environment: ${result.data.environment}`);
            console.log(`   Uptime: ${result.data.uptime} seconds`);
            console.log(`   Memory: ${Math.round(result.data.memory.heapUsed / 1024 / 1024)}MB used`);
            return true;
        } else {
            console.log('❌ Server is not responding correctly');
            console.log('   Make sure to start the server with: npm run dev');
            return false;
        }
    } catch (error) {
        console.log('❌ Cannot connect to server');
        console.log('   Make sure the server is running on port 5000');
        console.log('   Start with: npm run dev');
        return false;
    }
}

async function main() {
    console.log('🚀 Indulink Node.js to Flutter Integration Testing\n');

    const serverRunning = await checkServerRunning();

    if (!serverRunning) {
        console.log('\n❌ Cannot proceed with tests - server is not running');
        process.exit(1);
    }

    console.log('');
    const allTestsPassed = await testIntegrationEndpoints();

    if (allTestsPassed) {
        console.log('\n🎯 Integration testing completed successfully!');
        console.log('💡 The Flutter app should be able to connect to all backend services.');
        process.exit(0);
    } else {
        console.log('\n⚠️  Some integration tests need attention');
        console.log('   Check the server logs and fix any failing endpoints before proceeding.');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { testIntegrationEndpoints, checkServerRunning };