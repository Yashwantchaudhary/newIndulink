/// 🧪 Product Enhancements Integration Tests
/// Tests for advanced search, filtering, bulk operations, and analytics

const request = require('supertest');
const app = require('../../server');
const Product = require('../../models/Product');
const Category = require('../../models/Category');
const User = require('../../models/User');
const { setupTestDatabase, cleanupTestDatabase } = require('../utils/testHelpers');

describe('Product Catalog Enhancements Integration Tests', () => {
    let testCategory;
    let testSupplier;
    let testProducts = [];
    let adminToken;
    let supplierToken;

    beforeAll(async () => {
        await setupTestDatabase();

        // Create test category
        testCategory = await Category.create({
            name: 'Test Category',
            slug: 'test-category',
            description: 'Test category for integration tests'
        });

        // Create test supplier
        testSupplier = await User.create({
            firstName: 'Test',
            lastName: 'Supplier',
            email: 'test.supplier@example.com',
            password: 'testpassword',
            role: 'supplier',
            businessName: 'Test Business'
        });

        // Create test products
        for (let i = 1; i <= 10; i++) {
            const product = await Product.create({
                title: `Test Product ${i}`,
                description: `Description for test product ${i}`,
                price: 10 + i,
                stock: 5 + i,
                category: testCategory._id,
                supplier: testSupplier._id,
                sku: `TEST-SKU-${i}`,
                tags: ['test', 'integration', i % 2 === 0 ? 'even' : 'odd'],
                isFeatured: i <= 3,
                averageRating: Math.min(5, 1 + i * 0.5)
            });
            testProducts.push(product);
        }

        // Get authentication tokens
        const adminLogin = await request(app)
            .post('/api/auth/login')
            .send({ email: 'admin@example.com', password: 'adminpassword' });

        const supplierLogin = await request(app)
            .post('/api/auth/login')
            .send({ email: 'test.supplier@example.com', password: 'testpassword' });

        adminToken = adminLogin.body.data.token;
        supplierToken = supplierLogin.body.data.token;
    });

    afterAll(async () => {
        await cleanupTestDatabase();
    });

    describe('Advanced Search Functionality', () => {
        test('should perform advanced search with multiple criteria', async () => {
            const response = await request(app)
                .post('/api/products/search')
                .send({
                    query: 'Test Product',
                    filters: {
                        priceRange: { min: 12, max: 18 },
                        ratingRange: { min: 2 }
                    },
                    sort: 'price_asc',
                    searchFields: ['title', 'description']
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.length).toBeGreaterThan(0);

            // Check that results are sorted by price ascending
            for (let i = 0; i < response.body.data.length - 1; i++) {
                expect(response.body.data[i].price).toBeLessThanOrEqual(response.body.data[i + 1].price);
            }
        });

        test('should perform fuzzy search', async () => {
            const response = await request(app)
                .post('/api/products/search')
                .send({
                    query: 'Test Prod',
                    fuzzy: true,
                    searchFields: ['title']
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.length).toBeGreaterThan(0);
        });
    });

    describe('Comprehensive Filtering Options', () => {
        test('should get available filter options', async () => {
            const response = await request(app)
                .get('/api/filters/products');

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.categories).toBeDefined();
            expect(response.body.data.priceRange).toBeDefined();
            expect(response.body.data.tags).toBeDefined();
        });

        test('should filter products with faceted search', async () => {
            const response = await request(app)
                .post('/api/filters/products')
                .send({
                    filters: {
                        priceRange: { min: 12, max: 18 },
                        stockStatus: 'in_stock',
                        tags: ['test']
                    },
                    sort: 'price_desc',
                    includeFacets: true
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.length).toBeGreaterThan(0);
            expect(response.body.facets).toBeDefined();
        });
    });

    describe('Bulk Operations Functionality', () => {
        test('should perform bulk update on products', async () => {
            const productIds = testProducts.slice(0, 3).map(p => p._id);

            const response = await request(app)
                .put('/api/products/bulk')
                .set('Authorization', `Bearer ${supplierToken}`)
                .send({
                    productIds,
                    updates: {
                        isFeatured: true,
                        price: 99.99
                    },
                    operation: 'update'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.successCount).toBe(3);

            // Verify the updates were applied
            const updatedProducts = await Product.find({ _id: { $in: productIds } });
            updatedProducts.forEach(product => {
                expect(product.isFeatured).toBe(true);
                expect(product.price).toBe(99.99);
            });
        });

        test('should perform bulk price adjustment', async () => {
            const productIds = testProducts.slice(3, 6).map(p => p._id);

            const response = await request(app)
                .put('/api/products/bulk')
                .set('Authorization', `Bearer ${supplierToken}`)
                .send({
                    productIds,
                    updates: {
                        adjustmentType: 'percentage_increase',
                        value: 10
                    },
                    operation: 'price_adjustment'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.successCount).toBe(3);
        });

        test('should perform bulk activation', async () => {
            // First deactivate some products
            await Product.updateMany(
                { _id: { $in: testProducts.slice(6, 9).map(p => p._id) } },
                { status: 'inactive' }
            );

            const productIds = testProducts.slice(6, 9).map(p => p._id);

            const response = await request(app)
                .put('/api/products/bulk')
                .set('Authorization', `Bearer ${supplierToken}`)
                .send({
                    productIds,
                    operation: 'activate'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);

            // Verify activation
            const activatedProducts = await Product.find({ _id: { $in: productIds } });
            activatedProducts.forEach(product => {
                expect(product.status).toBe('active');
            });
        });
    });

    describe('Import/Export Functionality', () => {
        test('should export products in CSV format', async () => {
            const response = await request(app)
                .post('/api/products/export')
                .set('Authorization', `Bearer ${supplierToken}`)
                .send({
                    format: 'csv',
                    filters: {
                        category: testCategory._id
                    }
                });

            expect(response.status).toBe(200);
            expect(response.headers['content-type']).toBe('text/csv');
            expect(response.headers['content-disposition']).toContain('attachment');
        });

        test('should import products', async () => {
            const csvData = `title,description,price,stock,category,sku,tags
New Product 1,Description for new product 1,29.99,25,${testCategory._id},NEW-SKU-1,import;test
New Product 2,Description for new product 2,39.99,15,${testCategory._id},NEW-SKU-2,import;test`;

            const response = await request(app)
                .post('/api/export/products')
                .set('Authorization', `Bearer ${adminToken}`)
                .attach('file', Buffer.from(csvData), 'products.csv');

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.imported).toBe(2);

            // Verify products were created
            const newProducts = await Product.find({ sku: { $in: ['NEW-SKU-1', 'NEW-SKU-2'] } });
            expect(newProducts.length).toBe(2);
        });
    });

    describe('Enhanced Analytics for Product Management', () => {
        test('should get comprehensive product performance analytics', async () => {
            const response = await request(app)
                .get('/api/analytics/products/performance')
                .set('Authorization', `Bearer ${supplierToken}`)
                .query({ timeframe: '30d' });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.salesPerformance).toBeDefined();
            expect(response.body.data.inventoryAnalytics).toBeDefined();
        });

        test('should get product trend analysis', async () => {
            const productId = testProducts[0]._id;

            const response = await request(app)
                .get('/api/analytics/products/trends')
                .set('Authorization', `Bearer ${supplierToken}`)
                .query({
                    productId,
                    timeframe: '30d'
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.trendData).toBeDefined();
            expect(response.body.data.trendData.length).toBeGreaterThan(0);
        });

        test('should compare multiple products', async () => {
            const productIds = testProducts.slice(0, 3).map(p => p._id);

            const response = await request(app)
                .post('/api/analytics/products/compare')
                .set('Authorization', `Bearer ${supplierToken}`)
                .send({
                    productIds,
                    metrics: ['sales', 'views', 'rating', 'stock']
                });

            expect(response.status).toBe(200);
            expect(response.body.success).toBe(true);
            expect(response.body.data.comparisonData.length).toBe(3);
            expect(response.body.data.comparisonData[0].metrics.sales).toBeDefined();
        });
    });
});

module.exports = {
    testProductEnhancements: () => describe('Product Catalog Enhancements Integration Tests', () => {})
};