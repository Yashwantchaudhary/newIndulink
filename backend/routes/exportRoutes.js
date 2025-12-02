/// 📊 Export/Import Routes
/// API endpoints for data export and import operations

const express = require('express');
const multer = require('multer');
const path = require('path');
const {
    exportUserData,
    exportCollection,
    importCollection,
    getExportHistory,
    deleteExportFile,
    getSupportedFormats
} = require('../controllers/exportController');

const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = path.join(__dirname, '..', 'uploads', 'imports');
        const fs = require('fs');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, `import-${uniqueSuffix}${path.extname(file.originalname)}`);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = [
            'application/json',
            'text/csv',
            'text/plain',
            'application/vnd.ms-excel'
        ];

        if (allowedTypes.includes(file.mimetype) ||
            file.originalname.endsWith('.json') ||
            file.originalname.endsWith('.csv')) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only JSON and CSV files are allowed.'), false);
        }
    }
});

// Public routes
router.get('/formats', getSupportedFormats);

// Protected routes
router.use(protect); // All routes below require authentication

// User data export (GDPR compliant)
router.get('/user-data', exportUserData);

// Collection export
router.get('/collection/:collection', exportCollection);

// Admin only routes
router.use(authorize('admin'));

// Collection import
router.post('/collection/:collection',
    upload.single('file'),
    importCollection
);

// Export history management
router.get('/history', getExportHistory);
router.delete('/file/:filename', deleteExportFile);

module.exports = router;