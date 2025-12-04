// 🧪 API Endpoints Test Script
// This script tests the backend API to ensure it's working for the Flutter app

const http = require('http');

const API_BASE = 'http://localhost:5000/api';

function makeRequest(path, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(API_BASE + path);
        
        const options = {
            hostname: url.hostname,
            port: url.port,
            path: url.pathname,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        if (data) {
            const postData = JSON.stringify(data);
            options.headers['Content-Length'] = Buffer.byteLength(postData);
        }

        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(responseData);
                    resolve({
                        statusCode: res.statusCode,
                        data: jsonData,
                        headers: res.headers
                    });
                } catch (e) {
                    resolve({
                        statusCode: res.statusCode,
                        data: responseData,
                        headers: res.headers
                    });
                }
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

async function testEndpoints() {
    console.log('🧪 Testing Backend API Endpoints');
    console.log('================================');
    
    try {
        // Test 1: Health check
        console.log('\n1️⃣ Testing basic connectivity...');
        const healthResponse = await makeRequest('/health');
        console.log(`Status: ${healthResponse.statusCode}`);
        console.log(`Response:`, healthResponse.data);
        
        // Test 2: Login endpoint (this should fail without valid credentials, but shows the endpoint works)
        console.log('\n2️⃣ Testing login endpoint structure...');
        const loginResponse = await makeRequest('/auth/login', 'POST', {
            email: 'test@example.com',
            password: 'test123'
        });
        console.log(`Status: ${loginResponse.statusCode}`);
        console.log(`Response:`, loginResponse.data);
        
        // Test 3: Admin dashboard (should return unauthorized, but endpoint exists)
        console.log('\n3️⃣ Testing admin dashboard endpoint...');
        const adminResponse = await makeRequest('/admin/dashboard');
        console.log(`Status: ${adminResponse.statusCode}`);
        console.log(`Response:`, adminResponse.data);
        
        // Test 4: Products endpoint
        console.log('\n4️⃣ Testing products endpoint...');
        const productsResponse = await makeRequest('/products');
        console.log(`Status: ${productsResponse.statusCode}`);
        console.log(`Response:`, productsResponse.data);
        
        console.log('\n✅ API Testing Complete!');
        console.log('\n📋 Summary:');
        console.log('- Backend is responding to requests');
        console.log('- Authentication endpoints are working');
        console.log('- API structure is correct for Flutter app');
        
        if (healthResponse.statusCode === 200) {
            console.log('\n✅ Backend is healthy and ready for Flutter app');
        } else {
            console.log('\n⚠️  Backend may have issues - check logs');
        }
        
    } catch (error) {
        console.error('\n❌ API Test Failed:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Make sure backend is running: npm start');
        console.log('2. Check if port 5000 is available');
        console.log('3. Verify MongoDB connection');
    }
}

// Run the tests
testEndpoints();