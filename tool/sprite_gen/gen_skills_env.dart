import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenSkillsEnv {
  static Future<void> generateAll() async {
    await _generateSkillsAndProjectiles();
    await _generateEnvironmentAndItems();
  }

  static Future<void> _generateSkillsAndProjectiles() async {
    const base = 'assets/images/skills';

    // 1. SLASH ARCS (Yellow, Cyan, Red, Purple - 5 frames each, 160x160)
    final slashConfigs = <String, List<Color>>{
      'slash_arc_yellow.png': [GenUtils.goldDark, GenUtils.yellow],
      'slash_arc_cyan.png': [GenUtils.darkCyan, GenUtils.cyan],
      'slash_arc_red.png': [GenUtils.darkRed, GenUtils.red],
      'slash_arc_purple.png': [GenUtils.darkPurple, GenUtils.purple],
    };

    for (final entry in slashConfigs.entries) {
      final baseCol = entry.value[0];
      final brightCol = entry.value[1];

      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 160,
        frameHeight: 160,
        frameCount: 5,
        drawFrame: (canvas, i, size) {
          final t = i / 4.0;
          final alpha = (1.0 - t * 0.65).clamp(0.2, 1.0);
          final thick = (1.0 - t * 0.55);

          canvas.save();
          canvas.translate(size.width * 0.42, size.height * 0.5);

          final path = Path();
          const outerR = 64.0;
          final innerR = 64.0 - 34.0 * thick;
          final startA = -pi * 0.48 + t * 0.25;
          final sweepA = pi * 0.95 * (1.0 - t * 0.2);

          for (int s = 0; s <= 16; s++) {
            final a = startA + sweepA * (s / 16.0);
            final pt = Offset(cos(a) * outerR, sin(a) * outerR);
            if (s == 0) {
              path.moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          for (int s = 16; s >= 0; s--) {
            final a = startA + sweepA * (s / 16.0);
            final midFactor = sin((s / 16.0) * pi);
            final r = outerR - (outerR - innerR) * midFactor;
            path.lineTo(cos(a) * r, sin(a) * r);
          }
          path.close();

          GenUtils.drawCelPath(
            canvas,
            path,
            baseCol.withValues(alpha: alpha),
            highlightColor: brightCol.withValues(alpha: alpha),
            outlineWidth: 3.5 * thick,
          );

          // Inner white energy core arc
          final corePaint = GenUtils.stroke(
            Colors.white.withValues(alpha: alpha),
            5.0 * thick,
          );
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: outerR - 8 * thick),
            startA + 0.15,
            sweepA - 0.3,
            false,
            corePaint,
          );

          // Cartoon sparkle star at tip
          GenUtils.drawCartoonStar(
            canvas,
            Offset(cos(startA + sweepA * 0.5) * (outerR + 4), 0),
            9 * thick,
            4 * thick,
            4,
            Colors.white,
            rotation: t * pi,
          );

          canvas.restore();
        },
      );
    }

    // 2. INK KUNAI PROJECTILE (4 frames, 96x48)
    await GenUtils.saveSheet(
      relativePath: '$base/proj_kunai.png',
      frameWidth: 96,
      frameHeight: 48,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        final cy = size.height / 2;

        // Fluttering red cloth ribbon tied to kunai ring
        final ribbon = Path()
          ..moveTo(22, cy)
          ..quadraticBezierTo(10, cy + sin(phase) * 9, 2, cy + cos(phase) * 7)
          ..lineTo(4, cy + cos(phase) * 7 + 5)
          ..quadraticBezierTo(12, cy + sin(phase) * 9 + 4, 22, cy + 3)
          ..close();
        GenUtils.drawCelPath(canvas, ribbon, GenUtils.red, outlineWidth: 2.5);

        // Pommel ring
        GenUtils.drawCelCircle(
          canvas,
          Offset(26, cy),
          6,
          GenUtils.gold,
          outlineWidth: 2.8,
        );
        canvas.drawCircle(Offset(26, cy), 2.5, GenUtils.fill(GenUtils.ink));

        // Red wrapped handle
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(31, cy - 3.5, 16, 7),
          2,
          GenUtils.red,
          outlineWidth: 2.5,
        );

        // Diamond Metallic Cartoon Kunai Blade
        final blade = Path()
          ..moveTo(90, cy)
          ..lineTo(54, cy - 12)
          ..lineTo(45, cy - 4)
          ..lineTo(45, cy + 4)
          ..lineTo(54, cy + 12)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          blade,
          GenUtils.steelDark,
          highlightColor: Colors.white,
          outlineWidth: 3.2,
        );
        // Cyan energy center ridge
        canvas.drawLine(
          Offset(50, cy),
          Offset(84, cy),
          GenUtils.stroke(GenUtils.cyan, 2.5),
        );
      },
    );

    // 3. BOSS DARK SLASH WAVE (4 frames, 120x140)
    await GenUtils.saveSheet(
      relativePath: '$base/proj_dark_wave.png',
      frameWidth: 120,
      frameHeight: 140,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        final cx = size.width * 0.55;
        final cy = size.height * 0.5;

        // Crescent shadow-flame wave
        final wave = Path()
          ..moveTo(cx - 10, 10)
          ..quadraticBezierTo(cx + 55, cy, cx - 10, size.height - 10)
          ..quadraticBezierTo(cx + 18, cy, cx - 10, 10)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          wave,
          GenUtils.darkPurple,
          highlightColor: GenUtils.red,
          outlineWidth: 4.0,
        );

        // Trailing dark flame spikes
        for (int f = -1; f <= 1; f++) {
          final fy = cy + f * 32.0;
          final spike = Path()
            ..moveTo(cx + 10, fy - 8)
            ..lineTo(10 + sin(phase + f) * 8, fy)
            ..lineTo(cx + 10, fy + 8)
            ..close();
          GenUtils.drawCelPath(canvas, spike, GenUtils.red, outlineWidth: 2.8);
        }
      },
    );

    // 4. BOSS FLAME PILLAR ERUPTION (6 frames, 120x320)
    await GenUtils.saveSheet(
      relativePath: '$base/proj_flame_pillar.png',
      frameWidth: 120,
      frameHeight: 320,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final cx = size.width / 2;
        final bottom = size.height - 4.0;

        // Outer red-orange cartoon fire column
        final outer = Path()..moveTo(cx - 42, bottom);
        for (double y = bottom - 30; y >= 24; y -= 40) {
          final sway = sin(phase + y * 0.04) * 10;
          outer.lineTo(cx - 38 + sway, y);
        }
        outer.lineTo(cx + sin(phase) * 8, 8);
        for (double y = 24; y <= bottom - 30; y += 40) {
          final sway = cos(phase + y * 0.04) * 10;
          outer.lineTo(cx + 38 + sway, y);
        }
        outer.lineTo(cx + 42, bottom);
        outer.close();

        GenUtils.drawCelPath(
          canvas,
          outer,
          GenUtils.red,
          highlightColor: GenUtils.orange,
          outlineWidth: 4.0,
        );

        // Inner yellow-white hot core
        final inner = Path()
          ..moveTo(cx - 22, bottom)
          ..quadraticBezierTo(cx - 18 + sin(phase) * 8, 120, cx, 36)
          ..quadraticBezierTo(cx + 18 + cos(phase) * 8, 120, cx + 22, bottom)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          inner,
          GenUtils.yellow,
          highlightColor: Colors.white,
          outlineWidth: 2.8,
        );
      },
    );

    // 5. BOSS ENERGY ORB (6 frames, 96x96)
    await GenUtils.saveSheet(
      relativePath: '$base/proj_energy_orb.png',
      frameWidth: 96,
      frameHeight: 96,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final center = Offset(size.width / 2, size.height / 2);

        // Spiky cartoon plasma outer ring
        GenUtils.drawCartoonStar(
          canvas,
          center,
          38,
          28,
          8,
          GenUtils.cyan,
          outlineWidth: 3.5,
          rotation: phase,
        );
        GenUtils.drawCelCircle(
          canvas,
          center,
          22,
          GenUtils.yellow,
          highlightColor: Colors.white,
          outlineWidth: 3.0,
        );
      },
    );

    // 6. DRONE INK NEEDLE (4 frames, 48x80)
    await GenUtils.saveSheet(
      relativePath: '$base/proj_drone_needle.png',
      frameWidth: 48,
      frameHeight: 80,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final cx = size.width / 2;
        final feather = Path()
          ..moveTo(cx, size.height - 6)
          ..lineTo(cx - 12, 22)
          ..lineTo(cx, 6)
          ..lineTo(cx + 12, 22)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          feather,
          GenUtils.ink,
          highlightColor: GenUtils.purple,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset(cx, size.height - 14),
          5,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 2.2,
        );
      },
    );

    // 7. VFX DUST PUFF (6 frames, 120x90)
    await GenUtils.saveSheet(
      relativePath: '$base/vfx_dust_puff.png',
      frameWidth: 120,
      frameHeight: 90,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final t = i / 5.0;
        final alpha = (1.0 - t * 0.85).clamp(0.1, 1.0);
        final spread = 12.0 + t * 28.0;
        final r = (18.0 - t * 8.0).clamp(5.0, 20.0);
        final cx = size.width / 2;
        final cy = size.height - 22 - t * 16;

        final puffs = [
          Offset(cx - spread, cy + 4),
          Offset(cx - spread * 0.45, cy - 8),
          Offset(cx + spread * 0.45, cy - 6),
          Offset(cx + spread, cy + 4),
        ];
        for (final p in puffs) {
          GenUtils.drawCelCircle(
            canvas,
            p,
            r,
            GenUtils.white.withValues(alpha: alpha),
            highlightColor: Colors.white.withValues(alpha: alpha),
            outlineWidth: 3.0 * alpha,
          );
        }
      },
    );
  }

  static Future<void> _generateEnvironmentAndItems() async {
    const base = 'assets/images/environment';

    // 1. INK SCROLL COLLECTIBLE (6 frames, 80x80)
    await GenUtils.saveSheet(
      relativePath: '$base/item_scroll.png',
      frameWidth: 80,
      frameHeight: 80,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final center = Offset(size.width / 2, size.height / 2 + sin(phase) * 3);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.25);

        // Wooden scroll roller ends
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-32, -9, 64, 18),
          4,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.0,
        );

        // Parchment cylinder body
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-25, -13, 50, 26),
          6,
          const Color(0xFFFFF8E1),
          topHighlight: Colors.white,
          outlineWidth: 3.5,
        );

        // Red ribbon & gold seal clasp
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-7, -14, 14, 28),
          3,
          GenUtils.red,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset.zero,
          6,
          GenUtils.gold,
          highlightColor: GenUtils.yellow,
          outlineWidth: 2.5,
        );

        canvas.restore();

        // Twinkling cartoon star
        if (i % 2 == 0) {
          GenUtils.drawCartoonStar(
            canvas,
            Offset(center.dx + 22, center.dy - 18),
            7,
            3,
            4,
            GenUtils.yellow,
          );
        }
      },
    );

    // 2. RAMEN BOWL COLLECTIBLE (6 frames, 80x80)
    await GenUtils.saveSheet(
      relativePath: '$base/item_ramen.png',
      frameWidth: 80,
      frameHeight: 80,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final cx = size.width / 2;
        final cy = size.height / 2 + 6;

        // Chopsticks behind top
        canvas.drawLine(
          Offset(cx - 24, cy - 22),
          Offset(cx + 28, cy - 12),
          GenUtils.stroke(GenUtils.wood, 5.0),
        );
        canvas.drawLine(
          Offset(cx - 24, cy - 22),
          Offset(cx + 28, cy - 12),
          GenUtils.stroke(GenUtils.ink, 2.0),
        );

        // Golden noodles & narutomaki swirl peeking out
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromCenter(center: Offset(cx, cy - 8), width: 48, height: 18),
          9,
          GenUtils.yellow,
          topHighlight: Colors.white,
          outlineWidth: 3.0,
        );
        // Narutomaki fishcake
        GenUtils.drawCelCircle(
          canvas,
          Offset(cx - 8, cy - 11),
          7,
          Colors.white,
          outlineWidth: 2.5,
        );
        canvas.drawCircle(
          Offset(cx - 8, cy - 11),
          3,
          GenUtils.fill(GenUtils.red),
        );

        // Red Ceramic Ramen Bowl
        final bowl = Path()
          ..moveTo(cx - 28, cy - 6)
          ..lineTo(cx + 28, cy - 6)
          ..quadraticBezierTo(cx + 26, cy + 20, cx, cy + 20)
          ..quadraticBezierTo(cx - 26, cy + 20, cx - 28, cy - 6)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          bowl,
          GenUtils.darkRed,
          highlightColor: GenUtils.red,
          outlineWidth: 3.5,
        );
        // Gold rim stripe
        canvas.drawLine(
          Offset(cx - 24, cy + 1),
          Offset(cx + 24, cy + 1),
          GenUtils.stroke(GenUtils.gold, 3.0),
        );

        // Rising cartoon steam curls
        for (int s = -1; s <= 1; s += 2) {
          final sx = cx + s * 10 + sin(phase + s) * 4;
          final sy = cy - 26 - ((i * 3) % 10);
          canvas.drawCircle(
            Offset(sx, sy),
            4.5,
            GenUtils.fill(Colors.white.withValues(alpha: 0.75)),
          );
        }
      },
    );

    // 3. TORII GATE EXIT (6 frames, 160x200)
    await GenUtils.saveSheet(
      relativePath: '$base/prop_torii.png',
      frameWidth: 160,
      frameHeight: 200,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final cx = size.width / 2;
        final bottom = size.height - 6.0;

        // Glowing swirling mystical portal inside gate
        final portalRect = Rect.fromLTWH(cx - 38, 56, 76, bottom - 56);
        final portalPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              GenUtils.cyan.withValues(alpha: 0.75),
              GenUtils.purple.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(portalRect);
        canvas.drawOval(portalRect, portalPaint);

        // Portal energy rings
        canvas.save();
        canvas.translate(cx, 125);
        canvas.rotate(phase);
        GenUtils.drawCartoonStar(
          canvas,
          Offset.zero,
          28,
          16,
          6,
          GenUtils.yellow.withValues(alpha: 0.65),
          outlineWidth: 2.0,
        );
        canvas.restore();

        // Stone pedestals & Vermilion Pillars
        for (final side in [-1, 1]) {
          final px = cx + side * 44.0;
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromLTWH(px - 10, 34, 20, bottom - 34),
            4,
            GenUtils.darkRed,
            topHighlight: GenUtils.red,
            outlineWidth: 3.8,
          );
          // Black stone base
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromLTWH(px - 14, bottom - 18, 28, 18),
            3,
            GenUtils.ink,
            topHighlight: GenUtils.steelDark,
            outlineWidth: 3.5,
          );
        }

        // Lower tie beam (Nuki)
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 64, 54, 128, 14),
          3,
          GenUtils.red,
          topHighlight: const Color(0xFFFF6B7A),
          outlineWidth: 3.5,
        );

        // Curved Top Lintels (Kasagi)
        final roof = Path()
          ..moveTo(cx - 74, 22)
          ..quadraticBezierTo(cx, 38, cx + 74, 22)
          ..lineTo(cx + 68, 40)
          ..quadraticBezierTo(cx, 50, cx - 68, 40)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          roof,
          GenUtils.ink,
          highlightColor: GenUtils.darkNavy,
          outlineWidth: 4.0,
        );

        // Center golden plaque
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 10, 38, 20, 22),
          3,
          GenUtils.gold,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.0,
        );
      },
    );

    // 4. SPRING PAD (4 frames, 96x64)
    await GenUtils.saveSheet(
      relativePath: '$base/trap_spring.png',
      frameWidth: 96,
      frameHeight: 64,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final heights = [36.0, 18.0, 48.0, 36.0];
        final h = heights[i];
        final cx = size.width / 2;
        final bottom = size.height - 4.0;

        // Metallic coil spring underneath
        final coilPaint = GenUtils.stroke(GenUtils.steel, 6.0);
        final coilOutline = GenUtils.stroke(GenUtils.ink, 10.0);
        final p1 = Offset(cx - 18, bottom - 4);
        final p2 = Offset(cx + 18, bottom - h * 0.45);
        final p3 = Offset(cx - 18, bottom - h * 0.8);
        canvas.drawLine(p1, p2, coilOutline);
        canvas.drawLine(p2, p3, coilOutline);
        canvas.drawLine(p1, p2, coilPaint);
        canvas.drawLine(p2, p3, coilPaint);

        // Bouncy Yellow/Cyan Cartoon Pad Top
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 38, bottom - h - 12, 76, 18),
          8,
          GenUtils.gold,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        // Upward double chevron arrows on pad
        canvas.drawLine(
          Offset(cx - 12, bottom - h),
          Offset(cx, bottom - h - 8),
          GenUtils.stroke(GenUtils.red, 3.5),
        );
        canvas.drawLine(
          Offset(cx + 12, bottom - h),
          Offset(cx, bottom - h - 8),
          GenUtils.stroke(GenUtils.red, 3.5),
        );
      },
    );

    // 5. ROTATING SAW BLADE (4 frames, 120x120)
    await GenUtils.saveSheet(
      relativePath: '$base/trap_saw.png',
      frameWidth: 120,
      frameHeight: 120,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final rot = (i / 4.0) * (pi / 4);
        final center = Offset(size.width / 2, size.height / 2);

        // Crimson-tipped cartoon shuriken saw teeth
        GenUtils.drawCartoonStar(
          canvas,
          center,
          54,
          34,
          8,
          GenUtils.steel,
          outlineWidth: 3.8,
          rotation: rot,
        );
        GenUtils.drawCelCircle(
          canvas,
          center,
          30,
          GenUtils.darkNavy,
          highlightColor: GenUtils.navy,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelCircle(
          canvas,
          center,
          14,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.0,
        );
      },
    );

    // 6. SPIKE TRAP SINGLE TILE (64x64)
    await GenUtils.saveSingle(
      relativePath: '$base/trap_spikes.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        for (int s = 0; s < 2; s++) {
          final left = s * 32.0 + 2;
          final right = (s + 1) * 32.0 - 2;
          final tip = (left + right) / 2;
          final spike = Path()
            ..moveTo(left, size.height - 4)
            ..lineTo(tip, 8)
            ..lineTo(right, size.height - 4)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            spike,
            GenUtils.steelDark,
            highlightColor: Colors.white,
            outlineWidth: 3.5,
          );
          // Crimson hazard tip
          final tipPath = Path()
            ..moveTo(tip - 5, 22)
            ..lineTo(tip, 8)
            ..lineTo(tip + 5, 22)
            ..close();
          GenUtils.drawCelPath(canvas, tipPath, GenUtils.red, outlineWidth: 2.0);
        }
      },
    );

    // 7. PLATFORM SPRITES (Rooftop, Citadel, Moving, Crumbling - 256x80)
    await _generatePlatformSprites(base);
  }

  static Future<void> _generatePlatformSprites(String base) async {
    // Rooftop Pagoda Platform
    await GenUtils.saveSingle(
      relativePath: '$base/platform_rooftop.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        // Wooden beam underside
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 20, size.width - 8, size.height - 24),
          8,
          GenUtils.woodDark,
          topHighlight: GenUtils.wood,
          outlineWidth: 4.0,
        );
        // Curved Japanese slate roof tiles along top
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(2, 4, size.width - 4, 24),
          8,
          GenUtils.darkNavy,
          topHighlight: GenUtils.navy,
          outlineWidth: 4.0,
        );
        for (double x = 28; x < size.width - 20; x += 32) {
          canvas.drawArc(
            Rect.fromCenter(center: Offset(x, 20), width: 28, height: 14),
            0,
            pi,
            false,
            GenUtils.stroke(GenUtils.cyan, 2.5),
          );
        }
      },
    );

    // Citadel Magma Stone Platform
    await GenUtils.saveSingle(
      relativePath: '$base/platform_citadel.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 6, size.width - 8, size.height - 10),
          8,
          const Color(0xFF2D1B2E),
          topHighlight: const Color(0xFF4A2545),
          outlineWidth: 4.0,
        );
        // Glowing magma cracks & gold trim along top
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 6, size.width - 8, 16),
          6,
          GenUtils.darkRed,
          topHighlight: GenUtils.red,
          outlineWidth: 3.5,
        );
        for (double x = 36; x < size.width - 24; x += 48) {
          canvas.drawLine(
            Offset(x, 24),
            Offset(x + 12, size.height - 12),
            GenUtils.stroke(GenUtils.orange, 3.0),
          );
        }
      },
    );

    // Moving Mechanical Cloud/Gear Platform
    await GenUtils.saveSingle(
      relativePath: '$base/platform_moving.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(6, 10, size.width - 12, size.height - 20),
          14,
          GenUtils.darkCyan,
          topHighlight: GenUtils.cyan,
          outlineWidth: 4.0,
        );
        // Gold rivets & thruster glow
        for (final x in [28.0, size.width / 2, size.width - 28.0]) {
          GenUtils.drawCelCircle(
            canvas,
            Offset(x, size.height / 2),
            8,
            GenUtils.gold,
            highlightColor: GenUtils.yellow,
            outlineWidth: 2.8,
          );
        }
      },
    );

    // Crumbling Cracked Stone Platform
    await GenUtils.saveSingle(
      relativePath: '$base/platform_crumbling.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(6, 8, size.width - 12, size.height - 16),
          8,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 4.0,
        );
        // Heavy jagged cartoon cracks
        final crack = Path()
          ..moveTo(70, 10)
          ..lineTo(88, 38)
          ..lineTo(74, 68)
          ..moveTo(170, 10)
          ..lineTo(155, 42)
          ..lineTo(178, 68);
        canvas.drawPath(crack, GenUtils.stroke(GenUtils.ink, 4.0));
      },
    );
  }
}

