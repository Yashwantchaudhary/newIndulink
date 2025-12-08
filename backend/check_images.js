const http = require('http');

const API_BASE = 'http://localhost:5000/api';

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

async function checkProductImages() {
    console.log('🖼️  Checking Product Image URLs...\n');

    const res = await makeRequest('GET', `${API_BASE}/products?limit=2`);

    if (res.status === 200 && res.data.data) {
        const products = res.data.data;
        console.log(`Found ${products.length} product(s)\n`);

        products.forEach((product, index) => {
            console.log(`Product ${index + 1}: ${product.title}`);
            console.log(`  Images count: ${product.images?.length || 0}`);

            if (product.images && product.images.length > 0) {
                product.images.forEach((img, imgIndex) => {
                    console.log(`  Image ${imgIndex + 1}:`);
                    console.log(`    URL: ${img.url}`);
                    console.log(`    Primary: ${img.isPrimary || false}`);
                });
            } else {
                console.log('  ⚠️  No images found!');
            }
            console.log('');
        });
    } else {
        console.error('Failed to fetch products:', res.status);
    }
}

checkProductImages();
