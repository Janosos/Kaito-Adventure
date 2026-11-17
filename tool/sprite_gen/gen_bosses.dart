import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenBosses {
  static Future<void> generateAll() async {
    await _generateKurokage();
    await _generateRyuKotei();
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
    double bodyCenterY = -88,
  }) {
    // Crackling cyan guard-break sparks on body
    for (int sp = 0; sp < 3; sp++) {
      final sa = animProgress * 2 * pi + sp * (2 * pi / 3);
      final sx = cos(sa) * 26.0;
      final sy = bodyCenterY + sin(sa * 2) * 20.0;
      final spark = Path()
        ..moveTo(sx - 8, sy - 6)
        ..lineTo(sx + 2, sy - 1)
        ..lineTo(sx - 3, sy + 4)
        ..lineTo(sx + 8, sy + 9);
      canvas.drawPath(spark, GenUtils.stroke(GenUtils.cyan, 2.8));
    }

    // Golden dizzy orbit ring + 4 orbiting cartoon stars
    final orbitRect =
        Rect.fromCenter(center: Offset(0, starY), width: starRadiusX * 2.1, height: 18);
    canvas.drawOval(
      orbitRect,
      GenUtils.stroke(GenUtils.yellow.withValues(alpha: 0.65), 2.4),
    );
    for (int s = 0; s < 4; s++) {
      final a = animProgress * 2 * pi + (s * pi / 2);
      final sx = cos(a) * starRadiusX;
      final sy = starY + sin(a) * 8;
      GenUtils.drawCartoonStar(
        canvas,
        Offset(sx, sy),
        s.isEven ? 10.5 : 8.0,
        4.8,
        5,
        s.isEven ? GenUtils.yellow : GenUtils.cyan,
        rotation: a,
      );
    }
  }

  // --- BOSS 1: KUROKAGE (THE SHADOW EXECUTIONER) ---
  static void _drawKurokagePose(
    Canvas canvas, {
    required Offset centerBottom,
    double bob = 0.0,
    double cloakBillow = 0.0,
    int mode = 0, // 0=idle, 1=charge, 2=cleave, 3=guard, 4=stun
    double animProgress = 0.0,
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
      bodyDx = sin(animProgress * pi) * 10.0;
      bodyDy = -4.0 + sin(animProgress * 2 * pi).abs() * 4.0;
      torsoTilt = 0.20;
    } else if (isCleave) {
      if (animProgress < 0.30) {
        final wt = animProgress / 0.30;
        bodyDx = -10.0 * wt;
        bodyDy = -5.0 * wt;
        torsoTilt = -0.18 * wt;
      } else {
        final st = ((animProgress - 0.30) / 0.70).clamp(0.0, 1.0);
        bodyDx = -10.0 + 26.0 * sin(st * pi * 0.65);
        bodyDy = 6.0 * sin(st * pi);
        torsoTilt = -0.18 + 0.42 * sin(st * pi * 0.75);
      }
    } else if (isGuard) {
      bodyDx = -3.0;
      bodyDy = 3.0;
      torsoTilt = -0.06;
    } else if (isStun) {
      bodyDx = sin(animProgress * 2 * pi) * 5.0;
      bodyDy = 2.0 + cos(animProgress * 4 * pi) * 1.5;
      torsoTilt = sin(animProgress * 2 * pi) * 0.11;
      scaleY = 1.0;
    }

    canvas.save();
    canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
    canvas.scale(1.0, scaleY);

    // Speedlines on charge/cleave
    if (isCharge || (isCleave && animProgress >= 0.25)) {
      for (int l = 0; l < 4; l++) {
        final ly = -30.0 - l * 28.0;
        canvas.drawLine(
          Offset(-78 - (l % 2) * 14.0, ly),
          Offset(-28, ly),
          GenUtils.stroke(GenUtils.purple.withValues(alpha: 0.75), 3.2),
        );
      }
    }

    // Shadow Aura Flames behind Kurokage
    final auraPaint = Paint()
      ..color = GenUtils.purple.withValues(alpha: (isCharge || isCleave) ? 0.48 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -75), width: 105, height: 135),
      auraPaint,
    );

    // 1. Armored Ronin Boots & Hakama Trousers (animated stride / lunge / kneel)
    for (final side in [-1, 1]) {
      double legDx = side * 14.0;
      double legDy = 0.0;
      double legRot = 0.0;
      if (isCharge) {
        final s = sin(animProgress * 2 * pi + (side < 0 ? 0 : pi));
        legDx += s * 12.0;
        legDy = s < 0 ? s * 6.0 : 0.0;
        legRot = -s * 0.28;
      } else if (isCleave && animProgress >= 0.30) {
        legDx += side * 10.0;
        legRot = side * -0.18;
      } else if (isStun) {
        if (side < 0) {
          legDx -= 3.0;
          legDy = 2.0;
          legRot = 0.14;
        } else {
          legDx += 3.0;
          legRot = -0.08;
        }
      }
      canvas.save();
      canvas.translate(legDx, -32 + legDy);
      canvas.rotate(legRot);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-9, 0, 18, 30),
        5,
        GenUtils.darkNavy,
        topHighlight: GenUtils.purple,
        outlineWidth: 3.5,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-9, 24, 22, 9),
        4,
        GenUtils.ink,
        outlineWidth: 3.0,
      );
      canvas.restore();
    }

    // Upper body pivot for torso tilt
    canvas.save();
    canvas.translate(0, -48);
    canvas.rotate(torsoTilt);
    canvas.translate(0, 48);

    // 2. Tattered Shadow Haori Cloak & Demon Armor
    final cloakPath = Path()
      ..moveTo(-26, -108)
      ..lineTo(26, -108)
      ..lineTo(38 + cloakBillow, -18)
      ..lineTo(22, -28)
      ..lineTo(8, -14)
      ..lineTo(-6, -26)
      ..lineTo(-22, -14)
      ..lineTo(-40 - cloakBillow, -20)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      cloakPath,
      GenUtils.ink,
      highlightColor: GenUtils.darkPurple,
      outlineWidth: 4.0,
    );

    // Crimson & Gold Samurai Chest Plate inside Haori
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-18, -98, 36, 44),
      6,
      GenUtils.darkRed,
      topHighlight: GenUtils.red,
      outlineWidth: 3.5,
    );
    for (double y = -88; y <= -64; y += 10) {
      canvas.drawLine(
        Offset(-15, y),
        Offset(15, y),
        GenUtils.stroke(GenUtils.gold, 2.8),
      );
    }

    // Golden Belt Sash & Skull Clasp
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-24, -56, 48, 10),
      4,
      GenUtils.purple,
      topHighlight: const Color(0xFFAB47BC),
      outlineWidth: 3.2,
    );
    GenUtils.drawCelCircle(
      canvas,
      const Offset(0, -51),
      7,
      GenUtils.gold,
      highlightColor: GenUtils.yellow,
      outlineWidth: 2.8,
    );

    // 3. Head in Shadow & Wide Woven Bamboo Kasa Hat
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-18, -132, 36, 28),
      10,
      GenUtils.ink,
      outlineWidth: 3.5,
    );

    // Glowing Crimson Demon Eyes
    for (final ex in [-4.0, 10.0]) {
      final eyePath = Path()
        ..moveTo(ex - 5, -118)
        ..lineTo(ex + 6, -115)
        ..lineTo(ex + 4, -110)
        ..lineTo(ex - 5, -113)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        eyePath,
        GenUtils.red,
        highlightColor: GenUtils.yellow,
        outlineWidth: 2.0,
      );
    }

    // Wide Cartoon Ronin Kasa Straw Hat
    final hatPath = Path()
      ..moveTo(-54, -122)
      ..quadraticBezierTo(0, -158, 54, -122)
      ..quadraticBezierTo(0, -130, -54, -122)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      hatPath,
      GenUtils.darkNavy,
      highlightColor: GenUtils.purple,
      outlineWidth: 4.0,
    );
    canvas.drawLine(
      const Offset(0, -142),
      const Offset(-32, -125),
      GenUtils.stroke(GenUtils.ink, 2.2),
    );
    canvas.drawLine(
      const Offset(0, -142),
      const Offset(32, -125),
      GenUtils.stroke(GenUtils.ink, 2.2),
    );
    GenUtils.drawCelCircle(
      canvas,
      const Offset(0, -143),
      5,
      GenUtils.red,
      outlineWidth: 2.5,
    );

    // 4. Giant Nodachi Katana & Arms based on state
    double swordAngle = 0.35 + sin(animProgress * 2 * pi) * 0.06;
    Offset armOrigin = const Offset(14, -84);
    if (isCharge) {
      swordAngle = -1.75 - sin(animProgress * pi) * 0.45;
      armOrigin = const Offset(-8, -96);
    } else if (isCleave) {
      swordAngle = -1.75 + animProgress * 2.75;
      armOrigin = const Offset(18, -82);
    } else if (isGuard) {
      swordAngle = -pi / 2 + sin(animProgress * 2 * pi) * 0.06;
      armOrigin = const Offset(28, -56);
    } else if (isStun) {
      swordAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
      armOrigin = const Offset(12, -68);
    }

    canvas.save();
    canvas.translate(armOrigin.dx, armOrigin.dy);
    canvas.rotate(swordAngle);

    // Armored Gauntlet Arm
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-6, -6, 20, 12),
      5,
      GenUtils.purple,
      outlineWidth: 3.0,
    );

    // Long Nodachi Hilt & Guard
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(8, -4.5, 22, 9),
      2,
      GenUtils.darkRed,
      outlineWidth: 2.8,
    );
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(28, -11, 6, 22),
      2,
      GenUtils.gold,
      outlineWidth: 2.8,
    );

    // Cursed Purple-Black & Silver Giant Nodachi Blade
    final bladePath = Path()
      ..moveTo(34, -6)
      ..lineTo(96, -3)
      ..lineTo(108, 1)
      ..lineTo(96, 6)
      ..lineTo(34, 6)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      bladePath,
      GenUtils.steel,
      highlightColor: Colors.white,
      outlineWidth: 3.5,
    );
    canvas.drawLine(
      const Offset(36, 1),
      const Offset(98, 1),
      GenUtils.stroke(GenUtils.purple, 3.5),
    );
    canvas.restore();

    // Cleave Slash Crescent Trail
    if (isCleave && animProgress >= 0.25 && animProgress <= 0.85) {
      _drawSlashArc(
        canvas,
        center: const Offset(18, -76),
        radius: 68,
        startAngle: -1.35 + (animProgress - 0.25) * 1.6,
        sweepAngle: 1.55,
        color: GenUtils.purple,
      );
    }

    // Guard Shield Barrier Effect
    if (isGuard) {
      final shieldPaint = Paint()
        ..color = GenUtils.cyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      final shieldBorder = GenUtils.stroke(GenUtils.cyan, 3.5);
      final shieldRect =
          Rect.fromCenter(center: const Offset(34, -75), width: 24, height: 112);
      canvas.drawOval(shieldRect, shieldPaint);
      canvas.drawOval(shieldRect, shieldBorder);
    }

    canvas.restore(); // end torso tilt

    // Stunned Cartoon Stars & Guard-Break Sparks
    if (isStun) {
      _drawStunSparksAndStars(
        canvas,
        animProgress: animProgress,
        starY: -154,
        starRadiusX: 34,
        bodyCenterY: -80,
      );
    }

    canvas.restore();
  }

  static Future<void> _generateKurokage() async {
    const base = 'assets/images/bosses';

    await GenUtils.saveSheet(
      relativePath: '$base/kurokage_idle.png',
      frameWidth: 200,
      frameHeight: 180,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        _drawKurokagePose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 10),
          bob: sin(phase) * 3.5,
          cloakBillow: sin(phase) * 6.0,
          mode: 0,
          animProgress: i / 6.0,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/kurokage_charge.png',
      frameWidth: 200,
      frameHeight: 180,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 3.0;
        _drawKurokagePose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 10),
          cloakBillow: 10.0 * sin(t * pi),
          mode: 1,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/kurokage_cleave.png',
      frameWidth: 200,
      frameHeight: 180,
      frameCount: 5,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawKurokagePose(
          canvas,
          centerBottom: Offset(size.width * 0.42, size.height - 10),
          cloakBillow: 12.0,
          mode: 2,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/kurokage_guard.png',
      frameWidth: 200,
      frameHeight: 180,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawKurokagePose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 10),
          cloakBillow: sin(t * 2 * pi) * 3.0,
          mode: 3,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/kurokage_stun.png',
      frameWidth: 200,
      frameHeight: 180,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawKurokagePose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 8),
          mode: 4,
          animProgress: t,
        );
      },
    );
  }

  // --- BOSS 2: RYU-KOTEI (THE DRAGON SHOGUN MECHA-SAMURAI) ---
  static void _drawRyuPose(
    Canvas canvas, {
    required Offset centerBottom,
    double bob = 0.0,
    int mode = 0, // 0=idle, 1=dash, 2=stomp, 3=cast, 4=stun
    double animProgress = 0.0,
  }) {
    final bool isDash = mode == 1;
    final bool isStomp = mode == 2;
    final bool isCast = mode == 3;
    final bool isStun = mode == 4;

    double bodyDx = 0.0;
    double bodyDy = bob;
    double torsoTilt = 0.0;
    double scaleY = 1.0;

    if (isDash) {
      bodyDx = sin(animProgress * pi) * 14.0;
      bodyDy = -3.0 + sin(animProgress * 2 * pi).abs() * 4.0;
      torsoTilt = 0.22;
    } else if (isStomp) {
      if (animProgress < 0.35) {
        final wt = animProgress / 0.35;
        bodyDx = -8.0 * wt;
        bodyDy = -16.0 * wt;
        torsoTilt = -0.16 * wt;
      } else {
        final st = ((animProgress - 0.35) / 0.65).clamp(0.0, 1.0);
        bodyDx = -8.0 + 22.0 * sin(st * pi * 0.7);
        bodyDy = -16.0 * (1.0 - st) + 8.0 * sin(st * pi);
        torsoTilt = -0.16 + 0.38 * sin(st * pi * 0.75);
      }
    } else if (isCast) {
      bodyDy = -8.0 - sin(animProgress * pi) * 8.0;
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

    // Speedlines on dash/stomp
    if (isDash || (isStomp && animProgress >= 0.35)) {
      for (int l = 0; l < 4; l++) {
        final ly = -35.0 - l * 32.0;
        canvas.drawLine(
          Offset(-90 - (l % 2) * 16.0, ly),
          Offset(-38, ly),
          GenUtils.stroke(GenUtils.orange.withValues(alpha: 0.75), 3.4),
        );
      }
    }

    // Fiery Dragon Aura
    final auraPaint = Paint()
      ..color = GenUtils.orange.withValues(alpha: (isDash || isStomp || isCast) ? 0.45 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -92), width: 135, height: 165),
      auraPaint,
    );

    // 1. Heavy Armored Mech Greaves / Legs (animated stride / stomp lift / kneel)
    for (final side in [-1, 1]) {
      double lx = side * 20.0;
      double ly = 0.0;
      double legRot = 0.0;
      if (isDash) {
        final s = sin(animProgress * 2 * pi + (side < 0 ? 0 : pi));
        lx += s * 13.0;
        ly = s < 0 ? s * 6.0 : 0.0;
        legRot = -s * 0.26;
      } else if (isStomp) {
        if (side > 0 && animProgress < 0.45) {
          // Raise front leg high for seismic stomp!
          ly = -18.0 * sin((animProgress / 0.45) * pi);
          legRot = -0.22;
        } else if (animProgress >= 0.45) {
          lx += side * 9.0;
          legRot = side * -0.15;
        }
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
      canvas.translate(lx, -48 + ly);
      canvas.rotate(legRot);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-14, 0, 28, 44),
        7,
        GenUtils.darkNavy,
        topHighlight: GenUtils.red,
        outlineWidth: 4.0,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, 14),
        8,
        GenUtils.gold,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-15, 36, 32, 12),
        4,
        GenUtils.gold,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.5,
      );
      canvas.restore();
    }

    // Upper body pivot
    canvas.save();
    canvas.translate(0, -56);
    canvas.rotate(torsoTilt);
    canvas.translate(0, 56);

    // 2. Hulking Shogun Cuirass Torso
    const torsoRect = Rect.fromLTWH(-38, -124, 76, 78);
    GenUtils.drawCelRRect(
      canvas,
      torsoRect,
      12,
      GenUtils.darkRed,
      topHighlight: GenUtils.red,
      outlineWidth: 4.2,
    );

    // Gold Samurai Tasset Skirt Plates (Kusazuri)
    for (int k = -1; k <= 1; k++) {
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(k * 22.0 - 10, -56, 20, 18),
        3,
        GenUtils.gold,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.0,
      );
    }

    // Glowing Molten Dragon Core in Chestplate
    GenUtils.drawCelCircle(
      canvas,
      const Offset(0, -88),
      18,
      GenUtils.gold,
      outlineWidth: 3.5,
    );
    GenUtils.drawCelCircle(
      canvas,
      const Offset(0, -88),
      12 + (isCast ? sin(animProgress * 2 * pi) * 2.5 : 0.0),
      isCast ? GenUtils.cyan : GenUtils.yellow,
      highlightColor: Colors.white,
      outlineWidth: 2.5,
    );

    // 3. Giant Golden Dragon-Wing Shoulder Pauldrons (Sode)
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1.0);
      final pauldron = Path()
        ..moveTo(26, -122)
        ..lineTo(64, -142)
        ..lineTo(56, -108)
        ..lineTo(62, -96)
        ..lineTo(30, -90)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        pauldron,
        GenUtils.goldDark,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.8,
      );
      canvas.restore();
    }

    // 4. Shogun Kabuto Helmet & Golden Dragon Crest Horns
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-24, -162, 48, 40),
      14,
      GenUtils.ink,
      topHighlight: GenUtils.darkRed,
      outlineWidth: 4.0,
    );

    // Fierce Glowing Visor Eyes
    for (final ex in [-9.0, 9.0]) {
      final visorEye = Path()
        ..moveTo(ex - 6, -144)
        ..lineTo(ex + 6, -141)
        ..lineTo(ex + 5, -135)
        ..lineTo(ex - 5, -138)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        visorEye,
        GenUtils.cyan,
        highlightColor: Colors.white,
        outlineWidth: 2.0,
      );
    }

    // Grand Golden Dragon V-Crest (Kuwagata)
    final crest = Path()
      ..moveTo(0, -154)
      ..lineTo(-38, -188)
      ..lineTo(-24, -156)
      ..lineTo(0, -166)
      ..lineTo(24, -156)
      ..lineTo(38, -188)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      crest,
      GenUtils.gold,
      highlightColor: Colors.white,
      outlineWidth: 3.5,
    );

    // 5. Blazing Dragon Greatsword (animated sweep across frames!)
    double bladeAngle = -0.5 + sin(animProgress * 2 * pi) * 0.06;
    if (isDash) {
      bladeAngle = -0.15 + sin(animProgress * 2 * pi) * 0.25;
    } else if (isStomp) {
      // Full overhead windup (-1.65) -> crushing downward smash (+0.92)!
      bladeAngle = -1.65 + animProgress * 2.57;
    } else if (isCast) {
      bladeAngle = -1.45 + sin(animProgress * 2 * pi) * 0.28;
    } else if (isStun) {
      bladeAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
    }

    canvas.save();
    canvas.translate(32, -88);
    canvas.rotate(bladeAngle);

    // Heavy Mech Gauntlet
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-8, -8, 22, 16),
      5,
      GenUtils.red,
      topHighlight: GenUtils.gold,
      outlineWidth: 3.5,
    );

    // Blazing Dragon Greatsword Blade
    final greatBlade = Path()
      ..moveTo(14, -10)
      ..lineTo(82, -7)
      ..lineTo(96, 0)
      ..lineTo(82, 7)
      ..lineTo(14, 10)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      greatBlade,
      GenUtils.orange,
      highlightColor: GenUtils.yellow,
      outlineWidth: 3.8,
    );
    canvas.drawLine(
      const Offset(18, 0),
      const Offset(84, 0),
      GenUtils.stroke(Colors.white, 3.5),
    );
    canvas.restore();

    // Stomp Slash Crescent & Ground Impact Spikes
    if (isStomp && animProgress >= 0.30 && animProgress <= 0.88) {
      _drawSlashArc(
        canvas,
        center: const Offset(24, -84),
        radius: 78,
        startAngle: -1.35 + (animProgress - 0.30) * 1.5,
        sweepAngle: 1.55,
        color: GenUtils.orange,
      );
      if (animProgress >= 0.50) {
        for (int sp = 0; sp < 3; sp++) {
          final sx = 42.0 + sp * 16.0;
          final spike = Path()
            ..moveTo(sx - 8, 0)
            ..lineTo(sx, -24 - (2 - sp) * 6.0)
            ..lineTo(sx + 8, 0)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            spike,
            GenUtils.orange,
            highlightColor: GenUtils.yellow,
            outlineWidth: 2.8,
          );
        }
      }
    }

    canvas.restore(); // end torso tilt

    // Stunned Stars & Guard-Break Sparks
    if (isStun) {
      _drawStunSparksAndStars(
        canvas,
        animProgress: animProgress,
        starY: -188,
        starRadiusX: 42,
        bodyCenterY: -94,
      );
    }

    canvas.restore();
  }

  static Future<void> _generateRyuKotei() async {
    const base = 'assets/images/bosses';

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_idle.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 10),
          bob: sin(phase) * 3.5,
          mode: 0,
          animProgress: i / 6.0,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_dash.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 3.0;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.42, size.height - 12),
          mode: 1,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_stomp.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final t = i / 5.0;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 12),
          mode: 2,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_cast.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 5,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 10),
          mode: 3,
          animProgress: t,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_stun.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.45, size.height - 8),
          mode: 4,
          animProgress: t,
        );
      },
    );
  }
}
