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

async function verifyCustomerFeatures() {
    console.log('🛍️  Verifying Customer Features...\n');

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
    console.log('\n2️⃣  Fetching products to test with...');
    res = await makeRequest('GET', `${API_BASE}/products`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200 && res.data.data && res.data.data.length > 0) {
        productId = res.data.data[0]._id;
        console.log(`   ✅ Found Product: ${res.data.data[0].title || res.data.data[0].name} (ID: ${productId})`);
    } else {
        console.error('   ❌ No products found');
        return;
    }

    // 3. Add to Wishlist
    console.log('\n3️⃣  Adding product to wishlist...');
    res = await makeRequest('POST', `${API_BASE}/wishlist/${productId}`, {}, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        console.log('   ✅ Product added to wishlist!');
        if (res.data.data && res.data.data.products) {
            const wishlistItems = res.data.data.products;
            console.log(`   ✅ Wishlist now has ${wishlistItems.length} item(s)`);

            // Check if product data is populated correctly
            if (wishlistItems.length > 0) {
                const item = wishlistItems[0];
                if (item.productId && item.productId.title) {
                    console.log(`   ✅ Product title populated: "${item.productId.title}"`);
                } else if (item.productId && item.productId.name) {
                    console.log(`   ⚠️  WARNING: Using 'name' field (should be 'title')`);
                } else {
                    console.log(`   ❌ Product data not populated correctly`);
                }
            }
        }
    } else {
        console.error('   ❌ Failed to add to wishlist:', res.status, res.data);
    }

    // 4. Get Wishlist
    console.log('\n4️⃣  Fetching wishlist...');
    res = await makeRequest('GET', `${API_BASE}/wishlist`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const items = res.data.data.products || [];
        console.log(`   ✅ Retrieved wishlist with ${items.length} item(s)`);

        if (items.length > 0) {
            const item = items[0];
            if (item.productId && item.productId.title) {
                console.log(`   ✅ Product details: ${item.productId.title} - Rs. ${item.productId.price}`);
            } else {
                console.log(`   ❌ Product data missing or incomplete`);
            }
        }
    } else {
        console.error('   ❌ Failed to get wishlist:', res.status);
    }

    // 5. Remove from Wishlist
    console.log('\n5️⃣  Removing product from wishlist...');
    res = await makeRequest('DELETE', `${API_BASE}/wishlist/${productId}`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        console.log('   ✅ Product removed from wishlist!');
        console.log(`   ✅ Wishlist now has ${res.data.data.products.length} item(s)`);
    } else {
        console.error('   ❌ Failed to remove from wishlist:', res.status);
    }

    // 6. Add to Cart
    console.log('\n6️⃣  Testing cart functionality...');
    res = await makeRequest('POST', `${API_BASE}/cart`, {
        productId: productId,
        quantity: 2
    }, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200 || res.status === 201) {
        console.log('   ✅ Product added to cart!');
        console.log(`   ✅ Cart has ${res.data.data.items.length} unique item(s)`);
    } else {
        console.error('   ❌ Failed to add to cart:', res.status);
    }

    // 7. Get Cart
    console.log('\n7️⃣  Fetching cart...');
    res = await makeRequest('GET', `${API_BASE}/cart`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const cart = res.data.data;
        console.log(`   ✅ Cart retrieved with ${cart.items.length} item(s)`);
        console.log(`   ✅ Cart Total: Rs. ${cart.total}`);
    } else {
        console.error('   ❌ Failed to get cart:', res.status);
    }

    console.log('\n✅ Customer Features Verification Complete.');
    console.log('\n📝 Note: Order placement should be tested manually in the app due to address requirements.');
}

verifyCustomerFeatures();
