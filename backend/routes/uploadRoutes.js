const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const { uploadSingle, uploadMultiple } = require('../middleware/upload');
const { protect } = require('../middleware/authMiddleware');

/**
 * @route   POST /api/upload/image
 * @desc    Upload a single image to the server
 * @access  Private
 */
router.post('/image', protect, uploadSingle('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'No image file provided'
            });
        }

        // Get folder from request body (optional)
        const folder = req.body.folder || 'general';

        // Construct the URL for the uploaded image
        const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
        const imageUrl = `${baseUrl}/uploads/${req.file.filename}`;

        res.status(200).json({
            success: true,
            message: 'Image uploaded successfully',
            url: imageUrl,
            filename: req.file.filename,
            originalName: req.file.originalname,
            size: req.file.size,
            mimetype: req.file.mimetype
        });
    } catch (error) {
        console.error('Image upload error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to upload image',
            error: error.message
        });
    }
});

/**
 * @route   POST /api/upload/images
 * @desc    Upload multiple images to the server
 * @access  Private
 */
router.post('/images', protect, uploadMultiple('images', 10), async (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'No image files provided'
            });
        }

        const folder = req.body.folder || 'general';
        const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 5000}`;

        const uploadedImages = req.files.map(file => ({
            url: `${baseUrl}/uploads/${file.filename}`,
            filename: file.filename,
            originalName: file.originalname,
            size: file.size,
            mimetype: file.mimetype
        }));

        res.status(200).json({
            success: true,
            message: `${uploadedImages.length} images uploaded successfully`,
            images: uploadedImages,
            urls: uploadedImages.map(img => img.url)
        });
    } catch (error) {
        console.error('Images upload error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to upload images',
            error: error.message
        });
    }
});

/**
 * @route   DELETE /api/upload/delete
 * @desc    Delete an uploaded image
 * @access  Private
 */
router.delete('/delete', protect, async (req, res) => {
    try {
        const { url, filename } = req.body;

        let fileToDelete = filename;

        // If URL is provided, extract filename from it
        if (url && !filename) {
            fileToDelete = path.basename(url);
        }

        if (!fileToDelete) {
            return res.status(400).json({
                success: false,
                message: 'No filename or URL provided'
            });
        }

        const filePath = path.join(__dirname, '..', 'uploads', fileToDelete);

        // Check if file exists
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                message: 'File not found'
            });
        }

        // Delete the file
        fs.unlinkSync(filePath);

        res.status(200).json({
            success: true,
            message: 'Image deleted successfully'
        });
    } catch (error) {
        console.error('Image delete error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete image',
            error: error.message
        });
    }
});

module.exports = router;
