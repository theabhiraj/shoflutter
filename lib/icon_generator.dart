import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const double iconSize = 1024; // Standard size for app icons
  const String appName = "Shop\nManagement"; // Your app name - adjust as needed

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..color = const ui.Color.fromARGB(255, 0, 0, 0) // Change color as needed
    ..style = PaintingStyle.fill;

  // Draw background
  canvas.drawRect(Rect.fromLTWH(0, 0, iconSize, iconSize), paint);

  // Add text
  final textPainter = TextPainter(
    text: TextSpan(
      text: appName,
      style: TextStyle(
        color: Colors.white,
        fontSize: iconSize / 6,
        fontWeight: FontWeight.bold,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  );

  textPainter.layout(
    minWidth: iconSize,
    maxWidth: iconSize,
  );

  // Center the text
  textPainter.paint(
    canvas,
    Offset(
      (iconSize - textPainter.width) / 2,
      (iconSize - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(iconSize.toInt(), iconSize.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Save the image directly to assets folder
  final file = File('assets/app_icon.png');
  await file.writeAsBytes(pngBytes);

  print('Icon generated at: ${file.path}');
  exit(0);
}
