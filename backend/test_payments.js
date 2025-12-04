#!/usr/bin/env node

/**
 * Payment API Testing Script
 * Tests the payment endpoints functionality
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

async function testPaymentEndpoints() {
    console.log('💳 Testing Payment API Endpoints...\n');

    const results = [];

    // Test 1: Check if payment routes are accessible (should return 401 for protected routes)
    console.log('Testing payment route accessibility...');

    const endpoints = [
        { method: 'GET', path: '/payments/user', expectStatus: 401, description: 'User payments (protected)' },
        { method: 'GET', path: '/payments/stats', expectStatus: 401, description: 'Payment stats (protected)' },
        { method: 'GET', path: '/payments/TXN123/status', expectStatus: 401, description: 'Payment status (protected)' },
        { method: 'POST', path: '/payments/esewa/create', expectStatus: 401, description: 'Create eSewa payment (protected)' },
    ];

    for (const endpoint of endpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path}`);

        try {
            const result = await makeRequest(endpoint.method, url);
            results.push({ ...result, endpoint, url });

            if (result.status === endpoint.expectStatus) {
                console.log(`    ✅ ${result.status} - ${endpoint.description} (expected)`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (unexpected status)`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint, url });
        }

        // Small delay between requests
        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Test 2: Test eSewa callback endpoints (should be accessible without auth)
    console.log('\nTesting eSewa callback endpoints...');

    const callbackEndpoints = [
        { method: 'GET', path: '/payments/esewa/success?oid=TXN123&amt=100&refId=REF123', expectStatus: 302, description: 'eSewa success callback' },
        { method: 'GET', path: '/payments/esewa/failure?oid=TXN123', expectStatus: 302, description: 'eSewa failure callback' },
    ];

    for (const endpoint of callbackEndpoints) {
        const url = `${API_BASE}${endpoint.path}`;
        console.log(`  Testing: ${endpoint.method} ${endpoint.path.split('?')[0]}`);

        try {
            const result = await makeRequest(endpoint.method, url);
            results.push({ ...result, endpoint, url });

            if (result.status === endpoint.expectStatus) {
                console.log(`    ✅ ${result.status} - ${endpoint.description} (redirect expected)`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`    ❌ ${result.status} - ${endpoint.description} (${result.error})`);
            } else {
                console.log(`    ⚠️  ${result.status} - ${endpoint.description} (unexpected status: ${result.status})`);
            }
        } catch (error) {
            console.log(`    ❌ ERROR - ${endpoint.description} (${error.message})`);
            results.push({ status: 'ERROR', error: error.message, endpoint, url });
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Summary
    console.log('\n📊 Payment API Test Results:');
    console.log('='.repeat(60));

    const successCount = results.filter(r =>
        r.status === r.endpoint?.expectStatus ||
        (r.endpoint?.description.includes('callback') && r.status === 302)
    ).length;

    const errorCount = results.filter(r =>
        r.status === 'ERROR' || r.status === 'TIMEOUT'
    ).length;

    console.log(`✅ Successful tests: ${successCount}/${results.length}`);
    console.log(`❌ Failed tests: ${errorCount}/${results.length}`);

    if (successCount === results.length) {
        console.log('\n🎉 All payment endpoints are working correctly!');
        console.log('✅ Payment infrastructure is ready for integration.');
    } else if (successCount >= results.length * 0.8) {
        console.log('\n⚠️  Most payment endpoints are working, but some need attention.');
    } else {
        console.log('\n❌ Multiple payment endpoints are not responding correctly.');
    }

    console.log('\n🔍 Detailed Results:');
    results.forEach((result, index) => {
        const status = result.status === result.endpoint?.expectStatus ||
                      (result.endpoint?.description.includes('callback') && result.status === 302)
                      ? '✅' : result.status === 'ERROR' || result.status === 'TIMEOUT' ? '❌' : '⚠️';
        const endpoint = result.endpoint || {};
        console.log(`${status} ${endpoint.method} ${endpoint.path} - ${result.status} (${endpoint.description})`);
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
    console.log('🚀 Indulink Payment API Testing\n');

    const serverRunning = await checkServerRunning();

    if (!serverRunning) {
        console.log('\n❌ Cannot proceed with tests - server is not running');
        process.exit(1);
    }

    console.log('');
    const allTestsPassed = await testPaymentEndpoints();

    if (allTestsPassed) {
        console.log('\n🎯 Payment API testing completed successfully!');
        console.log('💡 Next steps:');
        console.log('   1. Add eSewa credentials to environment variables');
        console.log('   2. Implement Flutter eSewa SDK integration');
        console.log('   3. Update checkout flow to use payment endpoints');
        console.log('   4. Test complete payment flow with real transactions');
        process.exit(0);
    } else {
        console.log('\n⚠️  Some payment endpoints need attention');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { testPaymentEndpoints, checkServerRunning };