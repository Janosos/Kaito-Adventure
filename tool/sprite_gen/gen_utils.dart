import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GenUtils {
  static const Color ink = Color(0xFF141419);
  static const Color white = Color(0xFFFDFBF7);
  static const Color red = Color(0xFFFF2A42);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color yellow = Color(0xFFFFD600);
  static const Color orange = Color(0xFFFF6D00);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color darkCyan = Color(0xFF00838F);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color darkPurple = Color(0xFF311B92);
  static const Color navy = Color(0xFF1E293B);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color skin = Color(0xFFFFE0BD);
  static const Color skinShadow = Color(0xFFE5B887);
  static const Color steel = Color(0xFFE2E8F0);
  static const Color steelDark = Color(0xFF94A3B8);
  static const Color wood = Color(0xFF8D5524);
  static const Color woodDark = Color(0xFF5C3317);
  static const Color gold = Color(0xFFFFC107);
  static const Color goldDark = Color(0xFFFF8F00);
  static const Color green = Color(0xFF00E676);

  static Paint fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static Paint stroke(Color c, [double width = 3.5]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static void drawCelPath(
    Canvas canvas,
    Path path,
    Color baseColor, {
    Color? highlightColor,
    double outlineWidth = 3.5,
    Color outlineColor = ink,
  }) {
    if (highlightColor != null) {
      final bounds = path.getBounds();
      final gradPaint = Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [highlightColor, baseColor],
        )
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, gradPaint);
    } else {
      canvas.drawPath(path, fill(baseColor));
    }
    if (outlineWidth > 0) {
      canvas.drawPath(path, stroke(outlineColor, outlineWidth));
    }
  }

  static void drawCelRRect(
    Canvas canvas,
    Rect rect,
    double radius,
    Color baseColor, {
    Color? topHighlight,
    double outlineWidth = 3.5,
    Color outlineColor = ink,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (topHighlight != null) {
      final gradPaint = Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [topHighlight, baseColor],
        )
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRRect(rrect, gradPaint);
    } else {
      canvas.drawRRect(rrect, fill(baseColor));
    }
    if (outlineWidth > 0) {
      canvas.drawRRect(rrect, stroke(outlineColor, outlineWidth));
    }
  }

  static void drawCelCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor, {
    Color? highlightColor,
    double outlineWidth = 3.5,
    Color outlineColor = ink,
  }) {
    if (highlightColor != null) {
      final gradPaint = Paint()
        ..shader = ui.Gradient.radial(
          center - Offset(radius * 0.3, radius * 0.3),
          radius * 1.3,
          [highlightColor, baseColor],
        )
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(center, radius, gradPaint);
    } else {
      canvas.drawCircle(center, radius, fill(baseColor));
    }
    if (outlineWidth > 0) {
      canvas.drawCircle(center, radius, stroke(outlineColor, outlineWidth));
    }
  }

  static void drawCartoonStar(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    int points,
    Color fillColor, {
    double outlineWidth = 2.5,
    double rotation = 0.0,
  }) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final a = rotation + (i * pi / points) - pi / 2;
      final pt = Offset(center.dx + cos(a) * r, center.dy + sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    drawCelPath(canvas, path, fillColor, outlineWidth: outlineWidth);
  }

  static Future<void> saveSheet({
    required String relativePath,
    required int frameWidth,
    required int frameHeight,
    required int frameCount,
    required void Function(Canvas canvas, int frame, Size frameSize) drawFrame,
  }) async {
    final totalWidth = frameWidth * frameCount;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, totalWidth.toDouble(), frameHeight.toDouble()),
    );

    for (int i = 0; i < frameCount; i++) {
      canvas.save();
      canvas.translate((i * frameWidth).toDouble(), 0);
      canvas.clipRect(
        Rect.fromLTWH(0, 0, frameWidth.toDouble(), frameHeight.toDouble()),
      );
      drawFrame(
        canvas,
        i,
        Size(frameWidth.toDouble(), frameHeight.toDouble()),
      );
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(totalWidth, frameHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    final file = File(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
  }

  static Future<void> saveSingle({
    required String relativePath,
    required int width,
    required int height,
    required void Function(Canvas canvas, Size size) draw,
  }) async {
    await saveSheet(
      relativePath: relativePath,
      frameWidth: width,
      frameHeight: height,
      frameCount: 1,
      drawFrame: (c, _, s) => draw(c, s),
    );
  }
}

