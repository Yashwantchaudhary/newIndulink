import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  // Create a 1024x1024 image
  final image = img.Image(width: 1024, height: 1024);

  // Fill with blue background
  img.fill(image, color: img.ColorRgb8(26, 115, 232));

  // Draw white circle
  img.fillCircle(image, x: 512, y: 512, radius: 400, color: img.ColorRgb8(255, 255, 255));

  // Draw blue link symbol
  final linkColor = img.ColorRgb8(26, 115, 232);

  // Left link part (circle)
  img.fillCircle(image, x: 412, y: 512, radius: 60, color: linkColor);

  // Right link part (circle)
  img.fillCircle(image, x: 612, y: 512, radius: 60, color: linkColor);

  // Connecting rectangle
  img.fillRect(image, x1: 472, y1: 482, x2: 552, y2: 542, color: linkColor);

  // Save the image
  final pngBytes = img.encodePng(image);
  File('customer_app/assets/icons/indulink_icon.png').writeAsBytesSync(pngBytes);

  print('Icon generated successfully!');
}