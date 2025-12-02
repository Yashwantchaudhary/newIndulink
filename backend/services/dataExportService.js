/// 📊 Data Export/Import Service
/// Handles data export to various formats and import from external sources

const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const { Parser } = require('json2csv');

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

    // Export data to CSV format
    async exportToCSV(data, filename, fields = null, options = {}) {
        const {
            includeHeaders = true,
            delimiter = ',',
            includeMetadata = true
        } = options;

        try {
            // If fields not specified, use all keys from first object
            const csvFields = fields || (data.length > 0 ? Object.keys(data[0]) : []);

            const opts = {
                fields: csvFields,
                header: includeHeaders,
                delimiter: delimiter
            };

            const parser = new Parser(opts);
            let csvData = parser.parse(data);

            // Add metadata if requested
            if (includeMetadata) {
                const metadata = [
                    `Exported At,${new Date().toISOString()}`,
                    `Total Records,${data.length}`,
                    `Format,csv`,
                    '', // Empty line
                ].join('\n');

                csvData = metadata + csvData;
            }

            const filePath = path.join(this.exportsDir, `${filename}.csv`);
            fs.writeFileSync(filePath, csvData, 'utf8');

            return {
                success: true,
                filePath,
                filename: `${filename}.csv`,
                size: Buffer.byteLength(csvData, 'utf8'),
                format: 'csv'
            };
        } catch (error) {
            throw new Error(`CSV export failed: ${error.message}`);
        }
    }

    // Export data to PDF format
    async exportToPDF(data, filename, options = {}) {
        const {
            title = 'Data Export',
            includeMetadata = true,
            orientation = 'landscape'
        } = options;

        return new Promise((resolve, reject) => {
            try {
                const filePath = path.join(this.exportsDir, `${filename}.pdf`);
                const doc = new PDFDocument({
                    size: 'A4',
                    orientation: orientation,
                    margin: 50
                });

                const stream = fs.createWriteStream(filePath);
                doc.pipe(stream);

                // Title
                doc.fontSize(20).font('Helvetica-Bold').text(title, { align: 'center' });
                doc.moveDown(2);

                // Metadata
                if (includeMetadata) {
                    doc.fontSize(10).font('Helvetica');
                    doc.text(`Exported At: ${new Date().toISOString()}`);
                    doc.text(`Total Records: ${data.length}`);
                    doc.text(`Format: PDF`);
                    doc.moveDown();
                }

                // Table headers (if data exists)
                if (data.length > 0) {
                    const headers = Object.keys(data[0]);
                    const colWidth = (doc.page.width - 100) / headers.length;

                    // Header row
                    doc.fontSize(12).font('Helvetica-Bold');
                    headers.forEach((header, index) => {
                        doc.text(header, 50 + (index * colWidth), doc.y, {
                            width: colWidth,
                            align: 'left'
                        });
                    });

                    doc.moveDown(0.5);

                    // Header underline
                    doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).stroke();
                    doc.moveDown();

                    // Data rows
                    doc.fontSize(10).font('Helvetica');
                    data.forEach((row, rowIndex) => {
                        if (doc.y > doc.page.height - 100) {
                            doc.addPage();
                            doc.fontSize(10).font('Helvetica');
                        }

                        headers.forEach((header, colIndex) => {
                            const value = String(row[header] || '').substring(0, 50); // Truncate long values
                            doc.text(value, 50 + (colIndex * colWidth), doc.y, {
                                width: colWidth,
                                align: 'left'
                            });
                        });

                        doc.moveDown(0.5);
                    });
                }

                // Footer
                const pageCount = doc.bufferedPageRange().count;
                for (let i = 0; i < pageCount; i++) {
                    doc.switchToPage(i);
                    doc.fontSize(8).font('Helvetica');
                    doc.text(
                        `Page ${i + 1} of ${pageCount}`,
                        50,
                        doc.page.height - 50,
                        { align: 'center' }
                    );
                }

                doc.end();

                stream.on('finish', () => {
                    const stats = fs.statSync(filePath);
                    resolve({
                        success: true,
                        filePath,
                        filename: `${filename}.pdf`,
                        size: stats.size,
                        format: 'pdf'
                    });
                });

                stream.on('error', reject);
            } catch (error) {
                reject(error);
            }
        });
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

        switch (format.toLowerCase()) {
            case 'csv':
                return await this.exportToCSV([exportData], filename);
            case 'pdf':
                return await this.exportToPDF([exportData], filename, { title: 'User Data Export' });
            default:
                return await this.exportToJSON(exportData, filename);
        }
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

    // Import data from CSV
    async importFromCSV(csvData, options = {}) {
        const {
            collection = null,
            validateData = true,
            skipDuplicates = true
        } = options;

        try {
            // Parse CSV (simplified - in production use a proper CSV parser)
            const lines = csvData.split('\n').filter(line => line.trim());
            const headers = lines[0].split(',').map(h => h.trim());

            const data = lines.slice(1).map(line => {
                const values = line.split(',');
                const item = {};
                headers.forEach((header, index) => {
                    item[header] = values[index]?.trim() || '';
                });
                return item;
            });

            return await this.importFromJSON(data, { collection, validateData, skipDuplicates });
        } catch (error) {
            throw new Error(`CSV import failed: ${error.message}`);
        }
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