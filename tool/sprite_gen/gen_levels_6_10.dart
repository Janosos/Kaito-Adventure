import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenLevels6To10 {
  static const Color brass = Color(0xFFD4AF37);
  static const Color darkBrass = Color(0xFF8B6508);
  static const Color copper = Color(0xFFB87333);
  static const Color foxViolet = Color(0xFFAB47BC);
  static const Color darkFoxViolet = Color(0xFF4A148C);
  static const Color abyssTeal = Color(0xFF00BFA5);
  static const Color darkAbyss = Color(0xFF004D40);
  static const Color coralRed = Color(0xFFFF5252);
  static const Color thunderGold = Color(0xFFFFEA00);
  static const Color stormBlue = Color(0xFF2979FF);
  static const Color voidMagenta = Color(0xFFD500F9);
  static const Color cosmicGold = Color(0xFFFFD740);

  static Future<void> generateAll() async {
    await _generateKaitoOugiSheet();
    await _generateEnemySamuraiShield();
    await _generateEnemyKitsuneMage();
    await _generateEnemyKarakuriAutomaton();
    await generateBosses6To10();
  }

  static Future<void> generateBosses6To10() async {
    await _generateBoss6GenjiKarakuri();
    await _generateBoss7InariKyubi();
    await _generateBoss8Wadatsumi();
    await _generateBoss9RaijinTei();
    await _generateBoss10AkumaShin();
  }

  // ===========================================================================
  // KAITO DEDICATED OUGI ULTIMATE SPRITESHEET (8 frames, 160x144)
  // ===========================================================================
  static Future<void> _generateKaitoOugiSheet() async {
    await GenUtils.saveSheet(
      relativePath: 'assets/images/characters/kaito_ougi.png',
      frameWidth: 160,
      frameHeight: 144,
      frameCount: 8,
      drawFrame: (canvas, frame, size) {
        final t = frame / 8.0;
        final cx = size.width * 0.5;
        final cy = size.height - 14.0;

        canvas.save();
        canvas.translate(cx, cy);

        // 1. Blazing Celestial Golden-Cyan Aura & Spinning Starburst behind Kaito
        final auraRadius = 46.0 + sin(t * pi) * 18.0;
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(0, -48),
          auraRadius + 14,
          auraRadius * 0.62,
          10,
          GenUtils.gold.withValues(alpha: 0.88),
          rotation: t * 2 * pi,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          const Offset(0, -48),
          auraRadius * 0.72,
          GenUtils.cyan.withValues(alpha: 0.75),
          highlightColor: Colors.white,
          outlineWidth: 2.8,
        );

        // 2. Dynamic Pose per Ougi Phase:
        // Frame 0-1: Iaijutsu Charge crouch
        // Frame 2-5: High-velocity 360 Omnislash Spin with dual crescent blades
        // Frame 6-7: Heroic Skyward Finisher Slash
        final isSpinPhase = frame >= 2 && frame <= 5;
        final isFinishPhase = frame >= 6;
        final crouchOffset = frame <= 1 ? 8.0 : (isSpinPhase ? -6.0 : -2.0);

        canvas.save();
        canvas.translate(0, crouchOffset);
        canvas.scale(0.84, 0.84);

        // Flowing Crimson Scarf billowing upward with spiritual energy
        final scarf = Path()
          ..moveTo(-14, -52)
          ..quadraticBezierTo(
            -48,
            -78 - sin(t * 4 * pi) * 14,
            -68,
            -56 + cos(t * 4 * pi) * 12,
          )
          ..lineTo(-54, -38)
          ..quadraticBezierTo(-34, -52, -10, -42)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          scarf,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.6,
        );

        // Legs
        for (final side in [-1.0, 1.0]) {
          final lx = side * 10.0;
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromLTWH(lx - 7, -34, 14, 26),
            5,
            GenUtils.darkNavy,
            topHighlight: GenUtils.navy,
            outlineWidth: 3.5,
          );
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromLTWH(lx - 6, -14, 12, 8),
            2,
            GenUtils.white,
            outlineWidth: 2.8,
          );
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromLTWH(lx - 8, -8, 16, 8),
            4,
            GenUtils.red,
            outlineWidth: 3.2,
          );
        }

        // Torso
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-18, -68, 36, 36),
          9,
          GenUtils.darkNavy,
          topHighlight: GenUtils.navy,
          outlineWidth: 3.8,
        );
        // White Obi Belt & Gold Buckle
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-19, -40, 38, 8),
          3,
          GenUtils.white,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-5, -41, 10, 10),
          2,
          GenUtils.gold,
          outlineWidth: 2.5,
        );
        // Red Scarf Collar
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-20, -72, 40, 11),
          5,
          GenUtils.red,
          topHighlight: const Color(0xFFFF6B7A),
          outlineWidth: 3.5,
        );

        // Head & Spiky Hair
        final hair = Path()
          ..moveTo(-20, -102)
          ..lineTo(-28, -120)
          ..lineTo(-10, -110)
          ..lineTo(0, -126)
          ..lineTo(10, -110)
          ..lineTo(28, -120)
          ..lineTo(20, -102)
          ..close();
        GenUtils.drawCelPath(canvas, hair, GenUtils.ink, outlineWidth: 3.5);

        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-22, -106, 44, 36),
          13,
          GenUtils.darkNavy,
          topHighlight: GenUtils.navy,
          outlineWidth: 3.8,
        );
        // Red Headband
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-23, -102, 46, 9),
          4,
          GenUtils.red,
          outlineWidth: 3.2,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-10, -101, 20, 7),
          2,
          GenUtils.white,
          outlineWidth: 2.4,
        );
        // Face & Awakened Glowing Golden-Cyan Eyes
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-16, -90, 32, 15),
          6,
          GenUtils.skin,
          outlineWidth: 3.0,
        );
        for (final ex in [-7.0, 7.0]) {
          GenUtils.drawCelCircle(
            canvas,
            Offset(ex, -82),
            4.5,
            GenUtils.cyan,
            highlightColor: Colors.white,
            outlineWidth: 2.2,
          );
        }

        // 3. Celestial Katana & Swirling Dragon Slash Crescent
        final bladeAngle = isSpinPhase
            ? ((frame - 2) * pi * 0.55 - 0.8)
            : (isFinishPhase ? -1.15 : 0.35);

        canvas.save();
        canvas.translate(10, -54);
        canvas.rotate(bladeAngle);

        // Giant Glowing Celestial Katana Blade
        final blade = Path()
          ..moveTo(0, -5)
          ..lineTo(74, -8)
          ..lineTo(88, 0)
          ..lineTo(74, 8)
          ..lineTo(0, 5)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          blade,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 3.8,
        );
        canvas.drawLine(
          const Offset(8, 0),
          const Offset(78, 0),
          GenUtils.stroke(GenUtils.yellow, 3.2),
        );
        canvas.restore();

        canvas.restore(); // end character scale

        // 4. Outer Swirling Dragon-Ink Slash Rings on Spin & Finish Frames
        if (frame >= 1) {
          final ringRect =
              Rect.fromCenter(center: const Offset(0, -48), width: 136, height: 92);
          final startAngle = frame * 1.1;
          final arcPaint = Paint()
            ..color = (frame.isEven ? GenUtils.yellow : GenUtils.cyan)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7.0
            ..strokeCap = StrokeCap.round;
          final borderPaint = Paint()
            ..color = GenUtils.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11.5
            ..strokeCap = StrokeCap.round;
          canvas.drawArc(ringRect, startAngle, 2.2, false, borderPaint);
          canvas.drawArc(ringRect, startAngle, 2.2, false, arcPaint);
        }

        canvas.restore();
      },
    );
  }

  // ===========================================================================
  // NEW ENEMY 1: ARMORED RONIN SHIELD-BEARER (128x128)
  // ===========================================================================
  static Future<void> _generateEnemySamuraiShield() async {
    const base = 'assets/images/enemies';

    void drawSamurai(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=walk, 1=attack, 2=guard
    }) {
      canvas.save();
      canvas.translate(centerBottom.dx, centerBottom.dy + bob);

      // Legs
      for (final side in [-1.0, 1.0]) {
        final step = mode == 0 ? sin(animProgress * 2 * pi + side) * 5.0 : 0.0;
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(side * 10 - 7 + step, -26, 14, 24),
          5,
          GenUtils.darkNavy,
          topHighlight: GenUtils.steelDark,
          outlineWidth: 3.4,
        );
      }

      // Heavy Crimson & Iron Samurai Armor Torso
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-20, -64, 40, 42),
        10,
        GenUtils.darkRed,
        topHighlight: GenUtils.red,
        outlineWidth: 3.8,
      );
      for (double y = -54; y <= -34; y += 10) {
        canvas.drawLine(
          Offset(-15, y),
          Offset(15, y),
          GenUtils.stroke(GenUtils.gold, 2.6),
        );
      }

      // Horned Kabuto Helmet & Glowing Visor
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-18, -94, 36, 32),
        10,
        GenUtils.ink,
        topHighlight: GenUtils.steelDark,
        outlineWidth: 3.8,
      );
      final horns = Path()
        ..moveTo(-12, -90)
        ..lineTo(-26, -108)
        ..lineTo(-6, -94)
        ..lineTo(6, -94)
        ..lineTo(26, -108)
        ..lineTo(12, -90)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        horns,
        GenUtils.gold,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.2,
      );
      for (final ex in [-6.0, 6.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -78),
          3.5,
          GenUtils.yellow,
          outlineWidth: 2.0,
        );
      }

      // Cleaving Naginata Polearm (Right Arm)
      final spearAngle =
          mode == 1 ? (-1.1 + animProgress * 2.0) : -0.45;
      canvas.save();
      canvas.translate(14, -50);
      canvas.rotate(spearAngle);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-4, -3, 38, 6),
        2,
        GenUtils.wood,
        outlineWidth: 2.8,
      );
      final blade = Path()
        ..moveTo(32, -6)
        ..lineTo(54, -2)
        ..lineTo(58, 0)
        ..lineTo(54, 5)
        ..lineTo(32, 4)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        blade,
        GenUtils.steel,
        highlightColor: Colors.white,
        outlineWidth: 3.0,
      );
      canvas.restore();

      // Front Iron Tower Shield (Left / Front Arm)
      final shieldX = mode == 2 ? -22.0 : -18.0;
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(shieldX - 10, -68, 20, 52),
        6,
        GenUtils.steelDark,
        topHighlight: GenUtils.steel,
        outlineWidth: 3.8,
      );
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(shieldX - 5, -58, 10, 32),
        3,
        GenUtils.red,
        topHighlight: GenUtils.gold,
        outlineWidth: 2.6,
      );

      canvas.restore();
    }

    for (final entry in {
      'samurai_walk.png': [6, 0],
      'samurai_attack.png': [5, 1],
      'samurai_guard.png': [4, 2],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 128,
        frameHeight: 128,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final t = i / entry.value[0];
          drawSamurai(
            canvas,
            Offset(size.width * 0.5, size.height - 10),
            bob: sin(t * 2 * pi) * 2.5,
            animProgress: t,
            mode: entry.value[1],
          );
        },
      );
    }
  }

  // ===========================================================================
  // NEW ENEMY 2: KITSUNE SPIRIT MAGE (128x128)
  // ===========================================================================
  static Future<void> _generateEnemyKitsuneMage() async {
    const base = 'assets/images/enemies';

    void drawKitsune(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=float, 1=cast
    }) {
      canvas.save();
      canvas.translate(centerBottom.dx, centerBottom.dy + bob - 8);

      // Twin Swooshing Violet-White Fox Tails
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * 12, -32);
        canvas.rotate(side * (0.45 + sin(animProgress * 2 * pi) * 0.18));
        final tail = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(side * 26, -18, side * 18, -44)
          ..quadraticBezierTo(0, -32, 0, 0)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          tail,
          foxViolet,
          highlightColor: Colors.white,
          outlineWidth: 3.4,
        );
        canvas.restore();
      }

      // Floating Mystic Shrine Robe
      final robe = Path()
        ..moveTo(-16, -64)
        ..lineTo(16, -64)
        ..lineTo(24, -14)
        ..lineTo(0, -22)
        ..lineTo(-24, -14)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        robe,
        darkFoxViolet,
        highlightColor: foxViolet,
        outlineWidth: 3.6,
      );

      // White & Crimson Kitsune Mask with Pointed Fox Ears
      final ears = Path()
        ..moveTo(-16, -88)
        ..lineTo(-22, -110)
        ..lineTo(-6, -94)
        ..lineTo(6, -94)
        ..lineTo(22, -110)
        ..lineTo(16, -88)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        ears,
        GenUtils.white,
        highlightColor: GenUtils.red,
        outlineWidth: 3.4,
      );

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-18, -94, 36, 32),
        12,
        GenUtils.white,
        topHighlight: Colors.white,
        outlineWidth: 3.6,
      );
      // Crimson Kitsune Mask Markings & Glowing Cyan Fox Eyes
      for (final ex in [-7.0, 7.0]) {
        canvas.drawLine(
          Offset(ex - 4, -80),
          Offset(ex + 4, -78),
          GenUtils.stroke(GenUtils.cyan, 3.2),
        );
        canvas.drawLine(
          Offset(ex * 1.4, -72),
          Offset(ex * 2.0, -68),
          GenUtils.stroke(GenUtils.red, 2.6),
        );
      }

      // Orbiting Foxfire Spirit Orbs
      final orbRadius = mode == 1 ? 6.5 : 4.8;
      for (int o = 0; o < 3; o++) {
        final a = animProgress * 2 * pi + (o * 2 * pi / 3);
        final ox = cos(a) * 32;
        final oy = -58 + sin(a) * 14;
        GenUtils.drawCelCircle(
          canvas,
          Offset(ox, oy),
          orbRadius,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 2.4,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'kitsune_float.png': [6, 0],
      'kitsune_cast.png': [5, 1],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 128,
        frameHeight: 128,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final t = i / entry.value[0];
          drawKitsune(
            canvas,
            Offset(size.width * 0.5, size.height - 10),
            bob: sin(t * 2 * pi) * 4.5,
            animProgress: t,
            mode: entry.value[1],
          );
        },
      );
    }
  }

  // ===========================================================================
  // NEW ENEMY 3: CLOCKWORK KARAKURI AUTOMATON (128x128)
  // ===========================================================================
  static Future<void> _generateEnemyKarakuriAutomaton() async {
    const base = 'assets/images/enemies';

    void drawKarakuri(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=march, 1=spin
    }) {
      canvas.save();
      canvas.translate(centerBottom.dx, centerBottom.dy + bob);

      // Wind-Up Brass Gear Key on Back
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -54),
        28,
        18,
        8,
        brass,
        rotation: animProgress * 2 * pi,
        outlineWidth: 3.0,
      );

      // Mechanical Piston Legs
      for (final side in [-1.0, 1.0]) {
        final lift = mode == 0 ? sin(animProgress * 2 * pi + side) * 4.0 : 0.0;
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(side * 10 - 6, -24 + lift, 12, 22),
          4,
          copper,
          topHighlight: brass,
          outlineWidth: 3.2,
        );
      }

      // Cylindrical Wood & Brass Puppet Torso
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-18, -62, 36, 40),
        8,
        GenUtils.wood,
        topHighlight: copper,
        outlineWidth: 3.8,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -42),
        8,
        GenUtils.orange,
        highlightColor: GenUtils.yellow,
        outlineWidth: 2.6,
      );

      // Wooden Karakuri Mask Head with Glowing Red Cyclops/Twin Visor
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-16, -90, 32, 28),
        7,
        brass,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.6,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-11, -80, 22, 8),
        3,
        GenUtils.ink,
        outlineWidth: 2.4,
      );
      GenUtils.drawCelCircle(
        canvas,
        Offset(sin(animProgress * 2 * pi) * 4, -76),
        3.5,
        GenUtils.red,
        highlightColor: GenUtils.yellow,
        outlineWidth: 1.8,
      );

      // Twin Whirling Buzzsaw Hands
      final sawSpread = mode == 1 ? 30.0 : 22.0;
      for (final side in [-1.0, 1.0]) {
        GenUtils.drawCartoonStar(
          canvas,
          Offset(side * sawSpread, -44),
          14,
          8,
          8,
          GenUtils.steel,
          rotation: animProgress * 4 * pi * side,
          outlineWidth: 2.8,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'karakuri_march.png': [6, 0],
      'karakuri_spin.png': [5, 1],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 128,
        frameHeight: 128,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final t = i / entry.value[0];
          drawKarakuri(
            canvas,
            Offset(size.width * 0.5, size.height - 10),
            bob: sin(t * 2 * pi).abs() * -3.5,
            animProgress: t,
            mode: entry.value[1],
          );
        },
      );
    }
  }

  static void _drawSlashArc(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = GenUtils.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      startAngle + sweepAngle * 0.15,
      sweepAngle * 0.7,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _drawStunSparksAndStars(
    Canvas canvas, {
    required double animProgress,
    required double starY,
    required double starRadiusX,
    double bodyCenterY = -96,
  }) {
    for (int sp = 0; sp < 3; sp++) {
      final sa = animProgress * 2 * pi + sp * (2 * pi / 3);
      final sx = cos(sa) * 28.0;
      final sy = bodyCenterY + sin(sa * 2) * 22.0;
      final spark = Path()
        ..moveTo(sx - 8, sy - 6)
        ..lineTo(sx + 2, sy - 1)
        ..lineTo(sx - 3, sy + 4)
        ..lineTo(sx + 8, sy + 9);
      canvas.drawPath(spark, GenUtils.stroke(GenUtils.cyan, 2.8));
    }

    final orbitRect = Rect.fromCenter(
      center: Offset(0, starY),
      width: starRadiusX * 2.1,
      height: 18,
    );
    canvas.drawOval(
      orbitRect,
      GenUtils.stroke(GenUtils.yellow.withValues(alpha: 0.65), 2.4),
    );
    for (int s = 0; s < 4; s++) {
      final a = animProgress * 2 * pi + (s * pi / 2);
      GenUtils.drawCartoonStar(
        canvas,
        Offset(cos(a) * starRadiusX, starY + sin(a) * 9),
        s.isEven ? 10.5 : 8.0,
        4.8,
        5,
        s.isEven ? GenUtils.yellow : GenUtils.cyan,
        rotation: a,
      );
    }
  }

  // ===========================================================================
  // BOSS 6: GENJI-KARAKURI (THE CLOCKWORK SHOGUN — LEVEL 6)
  // ===========================================================================
  static Future<void> _generateBoss6GenjiKarakuri() async {
    const base = 'assets/images/bosses';

    void drawGenji(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=charge, 2=cleave, 3=guard, 4=stun
    }) {
      final bool isCharge = mode == 1;
      final bool isCleave = mode == 2;
      final bool isGuard = mode == 3;
      final bool isStun = mode == 4;

      double bodyDx = 0.0;
      double bodyDy = bob;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isCharge) {
        bodyDx = sin(animProgress * pi) * 14.0;
        bodyDy = -3.0 + sin(animProgress * 2 * pi).abs() * 4.0;
        torsoTilt = 0.22;
      } else if (isCleave) {
        if (animProgress < 0.30) {
          final wt = animProgress / 0.30;
          bodyDx = -10.0 * wt;
          bodyDy = -8.0 * wt;
          torsoTilt = -0.18 * wt;
        } else {
          final st = ((animProgress - 0.30) / 0.70).clamp(0.0, 1.0);
          bodyDx = -10.0 + 26.0 * sin(st * pi * 0.65);
          bodyDy = 7.0 * sin(st * pi);
          torsoTilt = -0.18 + 0.42 * sin(st * pi * 0.75);
        }
      } else if (isGuard) {
        bodyDx = -3.0;
        bodyDy = 3.0;
        torsoTilt = -0.06;
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.5 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isCharge || (isCleave && animProgress >= 0.25)) {
        for (int l = 0; l < 4; l++) {
          final ly = -35.0 - l * 32.0;
          canvas.drawLine(
            Offset(-90 - (l % 2) * 16.0, ly),
            Offset(-38, ly),
            GenUtils.stroke(GenUtils.orange.withValues(alpha: 0.78), 3.4),
          );
        }
      }

      // 1. Giant Spinning Brass Clockwork Cogwheel Halo behind Shogun
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -114),
        78,
        58,
        12,
        brass,
        rotation: animProgress * (isCharge || isCleave ? 4 : 2) * pi,
        outlineWidth: 3.8,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -114),
        42,
        darkBrass,
        highlightColor: copper,
        outlineWidth: 3.5,
      );

      // 2. Heavy Steam-Piston Samurai Greaves (animated stride / lunge / kneel)
      for (final side in [-1.0, 1.0]) {
        double lx = side * 22.0;
        double ly = 0.0;
        double legRot = 0.0;
        if (isCharge) {
          final s = sin(animProgress * 2 * pi + (side < 0 ? 0 : pi));
          lx += s * 13.0;
          ly = s < 0 ? s * 6.0 : 0.0;
          legRot = -s * 0.25;
        } else if (isCleave && animProgress >= 0.30) {
          lx += side * 10.0;
          legRot = side * -0.18;
        } else if (isStun) {
          if (side < 0) {
            lx -= 4.0;
            ly = 2.0;
            legRot = 0.14;
          } else {
            lx += 4.0;
            legRot = -0.08;
          }
        }
        canvas.save();
        canvas.translate(lx, -52 + ly);
        canvas.rotate(legRot);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-14, 0, 28, 48),
          7,
          darkBrass,
          topHighlight: brass,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-16, 40, 32, 12),
          4,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 3.5,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 3. Hulking Brass & Crimson Clockwork Cuirass with Glowing Furnace Core
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-40, -130, 80, 82),
        14,
        copper,
        topHighlight: brass,
        outlineWidth: 4.4,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -92),
        18,
        GenUtils.ink,
        outlineWidth: 3.5,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -92),
        12,
        GenUtils.orange,
        highlightColor: GenUtils.yellow,
        outlineWidth: 2.5,
      );

      // 4. Steampunk Gear Pauldrons
      for (final side in [-1.0, 1.0]) {
        GenUtils.drawCartoonStar(
          canvas,
          Offset(side * 46, -120),
          26,
          18,
          8,
          brass,
          rotation: -animProgress * 2 * pi * side,
          outlineWidth: 3.6,
        );
      }

      // 5. Mechanical Shogun Kabuto Helmet & Twin Steam Smokestacks
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-28, -172, 56, 44),
        12,
        GenUtils.ink,
        topHighlight: GenUtils.steelDark,
        outlineWidth: 4.0,
      );
      final crest = Path()
        ..moveTo(0, -166)
        ..lineTo(-36, -204)
        ..lineTo(-14, -172)
        ..lineTo(0, -190)
        ..lineTo(14, -172)
        ..lineTo(36, -204)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        crest,
        brass,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.6,
      );
      for (final ex in [-10.0, 10.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -152),
          5.0,
          GenUtils.orange,
          highlightColor: GenUtils.yellow,
          outlineWidth: 2.2,
        );
      }

      // 6. Twin Steam-Saw Halberds (dynamic sweep across frames!)
      double bladeRot = -0.45 + sin(animProgress * 2 * pi) * 0.06;
      if (isCharge) {
        bladeRot = 0.05 + sin(animProgress * 2 * pi) * 0.25;
      } else if (isCleave) {
        bladeRot = -1.65 + animProgress * 2.55;
      } else if (isGuard) {
        bladeRot = -1.15;
      } else if (isStun) {
        bladeRot = 1.05 + sin(animProgress * 2 * pi) * 0.14;
      }

      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * 38, -96);
        final rot = side > 0
            ? bladeRot
            : (isStun ? (pi - bladeRot) : (-bladeRot - pi));
        canvas.rotate(rot);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(0, -6, 68, 12),
          4,
          GenUtils.steel,
          topHighlight: Colors.white,
          outlineWidth: 3.6,
        );
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(72, 0),
          22,
          13,
          10,
          GenUtils.orange,
          rotation: animProgress * 4 * pi,
          outlineWidth: 3.2,
        );
        canvas.restore();
      }

      if (isCleave && animProgress >= 0.25 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(28, -86),
          radius: 78,
          startAngle: -1.35 + (animProgress - 0.25) * 1.5,
          sweepAngle: 1.55,
          color: GenUtils.orange,
        );
      }

      if (isGuard) {
        final shield =
            Rect.fromCenter(center: const Offset(0, -96), width: 112, height: 138);
        canvas.drawOval(
          shield,
          GenUtils.fill(brass.withValues(alpha: 0.28)),
        );
        canvas.drawOval(shield, GenUtils.stroke(GenUtils.yellow, 4.0));
      }

      canvas.restore(); // end torso tilt

      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -202,
          starRadiusX: 44,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'genji_idle.png': [6, 0],
      'genji_charge.png': [4, 1],
      'genji_cleave.png': [5, 2],
      'genji_guard.png': [4, 3],
      'genji_stun.png': [4, 4],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 240,
        frameHeight: 220,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2 ? (i / (count - 1)) : (i / count);
          final phase = (i / count) * 2 * pi;
          drawGenji(
            canvas,
            Offset(size.width * 0.46, size.height - 8),
            bob: mode == 0 ? sin(phase) * 4.0 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // ===========================================================================
  // BOSS 7: INARI-KYUBI (THE NINE-TAIL ARCHMAGE — LEVEL 7)
  // ===========================================================================
  static Future<void> _generateBoss7InariKyubi() async {
    const base = 'assets/images/bosses';

    void drawInari(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=dash, 2=cast, 3=stun
    }) {
      final bool isDash = mode == 1;
      final bool isCast = mode == 2;
      final bool isStun = mode == 3;

      double bodyDx = 0.0;
      double bodyDy = bob;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isDash) {
        bodyDx = sin(animProgress * pi) * 18.0;
        bodyDy = -6.0 + sin(animProgress * 2 * pi) * 4.0;
        torsoTilt = 0.25;
      } else if (isCast) {
        bodyDy = -12.0 - sin(animProgress * pi) * 10.0;
        torsoTilt = -0.08 * sin(animProgress * pi);
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.5 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isDash) {
        for (int l = 0; l < 4; l++) {
          final ly = -35.0 - l * 32.0;
          canvas.drawLine(
            Offset(-90 - (l % 2) * 16.0, ly),
            Offset(-38, ly),
            GenUtils.stroke(foxViolet.withValues(alpha: 0.78), 3.4),
          );
        }
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 1. Nine Majestic Fanning Kitsune Tails behind Archmage (animated flare / droop)
      for (int tIdx = -4; tIdx <= 4; tIdx++) {
        canvas.save();
        canvas.translate(0, -92);
        final spread = isCast ? 0.36 : (isDash ? 0.20 : 0.28);
        final droop = isStun ? (tIdx.sign * 0.32) : 0.0;
        final wave = sin(animProgress * 2 * pi + tIdx) * (isCast ? 0.20 : 0.10);
        final angle = tIdx * spread + wave + droop;
        canvas.rotate(angle);
        final tail = Path()
          ..moveTo(-10, 0)
          ..quadraticBezierTo(-22, -55, 0, -96)
          ..quadraticBezierTo(22, -55, 10, 0)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          tail,
          tIdx.isEven ? foxViolet : GenUtils.gold,
          highlightColor: Colors.white,
          outlineWidth: 3.5,
        );
        canvas.restore();
      }

      // 2. Regal Shrine Maiden / Warlord Robes (Violet, Crimson & Gold)
      final robeSway = isDash ? -10.0 : sin(animProgress * 2 * pi) * 4.0;
      final robe = Path()
        ..moveTo(-30, -126)
        ..lineTo(30, -126)
        ..lineTo(46 + robeSway, -10)
        ..lineTo(-46 + robeSway, -10)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        robe,
        darkFoxViolet,
        highlightColor: foxViolet,
        outlineWidth: 4.2,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-26, -86, 52, 16),
        5,
        GenUtils.gold,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.4,
      );

      // 3. Ornate Nine-Tail Fox Mask & Tall Fox Ears
      final ears = Path()
        ..moveTo(-22, -166)
        ..lineTo(-34, -206)
        ..lineTo(-8, -172)
        ..lineTo(8, -172)
        ..lineTo(34, -206)
        ..lineTo(22, -166)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        ears,
        GenUtils.white,
        highlightColor: GenUtils.red,
        outlineWidth: 3.8,
      );

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-26, -172, 52, 46),
        16,
        GenUtils.white,
        topHighlight: Colors.white,
        outlineWidth: 4.0,
      );
      for (final ex in [-10.0, 10.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -150),
          5.0,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 2.2,
        );
      }

      // 4. Orbiting Foxfire Spirit Lantern Orbs & Cast Mandala
      if (isCast) {
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(0, -112),
          52,
          24,
          8,
          GenUtils.cyan.withValues(alpha: 0.55),
          rotation: -animProgress * 2 * pi,
          outlineWidth: 2.8,
        );
      }
      for (int f = 0; f < 4; f++) {
        final a = animProgress * 2 * pi + (f * pi / 2);
        final orbitR = isCast ? 76.0 : (isDash ? 54.0 : 64.0);
        final fx = cos(a) * orbitR;
        final fy = (isStun ? -78.0 : -112.0) + sin(a) * 28;
        GenUtils.drawCelCircle(
          canvas,
          Offset(fx, fy),
          isCast ? 12.0 : 8.5,
          f.isEven ? GenUtils.cyan : foxViolet,
          highlightColor: Colors.white,
          outlineWidth: 2.8,
        );
      }

      if (isDash && animProgress >= 0.20) {
        _drawSlashArc(
          canvas,
          center: const Offset(24, -92),
          radius: 70,
          startAngle: -1.1 + animProgress * 1.2,
          sweepAngle: 1.5,
          color: foxViolet,
        );
      }

      canvas.restore(); // end torso tilt

      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -206,
          starRadiusX: 42,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'inari_idle.png': [6, 0],
      'inari_dash.png': [4, 1],
      'inari_cast.png': [5, 2],
      'inari_stun.png': [4, 3],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 240,
        frameHeight: 220,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2 ? (i / (count - 1)) : (i / count);
          final phase = (i / count) * 2 * pi;
          drawInari(
            canvas,
            Offset(size.width * 0.46, size.height - 8),
            bob: mode == 0 ? sin(phase) * 5.0 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // ===========================================================================
  // BOSS 8: WADATSUMI (THE ABYSSAL LEVIATHAN LORD — LEVEL 8)
  // ===========================================================================
  static Future<void> _generateBoss8Wadatsumi() async {
    const base = 'assets/images/bosses';

    void drawWadatsumi(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=charge, 2=slam, 3=stun
    }) {
      final bool isCharge = mode == 1;
      final bool isSlam = mode == 2;
      final bool isStun = mode == 3;

      double bodyDx = 0.0;
      double bodyDy = bob;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isCharge) {
        bodyDx = sin(animProgress * pi) * 14.0;
        bodyDy = -3.0 + sin(animProgress * 2 * pi).abs() * 4.5;
        torsoTilt = 0.22;
      } else if (isSlam) {
        if (animProgress < 0.35) {
          final wt = animProgress / 0.35;
          bodyDx = -10.0 * wt;
          bodyDy = -12.0 * wt;
          torsoTilt = -0.18 * wt;
        } else {
          final st = ((animProgress - 0.35) / 0.65).clamp(0.0, 1.0);
          bodyDx = -10.0 + 26.0 * sin(st * pi * 0.7);
          bodyDy = 8.0 * sin(st * pi);
          torsoTilt = -0.18 + 0.42 * sin(st * pi * 0.75);
        }
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.5 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isCharge || (isSlam && animProgress >= 0.35)) {
        for (int l = 0; l < 4; l++) {
          final ly = -35.0 - l * 32.0;
          canvas.drawLine(
            Offset(-90 - (l % 2) * 16.0, ly),
            Offset(-38, ly),
            GenUtils.stroke(abyssTeal.withValues(alpha: 0.78), 3.4),
          );
        }
      }

      // 1. Massive Deep-Sea Armored Greaves (animated stride / lunge / kneel)
      for (final side in [-1.0, 1.0]) {
        double lx = side * 24.0;
        double ly = 0.0;
        double legRot = 0.0;
        if (isCharge) {
          final s = sin(animProgress * 2 * pi + (side < 0 ? 0 : pi));
          lx += s * 13.0;
          ly = s < 0 ? s * 6.0 : 0.0;
          legRot = -s * 0.25;
        } else if (isSlam && animProgress >= 0.35) {
          lx += side * 10.0;
          legRot = side * -0.18;
        } else if (isStun) {
          if (side < 0) {
            lx -= 4.0;
            ly = 2.0;
            legRot = 0.14;
          } else {
            lx += 4.0;
            legRot = -0.08;
          }
        }
        canvas.save();
        canvas.translate(lx, -52 + ly);
        canvas.rotate(legRot);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-15, 0, 30, 48),
          8,
          darkAbyss,
          topHighlight: abyssTeal,
          outlineWidth: 4.0,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 2. Swirling Abyssal Whirlpool & Kraken Tentacle Mantle
      for (int k = -2; k <= 2; k++) {
        if (k == 0) continue;
        canvas.save();
        canvas.translate(k * 18.0, -76);
        final whip = sin(animProgress * 2 * pi + k) * (isSlam ? 0.32 : 0.16);
        canvas.rotate(k * 0.25 + whip);
        final tentacle = Path()
          ..moveTo(-8, 0)
          ..quadraticBezierTo(k * 16.0, -45, k * 28.0, -75)
          ..lineTo(8, 0)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          tentacle,
          darkAbyss,
          highlightColor: abyssTeal,
          outlineWidth: 3.6,
        );
        canvas.restore();
      }

      // 3. Coral Cuirass
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-44, -132, 88, 84),
        16,
        darkAbyss,
        topHighlight: abyssTeal,
        outlineWidth: 4.4,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -92),
        16,
        coralRed,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.4,
      );

      // 4. Leviathan Dragon-Coral Horned Helmet
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-28, -174, 56, 46),
        14,
        darkAbyss,
        topHighlight: abyssTeal,
        outlineWidth: 4.2,
      );
      for (final side in [-1.0, 1.0]) {
        final horn = Path()
          ..moveTo(side * 18, -166)
          ..lineTo(side * 48, -198)
          ..lineTo(side * 28, -172)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          horn,
          coralRed,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.6,
        );
      }
      for (final ex in [-10.0, 10.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -152),
          5.0,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 2.2,
        );
      }

      // 5. Colossal Tidal Trident-Anchor Halberd (dynamic 150° smash arc!)
      double tridentAngle = -0.45 + sin(animProgress * 2 * pi) * 0.06;
      if (isCharge) {
        tridentAngle = -0.15 + sin(animProgress * 2 * pi) * 0.25;
      } else if (isSlam) {
        tridentAngle = -1.75 + animProgress * 2.60;
      } else if (isStun) {
        tridentAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
      }

      canvas.save();
      canvas.translate(38, -96);
      canvas.rotate(tridentAngle);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-8, -6, 86, 12),
        4,
        GenUtils.goldDark,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.6,
      );
      final prongs = Path()
        ..moveTo(74, -24)
        ..lineTo(106, -16)
        ..lineTo(84, -4)
        ..lineTo(114, 0)
        ..lineTo(84, 4)
        ..lineTo(106, 16)
        ..lineTo(74, 24)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        prongs,
        abyssTeal,
        highlightColor: Colors.white,
        outlineWidth: 3.8,
      );
      canvas.restore();

      if (isSlam && animProgress >= 0.30 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(28, -88),
          radius: 82,
          startAngle: -1.40 + (animProgress - 0.30) * 1.5,
          sweepAngle: 1.60,
          color: abyssTeal,
        );
      }

      canvas.restore(); // end torso tilt

      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -202,
          starRadiusX: 44,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'wadatsumi_idle.png': [6, 0],
      'wadatsumi_charge.png': [4, 1],
      'wadatsumi_slam.png': [6, 2],
      'wadatsumi_stun.png': [4, 3],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 240,
        frameHeight: 220,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2 ? (i / (count - 1)) : (i / count);
          final phase = (i / count) * 2 * pi;
          drawWadatsumi(
            canvas,
            Offset(size.width * 0.45, size.height - 8),
            bob: mode == 0 ? sin(phase) * 4.0 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // ===========================================================================
  // BOSS 9: RAIJIN-TEI (THE THUNDER EMPEROR — LEVEL 9)
  // ===========================================================================
  static Future<void> _generateBoss9RaijinTei() async {
    const base = 'assets/images/bosses';

    void drawRaijin(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=dash, 2=cast, 3=guard, 4=stun
    }) {
      final bool isDash = mode == 1;
      final bool isCast = mode == 2;
      final bool isGuard = mode == 3;
      final bool isStun = mode == 4;

      double bodyDx = 0.0;
      double bodyDy = bob;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isDash) {
        if (animProgress < 0.30) {
          final wt = animProgress / 0.30;
          bodyDx = -10.0 * wt;
          bodyDy = -6.0 * wt;
          torsoTilt = -0.18 * wt;
        } else {
          final st = ((animProgress - 0.30) / 0.70).clamp(0.0, 1.0);
          bodyDx = -10.0 + 26.0 * sin(st * pi * 0.65);
          bodyDy = 6.0 * sin(st * pi);
          torsoTilt = -0.18 + 0.42 * sin(st * pi * 0.75);
        }
      } else if (isCast) {
        bodyDy = -12.0 - sin(animProgress * pi) * 8.0;
      } else if (isGuard) {
        bodyDx = -3.0;
        bodyDy = 3.0;
        torsoTilt = -0.06;
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.5 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isDash && animProgress >= 0.25) {
        for (int l = 0; l < 4; l++) {
          final ly = -35.0 - l * 32.0;
          canvas.drawLine(
            Offset(-90 - (l % 2) * 16.0, ly),
            Offset(-38, ly),
            GenUtils.stroke(thunderGold.withValues(alpha: 0.82), 3.4),
          );
        }
      }

      // 1. Ring of 6 Floating Taiko Thunder-Drums behind Raijin-Tei
      for (int d = 0; d < 6; d++) {
        final a = animProgress * 2 * pi + (d * pi / 3);
        final drumR = isCast ? 78.0 : 68.0;
        final dx = cos(a) * drumR;
        final dy = (isStun ? -104.0 : -124.0) + sin(a) * 38;
        GenUtils.drawCelCircle(
          canvas,
          Offset(dx, dy),
          isCast ? 16 : 14,
          GenUtils.red,
          highlightColor: thunderGold,
          outlineWidth: 3.2,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset(dx, dy),
          7,
          GenUtils.white,
          outlineWidth: 2.0,
        );
      }

      // 2. Storm-Lord Samurai Greaves (animated stride / lunge / kneel)
      for (final side in [-1.0, 1.0]) {
        double lx = side * 20.0;
        double ly = 0.0;
        double legRot = 0.0;
        if (isDash && animProgress >= 0.30) {
          lx += side * 11.0;
          legRot = side * -0.18;
        } else if (isStun) {
          if (side < 0) {
            lx -= 4.0;
            ly = 2.0;
            legRot = 0.14;
          } else {
            lx += 4.0;
            legRot = -0.08;
          }
        }
        canvas.save();
        canvas.translate(lx, -52 + ly);
        canvas.rotate(legRot);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-13, 0, 26, 48),
          6,
          GenUtils.darkNavy,
          topHighlight: stormBlue,
          outlineWidth: 3.8,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 3. Storm-Lord Samurai Armor Cuirass
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-36, -130, 72, 80),
        14,
        GenUtils.darkNavy,
        topHighlight: stormBlue,
        outlineWidth: 4.2,
      );
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -92),
        22,
        10,
        6,
        thunderGold,
        rotation: animProgress * 2 * pi,
        outlineWidth: 3.0,
      );

      // 4. Lightning-Horned Kabuto Helmet
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-26, -172, 52, 44),
        13,
        GenUtils.ink,
        topHighlight: stormBlue,
        outlineWidth: 4.0,
      );
      final boltHorns = Path()
        ..moveTo(-14, -168)
        ..lineTo(-38, -208)
        ..lineTo(-8, -176)
        ..lineTo(8, -176)
        ..lineTo(38, -208)
        ..lineTo(14, -168)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        boltHorns,
        thunderGold,
        highlightColor: Colors.white,
        outlineWidth: 3.6,
      );
      for (final ex in [-9.0, 9.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -152),
          4.8,
          thunderGold,
          highlightColor: Colors.white,
          outlineWidth: 2.0,
        );
      }

      // 5. Twin Lightning Katanas (dynamic sweep across frames!)
      double slashRot = -0.40 + sin(animProgress * 2 * pi) * 0.06;
      if (isDash) {
        slashRot = -1.65 + animProgress * 2.55;
      } else if (isCast) {
        slashRot = -1.35 + sin(animProgress * 2 * pi) * 0.25;
      } else if (isGuard) {
        slashRot = -1.10;
      } else if (isStun) {
        slashRot = 1.05 + sin(animProgress * 2 * pi) * 0.14;
      }

      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(side * 34, -96);
        final rot = side > 0
            ? slashRot
            : (isStun ? (pi - slashRot) : (-slashRot - pi));
        canvas.rotate(rot);
        final blade = Path()
          ..moveTo(0, -6)
          ..lineTo(78, -4)
          ..lineTo(92, 0)
          ..lineTo(78, 6)
          ..lineTo(0, 6)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          blade,
          thunderGold,
          highlightColor: Colors.white,
          outlineWidth: 3.6,
        );
        canvas.restore();
      }

      if (isDash && animProgress >= 0.25 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(24, -86),
          radius: 78,
          startAngle: -1.35 + (animProgress - 0.25) * 1.5,
          sweepAngle: 1.55,
          color: thunderGold,
        );
      }

      if (isGuard) {
        final shield =
            Rect.fromCenter(center: const Offset(0, -96), width: 112, height: 140);
        canvas.drawOval(
          shield,
          GenUtils.fill(thunderGold.withValues(alpha: 0.28)),
        );
        canvas.drawOval(shield, GenUtils.stroke(GenUtils.cyan, 4.0));
      }

      canvas.restore(); // end torso tilt

      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -204,
          starRadiusX: 44,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'raijin_idle.png': [6, 0],
      'raijin_dash.png': [4, 1],
      'raijin_cast.png': [5, 2],
      'raijin_guard.png': [4, 3],
      'raijin_stun.png': [4, 4],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 240,
        frameHeight: 220,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2 ? (i / (count - 1)) : (i / count);
          final phase = (i / count) * 2 * pi;
          drawRaijin(
            canvas,
            Offset(size.width * 0.45, size.height - 8),
            bob: mode == 0 ? sin(phase) * 4.5 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // ===========================================================================
  // BOSS 10: AKUMA-SHIN (THE PRIMORDIAL INK GOD — TRUE FINAL BOSS LEVEL 10)
  // ===========================================================================
  static Future<void> _generateBoss10AkumaShin() async {
    const base = 'assets/images/bosses';

    void drawAkuma(
      Canvas canvas,
      Offset centerBottom, {
      double bob = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=slash, 2=cast, 3=guard, 4=stun
    }) {
      final bool isSlash = mode == 1;
      final bool isCast = mode == 2;
      final bool isGuard = mode == 3;
      final bool isStun = mode == 4;

      double bodyDx = 0.0;
      double bodyDy = bob;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isSlash) {
        if (animProgress < 0.30) {
          final wt = animProgress / 0.30;
          bodyDx = -10.0 * wt;
          bodyDy = -8.0 * wt;
          torsoTilt = -0.18 * wt;
        } else {
          final st = ((animProgress - 0.30) / 0.70).clamp(0.0, 1.0);
          bodyDx = -10.0 + 28.0 * sin(st * pi * 0.65);
          bodyDy = 7.0 * sin(st * pi);
          torsoTilt = -0.18 + 0.44 * sin(st * pi * 0.75);
        }
      } else if (isCast) {
        bodyDy = -12.0 - sin(animProgress * pi) * 10.0;
      } else if (isGuard) {
        bodyDx = -3.0;
        bodyDy = 3.0;
        torsoTilt = -0.06;
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.5 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isSlash && animProgress >= 0.25) {
        for (int l = 0; l < 4; l++) {
          final ly = -36.0 - l * 32.0;
          canvas.drawLine(
            Offset(-94 - (l % 2) * 16.0, ly),
            Offset(-40, ly),
            GenUtils.stroke(voidMagenta.withValues(alpha: 0.82), 3.6),
          );
        }
      }

      // 1. Supernova Astral Halo & Dual Rotating Cosmic Starbursts
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -120),
        92 + (isCast ? sin(animProgress * pi) * 12.0 : 0.0),
        58,
        14,
        cosmicGold.withValues(alpha: 0.90),
        rotation: animProgress * 2 * pi,
        outlineWidth: 3.6,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -120),
        52,
        GenUtils.ink,
        highlightColor: voidMagenta,
        outlineWidth: 4.2,
      );

      // 2. Primordial Void-God Greaves (animated lunge / kneel)
      for (final side in [-1.0, 1.0]) {
        double lx = side * 19.0;
        double ly = 0.0;
        double legRot = 0.0;
        if (isSlash && animProgress >= 0.30) {
          lx += side * 11.0;
          legRot = side * -0.18;
        } else if (isStun) {
          if (side < 0) {
            lx -= 4.0;
            ly = 2.0;
            legRot = 0.14;
          } else {
            lx += 4.0;
            legRot = -0.08;
          }
        }
        canvas.save();
        canvas.translate(lx, -52 + ly);
        canvas.rotate(legRot);
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-13, 0, 26, 48),
          6,
          GenUtils.ink,
          topHighlight: voidMagenta,
          outlineWidth: 3.8,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 3. Eight Primordial Void-and-Gold Seraph/Archfiend Wings (4 pairs)
      for (final side in [-1.0, 1.0]) {
        for (int w = 0; w < 4; w++) {
          canvas.save();
          canvas.translate(side * 24.0, -134.0 + w * 18.0);
          canvas.scale(side, 1.0);
          final flap = isCast
              ? sin(animProgress * 2 * pi + w) * 0.26
              : (isStun ? 0.32 : sin(animProgress * 2 * pi + w) * 0.10);
          canvas.rotate((w - 1.5) * 0.24 + flap);
          final wing = Path()
            ..moveTo(0, 0)
            ..lineTo(76 - w * 7.0, -38 + w * 9.0)
            ..lineTo(62 - w * 5.0, -4 + w * 7.0)
            ..lineTo(38, 12)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            wing,
            w.isEven ? GenUtils.ink : voidMagenta,
            highlightColor: cosmicGold,
            outlineWidth: 3.6,
          );
          canvas.restore();
        }
      }

      // 4. Primordial Void-God Armor & All-Seeing Astral Core
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-36, -132, 72, 82),
        14,
        GenUtils.ink,
        topHighlight: GenUtils.darkPurple,
        outlineWidth: 4.4,
      );
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -94),
        24,
        12,
        8,
        cosmicGold,
        rotation: -animProgress * 2 * pi,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -94),
        10,
        GenUtils.cyan,
        highlightColor: Colors.white,
        outlineWidth: 2.5,
      );

      // 5. Crowned Primordial Mask & Three Celestial Eyes
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-28, -174, 56, 46),
        14,
        GenUtils.ink,
        topHighlight: GenUtils.darkPurple,
        outlineWidth: 4.2,
      );
      final godCrown = Path()
        ..moveTo(-26, -168)
        ..lineTo(-48, -212)
        ..lineTo(-18, -178)
        ..lineTo(0, -216)
        ..lineTo(18, -178)
        ..lineTo(48, -212)
        ..lineTo(26, -168)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        godCrown,
        cosmicGold,
        highlightColor: Colors.white,
        outlineWidth: 3.8,
      );
      for (final ex in [-10.0, 0.0, 10.0]) {
        final ey = ex == 0.0 ? -162.0 : -152.0;
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, ey),
          4.2,
          ex == 0.0 ? GenUtils.cyan : voidMagenta,
          highlightColor: Colors.white,
          outlineWidth: 2.0,
        );
      }

      // 6. Dual Supernova Astral Odachi Blades (dynamic 150° sweep across frames!)
      double rAngle = -0.35 + sin(animProgress * 2 * pi) * 0.06;
      double lAngle = -2.65 - sin(animProgress * 2 * pi) * 0.06;
      if (isSlash) {
        rAngle = -1.70 + animProgress * 2.55;
        lAngle = -2.55 + animProgress * 1.95;
      } else if (isCast) {
        rAngle = -1.35 + sin(animProgress * 2 * pi) * 0.25;
        lAngle = -1.80 - sin(animProgress * 2 * pi) * 0.25;
      } else if (isGuard) {
        rAngle = -0.95;
        lAngle = -2.20;
      } else if (isStun) {
        rAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
        lAngle = 2.08 - sin(animProgress * 2 * pi) * 0.14;
      }

      for (final isRight in [false, true]) {
        canvas.save();
        canvas.translate(isRight ? 32 : -32, -96);
        canvas.rotate(isRight ? rAngle : lAngle);
        final odachi = Path()
          ..moveTo(12, -8)
          ..lineTo(98, -5)
          ..lineTo(116, 0)
          ..lineTo(98, 8)
          ..lineTo(12, 8)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          odachi,
          isRight ? voidMagenta : GenUtils.cyan,
          highlightColor: cosmicGold,
          outlineWidth: 3.8,
        );
        canvas.restore();
      }

      if (isSlash && animProgress >= 0.25 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(26, -86),
          radius: 82,
          startAngle: -1.35 + (animProgress - 0.25) * 1.5,
          sweepAngle: 1.60,
          color: GenUtils.cyan,
        );
      }

      if (isGuard) {
        final shield =
            Rect.fromCenter(center: const Offset(0, -96), width: 118, height: 146);
        canvas.drawOval(
          shield,
          GenUtils.fill(voidMagenta.withValues(alpha: 0.28)),
        );
        canvas.drawOval(shield, GenUtils.stroke(cosmicGold, 4.2));
      }

      canvas.restore(); // end torso tilt

      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -206,
          starRadiusX: 46,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'akuma_idle.png': [6, 0],
      'akuma_slash.png': [5, 1],
      'akuma_cast.png': [5, 2],
      'akuma_guard.png': [4, 3],
      'akuma_stun.png': [4, 4],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 240,
        frameHeight: 220,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2 ? (i / (count - 1)) : (i / count);
          final phase = (i / count) * 2 * pi;
          drawAkuma(
            canvas,
            Offset(size.width * 0.45, size.height - 8),
            bob: mode == 0 ? sin(phase) * 4.5 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }
}
