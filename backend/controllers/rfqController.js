const RFQ = require('../models/RFQ');
const Product = require('../models/Product');
const User = require('../models/User');
const Notification = require('../models/Notification');

// @desc    Create a new RFQ
// @route   POST /api/rfq
// @access  Private (Customer only)
exports.createRFQ = async (req, res) => {
    try {
        const { items, deliveryAddress, notes, expiresAt } = req.body;

        // Validate customer role (using 'customer' instead of 'buyer' to match User model)
        if (req.user.role !== 'customer') {
            return res.status(403).json({
                success: false,
                message: 'Only customers can create RFQs'
            });
        }

        if (!items || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'RFQ must have at least one item'
            });
        }

        // Create RFQ
        const rfq = await RFQ.create({
            customerId: req.user._id, // Matches schema 'customerId'
            items,
            deliveryAddress,
            notes,
            expiresAt,
            status: 'pending'
        });

        // Populate details for response
        await rfq.populate('customerId', 'firstName lastName email businessName');
        // Note: 'items.productId' population might need deep populate if needed immediately

        // Send notification to all suppliers
        const suppliers = await User.find({ role: 'supplier', isActive: true });

        const notifications = suppliers.map(supplier => ({
            user: supplier._id,
            type: 'rfq',
            title: 'New RFQ Request',
            message: `New RFQ request for ${items.length} product(s)`,
            data: { rfqId: rfq._id }
        }));

        if (notifications.length > 0) {
            await Notification.insertMany(notifications);
        }

        res.status(201).json({
            success: true,
            message: 'RFQ created successfully',
            data: rfq
        });
    } catch (error) {
        console.error('Create RFQ Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating RFQ',
            error: error.message
        });
    }
};

// @desc    Get all RFQs (for customer - their RFQs, for supplier - all pending RFQs)
// @route   GET /api/rfq
// @access  Private
exports.getRFQs = async (req, res) => {
    try {
        const { status, page = 1, limit = 10 } = req.query;
        const skip = (page - 1) * limit;

        let query = {};

        if (req.user.role === 'customer') {
            query.customerId = req.user._id;
        }

        if (status) {
            query.status = status;
        }

        const rfqs = await RFQ.find(query)
            .populate('customerId', 'firstName lastName email businessName')
            .populate({
                path: 'items.productId',
                select: 'title images price'
            })
            .populate('quotes.supplierId', 'firstName lastName email businessName')
            .sort({ createdAt: -1 })
            .limit(parseInt(limit))
            .skip(skip);

        const total = await RFQ.countDocuments(query);

        res.status(200).json({
            success: true,
            data: rfqs,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Get RFQs Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching RFQs',
            error: error.message
        });
    }
};

// @desc    Get single RFQ by ID
// @route   GET /api/rfq/:id
// @access  Private
exports.getRFQById = async (req, res) => {
    try {
        const rfq = await RFQ.findById(req.params.id)
            .populate('customerId', 'firstName lastName email businessName phone')
            .populate({
                path: 'items.productId',
                select: 'title images price description'
            })
            .populate('quotes.supplierId', 'firstName lastName email businessName phone rating');

        if (!rfq) {
            return res.status(404).json({
                success: false,
                message: 'RFQ not found'
            });
        }

        // Check authorization
        if (req.user.role === 'customer' && rfq.customerId._id.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to view this RFQ'
            });
        }

        res.status(200).json({
            success: true,
            data: rfq
        });
    } catch (error) {
        console.error('Get RFQ Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching RFQ',
            error: error.message
        });
    }
};

// @desc    Submit quote for RFQ
// @route   POST /api/rfq/:id/quote
// @access  Private (Supplier only)
exports.submitQuote = async (req, res) => {
    try {
        const { items, totalAmount, validUntil, notes } = req.body;

        // Validate supplier role
        if (req.user.role !== 'supplier') {
            return res.status(403).json({
                success: false,
                message: 'Only suppliers can submit quotes'
            });
        }

        const rfq = await RFQ.findById(req.params.id);

        if (!rfq) {
            return res.status(404).json({
                success: false,
                message: 'RFQ not found'
            });
        }

        if (rfq.status === 'closed' || rfq.status === 'awarded') {
            return res.status(400).json({
                success: false,
                message: 'This RFQ is no longer accepting quotes'
            });
        }

        // Check if supplier already submitted a quote
        const existingQuoteIndex = rfq.quotes.findIndex(
            q => q.supplierId.toString() === req.user._id.toString()
        );

        const quote = {
            supplierId: req.user._id,
            items,
            totalAmount,
            validUntil,
            notes,
            submittedAt: new Date()
        };

        if (existingQuoteIndex !== -1) {
            // Update existing quote
            rfq.quotes[existingQuoteIndex] = quote;
        } else {
            // Add new quote
            rfq.quotes.push(quote);
        }

        rfq.status = 'quoted';
        await rfq.save();

        // Notify customer
        await Notification.create({
            user: rfq.customerId,
            type: 'quote',
            title: 'New Quote Received',
            message: `You received a quote for your RFQ`,
            data: { rfqId: rfq._id }
        });

        const updatedRFQ = await RFQ.findById(rfq._id)
            .populate('quotes.supplierId', 'firstName lastName email businessName rating');

        res.status(200).json({
            success: true,
            message: 'Quote submitted successfully',
            data: updatedRFQ
        });
    } catch (error) {
        console.error('Submit Quote Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error submitting quote',
            error: error.message
        });
    }
};

// @desc    Accept a quote
// @route   PUT /api/rfq/:id/accept/:quoteId
// @access  Private (Buyer only)
exports.acceptQuote = async (req, res) => {
    try {
        const { id, quoteId } = req.params;

        const rfq = await RFQ.findById(id);

        if (!rfq) {
            return res.status(404).json({
                success: false,
                message: 'RFQ not found'
            });
        }

        // Check if user is the customer
        if (rfq.customerId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to accept quotes for this RFQ'
            });
        }

        const quote = rfq.quotes.id(quoteId);

        if (!quote) {
            return res.status(404).json({
                success: false,
                message: 'Quote not found'
            });
        }

        // Update quote status
        rfq.quotes.forEach(q => {
            if (q._id.toString() === quoteId) {
                q.status = 'accepted';
            } else {
                q.status = 'rejected';
            }
        });

        rfq.status = 'awarded';
        await rfq.save();

        // Notify supplier
        await Notification.create({
            user: quote.supplier,
            type: 'quote_accepted',
            title: 'Quote Accepted',
            message: 'Your quote has been accepted!',
            data: { rfqId: rfq._id }
        });

        const updatedRFQ = await RFQ.findById(rfq._id)
            .populate('quotes.supplierId', 'firstName lastName email businessName');

        res.status(200).json({
            success: true,
            message: 'Quote accepted successfully',
            data: updatedRFQ
        });
    } catch (error) {
        console.error('Accept Quote Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error accepting quote',
            error: error.message
        });
    }
};

// @desc    Update RFQ status
// @route   PUT /api/rfq/:id/status
// @access  Private (Buyer only)
exports.updateRFQStatus = async (req, res) => {
    try {
        const { status } = req.body;

        const rfq = await RFQ.findById(req.params.id);

        if (!rfq) {
            return res.status(404).json({
                success: false,
                message: 'RFQ not found'
            });
        }

        // Check if user is the customer
        if (rfq.customerId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this RFQ'
            });
        }

        rfq.status = status;
        await rfq.save();

        res.status(200).json({
            success: true,
            message: 'RFQ status updated successfully',
            data: rfq
        });
    } catch (error) {
        console.error('Update RFQ Status Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating RFQ status',
            error: error.message
        });
    }
};

// @desc    Delete RFQ
// @route   DELETE /api/rfq/:id
// @access  Private (Buyer only)
exports.deleteRFQ = async (req, res) => {
    try {
        const rfq = await RFQ.findById(req.params.id);

        if (!rfq) {
            return res.status(404).json({
                success: false,
                message: 'RFQ not found'
            });
        }

        // Check if user is the customer
        if (rfq.customerId.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this RFQ'
            });
        }

        await rfq.deleteOne();

        res.status(200).json({
            success: true,
            message: 'RFQ deleted successfully'
        });
    } catch (error) {
        console.error('Delete RFQ Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting RFQ',
            error: error.message
        });
    }
};

// @desc    Upload attachments for RFQ
// @route   POST /api/rfq/upload
// @access  Private
exports.uploadAttachments = async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No files uploaded'
            });
        }

        // Process uploaded files
        const attachments = req.files.map(file => ({
            type: file.mimetype.startsWith('image/') ? 'image' : 'document',
            url: `uploads/rfq/${file.filename}`,
            filename: file.originalname
        }));

        res.status(200).json({
            success: true,
            message: 'Files uploaded successfully',
            data: attachments
        });
    } catch (error) {
        console.error('Upload Attachments Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error uploading files',
            error: error.message
        });
    }
};

// @desc    Get RFQ statistics
// @route   GET /api/rfq/stats
// @access  Private (Admin)
exports.getRFQStats = async (req, res) => {
    try {
        const totalRFQs = await RFQ.countDocuments();
        const pendingRFQs = await RFQ.countDocuments({ status: 'pending' });
        const quotedRFQs = await RFQ.countDocuments({ status: 'quoted' });
        const awardedRFQs = await RFQ.countDocuments({ status: 'awarded' });
        const closedRFQs = await RFQ.countDocuments({ status: 'closed' });

        res.status(200).json({
            success: true,
            data: {
                totalRFQs,
                pendingRFQs,
                quotedRFQs,
                awardedRFQs,
                closedRFQs,
                count: totalRFQs
            }
        });
    } catch (error) {
        console.error('Get RFQ Stats Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching RFQ stats',
            error: error.message
        });
    }
};

// @desc    Get supplier RFQ statistics
// @route   GET /api/rfq/stats/supplier/:supplierId
// @access  Private (Supplier or Admin)
exports.getSupplierRFQStats = async (req, res) => {
    try {
        const supplierId = req.params.supplierId;

        // Check if user is authorized to access this supplier's data
        if (req.user.role !== 'admin' && req.user.id !== supplierId) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to access this supplier data',
            });
        }

        const totalRFQs = await RFQ.countDocuments({ 'quotes.supplier': supplierId });
        const pendingRFQs = await RFQ.countDocuments({ 'quotes.supplier': supplierId, status: 'pending' });
        const awardedRFQs = await RFQ.countDocuments({ 'quotes.supplier': supplierId, status: 'awarded' });

        res.status(200).json({
            success: true,
            data: {
                totalRFQs,
                pendingRFQs,
                awardedRFQs,
                count: totalRFQs
            }
        });
    } catch (error) {
        console.error('Get Supplier RFQ Stats Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching supplier RFQ stats',
            error: error.message
        });
    }
};
