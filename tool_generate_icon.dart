// Run this with: dart run tool_generate_icon.dart
// Or: flutter run -t tool_generate_icon.dart --release

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the icon widget
  final iconWidget = Container(
    width: 1024,
    height: 1024,
    color: Colors.white,
    alignment: Alignment.center,
    child: Icon(
      Icons.account_balance_wallet,
      size: 614, // 60% of 1024
      color: Color(0xFF731FE0), // purple700
    ),
  );

  // Render to image
  final bytes = await _widgetToImage(iconWidget);

  // Save to file
  final file = File('assets/icon/wallet-icon-1024.png');
  await file.writeAsBytes(bytes);

  print('✓ Icon generated: ${file.path}');
  exit(0);
}

Future<Uint8List> _widgetToImage(Widget widget) async {
  final repaintBoundary = RenderRepaintBoundary();

  final renderView = RenderView(
    window: WidgetsBinding.instance.window,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
  );

  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final image = await repaintBoundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
}
