const Inventory = require('../models/Inventory');
const InventoryTransaction = require('../models/InventoryTransaction');
const ReorderAlert = require('../models/ReorderAlert');
const Product = require('../models/Product');
const Location = require('../models/Location');
const inventoryService = require('../services/inventoryService');
const { protect, requireSupplier } = require('../middleware/authMiddleware');
const { webSocketService } = require('../services/webSocketService');

// Set WebSocket service
let wsService = null;
const setWebSocketService = (service) => {
    wsService = service;
};

// @desc    Get inventory for a product
// @route   GET /api/inventory/product/:productId
// @access  Private
exports.getProductInventory = async (req, res, next) => {
    try {
        const { productId } = req.params;

        const inventory = await inventoryService.getProductInventory(productId);

        res.status(200).json({
            success: true,
            data: inventory
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory for a location
// @route   GET /api/inventory/location/:locationId
// @access  Private
exports.getLocationInventory = async (req, res, next) => {
    try {
        const { locationId } = req.params;

        const inventory = await inventoryService.getLocationInventory(locationId);

        res.status(200).json({
            success: true,
            data: inventory
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update inventory quantity
// @route   PUT /api/inventory/update
// @access  Private
exports.updateInventoryQuantity = async (req, res, next) => {
    try {
        const { productId, locationId, quantityChange } = req.body;
        const userId = req.user.id;

        if (!productId || !locationId || quantityChange === undefined) {
            return res.status(400).json({
                success: false,
                message: 'productId, locationId, and quantityChange are required'
            });
        }

        const result = await inventoryService.updateInventoryQuantity(
            productId,
            locationId,
            quantityChange,
            {
                userId,
                ...req.body.options
            }
        );

        res.status(200).json({
            success: true,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Transfer inventory between locations
// @route   POST /api/inventory/transfer
// @access  Private
exports.transferInventory = async (req, res, next) => {
    try {
        const { productId, fromLocationId, toLocationId, quantity } = req.body;
        const userId = req.user.id;

        if (!productId || !fromLocationId || !toLocationId || !quantity) {
            return res.status(400).json({
                success: false,
                message: 'productId, fromLocationId, toLocationId, and quantity are required'
            });
        }

        const result = await inventoryService.transferInventory(
            productId,
            fromLocationId,
            toLocationId,
            quantity,
            userId,
            req.body.options
        );

        res.status(201).json({
            success: true,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Add batch to inventory
// @route   POST /api/inventory/batch
// @access  Private
exports.addBatchToInventory = async (req, res, next) => {
    try {
        const { productId, locationId } = req.body;
        const userId = req.user.id;

        if (!productId || !locationId || !req.body.batchData) {
            return res.status(400).json({
                success: false,
                message: 'productId, locationId, and batchData are required'
            });
        }

        const result = await inventoryService.addBatchToInventory(
            productId,
            locationId,
            req.body.batchData,
            userId
        );

        res.status(201).json({
            success: true,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Track serial numbers
// @route   POST /api/inventory/serial
// @access  Private
exports.trackSerialNumbers = async (req, res, next) => {
    try {
        const { productId, locationId, serialNumbers } = req.body;
        const userId = req.user.id;

        if (!productId || !locationId || !serialNumbers || !Array.isArray(serialNumbers)) {
            return res.status(400).json({
                success: false,
                message: 'productId, locationId, and serialNumbers array are required'
            });
        }

        const result = await inventoryService.trackSerialNumbers(
            productId,
            locationId,
            serialNumbers,
            {
                userId,
                ...req.body.options
            }
        );

        res.status(201).json({
            success: true,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Find serial number
// @route   GET /api/inventory/serial/:serialNumber
// @access  Private
exports.findSerialNumber = async (req, res, next) => {
    try {
        const { serialNumber } = req.params;

        const result = await inventoryService.findSerialNumber(serialNumber);

        if (!result) {
            return res.status(404).json({
                success: false,
                message: 'Serial number not found'
            });
        }

        res.status(200).json({
            success: true,
            data: result
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get reorder alerts
// @route   GET /api/inventory/alerts
// @access  Private
exports.getReorderAlerts = async (req, res, next) => {
    try {
        const { status, priority, productId, locationId } = req.query;

        const filter = {};

        if (status) {
            filter.status = status;
        }

        if (priority) {
            filter.priority = priority;
        }

        if (productId) {
            filter.product = productId;
        }

        if (locationId) {
            filter.location = locationId;
        }

        const alerts = await ReorderAlert.find(filter)
            .populate('product', 'title sku')
            .populate('location', 'name code')
            .populate('supplier', 'businessName')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: alerts.length,
            data: alerts
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Acknowledge reorder alert
// @route   PUT /api/inventory/alerts/:alertId/acknowledge
// @access  Private
exports.acknowledgeReorderAlert = async (req, res, next) => {
    try {
        const { alertId } = req.params;
        const userId = req.user.id;
        const { notes } = req.body;

        const alert = await inventoryService.acknowledgeReorderAlert(alertId, userId, notes);

        res.status(200).json({
            success: true,
            data: alert
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Resolve reorder alert
// @route   PUT /api/inventory/alerts/:alertId/resolve
// @access  Private
exports.resolveReorderAlert = async (req, res, next) => {
    try {
        const { alertId } = req.params;
        const userId = req.user.id;
        const { notes } = req.body;

        const alert = await inventoryService.resolveReorderAlert(alertId, userId, notes);

        res.status(200).json({
            success: true,
            data: alert
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Check and create reorder alerts
// @route   POST /api/inventory/alerts/check
// @access  Private
exports.checkReorderAlerts = async (req, res, next) => {
    try {
        const alerts = await inventoryService.checkReorderAlerts();

        res.status(200).json({
            success: true,
            count: alerts.length,
            data: alerts
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory turnover analytics
// @route   GET /api/inventory/analytics/turnover
// @access  Private
exports.getInventoryTurnoverAnalytics = async (req, res, next) => {
    try {
        const timeframe = req.query.timeframe || '30d';

        const analytics = await inventoryService.getInventoryTurnoverAnalytics(timeframe);

        res.status(200).json({
            success: true,
            data: analytics,
            timeframe
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get stock aging analytics
// @route   GET /api/inventory/analytics/aging
// @access  Private
exports.getStockAgingAnalytics = async (req, res, next) => {
    try {
        const analytics = await inventoryService.getStockAgingAnalytics();

        res.status(200).json({
            success: true,
            data: analytics
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory valuation
// @route   GET /api/inventory/analytics/valuation
// @access  Private
exports.getInventoryValuation = async (req, res, next) => {
    try {
        const valuation = await inventoryService.getInventoryValuation();

        res.status(200).json({
            success: true,
            data: valuation
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory transactions
// @route   GET /api/inventory/transactions
// @access  Private
exports.getInventoryTransactions = async (req, res, next) => {
    try {
        const { productId, locationId, transactionType, startDate, endDate } = req.query;

        const filter = {};

        if (productId) {
            filter.product = productId;
        }

        if (locationId) {
            filter.$or = [
                { fromLocation: locationId },
                { toLocation: locationId }
            ];
        }

        if (transactionType) {
            filter.transactionType = transactionType;
        }

        if (startDate || endDate) {
            filter.createdAt = {};
            if (startDate) filter.createdAt.$gte = new Date(startDate);
            if (endDate) filter.createdAt.$lte = new Date(endDate);
        }

        const transactions = await InventoryTransaction.find(filter)
            .populate('product', 'title sku')
            .populate('fromLocation', 'name code')
            .populate('toLocation', 'name code')
            .populate('user', 'name email')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: transactions.length,
            data: transactions
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory movement history
// @route   GET /api/inventory/history/:productId
// @access  Private
exports.getInventoryMovementHistory = async (req, res, next) => {
    try {
        const { productId } = req.params;
        const { locationId } = req.query;

        const filter = { product: productId };
        if (locationId) {
            filter.location = locationId;
        }

        const inventoryItems = await Inventory.find(filter)
            .populate('location', 'name code')
            .select('movementHistory');

        const history = inventoryItems.flatMap(item =>
            item.movementHistory.map(movement => ({
                ...movement.toObject(),
                productId,
                locationId: item.location._id,
                locationName: item.location.name,
                locationCode: item.location.code
            }))
        );

        res.status(200).json({
            success: true,
            count: history.length,
            data: history.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get inventory summary dashboard
// @route   GET /api/inventory/dashboard
// @access  Private
exports.getInventoryDashboard = async (req, res, next) => {
    try {
        const [inventoryValuation, reorderAlerts, lowStockProducts] = await Promise.all([
            inventoryService.getInventoryValuation(),
            ReorderAlert.countDocuments({ status: { $in: ['pending', 'triggered'] } }),
            Product.countDocuments({
                'inventorySettings.trackInventory': true,
                stock: { $lt: 10, $gt: 0 }
            })
        ]);

        const dashboardData = {
            inventoryValuation,
            activeAlerts: reorderAlerts,
            lowStockProducts,
            criticalStockProducts: await Product.countDocuments({
                'inventorySettings.trackInventory': true,
                stock: { $lte: 5 }
            }),
            outOfStockProducts: await Product.countDocuments({
                'inventorySettings.trackInventory': true,
                stock: 0
            }),
            lastUpdated: new Date()
        };

        res.status(200).json({
            success: true,
            data: dashboardData
        });
    } catch (error) {
        next(error);
    }
};

// Export WebSocket service setter
module.exports.setWebSocketService = setWebSocketService;