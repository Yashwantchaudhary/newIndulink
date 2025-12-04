#!/usr/bin/env node

/**
 * Simple API Health Check Script
 * Tests if the backend services are responding correctly
 */

const http = require('http');

const API_BASE = 'http://localhost:5000';
const API_ENDPOINTS = [
    '/health',
    '/api',
    '/api/auth/login',
    '/api/products',
    '/api/categories',
    '/api/cart',
    '/api/orders',
    '/api/rfq',
    '/api/supplier/dashboard',
    '/api/admin/dashboard',
    '/api/notifications',
    '/api/wishlist'
];

function makeRequest(url) {
    return new Promise((resolve, reject) => {
        const req = http.get(url, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(data);
                    resolve({
                        status: res.statusCode,
                        data: jsonData,
                        url: url
                    });
                } catch (e) {
                    resolve({
                        status: res.statusCode,
                        data: data,
                        url: url
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

        req.setTimeout(5000, () => {
            req.destroy();
            resolve({
                status: 'TIMEOUT',
                error: 'Request timeout',
                url: url
            });
        });
    });
}

async function testAPIHealth() {
    console.log('🩺 Testing API Health...\n');

    const results = [];

    for (const endpoint of API_ENDPOINTS) {
        const url = `${API_BASE}${endpoint}`;
        console.log(`Testing: ${endpoint}`);

        try {
            const result = await makeRequest(url);
            results.push(result);

            if (result.status === 200 || result.status === 401 || result.status === 403) {
                console.log(`   ✅ ${result.status} - OK`);
            } else if (result.status === 'ERROR' || result.status === 'TIMEOUT') {
                console.log(`   ❌ ${result.status} - ${result.error}`);
            } else {
                console.log(`   ⚠️  ${result.status} - Unexpected status`);
            }
        } catch (error) {
            console.log(`   ❌ ERROR - ${error.message}`);
            results.push({
                status: 'ERROR',
                error: error.message,
                url: url
            });
        }

        // Small delay between requests
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log('\n📊 Test Results Summary:');
    console.log('='.repeat(50));

    const successCount = results.filter(r =>
        r.status === 200 || r.status === 401 || r.status === 403
    ).length;

    const errorCount = results.filter(r =>
        r.status === 'ERROR' || r.status === 'TIMEOUT'
    ).length;

    console.log(`✅ Successful endpoints: ${successCount}/${API_ENDPOINTS.length}`);
    console.log(`❌ Failed endpoints: ${errorCount}/${API_ENDPOINTS.length}`);

    if (successCount === API_ENDPOINTS.length) {
        console.log('\n🎉 All services are responding correctly!');
        console.log('✅ Backend is healthy and ready for use.');
    } else if (successCount >= API_ENDPOINTS.length * 0.8) {
        console.log('\n⚠️  Most services are working, but some endpoints need attention.');
    } else {
        console.log('\n❌ Multiple services are not responding. Backend needs fixing.');
    }

    console.log('\n🔍 Detailed Results:');
    results.forEach(result => {
        const status = result.status === 200 || result.status === 401 || result.status === 403 ? '✅' :
                      result.status === 'ERROR' || result.status === 'TIMEOUT' ? '❌' : '⚠️';
        console.log(`${status} ${result.url.replace(API_BASE, '')} - ${result.status}`);
    });

    return successCount === API_ENDPOINTS.length;
}

// Check if server is running
async function checkServerRunning() {
    console.log('🔍 Checking if server is running...');

    try {
        const result = await makeRequest(`${API_BASE}/health`);
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
    console.log('🚀 Indulink Backend Service Health Check\n');

    const serverRunning = await checkServerRunning();

    if (!serverRunning) {
        console.log('\n❌ Cannot proceed with tests - server is not running');
        process.exit(1);
    }

    console.log('');
    const allHealthy = await testAPIHealth();

    if (allHealthy) {
        console.log('\n🎯 All backend services are working perfectly!');
        process.exit(0);
    } else {
        console.log('\n⚠️  Some services need attention');
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { testAPIHealth, checkServerRunning };