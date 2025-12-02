const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

/// 🖼️ Image Processing Service
/// Handles image compression, resizing, and optimization

class ImageService {
  constructor() {
    this.supportedFormats = ['jpeg', 'jpg', 'png', 'gif', 'webp'];
    this.compressionSettings = {
      // Product images - high quality for detail
      products: {
        quality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
        format: 'jpeg',
      },
      // Profile images - medium quality, square crop
      profiles: {
        quality: 80,
        maxWidth: 400,
        maxHeight: 400,
        format: 'jpeg',
        fit: 'cover',
      },
      // Review images - medium quality
      reviews: {
        quality: 80,
        maxWidth: 800,
        maxHeight: 800,
        format: 'jpeg',
      },
      // Thumbnails - low quality, small size
      thumbnails: {
        quality: 70,
        maxWidth: 300,
        maxHeight: 300,
        format: 'jpeg',
        fit: 'cover',
      },
    };
  }

  /**
   * Process and compress uploaded image
   * @param {string} inputPath - Path to input image
   * @param {string} outputPath - Path to save compressed image
   * @param {string} type - Type of image (products, profiles, reviews, thumbnails)
   * @returns {Promise<Object>} Processing result
   */
  async compressImage(inputPath, outputPath, type = 'products') {
    try {
      const settings = this.compressionSettings[type];
      if (!settings) {
        throw new Error(`Unknown image type: ${type}`);
      }

      // Ensure output directory exists
      const outputDir = path.dirname(outputPath);
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      let sharpInstance = sharp(inputPath);

      // Get original image info
      const metadata = await sharpInstance.metadata();

      // Resize if needed
      if (metadata.width > settings.maxWidth || metadata.height > settings.maxHeight) {
        sharpInstance = sharpInstance.resize({
          width: settings.maxWidth,
          height: settings.maxHeight,
          fit: settings.fit || 'inside',
          withoutEnlargement: true,
        });
      }

      // Convert and compress based on format
      switch (settings.format) {
        case 'jpeg':
        case 'jpg':
          sharpInstance = sharpInstance.jpeg({
            quality: settings.quality,
            progressive: true,
          });
          break;
        case 'png':
          sharpInstance = sharpInstance.png({
            quality: settings.quality,
            compressionLevel: 6,
          });
          break;
        case 'webp':
          sharpInstance = sharpInstance.webp({
            quality: settings.quality,
          });
          break;
        default:
          // Keep original format but compress
          if (metadata.format === 'jpeg') {
            sharpInstance = sharpInstance.jpeg({
              quality: settings.quality,
              progressive: true,
            });
          }
      }

      // Process and save
      const info = await sharpInstance.toFile(outputPath);

      // Get file sizes for comparison
      const originalSize = fs.statSync(inputPath).size;
      const compressedSize = info.size;
      const compressionRatio = ((originalSize - compressedSize) / originalSize * 100).toFixed(1);

      return {
        success: true,
        originalSize,
        compressedSize,
        compressionRatio: `${compressionRatio}%`,
        dimensions: `${info.width}x${info.height}`,
        format: settings.format,
      };

    } catch (error) {
      console.error('Image compression error:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Generate thumbnail from image
   * @param {string} inputPath - Path to input image
   * @param {string} outputPath - Path to save thumbnail
   * @returns {Promise<Object>} Thumbnail generation result
   */
  async generateThumbnail(inputPath, outputPath) {
    return this.compressImage(inputPath, outputPath, 'thumbnails');
  }

  /**
   * Process multiple images
   * @param {Array} images - Array of image objects with inputPath and outputPath
   * @param {string} type - Type of images
   * @returns {Promise<Array>} Array of processing results
   */
  async processMultipleImages(images, type = 'products') {
    const results = [];

    for (const image of images) {
      const result = await this.compressImage(image.inputPath, image.outputPath, type);
      results.push({
        ...result,
        filename: path.basename(image.outputPath),
      });
    }

    return results;
  }

  /**
   * Get image dimensions
   * @param {string} imagePath - Path to image
   * @returns {Promise<Object>} Image dimensions
   */
  async getImageDimensions(imagePath) {
    try {
      const metadata = await sharp(imagePath).metadata();
      return {
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        size: fs.statSync(imagePath).size,
      };
    } catch (error) {
      console.error('Error getting image dimensions:', error);
      return null;
    }
  }

  /**
   * Validate image file
   * @param {string} filePath - Path to image file
   * @returns {Promise<boolean>} Is valid image
   */
  async validateImage(filePath) {
    try {
      const metadata = await sharp(filePath).metadata();
      return this.supportedFormats.includes(metadata.format);
    } catch (error) {
      return false;
    }
  }

  /**
   * Clean up temporary files
   * @param {Array} filePaths - Array of file paths to delete
   */
  cleanupTempFiles(filePaths) {
    filePaths.forEach(filePath => {
      try {
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (error) {
        console.warn(`Failed to cleanup temp file: ${filePath}`, error);
      }
    });
  }

  /**
   * Get optimal compression settings based on image analysis
   * @param {string} imagePath - Path to image
   * @returns {Promise<Object>} Optimal settings
   */
  async getOptimalSettings(imagePath) {
    try {
      const metadata = await sharp(imagePath).metadata();
      const fileSize = fs.statSync(imagePath).size;

      // Adjust quality based on original file size
      let quality = 85; // Default

      if (fileSize > 2 * 1024 * 1024) { // > 2MB
        quality = 75;
      } else if (fileSize > 1 * 1024 * 1024) { // > 1MB
        quality = 80;
      }

      // Adjust dimensions for very large images
      let maxWidth = 1200;
      let maxHeight = 1200;

      if (metadata.width > 2000 || metadata.height > 2000) {
        maxWidth = 1600;
        maxHeight = 1600;
      }

      return {
        quality,
        maxWidth,
        maxHeight,
        format: 'jpeg',
      };

    } catch (error) {
      // Return default settings on error
      return this.compressionSettings.products;
    }
  }
}

module.exports = new ImageService();