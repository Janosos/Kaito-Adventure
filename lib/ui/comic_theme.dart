import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComicTheme {
  // Manga Ink & Screentone Palette
  static const Color inkBlack = Color(0xFF141419);
  static const Color paperWhite = Color(0xFFF7F5EE);
  static const Color halftoneGray = Color(0xFFD6D3C8);
  static const Color actionRed = Color(0xFFFF2A42);
  static const Color comicYellow = Color(0xFFFFCC00);
  static const Color energyCyan = Color(0xFF00E5FF);
  static const Color darkPurple = Color(0xFF4A148C);
  static const Color shadowBorder = Color(0xFF101014);

  // Manga Typography Helpers
  static TextStyle comicTitle({
    double fontSize = 28,
    Color color = inkBlack,
    Color? strokeColor,
    double strokeWidth = 3,
  }) {
    final base = GoogleFonts.bangers(
      fontSize: fontSize,
      letterSpacing: 2,
      fontWeight: FontWeight.bold,
      color: color,
    );

    return base;
  }

  static TextStyle mangaHeader({
    double fontSize = 22,
    Color color = inkBlack,
    FontWeight fontWeight = FontWeight.w900,
  }) {
    return GoogleFonts.bebasNeue(
      fontSize: fontSize,
      letterSpacing: 2.5,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle comicBody({
    double fontSize = 14,
    Color color = inkBlack,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.comicNeue(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Comic Panel Box Decoration (Crisp black ink border + solid black pop shadow)
  static BoxDecoration comicPanelDecoration({
    Color backgroundColor = paperWhite,
    Color borderColor = inkBlack,
    double borderWidth = 3.0,
    double shadowOffset = 4.0,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: borderColor,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: 0,
        ),
      ],
    );
  }

  // Comic Button Decoration
  static BoxDecoration comicButtonDecoration({
    Color backgroundColor = comicYellow,
    Color borderColor = inkBlack,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: borderColor, width: 3),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: borderColor,
                offset: const Offset(3.5, 3.5),
                blurRadius: 0,
              ),
            ],
    );
  }
}

// Custom Painter for authentic Manga Halftone Screentone pattern
class HalftonePainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double dotRadius;

  HalftonePainter({
    this.dotColor = const Color(0x33000000),
    this.spacing = 10.0,
    this.dotRadius = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += spacing) {
      final offsetX = ((y / spacing).floor() % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = offsetX; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HalftonePainter oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.spacing != spacing ||
      oldDelegate.dotRadius != dotRadius;
}

// Custom Painter for Manga Action Speed Lines
class SpeedLinesPainter extends CustomPainter {
  final Color color;
  final int count;
  final double progress;

  SpeedLinesPainter({
    this.color = const Color(0x44000000),
    this.count = 24,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;
    final innerRadius = maxRadius * 0.35;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = Random(42);

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i + (progress * 0.2);
      final raySpread = (random.nextDouble() * 0.04) + 0.02;

      final p1 = Offset(
        center.dx + cos(angle - raySpread) * maxRadius,
        center.dy + sin(angle - raySpread) * maxRadius,
      );
      final p2 = Offset(
        center.dx + cos(angle + raySpread) * maxRadius,
        center.dy + sin(angle + raySpread) * maxRadius,
      );
      final pTip = Offset(
        center.dx + cos(angle) * (innerRadius + random.nextDouble() * 50),
        center.dy + sin(angle) * (innerRadius + random.nextDouble() * 50),
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(pTip.dx, pTip.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Spiky Comic Speech Bubble Path
class ComicBubbleBorder extends ShapeBorder {
  final double borderWidth;
  final Color borderColor;
  final double spikeHeight;
  final bool spikeAtBottom;

  const ComicBubbleBorder({
    this.borderWidth = 3.0,
    this.borderColor = ComicTheme.inkBlack,
    this.spikeHeight = 16.0,
    this.spikeAtBottom = true,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
        bottom: spikeAtBottom ? spikeHeight : 0,
        top: !spikeAtBottom ? spikeHeight : 0,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double radius = 8.0;
    final r = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - (spikeAtBottom ? spikeHeight : 0),
    );

    final path = Path()
      ..moveTo(r.left + radius, r.top)
      ..lineTo(r.right - radius, r.top)
      ..quadraticBezierTo(r.right, r.top, r.right, r.top + radius)
      ..lineTo(r.right, r.bottom - radius)
      ..quadraticBezierTo(r.right, r.bottom, r.right - radius, r.bottom);

    if (spikeAtBottom) {
      // Add speech bubble tail / spike pointing toward speaker
      path.lineTo(r.left + 45, r.bottom);
      path.lineTo(r.left + 25, r.bottom + spikeHeight);
      path.lineTo(r.left + 20, r.bottom);
    }

    path.lineTo(r.left + radius, r.bottom);
    path.quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - radius);
    path.lineTo(r.left, r.top + radius);
    path.quadraticBezierTo(r.left, r.top, r.left + radius, r.top);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
