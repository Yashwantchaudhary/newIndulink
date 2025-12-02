#!/usr/bin/env node

/**
 * 🚀 INDULINK API ENDPOINTS TESTER (Simple Version)
 * Automated testing script using built-in Node.js modules
 */

const http = require('http');
const https = require('https');

const BASE_URL = 'http://localhost:5000';
let authToken = null;

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(testName, status, details = '') {
    const icon = status ? '✅' : '❌';
    const color = status ? 'green' : 'red';
    console.log(`${colors[color]}${icon} ${testName}${details ? ` - ${details}` : ''}${colors.reset}`);
}

// HTTP request helper
function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => {
                body += chunk;
            });
            res.on('end', () => {
                try {
                    const response = {
                        statusCode: res.statusCode,
                        headers: res.headers,
                        body: body
                    };
                    resolve(response);
                } catch (error) {
                    reject(error);
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        if (data) {
            req.write(data);
        }
        req.end();
    });
}

// Test functions
async function testHealthCheck() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/health',
            method: 'GET'
        };

        const response = await makeRequest(options);
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;
        logTest('Health Check', success, `Status: ${response.statusCode}`);
        return success;
    } catch (error) {
        logTest('Health Check', false, error.message);
        return false;
    }
}

async function testApiInfo() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api',
            method: 'GET'
        };

        const response = await makeRequest(options);
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;
        logTest('API Info', success, `Version: ${data.version}`);
        return success;
    } catch (error) {
        logTest('API Info', false, error.message);
        return false;
    }
}

async function testGetProducts() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/products?page=1&limit=5',
            method: 'GET'
        };

        const response = await makeRequest(options);
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;
        const count = data.data?.length || 0;
        logTest('GET Products', success, `Found ${count} products`);
        return success;
    } catch (error) {
        logTest('GET Products', false, error.message);
        return false;
    }
}

async function testGetCategories() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/categories',
            method: 'GET'
        };

        const response = await makeRequest(options);
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;
        const count = data.data?.length || 0;
        logTest('GET Categories', success, `Found ${count} categories`);
        return success;
    } catch (error) {
        logTest('GET Categories', false, error.message);
        return false;
    }
}

async function testUserRegistration() {
    try {
        const testUser = {
            firstName: 'Test',
            lastName: 'User',
            email: `test${Date.now()}@example.com`,
            password: 'password123',
            role: 'customer'
        };

        // Store the email for login test
        registeredUserEmail = testUser.email;

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth/register',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const response = await makeRequest(options, JSON.stringify(testUser));
        const data = JSON.parse(response.body);
        const success = response.statusCode === 201 && data.success;
        logTest('User Registration', success, `User created: ${testUser.email}`);
        return success;
    } catch (error) {
        logTest('User Registration', false, error.message);
        return false;
    }
}

// Store the registered user's email for login test
let registeredUserEmail = null;

async function testUserLogin() {
    if (!registeredUserEmail) {
        logTest('User Login', false, 'No registered user email available');
        return false;
    }

    try {
        const loginData = {
            email: registeredUserEmail,
            password: 'password123'
        };

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const response = await makeRequest(options, JSON.stringify(loginData));
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;

        if (success && data.data && data.data.accessToken) {
            authToken = data.data.accessToken;
            logTest('User Login', success, 'Token received');
        } else {
            logTest('User Login', false, `Response: ${response.statusCode} - ${data.message || 'No token'}`);
        }

        return success;
    } catch (error) {
        logTest('User Login', false, error.message);
        return false;
    }
}

async function testGetAddresses() {
    if (!authToken) {
        logTest('GET Addresses', false, 'No auth token available');
        return false;
    }

    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/addresses',
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        };

        const response = await makeRequest(options);
        const data = JSON.parse(response.body);
        const success = response.statusCode === 200 && data.success;
        const count = data.data?.length || 0;
        logTest('GET Addresses', success, `Found ${count} addresses`);
        return success;
    } catch (error) {
        logTest('GET Addresses', false, error.message);
        return false;
    }
}

async function testAddAddress() {
    if (!authToken) {
        logTest('POST Address', false, 'No auth token available');
        return false;
    }

    try {
        const addressData = {
            fullName: 'John Doe',
            phoneNumber: '+9779800000000',
            addressLine1: '123 Main Street',
            city: 'Kathmandu',
            state: 'Bagmati',
            zipCode: '44600',
            isDefault: true
        };

        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/addresses',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            }
        };

        const response = await makeRequest(options, JSON.stringify(addressData));
        const data = JSON.parse(response.body);
        const success = response.statusCode === 201 && data.success;
        logTest('POST Address', success, 'Address created successfully');
        return success;
    } catch (error) {
        logTest('POST Address', false, error.message);
        return false;
    }
}

// Main test runner
async function runAllTests() {
    log('\n🚀 INDULINK API ENDPOINTS TEST SUITE', 'cyan');
    log('=====================================', 'cyan');

    const results = [];

    // Basic health checks
    log('\n📊 BASIC HEALTH CHECKS', 'yellow');
    results.push(await testHealthCheck());
    results.push(await testApiInfo());

    // Public endpoints
    log('\n📦 PUBLIC ENDPOINTS', 'yellow');
    results.push(await testGetProducts());
    results.push(await testGetCategories());

    // Authentication
    log('\n🔐 AUTHENTICATION', 'yellow');
    results.push(await testUserRegistration());
    results.push(await testUserLogin());

    // Protected endpoints
    log('\n🔒 PROTECTED ENDPOINTS', 'yellow');
    results.push(await testGetAddresses());
    results.push(await testAddAddress());

    // Summary
    const passed = results.filter(r => r).length;
    const total = results.length;

    log('\n📈 TEST SUMMARY', 'magenta');
    log(`Total Tests: ${total}`, 'magenta');
    log(`Passed: ${passed}`, 'green');
    log(`Failed: ${total - passed}`, passed === total ? 'green' : 'red');

    if (passed === total) {
        log('\n🎉 ALL TESTS PASSED! Your API is working perfectly!', 'green');
        log('\n📱 Now test in Flutter:', 'cyan');
        log('   1. Run: flutter run', 'cyan');
        log('   2. Navigate to: /test-api', 'cyan');
        log('   3. Click all test buttons', 'cyan');
    } else {
        log('\n⚠️  Some tests failed. Check the output above for details.', 'yellow');
        log('\n💡 Make sure:', 'cyan');
        log('   - Backend server is running on localhost:5000', 'cyan');
        log('   - MongoDB is connected', 'cyan');
        log('   - All dependencies are installed', 'cyan');
    }

    log('\n🔗 API Documentation: http://localhost:5000/api', 'blue');
    log('📊 Monitoring Dashboard: http://localhost:5000/monitoring', 'blue');
}

// Handle command line execution
if (require.main === module) {
    runAllTests().catch(error => {
        log(`\n❌ Test suite failed: ${error.message}`, 'red');
        process.exit(1);
    });
}

module.exports = {
    runAllTests,
    testHealthCheck,
    testApiInfo,
    testGetProducts,
    testGetCategories,
    testUserRegistration,
    testUserLogin,
    testGetAddresses,
    testAddAddress
};