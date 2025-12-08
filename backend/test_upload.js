const fs = require('fs');
const path = require('path');

// Configuration
const API_URL = 'http://localhost:5000/api';

async function testUpload() {
    try {
        console.log('1. Logging in as supplier...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'supplier1@indulink.com',
                password: 'supplier123'
            })
        });

        if (!loginRes.ok) {
            throw new Error(`Login failed: ${loginRes.status} ${loginRes.statusText}`);
        }

        const loginData = await loginRes.json();
        const token = loginData.data.accessToken;
        console.log('Login successful. Token obtained.');
        console.log('User ID:', loginData.data.user._id);

        console.log('2. Preparing product upload...');

        // Fetch categories to get a valid ID
        const catRes = await fetch(`${API_URL}/categories`);
        const catData = await catRes.json();
        const categoryId = catData.data[0]._id;
        console.log(`Using Category ID: ${categoryId}`);

        // Create dummy file
        const dummyFilePath = path.join(__dirname, 'dummy_image.jpg');
        fs.writeFileSync(dummyFilePath, 'dummy image content');
        const fileBuffer = fs.readFileSync(dummyFilePath);
        const fileBlob = new Blob([fileBuffer], { type: 'image/jpeg' });

        // Construct FormData
        const form = new FormData();
        form.append('title', 'Test Upload Product (Fetch)');
        form.append('description', 'This is a test product uploaded via native fetch.');
        form.append('price', '123.45');
        form.append('stock', '50');
        form.append('category', categoryId);
        form.append('isFeatured', 'false');
        form.append('images', fileBlob, 'dummy_image.jpg');

        console.log('3. Sending POST request to /api/supplier/products...');
        const uploadRes = await fetch(`${API_URL}/supplier/products`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
                // Note: Do NOT set Content-Type header manually when using FormData, 
                // the browser/environment sets it with the boundary.
            },
            body: form
        });

        console.log('Upload Response Status:', uploadRes.status);
        const uploadData = await uploadRes.json();
        console.log('Upload Response Data:', JSON.stringify(uploadData, null, 2));

        // Cleanup
        fs.unlinkSync(dummyFilePath);

    } catch (error) {
        console.error('Test Failed!');
        console.error('Error:', error);
    }
}

testUpload();
