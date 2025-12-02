#!/usr/bin/env node

/**
 * 🚀 INDULINK API ENDPOINTS TESTER
 * Automated testing script for all API endpoints
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5000';
let authToken = null;

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
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

// Test functions
async function testHealthCheck() {
    try {
        const response = await axios.get(`${BASE_URL}/health`);
        const success = response.status === 200 && response.data.success;
        logTest('Health Check', success, `Status: ${response.status}`);
        return success;
    } catch (error) {
        logTest('Health Check', false, error.message);
        return false;
    }
}

async function testApiInfo() {
    try {
        const response = await axios.get(`${BASE_URL}/api`);
        const success = response.status === 200 && response.data.success;
        logTest('API Info', success, `Version: ${response.data.version}`);
        return success;
    } catch (error) {
        logTest('API Info', false, error.message);
        return false;
    }
}

async function testGetProducts() {
    try {
        const response = await axios.get(`${BASE_URL}/api/products?page=1&limit=5`);
        const success = response.status === 200 && response.data.success;
        const count = response.data.data?.length || 0;
        logTest('GET Products', success, `Found ${count} products`);
        return success;
    } catch (error) {
        logTest('GET Products', false, error.message);
        return false;
    }
}

async function testGetCategories() {
    try {
        const response = await axios.get(`${BASE_URL}/api/categories`);
        const success = response.status === 200 && response.data.success;
        const count = response.data.data?.length || 0;
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

        const response = await axios.post(`${BASE_URL}/api/auth/register`, testUser);
        const success = response.status === 201 && response.data.success;
        logTest('User Registration', success, `User created: ${testUser.email}`);
        return success;
    } catch (error) {
        logTest('User Registration', false, error.message);
        return false;
    }
}

async function testUserLogin() {
    try {
        const loginData = {
            email: 'test@example.com',
            password: 'password123'
        };

        const response = await axios.post(`${BASE_URL}/api/auth/login`, loginData);
        const success = response.status === 200 && response.data.success;

        if (success && response.data.token) {
            authToken = response.data.token;
            logTest('User Login', success, 'Token received');
        } else {
            logTest('User Login', false, 'No token in response');
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
        const response = await axios.get(`${BASE_URL}/api/addresses`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });

        const success = response.status === 200 && response.data.success;
        const count = response.data.data?.length || 0;
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

        const response = await axios.post(`${BASE_URL}/api/addresses`, addressData, {
            headers: { Authorization: `Bearer ${authToken}` }
        });

        const success = response.status === 201 && response.data.success;
        logTest('POST Address', success, 'Address created successfully');
        return success;
    } catch (error) {
        logTest('POST Address', false, error.message);
        return false;
    }
}

async function testMetrics() {
    try {
        const response = await axios.get(`${BASE_URL}/api/metrics`);
        const success = response.status === 200 && response.data.success;
        logTest('API Metrics', success, 'Metrics retrieved');
        return success;
    } catch (error) {
        logTest('API Metrics', false, error.message);
        return false;
    }
}

async function testInfrastructure() {
    try {
        const response = await axios.get(`${BASE_URL}/api/infrastructure`);
        const success = response.status === 200 && response.data.success;
        logTest('Infrastructure Metrics', success, 'System health OK');
        return success;
    } catch (error) {
        logTest('Infrastructure Metrics', false, error.message);
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
    results.push(await testMetrics());
    results.push(await testInfrastructure());

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
    } else {
        log('\n⚠️  Some tests failed. Check the output above for details.', 'yellow');
        log('💡 Make sure:', 'cyan');
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
    testAddAddress,
    testMetrics,
    testInfrastructure
};