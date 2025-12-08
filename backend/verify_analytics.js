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

async function verifyAnalytics() {
    console.log('📊 Verifying Analytics Data Flow...\n');

    let supplierToken, adminToken;
    let supplierId;

    // 1. Login
    console.log('1️⃣  Authenticating...');

    // Supplier Login
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'supplier1@indulink.com', password: 'supplier123' });
    if (res.status === 200) {
        supplierToken = res.data.data.accessToken;
        supplierId = res.data.data.user._id;
        console.log('   ✅ Supplier authenticated');
    } else {
        console.error('   ❌ Supplier login failed');
        return;
    }

    // Admin Login
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'admin@indulink.com', password: 'admin123' });
    if (res.status === 200) {
        adminToken = res.data.data.accessToken;
        console.log('   ✅ Admin authenticated');
    } else {
        console.error('   ❌ Admin login failed');
        return;
    }

    // 2. Verify Supplier Dashboard Analytics
    console.log('\n2️⃣  Verifying Supplier Analytics (/api/dashboard/supplier)...');
    res = await makeRequest('GET', `${API_BASE}/dashboard/supplier`, null, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200) {
        const data = res.data;
        console.log('   ✅ Endpoint reachable');
        console.log(`   Expected Data Points:`);
        console.log(`   - Total Revenue: NPR ${data.totalRevenue} ${data.totalRevenue > 0 ? '✅' : '⚠️ (Zero)'}`);
        console.log(`   - Total Orders: ${data.totalOrders} ${data.totalOrders > 0 ? '✅' : '⚠️ (Zero)'}`);
        console.log(`   - Active Products: ${data.totalProducts} ${data.totalProducts > 0 ? '✅' : '⚠️ (Zero)'}`);
        console.log(`   - Low Stock Count: ${data.lowStockCount}`);

        console.log(`   - Revenue Trend: ${data.revenueTrend}%`);
        console.log(`   - Orders Trend: ${data.ordersTrend}%`);

        if (data.revenueData && data.revenueData.length > 0) {
            console.log(`   - Revenue Chart Data: ✅ Present (${data.revenueData.length} points)`);
        } else {
            console.log(`   - Revenue Chart Data: ❌ Missing/Empty`);
        }

    } else {
        console.error('   ❌ Failed to fetch supplier dashboard:', res.status, res.data);
    }

    // 3. Verify Admin Dashboard Analytics
    console.log('\n3️⃣  Verifying Admin Analytics (/api/dashboard/admin)...');
    res = await makeRequest('GET', `${API_BASE}/dashboard/admin`, null, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 200) {
        const data = res.data;
        console.log('   ✅ Endpoint reachable');
        console.log(`   Expected Global Data:`);
        console.log(`   - Total Platform Revenue: NPR ${data.totalRevenue} ${data.totalRevenue > 0 ? '✅' : '⚠️ (Zero)'}`);
        console.log(`   - Total Users: ${data.totalUsers}`);
        console.log(`   - Total Suppliers: ${data.totalSuppliers}`);
        console.log(`   - Total Orders: ${data.totalOrders} ${data.totalOrders > 0 ? '✅' : '⚠️ (Zero)'}`);

        if (data.revenueData && data.revenueData.length > 0) {
            console.log(`   - Global Revenue Chart: ✅ Present`);
        } else {
            console.log(`   - Global Revenue Chart: ❌ Missing`);
        }

        if (data.topSuppliers && data.topSuppliers.length > 0) {
            console.log(`   - Top Suppliers List: ✅ Present`);
            console.log(`     #1: ${data.topSuppliers[0].name} (NPR ${data.topSuppliers[0].revenue})`);
        } else {
            console.log(`   - Top Suppliers List: ⚠️ Empty`);
        }

    } else {
        console.error('   ❌ Failed to fetch admin dashboard:', res.status, res.data);
    }

    console.log('\n✅ Analytics Verification Complete.');
}

verifyAnalytics();
