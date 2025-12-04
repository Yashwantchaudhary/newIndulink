/// 📊 Data Export/Import Service
/// Handles data export to JSON format and import from JSON sources (no third party libraries)

const fs = require('fs');
const path = require('path');

class DataExportService {
    constructor() {
        this.exportsDir = path.join(__dirname, '..', 'exports');
        this.ensureExportsDirectory();
    }

    ensureExportsDirectory() {
        if (!fs.existsSync(this.exportsDir)) {
            fs.mkdirSync(this.exportsDir, { recursive: true });
        }
    }

    // Export data to JSON format
    async exportToJSON(data, filename, options = {}) {
        const {
            pretty = true,
            includeMetadata = true
        } = options;

        const exportData = {
            ...(includeMetadata && {
                metadata: {
                    exportedAt: new Date().toISOString(),
                    totalRecords: data.length,
                    format: 'json'
                }
            }),
            data: data
        };

        const jsonString = pretty
            ? JSON.stringify(exportData, null, 2)
            : JSON.stringify(exportData);

        const filePath = path.join(this.exportsDir, `${filename}.json`);
        fs.writeFileSync(filePath, jsonString, 'utf8');

        return {
            success: true,
            filePath,
            filename: `${filename}.json`,
            size: Buffer.byteLength(jsonString, 'utf8'),
            format: 'json'
        };
    }

    // Export data to CSV format (stub - not implemented without third party libraries)
    async exportToCSV(data, filename, fields = null, options = {}) {
        throw new Error('CSV export not supported. Only JSON export is available.');
    }

    // Export data to PDF format (stub - not implemented without third party libraries)
    async exportToPDF(data, filename, options = {}) {
        throw new Error('PDF export not supported. Only JSON export is available.');
    }

    // Export user data (GDPR compliant)
    async exportUserData(userId, user, options = {}) {
        const {
            includeProfile = true,
            includeOrders = true,
            includeProducts = true,
            includeMessages = true,
            format = 'json'
        } = options;

        const exportData = {
            user: includeProfile ? {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            } : null,
            data: {}
        };

        // Include related data based on user role and options
        if (includeOrders && (user.role === 'customer' || user.role === 'admin')) {
            const Order = require('../models/Order');
            const orders = await Order.find({ user: userId }).populate('items.product');
            exportData.data.orders = orders;
        }

        if (includeProducts && (user.role === 'supplier' || user.role === 'admin')) {
            const Product = require('../models/Product');
            const products = await Product.find({ supplier: userId });
            exportData.data.products = products;
        }

        if (includeMessages) {
            const Message = require('../models/Message');
            const Conversation = require('../models/Conversation');
            const conversations = await Conversation.find({
                $or: [{ participant1: userId }, { participant2: userId }]
            }).populate('messages');
            exportData.data.messages = conversations;
        }

        const filename = `user_data_${userId}_${Date.now()}`;

        // Only JSON format supported
        if (format.toLowerCase() !== 'json') {
            throw new Error('Only JSON format is supported for user data export.');
        }

        return await this.exportToJSON(exportData, filename);
    }

    // Import data from JSON
    async importFromJSON(jsonData, options = {}) {
        const {
            validateData = true,
            skipDuplicates = true,
            collection = null
        } = options;

        try {
            let data;
            if (typeof jsonData === 'string') {
                data = JSON.parse(jsonData);
            } else {
                data = jsonData;
            }

            // Extract actual data if wrapped in metadata
            const actualData = data.data || data;

            if (!Array.isArray(actualData) && typeof actualData !== 'object') {
                throw new Error('Invalid data format. Expected array or object.');
            }

            const results = {
                success: true,
                imported: 0,
                skipped: 0,
                errors: [],
                total: Array.isArray(actualData) ? actualData.length : 1
            };

            // Import logic based on collection type
            if (collection) {
                const Model = this.getModelByCollection(collection);
                const items = Array.isArray(actualData) ? actualData : [actualData];

                for (const item of items) {
                    try {
                        if (validateData) {
                            // Basic validation
                            this.validateItem(item, collection);
                        }

                        if (skipDuplicates && await this.checkDuplicate(item, Model)) {
                            results.skipped++;
                            continue;
                        }

                        await Model.create(item);
                        results.imported++;
                    } catch (error) {
                        results.errors.push({
                            item: item,
                            error: error.message
                        });
                    }
                }
            }

            return results;
        } catch (error) {
            throw new Error(`Import failed: ${error.message}`);
        }
    }

    // Import data from CSV (stub - not implemented without third party libraries)
    async importFromCSV(csvData, options = {}) {
        throw new Error('CSV import not supported. Only JSON import is available.');
    }

    // Helper methods
    getModelByCollection(collection) {
        const models = {
            users: require('../models/User'),
            products: require('../models/Product'),
            orders: require('../models/Order'),
            categories: require('../models/Category'),
            reviews: require('../models/Review'),
            messages: require('../models/Message'),
            notifications: require('../models/Notification'),
            rfq: require('../models/RFQ'),
            cart: require('../models/Cart'),
            wishlist: require('../models/Wishlist'),
            addresses: require('../models/Address')
        };

        const Model = models[collection.toLowerCase()];
        if (!Model) {
            throw new Error(`Unknown collection: ${collection}`);
        }

        return Model;
    }

    validateItem(item, collection) {
        // Basic validation - extend as needed
        if (!item || typeof item !== 'object') {
            throw new Error('Invalid item format');
        }

        // Collection-specific validation
        switch (collection.toLowerCase()) {
            case 'users':
                if (!item.email || !item.name) {
                    throw new Error('User must have email and name');
                }
                break;
            case 'products':
                if (!item.title || !item.price) {
                    throw new Error('Product must have title and price');
                }
                break;
            // Add more validations as needed
        }
    }

    async checkDuplicate(item, Model) {
        // Simple duplicate check - extend based on requirements
        if (item.email && Model.modelName === 'User') {
            return await Model.findOne({ email: item.email });
        }
        if (item.title && Model.modelName === 'Product') {
            return await Model.findOne({ title: item.title });
        }
        return false;
    }

    // Clean up old export files
    cleanupOldExports(maxAge = 24 * 60 * 60 * 1000) { // 24 hours default
        try {
            const files = fs.readdirSync(this.exportsDir);
            const now = Date.now();

            files.forEach(file => {
                const filePath = path.join(this.exportsDir, file);
                const stats = fs.statSync(filePath);

                if (now - stats.mtime.getTime() > maxAge) {
                    fs.unlinkSync(filePath);
                    console.log(`Cleaned up old export file: ${file}`);
                }
            });
        } catch (error) {
            console.error('Error cleaning up exports:', error);
        }
    }

    // Get file info
    getFileInfo(filename) {
        const filePath = path.join(this.exportsDir, filename);
        if (!fs.existsSync(filePath)) {
            return null;
        }

        const stats = fs.statSync(filePath);
        return {
            filename,
            size: stats.size,
            createdAt: stats.birthtime,
            modifiedAt: stats.mtime
        };
    }
}

module.exports = new DataExportService();