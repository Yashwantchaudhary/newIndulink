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

// Main Test Flow
async function verifyOrderFlow() {
    console.log('🚀 Starting Order Visibility Verification...\n');

    let supplier = { email: 'supplier1@indulink.com', password: 'supplier123', token: null, id: null };
    let customer = { email: 'customer1@indulink.com', password: 'customer123', token: null, id: null };
    let admin = { email: 'admin@indulink.com', password: 'admin123', token: null };
    let targetProduct = null;
    let orderId = null;

    // 1. Supplier Login
    console.log('1️⃣  Logging in as Supplier...');
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: supplier.email, password: supplier.password });
    if (res.status === 200) {
        supplier.token = res.data.data.accessToken;
        supplier.id = res.data.data.user._id;
        console.log(`   ✅ Success! Supplier ID: ${supplier.id}`);
    } else {
        console.error('   ❌ Supplier login failed. Cannot proceed.');
        return;
    }

    // 2. Customer Login (or Register)
    console.log('\n2️⃣  Logging in as Customer...');
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: customer.email, password: customer.password });
    if (res.status === 200) {
        customer.token = res.data.data.accessToken;
        customer.id = res.data.data.user._id;
        console.log('   ✅ Login Success!');
    } else {
        console.log('   Warning: Default customer login failed. Attempting verification registration...');
        const uniqueEmail = `test.cust.${Date.now()}@test.com`;
        res = await makeRequest('POST', `${API_BASE}/auth/register`, {
            firstName: 'Test', lastName: 'Customer', email: uniqueEmail, password: 'password123', phone: '9800000000'
        });
        if (res.status === 201) {
            customer.token = res.data.data.accessToken;
            customer.id = res.data.data.user._id;
            console.log(`   ✅ Registered new customer: ${uniqueEmail}`);
        } else {
            console.error('   ❌ Customer registration failed. Aborting.');
            return;
        }
    }

    // 3. Find Product by Supplier
    console.log('\n3️⃣  Finding Product for Supplier...');
    res = await makeRequest('GET', `${API_BASE}/products`);
    if (res.status === 200) {
        const products = res.data.data || res.data.products; // Handle both likely response formats
        targetProduct = products.find(p => {
            // Check string match or object match for supplier field
            const pSupplierId = (typeof p.supplier === 'object') ? p.supplier._id : p.supplier;
            return pSupplierId.toString() === supplier.id.toString();
        });

        if (targetProduct) {
            console.log(`   ✅ Found Product: "${targetProduct.title}" (${targetProduct._id})`);
        } else {
            console.error('   ❌ No products found for this supplier. Cannot create order.');
            // Attempt to create one? No, scope creep.
            return;
        }
    }

    // 4. Add to Cart & Checkout
    console.log('\n4️⃣  Creating Order...');

    // Add to Cart
    await makeRequest('POST', `${API_BASE}/cart`,
        { productId: targetProduct._id, quantity: 1 },
        { 'Authorization': `Bearer ${customer.token}` }
    );

    // Get Address (create if needed)
    let addressId = null;
    res = await makeRequest('GET', `${API_BASE}/addresses`, null, { 'Authorization': `Bearer ${customer.token}` });
    if (res.data.data && res.data.data.length > 0) {
        addressId = res.data.data[0]._id;
    } else {
        console.log('   Creating new address...');
        res = await makeRequest('POST', `${API_BASE}/addresses`, {
            addressType: 'home', fullName: 'Tester', phoneNumber: '1234567890',
            addressLine1: '123 Street', city: 'City', state: 'State', zipCode: '12345', country: 'Nepal', isDefault: true
        }, { 'Authorization': `Bearer ${customer.token}` });

        if (res.status === 201 && res.data.data) {
            addressId = res.data.data._id;
            console.log(`   ✅ Address Created: ${addressId}`);
        } else {
            console.error('   ❌ Address creation failed. Response:', JSON.stringify(res.data));
            return;
        }
    }

    // Place Order
    res = await makeRequest('POST', `${API_BASE}/orders`, {
        shippingAddress: addressId,
        paymentMethod: 'cash_on_delivery',
        notes: 'Verification Order'
    }, { 'Authorization': `Bearer ${customer.token}` });

    if (res.status === 201) {
        // Create Order returns an array of orders (one per supplier)
        if (Array.isArray(res.data.data) && res.data.data.length > 0) {
            orderId = res.data.data[0]._id;
            const orderNum = res.data.data[0].orderNumber;
            console.log(`   ✅ Order Placed! #${orderNum} (ID: ${orderId})`);
        } else {
            console.error('   ❌ Order created but returned empty list:', JSON.stringify(res.data));
            return;
        }
    } else {
        console.error('   ❌ Order placement failed:', res.data);
        return;
    }

    // 5. Verify Customer Visibility
    console.log('\n5️⃣  Verifying Customer Visibility...');
    res = await makeRequest('GET', `${API_BASE}/orders`, null, { 'Authorization': `Bearer ${customer.token}` });
    const custOrders = res.data.data;
    const foundInCust = custOrders.find(o => o._id === orderId);
    if (foundInCust) console.log('   ✅ Order visible in Customer Dashboard');
    else console.error('   ❌ Order NOT found in Customer Dashboard');

    // 6. Verify Supplier Visibility
    console.log('\n6️⃣  Verifying Supplier Visibility...');
    res = await makeRequest('GET', `${API_BASE}/supplier/orders`, null, { 'Authorization': `Bearer ${supplier.token}` });
    const suppOrders = res.data.data;
    const foundInSupp = suppOrders.find(o => o._id === orderId);
    if (foundInSupp) console.log('   ✅ Order visible in Supplier Dashboard');
    else console.error('   ❌ Order NOT found in Supplier Dashboard');

    // 7. Verify Admin Visibility
    console.log('\n7️⃣  Verifying Admin Visibility...');
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: admin.email, password: admin.password });
    if (res.status === 200) {
        admin.token = res.data.data.accessToken;
        res = await makeRequest('GET', `${API_BASE}/admin/orders`, null, { 'Authorization': `Bearer ${admin.token}` });
        const adminOrders = res.data.data;
        if (Array.isArray(adminOrders)) {
            const foundInAdmin = adminOrders.find(o => o._id === orderId);
            if (foundInAdmin) console.log('   ✅ Order visible in Admin Dashboard');
            else console.error('   ❌ Order NOT found in Admin Dashboard');
        } else {
            console.error('   ❌ Admin API returned unexpected format:', JSON.stringify(res.data));
        }
    } else {
        console.error('   ❌ Admin login failed.');
    }

    console.log('\n✅ Verification Complete.');
}

verifyOrderFlow();
