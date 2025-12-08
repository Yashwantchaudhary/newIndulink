const http = require('http');

const TEST_USER = {
    firstName: 'Production',
    lastName: 'TestUser',
    email: `prod_test_${Date.now()}@example.com`,
    password: 'SecurePassword123!',
    phone: '9800000000',
    role: 'customer'
};

function makeRequest(path, method, data, token = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 5000,
            path: '/api/auth' + path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        if (token) {
            options.headers['Authorization'] = `Bearer ${token}`;
        }

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(body);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', reject);

        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function verifyAuth() {
    console.log('🚀 Starting Authentication Verification (Native HTTP)...');

    try {
        // 1. Registration
        console.log('\n1️⃣ Testing Registration...');
        console.log('Sending:', TEST_USER);

        const regRes = await makeRequest('/register', 'POST', TEST_USER);

        if (regRes.status === 201 && regRes.data.success) {
            console.log('✅ Registration Successful!');
        } else {
            console.error('❌ Registration Failed:', regRes.data);
            process.exit(1);
        }

        // 2. Login
        console.log('\n2️⃣ Testing Login...');
        const loginRes = await makeRequest('/login', 'POST', {
            email: TEST_USER.email,
            password: TEST_USER.password
        });

        if (loginRes.status === 200 && loginRes.data.success) {
            console.log('✅ Login Successful!');
            const token = loginRes.data.data.accessToken;

            // 3. Protected Route
            console.log('\n3️⃣ Testing Protected Route (/me)...');
            const meRes = await makeRequest('/me', 'GET', null, token);

            if (meRes.status === 200 && meRes.data.success) {
                console.log('✅ Protected Route Access Successful!');
                console.log('User:', meRes.data.data.email);
                console.log('\n🎉 BACKEND AUTHENTICATION IS WORKING CORRECTLY!');
            } else {
                console.error('❌ Protected Route Failed:', meRes.data);
            }
        } else {
            console.error('❌ Login Failed:', loginRes.data);
        }

    } catch (error) {
        console.error('❌ Error executing script:', error);
    }
}

verifyAuth();
