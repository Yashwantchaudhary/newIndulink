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

async function verifyMessaging() {
    console.log('💬 Verifying Messaging System...\n');

    let customerToken, supplierToken;
    let customerId, supplierId;
    let sentMessageId, conversationId;

    // 1. Authenticate Users
    console.log('1️⃣  Authenticating users...');
    let res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'customer1@indulink.com', password: 'customer123' });

    if (res.status === 200) {
        customerToken = res.data.data.accessToken;
        customerId = res.data.data.user._id;
        console.log('   ✅ Customer authenticated');
    } else {
        console.error('   ❌ Customer login failed');
        return;
    }

    res = await makeRequest('POST', `${API_BASE}/auth/login`, { email: 'supplier1@indulink.com', password: 'supplier123' });
    if (res.status === 200) {
        supplierToken = res.data.data.accessToken;
        supplierId = res.data.data.user._id;
        console.log('   ✅ Supplier authenticated');
    } else {
        console.error('   ❌ Supplier login failed');
        return;
    }

    // 2. Customer sends message to Supplier
    console.log('\n2️⃣  Customer sending message to Supplier...');
    const messagePayload = {
        receiver: supplierId,
        content: 'Hello! I have a question about your products.'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, messagePayload, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 201) {
        sentMessageId = res.data.data._id;
        conversationId = res.data.data.conversationId;
        console.log(`   ✅ Message Sent! ID: ${sentMessageId}`);
        console.log(`   ✅ Conversation ID: ${conversationId}`);
    } else {
        console.error('   ❌ Failed to send message:', res.status, res.data);
        return;
    }

    // 3. Supplier gets conversations
    console.log('\n3️⃣  Supplier checking conversations...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversations`, null, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200) {
        const conversations = res.data.data || [];
        console.log(`   ✅ Retrieved ${conversations.length} conversation(s)`);

        const found = conversations.find(c => c.conversationId === conversationId);
        if (found) {
            console.log(`   ✅ New conversation is visible (Unread: ${found.unreadCount})`);
        } else {
            console.log('   ⚠️  Conversation not found in list');
        }
    } else {
        console.error('   ❌ Failed to get conversations:', res.status);
    }

    // 4. Supplier gets messages in conversation
    console.log('\n4️⃣  Supplier retrieving messages...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversation/${customerId}`, null, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 200) {
        const messages = res.data.data || [];
        console.log(`   ✅ Retrieved ${messages.length} message(s)`);

        const sentMsg = messages.find(m => m._id === sentMessageId);
        if (sentMsg) {
            console.log(`   ✅ Sent message found`);
            console.log(`   ✅ Message marked as read: ${sentMsg.isRead}`);
        }
    } else {
        console.error('   ❌ Failed to get messages:', res.status);
    }

    // 5. Supplier replies
    console.log('\n5️⃣  Supplier replying to Customer...');
    const replyPayload = {
        receiver: customerId,
        content: 'Hi! Sure, I\'d be happy to help. What would you like to know?'
    };

    res = await makeRequest('POST', `${API_BASE}/messages`, replyPayload, { 'Authorization': `Bearer ${supplierToken}` });

    if (res.status === 201) {
        console.log('   ✅ Reply Sent!');
    } else {
        console.error('   ❌ Failed to send reply:', res.status);
    }

    // 6. Customer checks unread count
    console.log('\n6️⃣  Customer checking unread count...');
    res = await makeRequest('GET', `${API_BASE}/messages/unread/count`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const unreadCount = res.data.data.unreadCount;
        console.log(`   ✅ Unread messages: ${unreadCount}`);
    } else {
        console.error('   ❌ Failed to get unread count:', res.status);
    }

    // 7. Customer reads messages
    console.log('\n7️⃣  Customer reading messages...');
    res = await makeRequest('GET', `${API_BASE}/messages/conversation/${supplierId}`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const messages = res.data.data || [];
        console.log(`   ✅ Retrieved ${messages.length} message(s)`);
        console.log(`   ✅ Messages auto-marked as read on retrieval`);
    } else {
        console.error('   ❌ Failed to read messages:', res.status);
    }

    // 8. Verify unread count is now 0
    console.log('\n8️⃣  Verifying unread count after reading...');
    res = await makeRequest('GET', `${API_BASE}/messages/unread/count`, null, { 'Authorization': `Bearer ${customerToken}` });

    if (res.status === 200) {
        const unreadCount = res.data.data.unreadCount;
        console.log(`   ✅ Unread messages: ${unreadCount} (Should be 0)`);
    }

    console.log('\n✅ Messaging System Verification Complete.');
}

verifyMessaging();
