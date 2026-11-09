import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenBosses {
  static Future<void> generateAll() async {
    await _generateKurokage();
    await _generateRyuKotei();
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
    canvas.save();
    canvas.translate(centerBottom.dx, centerBottom.dy + bob);

    // Shadow Aura Flames behind Kurokage
    final auraPaint = Paint()
      ..color = GenUtils.purple.withValues(alpha: mode == 1 ? 0.45 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -75), width: 105, height: 135),
      auraPaint,
    );

    // 1. Armored Ronin Boots & Hakama Trousers
    for (final side in [-1, 1]) {
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(side * 14.0 - 9, -32, 18, 30),
        5,
        GenUtils.darkNavy,
        topHighlight: GenUtils.purple,
        outlineWidth: 3.5,
      );
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(side * 14.0 - 9, -8, 22, 9),
        4,
        GenUtils.ink,
        outlineWidth: 3.0,
      );
    }

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
    // Horizontal samurai armor ribs
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

    // Glowing Crimson Demon Eyes with trailing eye-scar glow
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
    // Bamboo weave lines on Kasa hat
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
    // Red ornamental cord & tassels on hat
    GenUtils.drawCelCircle(
      canvas,
      const Offset(0, -143),
      5,
      GenUtils.red,
      outlineWidth: 2.5,
    );

    // 4. Giant Nodachi Katana & Arms based on state
    double swordAngle = 0.35;
    Offset armOrigin = const Offset(14, -84);
    if (mode == 1) {
      // Charging overhead
      swordAngle = -1.8 - animProgress * 0.4;
      armOrigin = const Offset(-8, -96);
    } else if (mode == 2) {
      // Cleaving forward
      swordAngle = -1.6 + animProgress * 2.6;
      armOrigin = const Offset(18, -82);
    } else if (mode == 3) {
      // Guard stance vertical in front
      swordAngle = -pi / 2;
      armOrigin = const Offset(28, -56);
    } else if (mode == 4) {
      // Stunned dropped blade
      swordAngle = 0.7;
      armOrigin = const Offset(12, -70);
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

    // Guard Shield Barrier Effect
    if (mode == 3) {
      final shieldPaint = Paint()
        ..color = GenUtils.cyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      final shieldBorder = GenUtils.stroke(GenUtils.cyan, 3.5);
      final shieldRect = Rect.fromCenter(center: const Offset(34, -75), width: 22, height: 110);
      canvas.drawOval(shieldRect, shieldPaint);
      canvas.drawOval(shieldRect, shieldBorder);
    }

    // Stunned Cartoon Stars circling Kasa Hat
    if (mode == 4) {
      for (int s = 0; s < 3; s++) {
        final a = animProgress * 2 * pi + (s * 2 * pi / 3);
        final sx = cos(a) * 34;
        final sy = -152 + sin(a) * 8;
        GenUtils.drawCartoonStar(
          canvas,
          Offset(sx, sy),
          9,
          4.5,
          5,
          GenUtils.yellow,
          rotation: a,
        );
      }
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
          bob: sin(phase) * 3.0,
          cloakBillow: sin(phase) * 5.0,
          mode: 0,
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
          cloakBillow: 8.0 * sin(t * pi),
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
          cloakBillow: 10.0,
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
          centerBottom: Offset(size.width * 0.45, size.height - 6),
          bob: 6.0,
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
    canvas.save();
    canvas.translate(centerBottom.dx, centerBottom.dy + bob);

    // Fiery Dragon Aura
    final auraPaint = Paint()
      ..color = GenUtils.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -92), width: 135, height: 165),
      auraPaint,
    );

    // 1. Heavy Armored Mech Greaves / Legs
    for (final side in [-1, 1]) {
      final lx = side * 20.0;
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(lx - 14, -48, 28, 44),
        7,
        GenUtils.darkNavy,
        topHighlight: GenUtils.red,
        outlineWidth: 4.0,
      );
      // Gold knee dragon guard
      GenUtils.drawCelCircle(
        canvas,
        Offset(lx, -34),
        8,
        GenUtils.gold,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.0,
      );
      // Heavy iron clawed foot
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(lx - 15, -12, 32, 12),
        4,
        GenUtils.gold,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.5,
      );
    }

    // 2. Hulking Shogun Cuirass Torso
    final torsoRect = const Rect.fromLTWH(-38, -124, 76, 78);
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
      12,
      mode == 3 ? GenUtils.cyan : GenUtils.yellow,
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

    // 5. Twin Blazing Dragon Greatswords
    double bladeAngle = -0.5;
    if (mode == 1) {
      // Dash forward lance
      bladeAngle = 0.15;
    } else if (mode == 2) {
      // Stomp slam downward
      bladeAngle = 0.85;
    } else if (mode == 3) {
      // Cast raised high
      bladeAngle = -1.35 + sin(animProgress * 2 * pi) * 0.2;
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
    // Inner white-hot core line
    canvas.drawLine(
      const Offset(18, 0),
      const Offset(84, 0),
      GenUtils.stroke(Colors.white, 3.5),
    );
    canvas.restore();

    // Stunned Stars & Steam
    if (mode == 4) {
      for (int s = 0; s < 3; s++) {
        final a = animProgress * 2 * pi + (s * 2 * pi / 3);
        GenUtils.drawCartoonStar(
          canvas,
          Offset(cos(a) * 42, -188 + sin(a) * 10),
          10,
          5,
          5,
          GenUtils.yellow,
          rotation: a,
        );
      }
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
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/ryu_dash.png',
      frameWidth: 240,
      frameHeight: 220,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawRyuPose(
          canvas,
          centerBottom: Offset(size.width * 0.42, size.height - 12),
          bob: sin(t * 2 * pi) * 2.0,
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
          bob: -sin(t * pi) * 14.0,
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
          centerBottom: Offset(size.width * 0.45, size.height - 6),
          bob: 6.0,
          mode: 4,
          animProgress: t,
        );
      },
    );
  }
}

