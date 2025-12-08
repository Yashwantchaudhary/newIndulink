const http = require('http');

const API_BASE = 'http://localhost:5000/api';

// Utilities
function makeRequest(method, url, headers = {}) {
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
                    resolve({ status: res.statusCode, data: jsonData });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', (err) => resolve({ status: 'ERROR', error: err.message }));
        req.end();
    });
}

function makeLoginRequest(email, password) {
    return new Promise((resolve, reject) => {
        const req = http.request(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        }, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(body);
                    resolve({ status: res.statusCode, data: jsonData });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });
        req.write(JSON.stringify({ email, password }));
        req.end();
    });
}

async function verifyQuickActions() {
    console.log('🚀 Verifying Supplier Quick Actions Endpoints...\n');

    // 1. Authenticate Supplier
    console.log('1️⃣  Authenticating Supplier...');
    const loginRes = await makeLoginRequest('supplier1@indulink.com', 'supplier123');

    if (loginRes.status !== 200) {
        console.error('   ❌ Login failed:', loginRes.data);
        return;
    }

    const token = loginRes.data.data.accessToken;
    console.log('   ✅ Authenticated');

    // 2. Verify Analytics Endpoint
    console.log('\n2️⃣  Verifying Analytics (/api/supplier/analytics)...');
    const analyticsRes = await makeRequest('GET', `${API_BASE}/supplier/analytics`, { 'Authorization': `Bearer ${token}` });

    if (analyticsRes.status === 200) {
        console.log('   ✅ Analytics Data Received');
        const data = analyticsRes.data.data || analyticsRes.data;
        console.log(`     - Total Revenue: ${data.totalRevenue}`);
        console.log(`     - Active Products: ${data.activeProducts}`);
    } else {
        console.error('   ❌ Analytics Failed:', analyticsRes.status);
    }

    // 3. Verify Reviews Endpoint
    console.log('\n3️⃣  Verifying Reviews (/api/reviews/supplier/me)...');
    const reviewsRes = await makeRequest('GET', `${API_BASE}/reviews/supplier/me`, { 'Authorization': `Bearer ${token}` });

    if (reviewsRes.status === 200) {
        console.log('   ✅ Reviews Data Received');
        const data = reviewsRes.data.data || reviewsRes.data;
        if (Array.isArray(data)) {
            console.log(`     - Reviews Count: ${data.length}`);
        } else {
            // Maybe paginated
            console.log(`     - Reviews Count: ${data.reviews ? data.reviews.length : 'Unknown structure'}`);
        }
    } else {
        console.error('   ❌ Reviews Failed:', reviewsRes.status);
    }

    // 4. Verify Active Cart Items (Often used for dashboard/quick insights)
    console.log('\n4️⃣  Verifying Active Carts (/api/supplier/products/active-carts)...');
    const cartRes = await makeRequest('GET', `${API_BASE}/supplier/products/active-carts`, { 'Authorization': `Bearer ${token}` });

    if (cartRes.status === 200) {
        console.log('   ✅ Active Cart Data Received');
        const data = cartRes.data.data || cartRes.data;
        console.log(`     - Unique Carts: ${data.uniqueCartsCount}`);
    } else {
        // This might not be a quick action, but good to check as it's often on dashboard
        console.log(`   ℹ️  Active Carts Endpoint status: ${cartRes.status}`);
    }

    console.log('\n✅ Quick Actions Verification Complete.');
}

verifyQuickActions();
