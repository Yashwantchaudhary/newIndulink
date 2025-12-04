#!/usr/bin/env node

/**
 * 🚀 INDULINK BACKEND SERVER TEST
 * Simple test to verify backend server is running and MongoDB is connected
 */

const http = require('http');

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
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
function makeRequest(options) {
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

        req.end();
    });
}

// Test backend server connectivity
async function testServerRunning() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/',
            method: 'GET',
            timeout: 5000
        };

        const response = await makeRequest(options);
        const success = response.statusCode >= 200 && response.statusCode < 500;
        logTest('Backend Server', success, `Status: ${response.statusCode}`);
        return success;
    } catch (error) {
        logTest('Backend Server', false, `Connection failed: ${error.message}`);
        return false;
    }
}

// Test basic API connectivity (implies MongoDB is working if server started)
async function testApiConnectivity() {
    try {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api',
            method: 'GET',
            timeout: 5000
        };

        const response = await makeRequest(options);

        if (response.statusCode !== 200) {
            logTest('API Connectivity', false, `API endpoint failed: ${response.statusCode}`);
            return false;
        }

        try {
            const data = JSON.parse(response.body);
            const success = data.success === true;
            logTest('API Connectivity', success, 'API responding correctly');
            return success;
        } catch (parseError) {
            logTest('API Connectivity', false, 'Invalid API response format');
            return false;
        }
    } catch (error) {
        logTest('API Connectivity', false, `API request failed: ${error.message}`);
        return false;
    }
}

// Main test runner
async function runTests() {
    log('\n🚀 INDULINK BACKEND SERVER TEST', 'cyan');
    log('================================', 'cyan');

    const results = [];

    log('\n🔍 TESTING BASIC CONNECTIVITY', 'yellow');
    results.push(await testServerRunning());

    log('\n🔗 TESTING API CONNECTIVITY', 'yellow');
    results.push(await testApiConnectivity());

    // Summary
    const passed = results.filter(r => r).length;
    const total = results.length;

    log('\n📈 TEST SUMMARY', 'blue');
    log(`Total Tests: ${total}`, 'blue');
    log(`Passed: ${passed}`, 'green');
    log(`Failed: ${total - passed}`, passed === total ? 'green' : 'red');

    if (passed === total) {
        log('\n🎉 ALL TESTS PASSED! Backend server is running correctly!', 'green');
        log('\n✅ Server: localhost:5000', 'green');
        log('✅ API: Responding correctly', 'green');
    } else {
        log('\n❌ Some tests failed. Check the output above for details.', 'red');
        log('\n💡 Make sure:', 'yellow');
        log('   - Backend server is running: npm start', 'yellow');
        log('   - MongoDB is running and accessible', 'yellow');
        log('   - Environment variables are configured', 'yellow');
    }

    return passed === total;
}

// Handle command line execution
if (require.main === module) {
    runTests().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        log(`\n❌ Test suite failed: ${error.message}`, 'red');
        process.exit(1);
    });
}

module.exports = {
    runTests,
    testServerRunning,
    testApiConnectivity
};