const { faker } = require('@faker-js/faker');
const bcrypt = require('bcryptjs');

// Utility functions for generating sample data
class SampleDataUtils {
    // Generate random users
    static generateUsers(count = 10, role = 'customer') {
        const users = [];
        const firstNames = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emma', 'Chris', 'Lisa', 'Robert', 'Maria'];
        const lastNames = ['Smith', 'Johnson', 'Brown', 'Williams', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
        const cities = ['Kathmandu', 'Pokhara', 'Lalitpur', 'Bhaktapur', 'Biratnagar', 'Birgunj', 'Dharan', 'Butwal', 'Hetauda', 'Janakpur'];
        const streets = ['Main Road', 'Market Street', 'Temple Road', 'River Side', 'Hill View', 'Garden Lane', 'Commercial Area', 'Residential Block'];

        for (let i = 0; i < count; i++) {
            const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
            const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
            const city = cities[Math.floor(Math.random() * cities.length)];
            const street = streets[Math.floor(Math.random() * streets.length)];

            const user = {
                firstName,
                lastName,
                email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}${i}@example.com`,
                password: 'password123', // Will be hashed by pre-save middleware
                phone: `+977-98${Math.floor(Math.random() * 90000000 + 10000000)}`,
                role,
                addresses: [{
                    label: 'home',
                    fullName: `${firstName} ${lastName}`,
                    phone: `+977-98${Math.floor(Math.random() * 90000000 + 10000000)}`,
                    addressLine1: `${Math.floor(Math.random() * 500) + 1} ${street}`,
                    city,
                    state: 'Bagmati',
                    postalCode: `${Math.floor(Math.random() * 90000 + 10000)}`,
                    country: 'Nepal',
                    isDefault: true
                }],
                isEmailVerified: Math.random() > 0.3, // 70% verified
                isActive: Math.random() > 0.1, // 90% active
                notificationPreferences: {
                    orderUpdates: Math.random() > 0.2,
                    promotions: Math.random() > 0.3,
                    messages: Math.random() > 0.2,
                    system: true,
                    emailNotifications: Math.random() > 0.3,
                    pushNotifications: Math.random() > 0.4
                }
            };

            // Add supplier-specific fields
            if (role === 'supplier') {
                user.businessName = `${firstName} ${lastName} Enterprises`;
                user.businessDescription = `Leading supplier of quality products in ${city}. We specialize in providing excellent service and competitive pricing.`;
                user.businessAddress = `${Math.floor(Math.random() * 500) + 1} ${street}, ${city}`;
                user.businessLicense = `LIC${Math.floor(Math.random() * 900000 + 100000)}`;
            }

            users.push(user);
        }

        return users;
    }

    // Generate categories
    static generateCategories() {
        const mainCategories = [
            { name: 'Electronics', description: 'Electronic devices and accessories', icon: '📱' },
            { name: 'Clothing', description: 'Fashion and apparel', icon: '👕' },
            { name: 'Home & Garden', description: 'Home improvement and garden supplies', icon: '🏠' },
            { name: 'Sports & Outdoors', description: 'Sports equipment and outdoor gear', icon: '⚽' },
            { name: 'Books & Media', description: 'Books, movies, and digital media', icon: '📚' },
            { name: 'Health & Beauty', description: 'Health products and beauty supplies', icon: '💄' },
            { name: 'Automotive', description: 'Car parts and automotive accessories', icon: '🚗' },
            { name: 'Toys & Games', description: 'Toys, games, and entertainment', icon: '🧸' }
        ];

        const subcategories = {
            'Electronics': ['Smartphones', 'Laptops', 'Tablets', 'Headphones', 'Cameras', 'Gaming Consoles', 'Electronic Accessories'],
            'Clothing': ['Men\'s Clothing', 'Women\'s Clothing', 'Kids\' Clothing', 'Shoes', 'Fashion Accessories', 'Sportswear'],
            'Home & Garden': ['Furniture', 'Kitchen Appliances', 'Bathroom', 'Garden Tools', 'Home Decor', 'Lighting', 'Home Appliances'],
            'Sports & Outdoors': ['Fitness Equipment', 'Outdoor Gear', 'Team Sports', 'Water Sports', 'Cycling', 'Camping'],
            'Books & Media': ['Fiction Books', 'Non-Fiction Books', 'Textbooks', 'Magazines', 'Movies', 'Music', 'Digital Media'],
            'Health & Beauty': ['Skincare', 'Hair Care', 'Makeup', 'Supplements', 'Fitness', 'Personal Care'],
            'Automotive': ['Car Parts', 'Tools', 'Car Accessories', 'Car Electronics', 'Maintenance', 'Tires'],
            'Toys & Games': ['Action Figures', 'Board Games', 'Puzzles', 'Educational Toys', 'Outdoor Toys', 'Video Games']
        };

        const categories = [];

        mainCategories.forEach((mainCat, index) => {
            const mainSlug = mainCat.name
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/(^-|-$)/g, '');

            // Add main category
            categories.push({
                ...mainCat,
                slug: mainSlug,
                level: 0,
                order: index,
                isActive: true
            });

            // Add subcategories
            if (subcategories[mainCat.name]) {
                subcategories[mainCat.name].forEach((subName, subIndex) => {
                    const subSlug = subName
                        .toLowerCase()
                        .replace(/[^a-z0-9]+/g, '-')
                        .replace(/(^-|-$)/g, '');

                    categories.push({
                        name: subName,
                        slug: subSlug,
                        description: `${subName} products`,
                        parent: null, // Will be set after insertion
                        level: 1,
                        order: subIndex,
                        isActive: true
                    });
                });
            }
        });

        return categories;
    }

    // Generate products
    static generateProducts(categories, suppliers, count = 50) {
        const products = [];
        const productTemplates = [
            // Electronics
            { title: 'Wireless Bluetooth Headphones', price: 2999, category: 'Electronics' },
            { title: 'Smartphone 128GB', price: 25999, category: 'Electronics' },
            { title: 'Gaming Laptop', price: 89999, category: 'Electronics' },
            { title: '4K Action Camera', price: 15999, category: 'Electronics' },
            { title: 'Wireless Charging Pad', price: 1499, category: 'Electronics' },

            // Clothing
            { title: 'Cotton T-Shirt', price: 899, category: 'Clothing' },
            { title: 'Denim Jeans', price: 2499, category: 'Clothing' },
            { title: 'Winter Jacket', price: 4999, category: 'Clothing' },
            { title: 'Running Shoes', price: 3499, category: 'Clothing' },
            { title: 'Leather Wallet', price: 1299, category: 'Clothing' },

            // Home & Garden
            { title: 'Ceramic Dinner Set', price: 3999, category: 'Home & Garden' },
            { title: 'Garden Hose 50ft', price: 1899, category: 'Home & Garden' },
            { title: 'LED Desk Lamp', price: 2499, category: 'Home & Garden' },
            { title: 'Throw Pillow Set', price: 1499, category: 'Home & Garden' },
            { title: 'Stainless Steel Cookware', price: 5999, category: 'Home & Garden' },

            // Sports & Outdoors
            { title: 'Yoga Mat', price: 1999, category: 'Sports & Outdoors' },
            { title: 'Dumbbell Set 20kg', price: 4999, category: 'Sports & Outdoors' },
            { title: 'Camping Tent', price: 8999, category: 'Sports & Outdoors' },
            { title: 'Basketball', price: 2499, category: 'Sports & Outdoors' },
            { title: 'Cycling Helmet', price: 3499, category: 'Sports & Outdoors' },

            // Books & Media
            { title: 'Programming Textbook', price: 1499, category: 'Books & Media' },
            { title: 'Novel Collection', price: 999, category: 'Books & Media' },
            { title: 'Educational DVD Set', price: 1999, category: 'Books & Media' },
            { title: 'Music CD Collection', price: 2499, category: 'Books & Media' },
            { title: 'Digital Drawing Tablet', price: 7999, category: 'Books & Media' },

            // Health & Beauty
            { title: 'Face Moisturizer', price: 1899, category: 'Health & Beauty' },
            { title: 'Vitamin Supplements', price: 2999, category: 'Health & Beauty' },
            { title: 'Hair Dryer', price: 3499, category: 'Health & Beauty' },
            { title: 'Fitness Tracker', price: 5999, category: 'Health & Beauty' },
            { title: 'Essential Oil Set', price: 2499, category: 'Health & Beauty' },

            // Automotive
            { title: 'Car Air Freshener', price: 499, category: 'Automotive' },
            { title: 'Tire Pressure Gauge', price: 899, category: 'Automotive' },
            { title: 'Car Vacuum Cleaner', price: 3999, category: 'Automotive' },
            { title: 'Dashboard Camera', price: 7999, category: 'Automotive' },
            { title: 'Engine Oil 5L', price: 2499, category: 'Automotive' },

            // Toys & Games
            { title: 'Building Block Set', price: 2999, category: 'Toys & Games' },
            { title: 'Board Game Collection', price: 1999, category: 'Toys & Games' },
            { title: 'Remote Control Car', price: 4999, category: 'Toys & Games' },
            { title: 'Puzzle 1000 Pieces', price: 1499, category: 'Toys & Games' },
            { title: 'Educational Toy Set', price: 3499, category: 'Toys & Games' }
        ];

        for (let i = 0; i < count; i++) {
            const template = productTemplates[Math.floor(Math.random() * productTemplates.length)];
            const category = categories.find(cat => cat.name === template.category);
            const supplier = suppliers[Math.floor(Math.random() * suppliers.length)];

            const variations = Math.random() > 0.7 ? Math.floor(Math.random() * 3) + 1 : 0; // 30% have variations
            const basePrice = template.price + (Math.random() - 0.5) * template.price * 0.4; // ±20% variation

            const product = {
                title: `${template.title} ${variations > 0 ? `Variant ${i % variations + 1}` : ''}`.trim(),
                description: `High-quality ${template.title.toLowerCase()} with excellent features and durability. Perfect for everyday use and comes with warranty.`,
                price: Math.round(basePrice),
                compareAtPrice: Math.random() > 0.6 ? Math.round(basePrice * 1.2) : null, // 40% have compare price
                images: [
                    {
                        url: `https://picsum.photos/400/400?random=${i + 1}`,
                        alt: template.title,
                        isPrimary: true
                    },
                    {
                        url: `https://picsum.photos/400/400?random=${i + 100}`,
                        alt: `${template.title} - Side view`
                    }
                ],
                category: category ? category._id : categories[0]._id,
                supplier: supplier._id,
                stock: Math.floor(Math.random() * 100) + 10, // 10-110 stock
                sku: `SKU${String(i + 1).padStart(6, '0')}`,
                weight: {
                    value: Math.random() * 5 + 0.5, // 0.5-5.5 kg
                    unit: 'kg'
                },
                dimensions: {
                    length: Math.random() * 50 + 10, // 10-60 cm
                    width: Math.random() * 50 + 10,
                    height: Math.random() * 50 + 10,
                    unit: 'cm'
                },
                tags: [template.category.toLowerCase(), 'quality', 'durable'],
                status: Math.random() > 0.1 ? 'active' : 'inactive', // 90% active
                isFeatured: Math.random() > 0.8, // 20% featured
                metaTitle: template.title,
                metaDescription: `Buy ${template.title} online at best prices. Quality assured with fast delivery.`,
                viewCount: Math.floor(Math.random() * 1000),
                purchaseCount: Math.floor(Math.random() * 100)
            };

            products.push(product);
        }

        return products;
    }

    // Generate orders
    static generateOrders(customers, products, suppliers, count = 20) {
        const orders = [];
        const statuses = ['pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled'];
        const paymentMethods = ['cash_on_delivery', 'online', 'wallet'];
        const paymentStatuses = ['pending', 'paid', 'failed'];

        for (let i = 0; i < count; i++) {
            const customer = customers[Math.floor(Math.random() * customers.length)];
            const supplier = suppliers[Math.floor(Math.random() * suppliers.length)];

            // Generate order items
            const itemCount = Math.floor(Math.random() * 5) + 1; // 1-5 items
            const orderItems = [];
            let subtotal = 0;

            for (let j = 0; j < itemCount; j++) {
                const product = products[Math.floor(Math.random() * products.length)];
                const quantity = Math.floor(Math.random() * 5) + 1; // 1-5 quantity
                const price = product.price;
                const itemSubtotal = price * quantity;

                orderItems.push({
                    product: product._id,
                    productSnapshot: {
                        title: product.title,
                        image: product.images[0]?.url,
                        sku: product.sku
                    },
                    quantity,
                    price,
                    subtotal: itemSubtotal
                });

                subtotal += itemSubtotal;
            }

            const tax = Math.round(subtotal * 0.13); // 13% tax
            const shippingCost = subtotal > 5000 ? 0 : 250; // Free shipping over 5000
            const total = subtotal + tax + shippingCost;

            const status = statuses[Math.floor(Math.random() * statuses.length)];
            const paymentMethod = paymentMethods[Math.floor(Math.random() * paymentMethods.length)];
            const paymentStatus = status === 'delivered' ? 'paid' : paymentStatuses[Math.floor(Math.random() * paymentStatuses.length)];

            // Generate order number manually (similar to the pre-save middleware)
            const orderNumber = `IND${Date.now()}${String(i + 1).padStart(4, '0')}`;

            const order = {
                orderNumber,
                customer: customer._id,
                supplier: supplier._id,
                items: orderItems,
                subtotal,
                tax,
                shippingCost,
                total,
                shippingAddress: customer.addresses[0],
                status,
                paymentMethod,
                paymentStatus,
                customerNote: Math.random() > 0.7 ? 'Please handle with care' : null,
                supplierNote: Math.random() > 0.8 ? 'Order processed successfully' : null
            };

            // Add status-specific timestamps
            const createdAt = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000); // Last 30 days
            order.createdAt = createdAt;

            if (['confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered'].includes(status)) {
                order.confirmedAt = new Date(createdAt.getTime() + Math.random() * 2 * 24 * 60 * 60 * 1000);
            }
            if (['shipped', 'out_for_delivery', 'delivered'].includes(status)) {
                order.shippedAt = new Date(order.confirmedAt.getTime() + Math.random() * 3 * 24 * 60 * 60 * 1000);
            }
            if (status === 'delivered') {
                order.deliveredAt = new Date(order.shippedAt.getTime() + Math.random() * 5 * 24 * 60 * 60 * 1000);
            }
            if (status === 'cancelled') {
                order.cancelledAt = new Date(createdAt.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000);
                order.cancellationReason = 'Customer requested cancellation';
            }

            orders.push(order);
        }

        return orders;
    }

    // Generate reviews
    static generateReviews(customers, products, orders, count = 30) {
        const reviews = [];
        const usedCombinations = new Set(); // Track product-customer combinations
        const reviewTitles = [
            'Excellent product!', 'Great quality', 'Satisfied with purchase', 'Good value for money',
            'Fast delivery', 'Highly recommended', 'Could be better', 'Average product', 'Not satisfied',
            'Amazing quality', 'Worth every penny', 'Decent product', 'Delivery was slow'
        ];
        const reviewComments = [
            'I am very happy with this purchase. The product quality is excellent and it arrived on time.',
            'Good product for the price. Would recommend to others looking for quality items.',
            'The item was as described. Fast shipping and good packaging. Will buy again.',
            'Satisfied with the overall experience. The product works well and customer service was helpful.',
            'Quality could be better but for the price it\'s acceptable. Delivery was on time.',
            'Amazing product! Exceeded my expectations. Highly recommend this seller.',
            'The product is okay but took longer than expected to arrive. Otherwise satisfied.',
            'Great value for money. The product performs well and looks exactly like the pictures.',
            'Not completely satisfied with the quality. Expected better for the price paid.',
            'Excellent service from start to finish. Product is high quality and well packaged.'
        ];

        let attempts = 0;
        const maxAttempts = count * 3; // Prevent infinite loops

        while (reviews.length < count && attempts < maxAttempts) {
            const customer = customers[Math.floor(Math.random() * customers.length)];
            const product = products[Math.floor(Math.random() * products.length)];
            const combinationKey = `${product._id}-${customer._id}`;

            // Skip if this combination already exists
            if (usedCombinations.has(combinationKey)) {
                attempts++;
                continue;
            }

            // Find an order that contains this product and belongs to this customer
            const relevantOrder = orders.find(order =>
                order.customer.toString() === customer._id.toString() &&
                order.items.some(item => item.product.toString() === product._id.toString())
            );

            if (!relevantOrder) {
                attempts++;
                continue; // No order found for this combination
            }

            const rating = Math.floor(Math.random() * 5) + 1; // 1-5 stars
            const title = reviewTitles[Math.floor(Math.random() * reviewTitles.length)];
            const comment = reviewComments[Math.floor(Math.random() * reviewComments.length)];

            const review = {
                product: product._id,
                customer: customer._id,
                order: relevantOrder._id,
                rating,
                title,
                comment,
                isVerifiedPurchase: Math.random() > 0.2, // 80% verified
                status: 'approved',
                helpfulCount: Math.floor(Math.random() * 20)
            };

            reviews.push(review);
            usedCombinations.add(combinationKey);
        }

        return reviews;
    }

    // Generate notifications
    static generateNotifications(users, orders, products, count = 40) {
        const notifications = [];
        const types = ['order', 'promotion', 'message', 'system', 'review'];
        const orderMessages = [
            'Your order has been confirmed',
            'Your order is being processed',
            'Your order has been shipped',
            'Your order is out for delivery',
            'Your order has been delivered successfully'
        ];
        const promotionMessages = [
            'Flash Sale: 50% off on selected items!',
            'New arrivals in Electronics category',
            'Limited time offer: Buy one get one free',
            'Clearance sale: Up to 70% off',
            'Weekend special: Free shipping on orders over Rs. 2000'
        ];
        const systemMessages = [
            'Welcome to InduLink! Start exploring our products.',
            'Your account has been verified successfully.',
            'Password changed successfully.',
            'Profile updated successfully.',
            'New feature available: Wishlist functionality.'
        ];

        for (let i = 0; i < count; i++) {
            const user = users[Math.floor(Math.random() * users.length)];
            const type = types[Math.floor(Math.random() * types.length)];

            let title, message, data = {};

            switch (type) {
                case 'order':
                    const order = orders[Math.floor(Math.random() * orders.length)];
                    title = 'Order Update';
                    message = orderMessages[Math.floor(Math.random() * orderMessages.length)];
                    data = { orderId: order._id, orderNumber: order.orderNumber };
                    break;
                case 'promotion':
                    title = 'Special Offer';
                    message = promotionMessages[Math.floor(Math.random() * promotionMessages.length)];
                    data = { category: 'Electronics' };
                    break;
                case 'message':
                    title = 'New Message';
                    message = 'You have received a new message from a supplier.';
                    data = { senderId: users[Math.floor(Math.random() * users.length)]._id };
                    break;
                case 'system':
                    title = 'System Notification';
                    message = systemMessages[Math.floor(Math.random() * systemMessages.length)];
                    break;
                case 'review':
                    const product = products[Math.floor(Math.random() * products.length)];
                    title = 'New Review';
                    message = `Your product "${product.title}" received a new review.`;
                    data = { productId: product._id };
                    break;
            }

            const notification = {
                userId: user._id,
                type,
                title,
                message,
                data,
                isRead: Math.random() > 0.6, // 40% read
                createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000) // Last 7 days
            };

            if (notification.isRead) {
                notification.readAt = new Date(notification.createdAt.getTime() + Math.random() * 24 * 60 * 60 * 1000);
            }

            notifications.push(notification);
        }

        return notifications;
    }
}

module.exports = SampleDataUtils;