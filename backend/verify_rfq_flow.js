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

async function verifyRFQFlow() {
    console.log('📜 Verifying RFQ System Flow...\n');

    let customerToken, supplierToken;
    let customerId, supplierId;
    let createdRFQId, quoteId;
    let targetProductId;

    // 1. Authenticate
    console.log('1️⃣  Authenticating users...');

    // Customer Login
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'customer1@indulink.com', password: 'customer123' });
    if (res.status === 200) {
        customerToken = res.data.data.accessToken;
        customerId = res.data.data.user._id;
        console.log('   ✅ Customer authenticated');
    } else {
        console.error('   ❌ Customer login failed');
        return;
    }

    // Supplier Login
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'supplier1@indulink.com', password: 'supplier123' });
    if (res.status === 200) {
        supplierToken = res.data.data.accessToken;
        supplierId = res.data.data.user._id;
        console.log('   ✅ Supplier authenticated');
    } else {
        console.error('   ❌ Supplier login failed');
        return;
    }

    // 1.5 Fetch a Product
    console.log('\n1️⃣.5 Fetching a valid Product ID...');
    res = await makeRequest('GET', `${API_BASE}/products`, null, {});
    if (res.status === 200 && res.data.data.length > 0) {
        targetProductId = res.data.data[0]._id;
        console.log(`   ✅ Found Product: ${res.data.data[0].title} (ID: ${targetProductId})`);
    } else {
        console.error('   ❌ No products found. Cannot create RFQ.');
        return;
    }

    // 2. Create RFQ (Customer)
    console.log('\n2️⃣  Customer creating RFQ...');
    const rfqPayload = {
        items: [
            {
                productId: targetProductId,
                quantity: 500,
                specifications: "Need 500 bags of OPC cement. Urgent."
            }
        ],
        notes: "Urgent delivery required within 7 days.",
        deliveryAddress: {
            fullName: "Test Customer",
            phone: "9800000000",
            addressLine1: "Site A",
            city: "Kathmandu",
            postalCode: "44600" // Required by schema potentially
        },
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    };

    res = await makeRequest('POST', `${API_BASE}/rfq`, rfqPayload, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 201) {
        createdRFQId = res.data.data._id;
        console.log(`   ✅ RFQ Created! ID: ${createdRFQId}`);
    } else {
        console.error('   ❌ Failed to create RFQ:', res.status, res.data);
        return;
    }

    // 3. Supplier Lists RFQs
    console.log('\n3️⃣  Supplier checking available RFQs...');
    res = await makeRequest('GET', `${API_BASE}/rfq`, null, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200) {
        const rfqs = res.data.data;
        const found = rfqs.find(r => r._id === createdRFQId);
        if (found) {
            console.log('   ✅ Newly created RFQ is visible to Supplier');
        } else {
            console.log('   ⚠️ RFQ not visible (might strictly enforce only if mapped to supplier products, or general market?)');
            console.log('   For now, proceeding with direct quote submission via ID...');
        }
    }

    // 4. Supplier Submits Quote
    console.log('\n4️⃣  Supplier submitting a Quote...');
    const quotePayload = {
        items: [{
            productId: targetProductId,
            quantity: 500,
            unitPrice: 760,
            subtotal: 380000
        }],
        totalAmount: 380000,
        message: "We can supply 500 bags at this price.",
        validUntil: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString()
    };

    res = await makeRequest('POST', `${API_BASE}/rfq/${createdRFQId}/quote`, quotePayload, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200 || res.status === 201) { // 200 is often update, 201 created
        const rfqData = res.data.data;
        // Search quotes
        const quotes = rfqData.quotes || [];
        const quote = quotes.find(q => q.supplierId === supplierId || (q.supplierId && q.supplierId._id === supplierId));

        if (quote) {
            quoteId = quote._id;
            console.log(`   ✅ Quote Submitted! ID: ${quoteId}`);
        } else {
            // Fallback: take the last quote
            if (quotes.length > 0) {
                quoteId = quotes[quotes.length - 1]._id;
                console.log(`   ✅ Quote Submitted (Inferred ID: ${quoteId})`);
            } else {
                console.error('   ❌ No quotes in response');
            }
        }
    } else {
        console.error('   ❌ Failed to submit quote:', res.status, res.data);
        return;
    }

    // 5. Customer Views Quotes
    console.log('\n5️⃣  Customer viewing RFQ details...');
    res = await makeRequest('GET', `${API_BASE}/rfq/${createdRFQId}`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const rfq = res.data.data;
        if (rfq.quotes && rfq.quotes.length > 0) {
            console.log(`   ✅ Customer sees ${rfq.quotes.length} quote(s)`);
        }
    }

    // 6. Customer Accepts Quote
    if (quoteId) {
        console.log('\n6️⃣  Customer accepting the Quote...');
        res = await makeRequest('PUT', `${API_BASE}/rfq/${createdRFQId}/accept/${quoteId}`, {}, { 'Authorization': `Bearer ${customerToken}` });

        if (res.status === 200) {
            console.log('   ✅ Quote Accepted!');
            const updatedRfq = res.data.data;
            if (updatedRfq.status === 'awarded' || updatedRfq.status === 'closed') {
                console.log(`   ✅ RFQ Status changed to "${updatedRfq.status}"`);
            } else {
                console.log(`   ⚠️ RFQ Status is: ${updatedRfq.status} (Expected: awarded/closed)`);
            }
        } else {
            console.error('   ❌ Failed to accept quote:', res.status, res.data);
        }
    }

    console.log('\n✅ RFQ Flow Verification Complete.');
}

verifyRFQFlow();
