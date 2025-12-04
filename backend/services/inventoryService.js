const Inventory = require('../models/Inventory');
const InventoryTransaction = require('../models/InventoryTransaction');
const ReorderAlert = require('../models/ReorderAlert');
const Product = require('../models/Product');
const Location = require('../models/Location');
const alertService = require('./alertService');
const { webSocketService } = require('./webSocketService');

class InventoryService {
    constructor() {
        this.inventoryCache = new Map(); // Cache for inventory data
        this.cacheTTL = 5 * 60 * 1000; // 5 minutes cache
    }

    // ==================== CORE INVENTORY OPERATIONS ====================

    /**
     * Get inventory for a product across all locations
     */
    async getProductInventory(productId) {
        const cacheKey = `product_inventory_${productId}`;
        const cachedData = this.inventoryCache.get(cacheKey);

        if (cachedData && (Date.now() - cachedData.timestamp) < this.cacheTTL) {
            return cachedData.data;
        }

        const inventoryItems = await Inventory.find({ product: productId })
            .populate('location', 'name code type')
            .lean();

        const result = {
            productId,
            totalQuantity: inventoryItems.reduce((sum, item) => sum + item.quantity, 0),
            availableQuantity: inventoryItems.reduce((sum, item) =>
                sum + (item.status === 'active' ? item.quantity : 0), 0),
            byLocation: inventoryItems,
            lastUpdated: new Date()
        };

        this.inventoryCache.set(cacheKey, {
            data: result,
            timestamp: Date.now()
        });

        return result;
    }

    /**
     * Get inventory for a specific location
     */
    async getLocationInventory(locationId) {
        const cacheKey = `location_inventory_${locationId}`;
        const cachedData = this.inventoryCache.get(cacheKey);

        if (cachedData && (Date.now() - cachedData.timestamp) < this.cacheTTL) {
            return cachedData.data;
        }

        const inventoryItems = await Inventory.find({ location: locationId })
            .populate('product', 'title sku images')
            .lean();

        const result = {
            locationId,
            totalQuantity: inventoryItems.reduce((sum, item) => sum + item.quantity, 0),
            totalValue: inventoryItems.reduce((sum, item) =>
                sum + (item.quantity * (item.costPrice || 0)), 0),
            byProduct: inventoryItems,
            lastUpdated: new Date()
        };

        this.inventoryCache.set(cacheKey, {
            data: result,
            timestamp: Date.now()
        });

        return result;
    }

    /**
     * Update inventory quantity with transaction tracking
     */
    async updateInventoryQuantity(productId, locationId, quantityChange, options = {}) {
        const {
            transactionType = 'adjustment',
            userId,
            batchNumber,
            serialNumbers = [],
            referenceId,
            referenceType,
            notes,
            costPrice,
            supplierId
        } = options;

        // Get current inventory
        const inventoryItem = await Inventory.findOne({ product: productId, location: locationId });

        if (!inventoryItem) {
            throw new Error('Inventory record not found');
        }

        const oldQuantity = inventoryItem.quantity;
        const newQuantity = Math.max(0, oldQuantity + quantityChange);

        // Update inventory
        inventoryItem.quantity = newQuantity;
        inventoryItem.costPrice = costPrice || inventoryItem.costPrice;
        inventoryItem.supplier = supplierId || inventoryItem.supplier;
        inventoryItem.lastUpdated = new Date();

        // Add movement history
        inventoryItem.movementHistory.push({
            type: transactionType,
            quantity: quantityChange,
            fromLocation: transactionType === 'transfer' ? locationId : undefined,
            toLocation: transactionType === 'transfer' ? options.toLocationId : undefined,
            timestamp: new Date(),
            user: userId,
            reference: referenceId,
        });

        // Save inventory update
        const updatedInventory = await inventoryItem.save();

        // Create transaction record
        const transaction = await InventoryTransaction.create({
            transactionType,
            product: productId,
            fromLocation: transactionType === 'transfer' ? locationId : undefined,
            toLocation: transactionType === 'transfer' ? options.toLocationId : locationId,
            quantity: Math.abs(quantityChange),
            unitPrice: costPrice,
            totalValue: Math.abs(quantityChange) * (costPrice || 0),
            batchNumber,
            serialNumbers,
            referenceId,
            referenceType,
            user: userId,
            supplier: supplierId,
            notes,
            status: 'completed',
        });

        // Update product stock (legacy field)
        const product = await Product.findById(productId);
        if (product) {
            product.stock = await this.getTotalProductStock(productId);
            await product.save();
        }

        // Update location usage
        await this.updateLocationUsage(locationId);

        // Clear cache
        this.inventoryCache.delete(`product_inventory_${productId}`);
        this.inventoryCache.delete(`location_inventory_${locationId}`);

        // Send real-time update
        if (webSocketService) {
            webSocketService.broadcastInventoryUpdate({
                productId,
                locationId,
                oldQuantity,
                newQuantity,
                transactionType,
                timestamp: new Date()
            });
        }

        return {
            inventory: updatedInventory,
            transaction,
            oldQuantity,
            newQuantity
        };
    }

    /**
     * Get total stock for a product across all locations
     */
    async getTotalProductStock(productId) {
        const inventoryItems = await Inventory.find({ product: productId });
        return inventoryItems.reduce((sum, item) => sum + item.quantity, 0);
    }

    /**
     * Update location usage statistics
     */
    async updateLocationUsage(locationId) {
        const location = await Location.findById(locationId);
        if (!location) return;

        const inventoryItems = await Inventory.find({ location: locationId });
        const totalQuantity = inventoryItems.reduce((sum, item) => sum + item.quantity, 0);

        location.currentUsage = totalQuantity;
        await location.save();
    }

    // ==================== REORDER ALERT MANAGEMENT ====================

    /**
     * Check and create reorder alerts
     */
    async checkReorderAlerts() {
        const products = await Product.find({
            'inventorySettings.trackInventory': true,
            status: 'active'
        });

        const alerts = [];

        for (const product of products) {
            const totalStock = await this.getTotalProductStock(product._id);
            const threshold = product.inventorySettings?.reorderThreshold || 10;

            if (totalStock <= threshold) {
                // Check if alert already exists
                const existingAlert = await ReorderAlert.findOne({
                    product: product._id,
                    status: { $in: ['pending', 'triggered'] }
                });

                if (!existingAlert) {
                    const alert = await ReorderAlert.create({
                        product: product._id,
                        location: null, // Will be set by location-specific check
                        threshold,
                        currentStock: totalStock,
                        status: 'pending',
                        priority: totalStock <= (threshold / 2) ? 'high' : 'medium',
                        suggestedQuantity: product.inventorySettings?.reorderQuantity || 50,
                        leadTimeDays: product.inventorySettings?.leadTimeDays || 7,
                        supplier: product.supplier,
                    });

                    alerts.push(alert);

                    // Send notification
                    await alertService.sendAlert(
                        'LOW_STOCK_ALERT',
                        alert.priority === 'high' ? 'high' : 'medium',
                        `Low stock alert for ${product.title} (SKU: ${product.sku}) - Current stock: ${totalStock}`,
                        {
                            productId: product._id,
                            productName: product.title,
                            sku: product.sku,
                            currentStock: totalStock,
                            threshold,
                            suggestedReorder: alert.suggestedQuantity
                        }
                    );
                }
            }
        }

        return alerts;
    }

    /**
     * Check reorder alerts for specific location
     */
    async checkLocationReorderAlerts(locationId) {
        const inventoryItems = await Inventory.find({ location: locationId })
            .populate('product');

        const alerts = [];

        for (const inventoryItem of inventoryItems) {
            const product = inventoryItem.product;
            if (!product || !product.inventorySettings?.trackInventory) continue;

            const threshold = product.inventorySettings?.reorderThreshold || 10;

            if (inventoryItem.quantity <= threshold && inventoryItem.quantity > 0) {
                // Check if location-specific alert already exists
                const existingAlert = await ReorderAlert.findOne({
                    product: product._id,
                    location: locationId,
                    status: { $in: ['pending', 'triggered'] }
                });

                if (!existingAlert) {
                    const alert = await ReorderAlert.create({
                        product: product._id,
                        location: locationId,
                        threshold,
                        currentStock: inventoryItem.quantity,
                        status: 'pending',
                        priority: inventoryItem.quantity <= (threshold / 2) ? 'high' : 'medium',
                        suggestedQuantity: product.inventorySettings?.reorderQuantity || 50,
                        leadTimeDays: product.inventorySettings?.leadTimeDays || 7,
                        supplier: product.supplier,
                    });

                    alerts.push(alert);

                    // Send notification
                    await alertService.sendAlert(
                        'LOCATION_LOW_STOCK_ALERT',
                        alert.priority === 'high' ? 'high' : 'medium',
                        `Low stock alert for ${product.title} at location ${inventoryItem.location} - Current stock: ${inventoryItem.quantity}`,
                        {
                            productId: product._id,
                            productName: product.title,
                            locationId,
                            currentStock: inventoryItem.quantity,
                            threshold,
                            suggestedReorder: alert.suggestedQuantity
                        }
                    );
                }
            }
        }

        return alerts;
    }

    /**
     * Acknowledge reorder alert
     */
    async acknowledgeReorderAlert(alertId, userId, notes) {
        const alert = await ReorderAlert.findById(alertId);

        if (!alert) {
            throw new Error('Alert not found');
        }

        alert.status = 'acknowledged';
        alert.acknowledgedAt = new Date();
        alert.acknowledgedBy = userId;

        if (notes) {
            alert.notes = notes;
        }

        alert.alertHistory.push({
            status: 'acknowledged',
            timestamp: new Date(),
            user: userId,
            notes
        });

        const updatedAlert = await alert.save();

        // Send notification
        await alertService.sendAlert(
            'REORDER_ALERT_ACKNOWLEDGED',
            'low',
            `Reorder alert acknowledged for ${updatedAlert.product}`,
            {
                alertId,
                productId: updatedAlert.product,
                acknowledgedBy: userId
            }
        );

        return updatedAlert;
    }

    /**
     * Resolve reorder alert
     */
    async resolveReorderAlert(alertId, userId, notes) {
        const alert = await ReorderAlert.findById(alertId);

        if (!alert) {
            throw new Error('Alert not found');
        }

        alert.status = 'resolved';
        alert.resolvedAt = new Date();
        alert.resolvedBy = userId;

        if (notes) {
            alert.notes = notes;
        }

        alert.alertHistory.push({
            status: 'resolved',
            timestamp: new Date(),
            user: userId,
            notes
        });

        const updatedAlert = await alert.save();

        // Send notification
        await alertService.sendAlert(
            'REORDER_ALERT_RESOLVED',
            'low',
            `Reorder alert resolved for ${updatedAlert.product}`,
            {
                alertId,
                productId: updatedAlert.product,
                resolvedBy: userId
            }
        );

        return updatedAlert;
    }

    // ==================== INVENTORY TRANSFER OPERATIONS ====================

    /**
     * Transfer inventory between locations
     */
    async transferInventory(productId, fromLocationId, toLocationId, quantity, userId, options = {}) {
        const {
            batchNumber,
            serialNumbers = [],
            referenceId,
            notes
        } = options;

        // Check source inventory
        const sourceInventory = await Inventory.findOne({
            product: productId,
            location: fromLocationId
        });

        if (!sourceInventory) {
            throw new Error('Source inventory not found');
        }

        if (sourceInventory.quantity < quantity) {
            throw new Error('Insufficient quantity in source location');
        }

        // Check or create destination inventory
        let destInventory = await Inventory.findOne({
            product: productId,
            location: toLocationId
        });

        if (!destInventory) {
            destInventory = await Inventory.create({
                product: productId,
                location: toLocationId,
                quantity: 0,
                batchNumber,
                serialNumbers: [],
                status: 'active'
            });
        }

        // Update source inventory
        const sourceUpdate = await this.updateInventoryQuantity(
            productId,
            fromLocationId,
            -quantity,
            {
                transactionType: 'transfer',
                userId,
                batchNumber,
                serialNumbers,
                referenceId,
                referenceType: 'transfer',
                notes,
                toLocationId
            }
        );

        // Update destination inventory
        const destUpdate = await this.updateInventoryQuantity(
            productId,
            toLocationId,
            quantity,
            {
                transactionType: 'transfer',
                userId,
                batchNumber,
                serialNumbers,
                referenceId,
                referenceType: 'transfer',
                notes,
                fromLocationId
            }
        );

        return {
            sourceUpdate,
            destUpdate,
            transferTransaction: {
                productId,
                fromLocationId,
                toLocationId,
                quantity,
                timestamp: new Date(),
                userId,
                referenceId
            }
        };
    }

    // ==================== BATCH AND SERIAL NUMBER TRACKING ====================

    /**
     * Add batch to inventory
     */
    async addBatchToInventory(productId, locationId, batchData, userId) {
        const {
            batchNumber,
            quantity,
            expirationDate,
            costPrice,
            serialNumbers = [],
            supplierId,
            notes
        } = batchData;

        // Check if batch already exists
        const existingBatch = await Inventory.findOne({
            product: productId,
            location: locationId,
            batchNumber
        });

        if (existingBatch) {
            throw new Error('Batch number already exists for this product and location');
        }

        // Create new inventory record for the batch
        const inventoryItem = await Inventory.create({
            product: productId,
            location: locationId,
            quantity,
            batchNumber,
            serialNumbers,
            expirationDate,
            costPrice,
            supplier: supplierId,
            status: 'active',
            movementHistory: [{
                type: 'received',
                quantity,
                timestamp: new Date(),
                user: userId,
                reference: `BATCH-${batchNumber}`
            }]
        });

        // Create transaction record
        const transaction = await InventoryTransaction.create({
            transactionType: 'purchase',
            product: productId,
            toLocation: locationId,
            quantity,
            unitPrice: costPrice,
            totalValue: quantity * costPrice,
            batchNumber,
            serialNumbers,
            referenceId: `BATCH-${batchNumber}`,
            referenceType: 'purchase',
            user: userId,
            supplier: supplierId,
            notes,
            status: 'completed'
        });

        // Update product stock
        const product = await Product.findById(productId);
        if (product) {
            product.stock = await this.getTotalProductStock(productId);
            await product.save();
        }

        // Update location usage
        await this.updateLocationUsage(locationId);

        // Clear cache
        this.inventoryCache.delete(`product_inventory_${productId}`);
        this.inventoryCache.delete(`location_inventory_${locationId}`);

        return {
            inventoryItem,
            transaction
        };
    }

    /**
     * Track serial numbers
     */
    async trackSerialNumbers(productId, locationId, serialNumbers, options = {}) {
        const {
            batchNumber,
            status = 'active',
            userId,
            notes
        } = options;

        // Find inventory item
        let inventoryItem = await Inventory.findOne({
            product: productId,
            location: locationId,
            ...(batchNumber ? { batchNumber } : {})
        });

        if (!inventoryItem) {
            inventoryItem = await Inventory.create({
                product: productId,
                location: locationId,
                quantity: 0,
                batchNumber,
                serialNumbers: [],
                status: 'active'
            });
        }

        // Add serial numbers
        inventoryItem.serialNumbers.push(...serialNumbers);
        inventoryItem.quantity = inventoryItem.serialNumbers.length;

        // Update movement history
        inventoryItem.movementHistory.push({
            type: 'received',
            quantity: serialNumbers.length,
            timestamp: new Date(),
            user: userId,
            reference: `SERIAL-${serialNumbers.join(',')}`
        });

        const updatedInventory = await inventoryItem.save();

        // Create transaction record
        const transaction = await InventoryTransaction.create({
            transactionType: 'purchase',
            product: productId,
            toLocation: locationId,
            quantity: serialNumbers.length,
            batchNumber,
            serialNumbers,
            referenceId: `SERIAL-${serialNumbers.join(',')}`,
            referenceType: 'serial_tracking',
            user: userId,
            status: 'completed',
            notes
        });

        return {
            inventoryItem: updatedInventory,
            transaction
        };
    }

    /**
     * Find serial number location
     */
    async findSerialNumber(serialNumber) {
        const inventoryItem = await Inventory.findOne({
            serialNumbers: serialNumber
        });

        if (!inventoryItem) {
            return null;
        }

        return {
            productId: inventoryItem.product,
            locationId: inventoryItem.location,
            batchNumber: inventoryItem.batchNumber,
            status: inventoryItem.status,
            foundAt: new Date()
        };
    }

    // ==================== INVENTORY ANALYTICS ====================

    /**
     * Get inventory turnover analytics
     */
    async getInventoryTurnoverAnalytics(timeframe = '30d') {
        const startDate = this.getStartDate(timeframe);

        const analytics = await InventoryTransaction.aggregate([
            {
                $match: {
                    createdAt: { $gte: startDate },
                    transactionType: { $in: ['sale', 'transfer', 'adjustment'] }
                }
            },
            {
                $group: {
                    _id: '$product',
                    totalSold: {
                        $sum: {
                            $cond: [{ $eq: ['$transactionType', 'sale'] }, '$quantity', 0]
                        }
                    },
                    totalReceived: {
                        $sum: {
                            $cond: [{ $eq: ['$transactionType', 'purchase'] }, '$quantity', 0]
                        }
                    },
                    totalTransferredOut: {
                        $sum: {
                            $cond: [{ $eq: ['$transactionType', 'transfer'] }, '$quantity', 0]
                        }
                    },
                    totalAdjusted: {
                        $sum: {
                            $cond: [{ $eq: ['$transactionType', 'adjustment'] }, '$quantity', 0]
                        }
                    },
                    lastTransaction: { $max: '$createdAt' }
                }
            },
            {
                $lookup: {
                    from: 'products',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $lookup: {
                    from: 'inventories',
                    localField: '_id',
                    foreignField: 'product',
                    as: 'currentInventory'
                }
            },
            {
                $addFields: {
                    currentStock: {
                        $reduce: {
                            input: '$currentInventory',
                            initialValue: 0,
                            in: { $add: ['$$value', '$$this.quantity'] }
                        }
                    }
                }
            },
            {
                $project: {
                    productId: '$_id',
                    productName: '$product.title',
                    sku: '$product.sku',
                    currentStock: 1,
                    totalSold: 1,
                    totalReceived: 1,
                    totalTransferredOut: 1,
                    totalAdjusted: 1,
                    lastTransaction: 1,
                    turnoverRate: {
                        $cond: [
                            { $gt: ['$currentStock', 0] },
                            { $divide: ['$totalSold', '$currentStock'] },
                            0
                        ]
                    },
                    daysOfSupply: {
                        $cond: [
                            { $gt: ['$totalSold', 0] },
                            {
                                $divide: [
                                    '$currentStock',
                                    { $divide: ['$totalSold', { $subtract: [new Date(), startDate] }] }
                                ]
                            },
                            0
                        ]
                    }
                }
            },
            { $sort: { turnoverRate: -1 } }
        ]);

        return analytics;
    }

    /**
     * Get stock aging analytics
     */
    async getStockAgingAnalytics() {
        const now = new Date();

        const agingData = await Inventory.aggregate([
            {
                $match: {
                    quantity: { $gt: 0 },
                    status: 'active'
                }
            },
            {
                $lookup: {
                    from: 'products',
                    localField: 'product',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $addFields: {
                    daysInStock: {
                        $divide: [
                            { $subtract: [now, '$receivedDate'] },
                            24 * 60 * 60 * 1000
                        ]
                    },
                    agingCategory: {
                        $switch: {
                            branches: [
                                { case: { $lt: ['$daysInStock', 30] }, then: '0-30 days' },
                                { case: { $lt: ['$daysInStock', 90] }, then: '31-90 days' },
                                { case: { $lt: ['$daysInStock', 180] }, then: '91-180 days' },
                                { case: { $lt: ['$daysInStock', 365] }, then: '181-365 days' },
                                { case: { $gte: ['$daysInStock', 365] }, then: '365+ days' }
                            ],
                            default: 'Unknown'
                        }
                    }
                }
            },
            {
                $group: {
                    _id: '$agingCategory',
                    totalQuantity: { $sum: '$quantity' },
                    totalValue: { $sum: { $multiply: ['$quantity', '$costPrice'] } },
                    productCount: { $sum: 1 },
                    products: {
                        $push: {
                            productId: '$product._id',
                            productName: '$product.title',
                            quantity: '$quantity',
                            daysInStock: '$daysInStock'
                        }
                    }
                }
            },
            {
                $project: {
                    agingCategory: '$_id',
                    totalQuantity: 1,
                    totalValue: 1,
                    productCount: 1,
                    averageDays: { $avg: '$products.daysInStock' },
                    topProducts: { $slice: ['$products', 5] }
                }
            },
            { $sort: { totalValue: -1 } }
        ]);

        return agingData;
    }

    /**
     * Get inventory valuation
     */
    async getInventoryValuation() {
        const valuation = await Inventory.aggregate([
            {
                $group: {
                    _id: null,
                    totalItems: { $sum: 1 },
                    totalQuantity: { $sum: '$quantity' },
                    totalValue: { $sum: { $multiply: ['$quantity', '$costPrice'] } },
                    averageCost: { $avg: '$costPrice' }
                }
            },
            {
                $lookup: {
                    from: 'locations',
                    localField: 'location',
                    foreignField: '_id',
                    as: 'locations'
                }
            }
        ]);

        return valuation[0] || {
            totalItems: 0,
            totalQuantity: 0,
            totalValue: 0,
            averageCost: 0
        };
    }

    // ==================== HELPER METHODS ====================

    /**
     * Get start date based on timeframe
     */
    getStartDate(timeframe) {
        const now = new Date();
        const units = {
            '1h': 1 * 60 * 60 * 1000,
            '24h': 24 * 60 * 60 * 1000,
            '7d': 7 * 24 * 60 * 60 * 1000,
            '30d': 30 * 24 * 60 * 60 * 1000,
            '90d': 90 * 24 * 60 * 60 * 1000,
            '1y': 365 * 24 * 60 * 60 * 1000
        };

        return new Date(now.getTime() - (units[timeframe] || units['30d']));
    }

    /**
     * Clear inventory cache
     */
    clearCache() {
        this.inventoryCache.clear();
    }
}

// Export singleton instance
const inventoryService = new InventoryService();

module.exports = inventoryService;