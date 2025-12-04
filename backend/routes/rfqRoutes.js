const express = require('express');
const router = express.Router();
const {
  createRFQ,
  getRFQs,
  getRFQById,
  submitQuote,
  acceptQuote,
  updateRFQStatus,
  deleteRFQ,
  uploadAttachments,
} = require('../controllers/rfqController');
const { protect } = require('../middleware/authMiddleware');
// Use the centralized uploads utility (adjust path if needed)
const uploads = require('../middleware/upload');

// RFQ routes
router.post('/', protect, createRFQ);
router.get('/', protect, getRFQs);
router.get('/:id', protect, getRFQById);
router.post('/:id/quote', protect, submitQuote);
router.put('/:id/accept/:quoteId', protect, acceptQuote);
router.put('/:id/status', protect, updateRFQStatus);
router.delete('/:id', protect, deleteRFQ);

// Upload attachments for a specific RFQ
// field name: 'attachments', max 3 files; allows images and documents
router.post(
  '/:id/attachments',
  protect,
  uploads.uploadMultiple('attachments', 3),
  uploadAttachments
);

module.exports = router;
