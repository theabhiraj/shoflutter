import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

void main() {
  // Create a new image with the specified dimensions
  final image = Image(width: 1024, height: 1024);

  // Create a modern gradient background
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final double progress = y / image.height;
      // Use a more vibrant gradient (blue to purple)
      final r = (64 * (1 - progress) + 147 * progress).toInt();
      final g = (169 * (1 - progress) + 51 * progress).toInt();
      final b = (245 * (1 - progress) + 255 * progress).toInt();
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Add a subtle radial gradient overlay
  final centerX = image.width ~/ 2;
  final centerY = image.height ~/ 2;
  final maxRadius = math.sqrt(centerX * centerX + centerY * centerY);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distance = math.sqrt(dx * dx + dy * dy);
      final factor = (1 - distance / maxRadius).clamp(0.0, 1.0);
      final pixel = image.getPixel(x, y);
      image.setPixelRgba(x, y, (pixel.r * factor).toInt(),
          (pixel.g * factor).toInt(), (pixel.b * factor).toInt(), 255);
    }
  }

  // Draw modern circular background for the logo
  fillCircle(
    image,
    x: centerX,
    y: centerY,
    radius: 300,
    color: getColor(255, 255, 255, 40),
  );

  // Draw multiple circles for a modern effect
  for (int i = 0; i < 5; i++) {
    drawLine(
      image,
      x1: centerX - 300 + i * 20,
      y1: centerY,
      x2: centerX + 300 - i * 20,
      y2: centerY,
      color: getColor(255, 255, 255, 20 - i * 3),
    );
  }

  // Function to draw thick line with gradient effect
  void drawThickLine(int x1, int y1, int x2, int y2, int thickness) {
    for (int i = 0; i < thickness; i++) {
      final alpha = ((1 - i / thickness) * 255).toInt();
      drawLine(
        image,
        x1: x1,
        y1: y1 + i,
        x2: x2,
        y2: y2 + i,
        color: getColor(255, 255, 255, alpha),
      );
    }
  }

  // Draw stylized 'x' in the center
  void drawStylizedX(int centerX, int centerY, int size) {
    final halfSize = size ~/ 2;

    // Draw multiple lines for thickness
    for (int i = -20; i <= 20; i++) {
      // Main diagonal strokes
      drawLine(
        image,
        x1: centerX - halfSize + i,
        y1: centerY - halfSize,
        x2: centerX + halfSize + i,
        y2: centerY + halfSize,
        color: getColor(255, 255, 255, 255),
      );

      drawLine(
        image,
        x1: centerX + halfSize + i,
        y1: centerY - halfSize,
        x2: centerX - halfSize + i,
        y2: centerY + halfSize,
        color: getColor(255, 255, 255, 255),
      );
    }

    // Add highlights
    for (int i = -7; i <= 7; i++) {
      drawLine(
        image,
        x1: centerX - halfSize + 10 + i,
        y1: centerY - halfSize + 10,
        x2: centerX + halfSize - 10 + i,
        y2: centerY + halfSize - 10,
        color: getColor(255, 255, 255, 100),
      );
    }
  }

  // Draw the main 'x' logo
  drawStylizedX(centerX, centerY, 400);

  // Draw 'Shop' text below
  final shopY = centerY + 250;
  drawThickLine(centerX - 150, shopY, centerX + 150, shopY, 5);

  // Add subtle glow effect
  for (int i = 1; i <= 30; i++) {
    for (int j = 0; j < 360; j += 30) {
      final angle = j * math.pi / 180;
      final radius = 450 - i * 5;
      drawLine(
        image,
        x1: centerX + (radius * math.cos(angle)).toInt(),
        y1: centerY + (radius * math.sin(angle)).toInt(),
        x2: centerX + (radius * math.cos(angle + math.pi / 6)).toInt(),
        y2: centerY + (radius * math.sin(angle + math.pi / 6)).toInt(),
        color: getColor(255, 255, 255, 2),
      );
    }
  }

  // Save the image
  final pngBytes = encodePng(image);
  Directory('assets').createSync(recursive: true);
  File('assets/app_icon.png').writeAsBytesSync(pngBytes);

  print('Modern icon generated successfully at assets/app_icon.png');
}

// Helper function to create color with alpha
Color getColor(int r, int g, int b, int a) {
  return ColorRgba8(r, g, b, a);
}
