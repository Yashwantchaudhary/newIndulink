const http = require('http');

const API_BASE = 'http://localhost:5000/api';

// Utilities
function makeRequest(method, url, data = null, headers = {}) {
    return new Promise((resolve) => {
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
        if (data) req.write(JSON.stringify(data));
        req.end();
    });
}

async function verifyReviews() {
    console.log('⭐ Verifying Review System...\n');

    let customerToken, productId;

    // 1. Authenticate Customer
    console.log('1️⃣  Authenticating Customer...');
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, {
        email: 'customer1@indulink.com',
        password: 'customer123'
    });

    if (res.status === 200) {
        customerToken = res.data.data.accessToken;
        console.log('   ✅ Customer authenticated');
    } else {
        console.error('   ❌ Customer login failed');
        return;
    }

    // 2. Get a Product ID
    console.log('\n2️⃣  Fetching product to review...');
    res = await makeRequest('GET', `${API_BASE}/products`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200 && res.data.data && res.data.data.length > 0) {
        productId = res.data.data[0]._id;
        console.log(`   ✅ Found Product: ${res.data.data[0].title} (ID: ${productId})`);
    } else {
        console.error('   ❌ No products found');
        return;
    }

    // 3. Create Review (using productId)
    console.log('\n3️⃣  Creating review with "productId" field...');
    res = await makeRequest('POST', `${API_BASE}/reviews`, {
        productId: productId,  // Using productId (like frontend)
        rating: 5,
        title: 'Excellent Product!',
        comment: 'This is a test review from the verification script. The product quality is excellent and shipping was fast.'
    }, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 201) {
        console.log('   ✅ Review created successfully!');
        console.log(`   ✅ Review ID: ${res.data.data._id}`);
        console.log(`   ✅ Rating: ${res.data.data.rating}/5`);
    } else if (res.status === 400 && res.data.message && res.data.message.includes('already reviewed')) {
        console.log('   ℹ️  Review already exists (expected if re-running)');
    } else {
        console.error('   ❌ Failed to create review:', res.status, res.data);
    }

    // 4. Get Product Reviews
    console.log('\n4️⃣  Fetching product reviews...');
    res = await makeRequest('GET', `${API_BASE}/reviews/product/${productId}`, null);

    if (res.status === 200) {
        const reviews = res.data.data || [];
        console.log(`   ✅ Retrieved ${reviews.length} review(s)`);

        if (reviews.length > 0) {
            const review = reviews[0];
            console.log(`   ✅ Latest Review: ${review.rating}/5 - "${review.title}"`);
            if (review.customer) {
                console.log(`   ✅ Reviewer: ${review.customer.firstName || 'Customer'}`);
            }
        }
    } else {
        console.error('   ❌ Failed to get reviews:', res.status);
    }

    // 5. Test with 'product' field (backend compatible)
    console.log('\n5️⃣  Testing alternate field name ("product")...');
    res = await makeRequest('POST', `${API_BASE}/reviews`, {
        product: productId,  // Using product (backend original)
        rating: 4,
        title: 'Good Quality',
        comment: 'Testing with "product" field instead of "productId".'
    }, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 201 || (res.status === 400 && res.data.message && res.data.message.includes('already reviewed'))) {
        console.log('   ✅ Backend accepts "product" field');
    } else {
        console.log('   ⚠️  Backend may have issue with "product" field:', res.status);
    }

    console.log('\n✅ Review System Verification Complete.');
}

verifyReviews();
