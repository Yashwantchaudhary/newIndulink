const request = require('supertest');
const app = require('../server');
const Order = require('../models/Order');
const User = require('../models/User');
const { setupTestDB, teardownTestDB, createTestUser, createTestOrder } = require('./utils/testHelpers');

describe('Order Controller Improvements', () => {
    let adminUser, customerUser, supplierUser;
    let adminToken, customerToken, supplierToken;
    let testOrder;

    beforeAll(async () => {
        await setupTestDB();

        // Create test users
        adminUser = await createTestUser({ role: 'admin' });
        customerUser = await createTestUser({ role: 'customer' });
        supplierUser = await createTestUser({ role: 'supplier' });

        // Create test order
        testOrder = await createTestOrder({
            customer: customerUser._id,
            supplier: supplierUser._id,
            status: 'pending'
        });

        // Generate tokens
        adminToken = adminUser.generateAuthToken();
        customerToken = customerUser.generateAuthToken();
        supplierToken = supplierUser.generateAuthToken();
    });

    afterAll(async () => {
        await teardownTestDB();
    });

    describe('GET /api/orders/stats', () => {
        it('should return order statistics for admin', async () => {
            const res = await request(app)
                .get('/api/orders/stats')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('totalOrders');
            expect(res.body.data).toHaveProperty('totalRevenue');
        });

        it('should return 403 for non-admin users', async () => {
            const res = await request(app)
                .get('/api/orders/stats')
                .set('Authorization', `Bearer ${customerToken}`);

            expect(res.statusCode).toEqual(403);
        });
    });

    describe('GET /api/orders/search', () => {
        it('should search orders for admin', async () => {
            const res = await request(app)
                .get('/api/orders/search')
                .query({ query: testOrder.orderNumber })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
        });

        it('should filter by status', async () => {
            const res = await request(app)
                .get('/api/orders/search')
                .query({ status: 'pending' })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
        });
    });

    describe('PUT /api/orders/bulk/status', () => {
        it('should bulk update order statuses', async () => {
            const res = await request(app)
                .put('/api/orders/bulk/status')
                .send({
                    orderIds: [testOrder._id],
                    status: 'confirmed'
                })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.message).toContain('Bulk order status update completed');
        });

        it('should return 400 for invalid status', async () => {
            const res = await request(app)
                .put('/api/orders/bulk/status')
                .send({
                    orderIds: [testOrder._id],
                    status: 'invalid_status'
                })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(400);
        });
    });

    describe('GET /api/orders/export', () => {
        it('should export orders as CSV', async () => {
            const res = await request(app)
                .get('/api/orders/export')
                .query({ format: 'csv' })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.headers['content-type']).toContain('text/csv');
            expect(res.headers['content-disposition']).toContain('orders_export.csv');
        });

        it('should export orders as JSON', async () => {
            const res = await request(app)
                .get('/api/orders/export')
                .query({ format: 'json' })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
        });
    });

    describe('PUT /api/orders/:id/tracking', () => {
        it('should update order tracking for supplier', async () => {
            const res = await request(app)
                .put(`/api/orders/${testOrder._id}/tracking`)
                .send({
                    trackingNumber: 'TRACK12345',
                    carrier: 'FedEx',
                    estimatedDelivery: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
                })
                .set('Authorization', `Bearer ${supplierToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.trackingNumber).toBe('TRACK12345');
        });

        it('should return 403 for non-supplier users', async () => {
            const res = await request(app)
                .put(`/api/orders/${testOrder._id}/tracking`)
                .send({
                    trackingNumber: 'TRACK12345'
                })
                .set('Authorization', `Bearer ${customerToken}`);

            expect(res.statusCode).toEqual(403);
        });
    });

    describe('GET /api/orders/analytics', () => {
        it('should return order analytics for admin', async () => {
            const res = await request(app)
                .get('/api/orders/analytics')
                .query({ timeRange: '7days' })
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('statusDistribution');
            expect(res.body.data).toHaveProperty('revenueByDay');
            expect(res.body.data).toHaveProperty('averageOrderValue');
        });
    });
});