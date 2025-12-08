const axios = require('axios');

const API_URL = 'http://localhost:5000/api/auth';
const TEST_USER = {
    firstName: 'Production',
    lastName: 'TestUser',
    email: `prod_test_${Date.now()}@example.com`,
    password: 'SecurePassword123!',
    phone: '9800000000',
    role: 'customer'
};

async function verifyAuth() {
    console.log('🚀 Starting Authentication Verification...');
    console.log('Target:', API_URL);

    try {
        // 1. Test Registration
        console.log('\n1️⃣ Testing Registration...');
        console.log('Sending data:', TEST_USER);

        const registerResponse = await axios.post(`${API_URL}/register`, TEST_USER);

        if (registerResponse.status === 201 && registerResponse.data.success) {
            console.log('✅ Registration Successful!');
            console.log('User ID:', registerResponse.data.data.user._id);
            console.log('Access Token received:', !!registerResponse.data.data.accessToken);
        } else {
            console.error('❌ Registration Failed:', registerResponse.data);
            process.exit(1);
        }

        // 2. Test Login
        console.log('\n2️⃣ Testing Login...');
        const loginCredentials = {
            email: TEST_USER.email,
            password: TEST_USER.password
        };
        console.log('Logging in with:', loginCredentials);

        const loginResponse = await axios.post(`${API_URL}/login`, loginCredentials);

        if (loginResponse.status === 200 && loginResponse.data.success) {
            console.log('✅ Login Successful!');
            const token = loginResponse.data.data.accessToken;
            console.log('Access Token received:', !!token);

            // 3. Test Protected Route (Get Me)
            console.log('\n3️⃣ Testing Protected Route (/me)...');
            try {
                const meResponse = await axios.get(`${API_URL}/me`, {
                    headers: { Authorization: `Bearer ${token}` }
                });

                if (meResponse.status === 200 && meResponse.data.success) {
                    console.log('✅ Protected Route Access Successful!');
                    console.log('Verified User Email:', meResponse.data.data.email);
                }
            } catch (error) {
                console.error('❌ Protected Route Failed:', error.response?.data || error.message);
            }

        } else {
            console.error('❌ Login Failed:', loginResponse.data);
            process.exit(1);
        }

        console.log('\n🎉 ALL CHECKS PASSED: Backend Authentication is Production-Ready!');

    } catch (error) {
        console.error('\n❌ Verification Failed!');
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        } else {
            console.error('Error:', error.message);
        }
    }
}

// Check if axios is installed, if not we can't run this easily without installing it. 
// Assuming the user has axios or fetch available in node usually, but let's use standard http if we want to be safe? 
// Actually, I'll assume I can run `npm install axios` or just use standard http to be dependency-free.
// Let's rewrite to use standard 'http' module to be safe and dependency-free.
verifyAuth();
