const baseUrl = 'http://127.0.0.1:5000/api';

async function run() {
    try {
        console.log('Logging in as Supplier...');
        const loginRes = await fetch(`${baseUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'bibek@gmail.com', password: 'bibek@123' })
        });

        const loginData = await loginRes.json();
        if (!loginData.success) throw new Error(loginData.message || 'Login failed');

        const token = loginData.data?.accessToken || loginData.token;
        const user = loginData.data?.user || loginData.user;
        console.log('✅ Logged in as:', user?.firstName, user?.lastName);

        // Fetch a category to use
        const catRes = await fetch(`${baseUrl}/categories`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const catData = await catRes.json();
        // Handle unwrapped or wrapped data
        const categories = catData.success ? (catData.data || catData.categories || []) : [];
        const categoryId = categories[0]?._id || categories[0]?.id;

        if (!categoryId) console.warn('⚠️ No categories found, using dummy ID may fail');

        const product = {
            title: 'Test Notification Product ' + Date.now(),
            description: 'This is a test product to verify notifications',
            price: 550,
            category: categoryId || '657056c7521731674488b394',
            stock: 100,
            isActive: true,
            images: ['/uploads/placeholder.jpg'],
            specifications: []
        };

        console.log('Creating product...');
        const createRes = await fetch(`${baseUrl}/supplier/products`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(product)
        });

        const createData = await createRes.json();
        if (createData.success) {
            console.log('✅ Product Created Successfully!');
            console.log('🆔 ID:', createData.product?._id);
        } else {
            console.error('❌ Failed to create product:', createData.message);
            console.dir(createData);
        }

    } catch (e) {
        console.error('❌ Error:', e.message);
    }
}

run();
