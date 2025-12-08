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

async function verifyAdminMessaging() {
    console.log('👨‍💼 Verifying Admin Messaging System...\n');

    let adminToken, customerToken, supplierToken;
    let adminId, customerId, supplierId;

    // 1. Authenticate Users
    console.log('1️⃣  Authenticating users...');

    // Admin Login
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'admin@indulink.com', password: 'admin123' });
    if (res.status === 200) {
        adminToken = res.data.data.accessToken;
        adminId = res.data.data.user._id;
        console.log('   ✅ Admin authenticated');
    } else {
        console.error('   ❌ Admin login failed');
        return;
    }

    // Customer Login
    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'customer1@indulink.com', password: 'customer123' });
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

    // 2. Customer sends message to Admin
    console.log('\n2️⃣  Customer sending message to Admin...');
    const customerToAdminMessage = {
        receiver: adminId,
        content: 'Hello Admin, I need help with my account.'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, customerToAdminMessage, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 201) {
        console.log('   ✅ Customer → Admin message sent!');
    } else {
        console.error('   ❌ Failed to send message:', res.status);
    }

    // 3. Supplier sends message to Admin
    console.log('\n3️⃣  Supplier sending message to Admin...');
    const supplierToAdminMessage = {
        receiver: adminId,
        content: 'Hello Admin, I have a question about my product listing.'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, supplierToAdminMessage, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 201) {
        console.log('   ✅ Supplier → Admin message sent!');
    } else {
        console.error('   ❌ Failed to send message:', res.status);
    }

    // 4. Admin checks conversations
    console.log('\n4️⃣  Admin checking all conversations...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversations`, null, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 200) {
        const conversations = res.data.data || [];
        console.log(`   ✅ Admin has ${conversations.length} conversation(s)`);

        const customerConv = conversations.find(c =>
            c.otherUser && (c.otherUser._id === customerId || c.conversationId.includes(customerId))
        );
        const supplierConv = conversations.find(c =>
            c.otherUser && (c.otherUser._id === supplierId || c.conversationId.includes(supplierId))
        );

        if (customerConv) console.log('   ✅ Customer conversation found');
        if (supplierConv) console.log('   ✅ Supplier conversation found');
    } else {
        console.error('   ❌ Failed to get conversations:', res.status);
    }

    // 5. Admin replies to Customer
    console.log('\n5️⃣  Admin replying to Customer...');
    const adminToCustomerMessage = {
        receiver: customerId,
        content: 'Hi! I can help you with that. What specifically do you need assistance with?'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, adminToCustomerMessage, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 201) {
        console.log('   ✅ Admin → Customer reply sent!');
    } else {
        console.error('   ❌ Failed to send reply:', res.status);
    }

    // 6. Admin replies to Supplier
    console.log('\n6️⃣  Admin replying to Supplier...');
    const adminToSupplierMessage = {
        receiver: supplierId,
        content: 'Hello! I\'d be happy to help with your product listing. What is your question?'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, adminToSupplierMessage, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 201) {
        console.log('   ✅ Admin → Supplier reply sent!');
    } else {
        console.error('   ❌ Failed to send reply:', res.status);
    }

    // 7. Admin checks message statistics
    console.log('\n7️⃣  Admin checking message statistics...');
    res = await makeRequest('GET', `${API_BASE}/messages/stats`, null, { 'Authorization': `Bearer ${adminToken}` });

    if (res.status === 200) {
        const stats = res.data.data;
        console.log('   ✅ Message Statistics Retrieved:');
        console.log(`      - Total Messages: ${stats.totalMessages}`);
        console.log(`      - Unread Messages: ${stats.unreadMessages}`);
        console.log(`      - Today's Messages: ${stats.todayMessages}`);
    } else {
        console.error('   ❌ Failed to get stats:', res.status);
    }

    // 8. Customer reads Admin's reply
    console.log('\n8️⃣  Customer reading Admin\'s reply...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversation/${adminId}`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const messages = res.data.data || [];
        console.log(`   ✅ Customer retrieved ${messages.length} messages from Admin`);
        const adminReply = messages.find(m => m.sender._id === adminId);
        if (adminReply) {
            console.log('   ✅ Admin\'s reply found and marked as read');
        }
    } else {
        console.error('   ❌ Failed to read messages:', res.status);
    }

    // 9. Supplier reads Admin's reply
    console.log('\n9️⃣  Supplier reading Admin\'s reply...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversation/${adminId}`, null, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200) {
        const messages = res.data.data || [];
        console.log(`   ✅ Supplier retrieved ${messages.length} messages from Admin`);
        const adminReply = messages.find(m => m.sender._id === adminId);
        if (adminReply) {
            console.log('   ✅ Admin\'s reply found and marked as read');
        }
    } else {
        console.error('   ❌ Failed to read messages:', res.status);
    }

    console.log('\n✅ Admin Messaging Verification Complete.');
}

verifyAdminMessaging();
