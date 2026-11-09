import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenUiIcons {
  static Future<void> generateAll() async {
    const base = 'assets/images/ui';

    // 1. HEART FULL & HEART EMPTY (64x64)
    for (final isFull in [true, false]) {
      await GenUtils.saveSingle(
        relativePath: '$base/${isFull ? 'icon_heart_full.png' : 'icon_heart_empty.png'}',
        width: 64,
        height: 64,
        draw: (canvas, size) {
          final cx = size.width / 2;
          final cy = size.height / 2;
          final heart = Path()
            ..moveTo(cx, cy + 22)
            ..cubicTo(cx - 32, cy + 4, cx - 28, cy - 22, cx - 12, cy - 22)
            ..cubicTo(cx - 4, cy - 22, cx, cy - 14, cx, cy - 10)
            ..cubicTo(cx, cy - 14, cx + 4, cy - 22, cx + 12, cy - 22)
            ..cubicTo(cx + 28, cy - 22, cx + 32, cy + 4, cx, cy + 22)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            heart,
            isFull ? GenUtils.darkRed : const Color(0xFF475569),
            highlightColor: isFull ? GenUtils.red : const Color(0xFF94A3B8),
            outlineWidth: 3.8,
          );
          if (isFull) {
            // Glossy cartoon shine spot
            canvas.drawOval(
              Rect.fromCenter(center: Offset(cx - 11, cy - 11), width: 9, height: 6),
              GenUtils.fill(Colors.white.withValues(alpha: 0.85)),
            );
          }
        },
      );
    }

    // 2. SPIRIT ORB ICON (64x64)
    await GenUtils.saveSingle(
      relativePath: '$base/icon_spirit_orb.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        final c = Offset(size.width / 2, size.height / 2 + 4);
        final flame = Path()
          ..moveTo(c.dx, 6)
          ..quadraticBezierTo(c.dx + 26, c.dy - 6, c.dx + 18, c.dy + 16)
          ..quadraticBezierTo(c.dx, c.dy + 26, c.dx - 18, c.dy + 16)
          ..quadraticBezierTo(c.dx - 26, c.dy - 6, c.dx, 6)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          flame,
          GenUtils.darkCyan,
          highlightColor: GenUtils.cyan,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelCircle(
          canvas,
          c + const Offset(0, 4),
          9,
          GenUtils.yellow,
          highlightColor: Colors.white,
          outlineWidth: 2.5,
        );
      },
    );

    // 3. SCORE COIN / SHURIKEN EMBLEM (64x64)
    await GenUtils.saveSingle(
      relativePath: '$base/icon_score_scroll.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        final c = Offset(size.width / 2, size.height / 2);
        GenUtils.drawCelCircle(
          canvas,
          c,
          24,
          GenUtils.goldDark,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        GenUtils.drawCartoonStar(canvas, c, 16, 7, 4, GenUtils.white, outlineWidth: 2.5);
      },
    );

    // 4. PAUSE ICON (64x64)
    await GenUtils.saveSingle(
      relativePath: '$base/icon_pause.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(14, 12, 13, 40),
          4,
          GenUtils.gold,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(37, 12, 13, 40),
          4,
          GenUtils.gold,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
      },
    );

    // 5. D-PAD LEFT & RIGHT ARROWS (80x80)
    for (final isRight in [false, true]) {
      await GenUtils.saveSingle(
        relativePath: '$base/${isRight ? 'icon_dpad_right.png' : 'icon_dpad_left.png'}',
        width: 80,
        height: 80,
        draw: (canvas, size) {
          canvas.save();
          if (!isRight) {
            canvas.translate(size.width, 0);
            canvas.scale(-1, 1);
          }
          final arrow = Path()
            ..moveTo(14, 26)
            ..lineTo(42, 26)
            ..lineTo(42, 12)
            ..lineTo(68, 40)
            ..lineTo(42, 68)
            ..lineTo(42, 54)
            ..lineTo(14, 54)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            arrow,
            GenUtils.goldDark,
            highlightColor: GenUtils.yellow,
            outlineWidth: 4.0,
          );
          canvas.restore();
        },
      );
    }

    // 6. SKILL BUTTON ICONS (96x96)
    // SLASH
    await GenUtils.saveSingle(
      relativePath: '$base/icon_skill_slash.png',
      width: 96,
      height: 96,
      draw: (canvas, size) {
        final arc = Path()
          ..moveTo(16, 76)
          ..quadraticBezierTo(48, 12, 82, 18)
          ..quadraticBezierTo(56, 40, 26, 82)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          arc,
          GenUtils.orange,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        // Crossed katana blade
        canvas.save();
        canvas.translate(48, 48);
        canvas.rotate(-0.75);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-32, -4, 48, 8),
          3,
          GenUtils.steel,
          topHighlight: Colors.white,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(14, -10, 5, 20),
          2,
          GenUtils.gold,
          outlineWidth: 2.5,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(19, -4, 14, 8),
          2,
          GenUtils.red,
          outlineWidth: 2.5,
        );
        canvas.restore();
      },
    );

    // JUMP
    await GenUtils.saveSingle(
      relativePath: '$base/icon_skill_jump.png',
      width: 96,
      height: 96,
      draw: (canvas, size) {
        final cx = size.width / 2;
        // Upward winged arrow + cloud puff
        final arrow = Path()
          ..moveTo(cx, 12)
          ..lineTo(cx + 26, 44)
          ..lineTo(cx + 12, 44)
          ..lineTo(cx + 12, 68)
          ..lineTo(cx - 12, 68)
          ..lineTo(cx - 12, 44)
          ..lineTo(cx - 26, 44)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          arrow,
          GenUtils.darkCyan,
          highlightColor: GenUtils.cyan,
          outlineWidth: 3.8,
        );
        GenUtils.drawCelCircle(canvas, Offset(cx - 16, 74), 10, Colors.white, outlineWidth: 3.0);
        GenUtils.drawCelCircle(canvas, Offset(cx + 16, 74), 10, Colors.white, outlineWidth: 3.0);
        GenUtils.drawCelCircle(canvas, Offset(cx, 72), 13, Colors.white, outlineWidth: 3.0);
      },
    );

    // DASH
    await GenUtils.saveSingle(
      relativePath: '$base/icon_skill_dash.png',
      width: 96,
      height: 96,
      draw: (canvas, size) {
        // Cartoon lightning bolt
        final bolt = Path()
          ..moveTo(56, 10)
          ..lineTo(20, 52)
          ..lineTo(46, 52)
          ..lineTo(34, 86)
          ..lineTo(76, 42)
          ..lineTo(50, 42)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          bolt,
          GenUtils.goldDark,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.8,
        );
      },
    );

    // KUNAI
    await GenUtils.saveSingle(
      relativePath: '$base/icon_skill_kunai.png',
      width: 96,
      height: 96,
      draw: (canvas, size) {
        for (final angle in [-0.45, 0.45]) {
          canvas.save();
          canvas.translate(48, 48);
          canvas.rotate(angle);
          final blade = Path()
            ..moveTo(0, -36)
            ..lineTo(12, 4)
            ..lineTo(0, 14)
            ..lineTo(-12, 4)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            blade,
            GenUtils.steelDark,
            highlightColor: Colors.white,
            outlineWidth: 3.2,
          );
          GenUtils.drawCelCircle(
            canvas,
            const Offset(0, 26),
            6,
            GenUtils.red,
            outlineWidth: 2.8,
          );
          canvas.restore();
        }
      },
    );

    // OUGI ULTIMATE
    await GenUtils.saveSingle(
      relativePath: '$base/icon_skill_ougi.png',
      width: 96,
      height: 96,
      draw: (canvas, size) {
        final c = Offset(size.width / 2, size.height / 2);
        GenUtils.drawCartoonStar(
          canvas,
          c,
          42,
          22,
          8,
          GenUtils.red,
          outlineWidth: 3.8,
        );
        GenUtils.drawCartoonStar(
          canvas,
          c,
          28,
          14,
          8,
          GenUtils.yellow,
          outlineWidth: 3.0,
          rotation: pi / 8,
        );
        GenUtils.drawCelCircle(
          canvas,
          c,
          10,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 2.5,
        );
      },
    );

    // 7. S-RANK / VICTORY / DEFEAT BADGES (160x160)
    await GenUtils.saveSingle(
      relativePath: '$base/badge_s_rank.png',
      width: 160,
      height: 160,
      draw: (canvas, size) {
        final c = Offset(size.width / 2, size.height / 2);
        GenUtils.drawCartoonStar(
          canvas,
          c,
          72,
          52,
          12,
          GenUtils.goldDark,
          outlineWidth: 4.5,
        );
        GenUtils.drawCelCircle(
          canvas,
          c,
          46,
          GenUtils.red,
          highlightColor: GenUtils.orange,
          outlineWidth: 4.0,
        );
        final tp = TextPainter(
          text: const TextSpan(
            text: 'S',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: GenUtils.yellow,
              shadows: [Shadow(offset: Offset(3, 3), color: GenUtils.ink)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      },
    );
  }
}

