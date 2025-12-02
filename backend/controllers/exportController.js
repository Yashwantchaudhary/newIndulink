/// 📊 Export/Import Controller
/// Handles data export and import operations

const dataExportService = require('../services/dataExportService');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Category = require('../models/Category');
const Review = require('../models/Review');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const RFQ = require('../models/RFQ');
const Cart = require('../models/Cart');
const Wishlist = require('../models/Wishlist');
const Address = require('../models/Address');

// @desc    Export user data (GDPR compliant)
// @route   GET /api/export/user-data
// @access  Private (Own data only)
exports.exportUserData = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        const format = req.query.format || 'json';
        const options = {
            includeProfile: req.query.includeProfile !== 'false',
            includeOrders: req.query.includeOrders !== 'false',
            includeProducts: req.query.includeProducts !== 'false',
            includeMessages: req.query.includeMessages !== 'false',
            format: format
        };

        const result = await dataExportService.exportUserData(userId, user, options);

        // Set appropriate headers for file download
        const mimeTypes = {
            json: 'application/json',
            csv: 'text/csv',
            pdf: 'application/pdf'
        };

        res.setHeader('Content-Type', mimeTypes[format] || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);

        // Stream the file
        const fs = require('fs');
        const fileStream = fs.createReadStream(result.filePath);
        fileStream.pipe(res);

        // Clean up file after streaming (optional - can be done via cron job)
        fileStream.on('end', () => {
            setTimeout(() => {
                try {
                    fs.unlinkSync(result.filePath);
                } catch (error) {
                    console.error('Error cleaning up export file:', error);
                }
            }, 5000); // Delete after 5 seconds
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Export collection data
// @route   GET /api/export/collection/:collection
// @access  Private (Admin only for full export, Suppliers/Customers for their data)
exports.exportCollection = async (req, res, next) => {
    try {
        const { collection } = req.params;
        const format = req.query.format || 'json';
        const limit = parseInt(req.query.limit) || 1000;
        const skip = parseInt(req.query.skip) || 0;

        // Define allowed collections and access control
        const collectionConfig = {
            products: {
                model: Product,
                access: ['admin', 'supplier'],
                filter: (user) => user.role === 'supplier' ? { supplier: user.id } : {}
            },
            orders: {
                model: Order,
                access: ['admin', 'supplier', 'customer'],
                filter: (user) => {
                    if (user.role === 'supplier') return { 'items.supplier': user.id };
                    if (user.role === 'customer') return { user: user.id };
                    return {};
                }
            },
            categories: {
                model: Category,
                access: ['admin']
            },
            reviews: {
                model: Review,
                access: ['admin', 'supplier', 'customer'],
                filter: (user) => {
                    if (user.role === 'supplier') return { 'product.supplier': user.id };
                    if (user.role === 'customer') return { user: user.id };
                    return {};
                }
            },
            messages: {
                model: Message,
                access: ['admin'],
                populate: ['sender', 'receiver']
            },
            notifications: {
                model: Notification,
                access: ['admin', 'supplier', 'customer'],
                filter: (user) => ({ user: user.id })
            },
            rfq: {
                model: RFQ,
                access: ['admin', 'supplier', 'customer'],
                filter: (user) => {
                    if (user.role === 'supplier') return { supplier: user.id };
                    if (user.role === 'customer') return { customer: user.id };
                    return {};
                }
            }
        };

        if (!collectionConfig[collection]) {
            return res.status(400).json({
                success: false,
                message: 'Invalid collection name'
            });
        }

        const config = collectionConfig[collection];

        // Check access permissions
        if (!config.access.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Build query
        const query = config.filter ? config.filter(req.user) : {};
        let dataQuery = config.model.find(query).limit(limit).skip(skip);

        // Add population if specified
        if (config.populate) {
            config.populate.forEach(field => {
                dataQuery = dataQuery.populate(field);
            });
        }

        const data = await dataQuery.lean();

        const filename = `${collection}_export_${Date.now()}`;

        let result;
        switch (format.toLowerCase()) {
            case 'csv':
                result = await dataExportService.exportToCSV(data, filename);
                break;
            case 'pdf':
                result = await dataExportService.exportToPDF(data, filename, {
                    title: `${collection.charAt(0).toUpperCase() + collection.slice(1)} Export`
                });
                break;
            default:
                result = await dataExportService.exportToJSON(data, filename);
        }

        // Set appropriate headers
        const mimeTypes = {
            json: 'application/json',
            csv: 'text/csv',
            pdf: 'application/pdf'
        };

        res.setHeader('Content-Type', mimeTypes[format] || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${result.filename}"`);

        // Stream the file
        const fs = require('fs');
        const fileStream = fs.createReadStream(result.filePath);
        fileStream.pipe(res);

        // Clean up
        fileStream.on('end', () => {
            setTimeout(() => {
                try {
                    fs.unlinkSync(result.filePath);
                } catch (error) {
                    console.error('Error cleaning up export file:', error);
                }
            }, 5000);
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Import data to collection
// @route   POST /api/import/collection/:collection
// @access  Private (Admin only)
exports.importCollection = async (req, res, next) => {
    try {
        const { collection } = req.params;
        const format = req.query.format || 'json';
        const options = {
            validateData: req.query.validate !== 'false',
            skipDuplicates: req.query.skipDuplicates !== 'false'
        };

        // Only admins can import data
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Import access denied. Admin privileges required.'
            });
        }

        let data;
        if (req.file) {
            // File upload
            const fs = require('fs');
            const fileContent = fs.readFileSync(req.file.path, 'utf8');

            if (format === 'csv') {
                data = fileContent;
            } else {
                data = JSON.parse(fileContent);
            }

            // Clean up uploaded file
            fs.unlinkSync(req.file.path);
        } else if (req.body.data) {
            // Raw data in request body
            data = req.body.data;
        } else {
            return res.status(400).json({
                success: false,
                message: 'No data provided. Use file upload or raw data in request body.'
            });
        }

        let result;
        if (format === 'csv') {
            result = await dataExportService.importFromCSV(data, {
                collection,
                ...options
            });
        } else {
            result = await dataExportService.importFromJSON(data, {
                collection,
                ...options
            });
        }

        res.status(200).json({
            success: true,
            message: `Import completed. ${result.imported} records imported, ${result.skipped} skipped.`,
            data: result
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Get export/import history
// @route   GET /api/export/history
// @access  Private (Admin only)
exports.getExportHistory = async (req, res, next) => {
    try {
        // In a production app, you'd store export history in a database
        // For now, return available export files
        const fs = require('fs');
        const path = require('path');
        const exportsDir = path.join(__dirname, '..', 'exports');

        let files = [];
        if (fs.existsSync(exportsDir)) {
            files = fs.readdirSync(exportsDir)
                .filter(file => file.endsWith('.json') || file.endsWith('.csv') || file.endsWith('.pdf'))
                .map(filename => {
                    const stats = fs.statSync(path.join(exportsDir, filename));
                    return {
                        filename,
                        size: stats.size,
                        createdAt: stats.birthtime,
                        format: filename.split('.').pop()
                    };
                })
                .sort((a, b) => b.createdAt - a.createdAt);
        }

        res.status(200).json({
            success: true,
            data: files
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Delete export file
// @route   DELETE /api/export/file/:filename
// @access  Private (Admin only)
exports.deleteExportFile = async (req, res, next) => {
    try {
        const { filename } = req.params;
        const fs = require('fs');
        const path = require('path');
        const filePath = path.join(__dirname, '..', 'exports', filename);

        if (!fs.existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                message: 'File not found'
            });
        }

        fs.unlinkSync(filePath);

        res.status(200).json({
            success: true,
            message: 'Export file deleted successfully'
        });

    } catch (error) {
        next(error);
    }
};

// @desc    Get supported export formats
// @route   GET /api/export/formats
// @access  Public
exports.getSupportedFormats = async (req, res, next) => {
    res.status(200).json({
        success: true,
        data: {
            export: ['json', 'csv', 'pdf'],
            import: ['json', 'csv'],
            collections: [
                'users', 'products', 'orders', 'categories',
                'reviews', 'messages', 'notifications', 'rfq',
                'cart', 'wishlist', 'addresses'
            ]
        }
    });
};