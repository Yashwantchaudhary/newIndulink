const http = require('http');

const API_BASE = 'http://localhost:5000/api';

// Utilities
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
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(body);
                    resolve({ status: res.statusCode, data: jsonData, headers: res.headers });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body, headers: res.headers });
                }
            });
        });

        req.on('error', (err) => resolve({ status: 'ERROR', error: err.message }));
        if (data) req.write(JSON.stringify(data));
        req.end();
    });
}

async function verifyDataManagement() {
    console.log('🗄️  Verifying Data Management Hub...\n');

    let supplierToken, adminToken;
    let supplierId;

    // 1. Authenticate
    console.log('1️⃣  Authenticating...');

    // Admin Login
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'admin@indulink.com', password: 'admin123' });
    if (res.status === 200) {
        adminToken = res.data.data.accessToken;
        console.log('   ✅ Admin authenticated');
    } else {
        console.error('   ❌ Admin login failed');
        return;
    }

    // Supplier Login
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'supplier1@indulink.com', password: 'supplier123' });
    if (res.status === 200) {
        supplierToken = res.data.data.accessToken;
        supplierId = res.data.data.user._id;
        console.log(`   ✅ Supplier authenticated (ID: ${supplierId})`);
    } else {
        console.error('   ❌ Supplier login failed');
        return;
    }

    // 2. Verify Admin Data Management Stats
    console.log('\n2️⃣  Verifying Admin Data Hub (/api/dashboard/admin)...');
    res = await makeRequest('GET', `${API_BASE}/dashboard/admin`, null, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 200) {
        const data = res.data;
        console.log('   ✅ Admin Dashboard Data Received');

        const requiredKeys = ['totalUsers', 'totalProducts', 'totalOrders', 'totalCategories', 'totalReviews', 'totalRFQs', 'totalMessages', 'totalNotifications'];
        let missingKeys = [];
        requiredKeys.forEach(key => {
            if (data[key] === undefined) missingKeys.push(key);
        });

        if (missingKeys.length === 0) {
            console.log('   ✅ All required stats keys present');
            console.log(`     - Users: ${data.totalUsers}`);
            console.log(`     - Products: ${data.totalProducts}`);
            console.log(`     - Categories: ${data.totalCategories}`);
            console.log(`     - RFQs: ${data.totalRFQs}`);
        } else {
            console.error(`   ❌ Missing keys: ${missingKeys.join(', ')}`);
        }

    } else {
        console.error('   ❌ Failed to fetch admin dashboard:', res.status);
    }

    // 3. Verify Supplier Data Management Stats
    console.log('\n3️⃣  Verifying Supplier Data Hub endpoints...');

    // Product Stats
    res = await makeRequest('GET', `${API_BASE}/products/stats/supplier/${supplierId}`, null, { 'Authorization': `Bearer ${supplierToken}` });
    if (res.status === 200) {
        console.log(`   ✅ Product Stats: ${JSON.stringify(res.data.data || res.data)}`);
    } else {
        console.error(`   ❌ Failed Product Stats: ${res.status}`);
    }

    // Order Stats
    res = await makeRequest('GET', `${API_BASE}/orders/stats/supplier/${supplierId}`, null, { 'Authorization': `Bearer ${supplierToken}` });
    if (res.status === 200) {
        console.log(`   ✅ Order Stats: ${JSON.stringify(res.data.data || res.data)}`);
    } else {
        console.error(`   ❌ Failed Order Stats: ${res.status}`);
    }

    // RFQ Stats
    res = await makeRequest('GET', `${API_BASE}/rfq/stats/supplier/${supplierId}`, null, { 'Authorization': `Bearer ${supplierToken}` });
    if (res.status === 200) {
        console.log(`   ✅ RFQ Stats: ${JSON.stringify(res.data.data || res.data)}`);
    } else {
        console.error(`   ❌ Failed RFQ Stats: ${res.status}`);
    }

    console.log('\n✅ Data Management Verification Complete.');
}

verifyDataManagement();
