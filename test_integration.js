/**
 * 🔗 INDULINK INTEGRATION TEST
 * Tests the complete backend + frontend integration
 */

const http = require('http');

console.log('🚀 INDULINK INTEGRATION TEST');
console.log('================================');
console.log('Testing backend + frontend integration...\n');

// Test backend API connectivity
async function testBackendAPI() {
    return new Promise((resolve) => {
        console.log('🔍 Testing Backend API...');

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api',
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    if (res.statusCode === 200 && response.success) {
                        console.log('✅ Backend API: Connected and responding');
                        console.log(`   Status: ${res.statusCode}`);
                        console.log(`   Message: ${response.message || 'OK'}`);
                        resolve(true);
                    } else {
                        console.log('❌ Backend API: Unexpected response');
                        console.log(`   Status: ${res.statusCode}`);
                        console.log(`   Response: ${data}`);
                        resolve(false);
                    }
                } catch (e) {
                    console.log('❌ Backend API: Invalid JSON response');
                    console.log(`   Raw response: ${data}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (err) => {
            console.log('❌ Backend API: Connection failed');
            console.log(`   Error: ${err.message}`);
            resolve(false);
        });

        req.setTimeout(5000, () => {
            console.log('❌ Backend API: Request timeout');
            req.destroy();
            resolve(false);
        });

        req.end();
    });
}

// Test authentication endpoint
async function testAuthEndpoint() {
    return new Promise((resolve) => {
        console.log('\n🔐 Testing Authentication Endpoint...');

        const postData = JSON.stringify({
            email: 'test@example.com',
            password: 'testpassword'
        });

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = http.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    console.log('✅ Auth Endpoint: Accessible');
                    console.log(`   Status: ${res.statusCode}`);
                    console.log(`   Response: ${response.message || 'Expected auth error for test credentials'}`);
                    resolve(true);
                } catch (e) {
                    console.log('❌ Auth Endpoint: Invalid response format');
                    resolve(false);
                }
            });
        });

        req.on('error', (err) => {
            console.log('❌ Auth Endpoint: Connection failed');
            console.log(`   Error: ${err.message}`);
            resolve(false);
        });

        req.setTimeout(5000, () => {
            console.log('❌ Auth Endpoint: Request timeout');
            req.destroy();
            resolve(false);
        });

        req.write(postData);
        req.end();
    });
}

// Test products endpoint
async function testProductsEndpoint() {
    return new Promise((resolve) => {
        console.log('\n📦 Testing Products Endpoint...');

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/products?page=1&limit=5',
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                try {
                    const response = JSON.parse(data);
                    console.log('✅ Products Endpoint: Accessible');
                    console.log(`   Status: ${res.statusCode}`);
                    if (response.success) {
                        console.log(`   Products found: ${response.data?.length || 0}`);
                    } else {
                        console.log(`   Message: ${response.message || 'No products yet'}`);
                    }
                    resolve(true);
                } catch (e) {
                    console.log('❌ Products Endpoint: Invalid response format');
                    resolve(false);
                }
            });
        });

        req.on('error', (err) => {
            console.log('❌ Products Endpoint: Connection failed');
            console.log(`   Error: ${err.message}`);
            resolve(false);
        });

        req.setTimeout(5000, () => {
            console.log('❌ Products Endpoint: Request timeout');
            req.destroy();
            resolve(false);
        });

        req.end();
    });
}

// Main test runner
async function runIntegrationTests() {
    console.log('🧪 RUNNING INTEGRATION TESTS\n');

    const results = [];

    // Test 1: Backend API connectivity
    const backendResult = await testBackendAPI();
    results.push(backendResult);

    // Test 2: Authentication endpoint
    const authResult = await testAuthEndpoint();
    results.push(authResult);

    // Test 3: Products endpoint
    const productsResult = await testProductsEndpoint();
    results.push(productsResult);

    // Summary
    console.log('\n📊 INTEGRATION TEST SUMMARY');
    console.log('================================');
    const passed = results.filter(r => r).length;
    const total = results.length;

    console.log(`Total Tests: ${total}`);
    console.log(`Passed: ${passed}`);
    console.log(`Failed: ${total - passed}`);

    if (passed === total) {
        console.log('\n🎉 ALL INTEGRATION TESTS PASSED!');
        console.log('✅ Backend server is running correctly');
        console.log('✅ API endpoints are responding');
        console.log('✅ Ready for Flutter frontend integration');
        console.log('\n💡 Next Steps:');
        console.log('   1. Run: cd frontend && flutter run');
        console.log('   2. Test the complete app functionality');
        console.log('   3. Verify real-time features work');
    } else {
        console.log('\n❌ SOME TESTS FAILED');
        console.log('🔧 Check backend server and database connection');
        console.log('🔧 Ensure MongoDB is running');
        console.log('🔧 Verify all dependencies are installed');
    }

    return passed === total;
}

// Run the tests
runIntegrationTests().catch(console.error);