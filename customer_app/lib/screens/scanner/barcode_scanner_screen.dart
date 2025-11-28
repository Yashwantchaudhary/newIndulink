import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../services/api_client.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart';

/// Barcode Scanner Screen
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Search for product by SKU/barcode
      final apiClient = ApiClient();
      final productService = ProductService(apiClient);
      final product = await productService.getProductBySKU(code);

      if (product != null && mounted) {
        // Product found - navigate to detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      } else if (mounted) {
        // Product not found
        _showProductNotFound(code);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to lookup product: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProductNotFound(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found with barcode: $code'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Close Scanner'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Scanner Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: AppConstants.paddingAll20,
              child: Column(
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  else
                    Container(
                      padding: AppConstants.paddingAll16,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: AppConstants.borderRadiusMedium,
                      ),
                      child: Text(
                        'Position the barcode within the frame',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scanner Overlay Painter
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanAreaWidth = size.width * 0.7;
    final scanAreaHeight = size.height * 0.3;
    final scanAreaLeft = (size.width - scanAreaWidth) / 2;
    final scanAreaTop = (size.height - scanAreaHeight) / 2;

    // Draw darkened areas around scan area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanAreaTop),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop, scanAreaLeft, scanAreaHeight),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(scanAreaLeft + scanAreaWidth, scanAreaTop, scanAreaLeft,
          scanAreaHeight),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, scanAreaTop + scanAreaHeight, size.width, size.height),
      paint,
    );

    // Draw scan area border
    final borderPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth - cornerLength,
          scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth,
          scanAreaTop + scanAreaHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
