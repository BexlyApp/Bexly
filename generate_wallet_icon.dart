import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a canvas to draw the icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 1024.0;

  // Draw white background
  final bgPaint = Paint()..color = Colors.white;
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

  // Draw the wallet icon in purple
  final iconColor = Color(0xFF731FE0); // purple700
  final iconSize = size * 0.6; // 60% of canvas
  final iconPadding = (size - iconSize) / 2;

  // Use TextPainter to render Material Icon
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(Icons.account_balance_wallet.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: Icons.account_balance_wallet.fontFamily,
        package: Icons.account_balance_wallet.fontPackage,
        color: iconColor,
      ),
    ),
  );

  textPainter.layout();
  textPainter.paint(canvas, Offset(iconPadding, iconPadding));

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Save to file
  final file = File('assets/icon/wallet-icon-1024.png');
  await file.writeAsBytes(pngBytes);

  print('Icon saved to ${file.path}');
  exit(0);
}
