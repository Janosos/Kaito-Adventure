import 'dart:math';
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenCharacters {
  static Future<void> generateAll() async {
    await _generateKaito();
    await _generateEnemyGrunt();
    await _generateEnemyDrone();
  }

  static void _drawKaitoPose(
    Canvas canvas, {
    required Offset centerBottom,
    double bodyBob = 0.0,
    double torsoLean = 0.0,
    double leftLegAngle = 0.0,
    double rightLegAngle = 0.0,
    double leftKneeOffset = 0.0,
    double rightKneeOffset = 0.0,
    double scarfWavePhase = 0.0,
    double scarfLift = 0.0,
    bool blink = false,
    bool angryEyes = false,
    bool shockedEyes = false,
    int swordMode = 0, // 0=sheathed, 1=slash1, 2=slash2, 3=slash3, 4=dash
    double swordProgress = 0.0,
    Color? auraColor,
  }) {
    canvas.save();
    canvas.translate(centerBottom.dx, centerBottom.dy + bodyBob);
    canvas.scale(0.84, 0.84);

    // Optional dash/combo cartoon aura glow behind character
    if (auraColor != null) {
      final auraPaint = Paint()
        ..color = auraColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -52), width: 76, height: 96),
        auraPaint,
      );
    }

    // 1. Flowing 2D Cartoon Red Scarf Tail (behind body)
    final scarfPath = Path()..moveTo(-6, -70);
    for (int i = 1; i <= 4; i++) {
      final t = i / 4.0;
      final sx = -8.0 - i * 13.0;
      final sy = -68.0 +
          scarfLift * t +
          sin(scarfWavePhase + i * 1.1) * (6.0 + i * 2.0);
      scarfPath.lineTo(sx, sy);
    }
    for (int i = 4; i >= 1; i--) {
      final t = i / 4.0;
      final sx = -6.0 - i * 13.0;
      final sy = -54.0 +
          scarfLift * t +
          sin(scarfWavePhase + i * 1.1 + 0.4) * (6.0 + i * 2.0);
      scarfPath.lineTo(sx, sy);
    }
    scarfPath.close();
    GenUtils.drawCelPath(
      canvas,
      scarfPath,
      GenUtils.darkRed,
      highlightColor: GenUtils.red,
      outlineWidth: 3.5,
    );

    // 2. Back Katana Scabbard (when sheathed or secondary)
    canvas.save();
    canvas.translate(-6, -62);
    canvas.rotate(-0.65 + torsoLean * 0.5);
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-4, -26, 8, 56),
      3,
      GenUtils.darkNavy,
      topHighlight: GenUtils.steelDark,
      outlineWidth: 3.0,
    );
    if (swordMode == 0) {
      // Gold tsuba guard & wrapped hilt peeking above shoulder
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-7, -30, 14, 5),
        2,
        GenUtils.gold,
        outlineWidth: 2.5,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-3.5, -46, 7, 16),
        2,
        GenUtils.red,
        topHighlight: GenUtils.white,
        outlineWidth: 2.5,
      );
    }
    canvas.restore();

    // 3. Back Leg (Left Leg)
    _drawKaitoLeg(
      canvas,
      hip: const Offset(-7, -34),
      angle: leftLegAngle,
      kneeBend: leftKneeOffset,
      isBack: true,
    );

    // 4. Front Leg (Right Leg)
    _drawKaitoLeg(
      canvas,
      hip: const Offset(7, -34),
      angle: rightLegAngle,
      kneeBend: rightKneeOffset,
      isBack: false,
    );

    // 5. Torso & Cartoon Shinobi Vest
    canvas.save();
    canvas.translate(0, -34);
    canvas.rotate(torsoLean);

    // Navy Shinobi Gi Tunic
    final torsoRect = const Rect.fromLTWH(-16, -38, 32, 36);
    GenUtils.drawCelRRect(
      canvas,
      torsoRect,
      8,
      GenUtils.darkNavy,
      topHighlight: GenUtils.navy,
      outlineWidth: 3.5,
    );

    // V-neck lapel & red undershirt trim
    final lapelPath = Path()
      ..moveTo(-10, -36)
      ..lineTo(0, -18)
      ..lineTo(10, -36)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      lapelPath,
      GenUtils.red,
      outlineWidth: 2.5,
    );

    // White & Gold Cartoon Shinobi Belt Sash
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-17, -12, 34, 9),
      3,
      GenUtils.white,
      topHighlight: Colors.white,
      outlineWidth: 3.0,
    );
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-5, -13, 10, 11),
      2,
      GenUtils.gold,
      topHighlight: GenUtils.yellow,
      outlineWidth: 2.5,
    );

    // Scarf Collar around neck
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-18, -42, 36, 11),
      5,
      GenUtils.red,
      topHighlight: const Color(0xFFFF6B7A),
      outlineWidth: 3.5,
    );

    // 6. Big Expressive Cartoon Head (Chibi/Heroic 2D Cartoon proportion)
    canvas.save();
    canvas.translate(0, -42);

    // Head base (Navy Cowl)
    final headRect = const Rect.fromLTWH(-22, -40, 44, 38);
    GenUtils.drawCelRRect(
      canvas,
      headRect,
      14,
      GenUtils.darkNavy,
      topHighlight: GenUtils.navy,
      outlineWidth: 3.8,
    );

    // Spiky Anime/Cartoon Hair bangs peeking over headband
    final hairPath = Path()
      ..moveTo(-16, -38)
      ..lineTo(-22, -48)
      ..lineTo(-8, -41)
      ..lineTo(0, -52)
      ..lineTo(8, -41)
      ..lineTo(20, -49)
      ..lineTo(16, -37)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      hairPath,
      GenUtils.ink,
      highlightColor: GenUtils.navy,
      outlineWidth: 3.0,
    );

    // Face Mask Opening (Warm Peach Skin)
    final faceMaskRect = const Rect.fromLTWH(-14, -27, 32, 16);
    GenUtils.drawCelRRect(
      canvas,
      faceMaskRect,
      6,
      GenUtils.skin,
      topHighlight: const Color(0xFFFFF0DB),
      outlineWidth: 3.0,
    );

    // Expressive Cartoon Eyes
    if (blink) {
      // Happy/focused curved closed eyes
      canvas.drawLine(
        const Offset(-6, -19),
        const Offset(1, -19),
        GenUtils.stroke(GenUtils.ink, 3.0),
      );
      canvas.drawLine(
        const Offset(6, -19),
        const Offset(14, -19),
        GenUtils.stroke(GenUtils.ink, 3.0),
      );
    } else if (shockedEyes) {
      // Wide white cartoon shocked eyes
      GenUtils.drawCelCircle(
        canvas,
        const Offset(-2, -19),
        5.5,
        Colors.white,
        outlineWidth: 2.5,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(10, -19),
        5.5,
        Colors.white,
        outlineWidth: 2.5,
      );
      canvas.drawCircle(const Offset(-2, -19), 2.0, GenUtils.fill(GenUtils.ink));
      canvas.drawCircle(const Offset(10, -19), 2.0, GenUtils.fill(GenUtils.ink));
    } else {
      // Crisp 2D Cartoon Eyes with Cyan Iris & White Specular Catchlight
      for (final ex in [-3.0, 9.0]) {
        final eyeRect = Rect.fromCenter(center: Offset(ex, -19), width: 8, height: 10);
        canvas.drawOval(eyeRect, GenUtils.fill(Colors.white));
        canvas.drawOval(eyeRect, GenUtils.stroke(GenUtils.ink, 2.2));
        // Cyan iris
        canvas.drawCircle(Offset(ex + 1.0, -19), 3.2, GenUtils.fill(GenUtils.cyan));
        // Pupil
        canvas.drawCircle(Offset(ex + 1.2, -19), 1.8, GenUtils.fill(GenUtils.ink));
        // Glossy white highlight dot
        canvas.drawCircle(Offset(ex - 0.5, -21), 1.4, GenUtils.fill(Colors.white));
      }
      if (angryEyes) {
        // Determined slanted eyebrows
        canvas.drawLine(
          const Offset(-8, -25),
          const Offset(2, -22),
          GenUtils.stroke(GenUtils.ink, 3.0),
        );
        canvas.drawLine(
          const Offset(15, -25),
          const Offset(5, -22),
          GenUtils.stroke(GenUtils.ink, 3.0),
        );
      }
    }

    // Red Headband & Metallic Forehead Protector Plate
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-23, -36, 46, 9),
      3,
      GenUtils.red,
      topHighlight: const Color(0xFFFF6B7A),
      outlineWidth: 3.0,
    );
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-8, -35, 22, 7),
      2,
      GenUtils.steel,
      topHighlight: Colors.white,
      outlineWidth: 2.5,
    );

    canvas.restore(); // End head

    // 7. Front Arm & Drawn Katana Blade (when attacking or dashing)
    if (swordMode == 0) {
      // Normal arm with gauntlet
      canvas.save();
      canvas.translate(4, -28);
      canvas.rotate(-rightLegAngle * 0.7);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-5, 0, 10, 20),
        4,
        GenUtils.navy,
        outlineWidth: 3.0,
      );
      // Red armored gauntlet + hand
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-5, 10, 10, 9),
        3,
        GenUtils.red,
        outlineWidth: 2.5,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, 21),
        4.5,
        GenUtils.skin,
        outlineWidth: 2.5,
      );
      canvas.restore();
    } else {
      // Drawn Glowing Katana & Swing Smear!
      double bladeAngle = 0.0;
      Color bladeGlow = GenUtils.yellow;
      if (swordMode == 1) {
        bladeAngle = -1.2 + swordProgress * 2.4;
        bladeGlow = GenUtils.yellow;
      } else if (swordMode == 2) {
        bladeAngle = 1.1 - swordProgress * 2.5;
        bladeGlow = GenUtils.cyan;
      } else if (swordMode == 3) {
        bladeAngle = -2.0 + swordProgress * 4.2;
        bladeGlow = GenUtils.red;
      } else if (swordMode == 4) {
        bladeAngle = 0.15;
        bladeGlow = GenUtils.cyan;
      }

      canvas.save();
      canvas.translate(8, -26);
      canvas.rotate(bladeAngle);

      // Arm holding sword
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-4, -5, 16, 10),
        4,
        GenUtils.navy,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(12, 0),
        5.0,
        GenUtils.skin,
        outlineWidth: 2.5,
      );

      // Katana Hilt & Guard
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(4, -4, 14, 8),
        2,
        GenUtils.red,
        outlineWidth: 2.5,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(16, -9, 5, 18),
        2,
        GenUtils.gold,
        outlineWidth: 2.5,
      );

      // Gleaming Cartoon Katana Blade
      final bladePath = Path()
        ..moveTo(21, -5)
        ..lineTo(66, -2)
        ..lineTo(74, 0)
        ..lineTo(66, 4)
        ..lineTo(21, 5)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        bladePath,
        GenUtils.steel,
        highlightColor: Colors.white,
        outlineWidth: 3.0,
      );
      // Colored energy edge along blade
      canvas.drawLine(
        const Offset(23, -2),
        const Offset(70, 0),
        GenUtils.stroke(bladeGlow, 3.0),
      );

      canvas.restore();
    }

    canvas.restore(); // End torso
    canvas.restore(); // End root
  }

  static void _drawKaitoLeg(
    Canvas canvas, {
    required Offset hip,
    required double angle,
    required double kneeBend,
    required bool isBack,
  }) {
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(angle);

    final legColor = isBack ? GenUtils.darkNavy : GenUtils.navy;
    // Upper & lower leg with white shin wraps
    GenUtils.drawCelRRect(
      canvas,
      Rect.fromLTWH(-6, 0, 12, 22 + kneeBend),
      5,
      legColor,
      outlineWidth: 3.2,
    );
    // White shinobi leg bandages
    GenUtils.drawCelRRect(
      canvas,
      Rect.fromLTWH(-5.5, 14 + kneeBend, 11, 12),
      3,
      GenUtils.white,
      outlineWidth: 2.8,
    );
    // Cartoon ninja boot/sandal
    GenUtils.drawCelRRect(
      canvas,
      Rect.fromLTWH(-6, 24 + kneeBend, 16, 8),
      4,
      GenUtils.red,
      topHighlight: const Color(0xFFFF6B7A),
      outlineWidth: 3.0,
    );

    canvas.restore();
  }

  static Future<void> _generateKaito() async {
    const base = 'assets/images/characters';

    // 1. IDLE (6 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_idle.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        final bob = sin(phase) * 2.5;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.52, size.height - 10),
          bodyBob: bob,
          scarfWavePhase: phase,
          blink: i == 4,
        );
      },
    );

    // 2. RUN (8 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_run.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 8,
      drawFrame: (canvas, i, size) {
        final phase = (i / 8.0) * 2 * pi;
        final legSwing = sin(phase) * 0.65;
        final bob = -abs(cos(phase)) * 5.0;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.52, size.height - 10),
          bodyBob: bob,
          torsoLean: 0.22,
          leftLegAngle: legSwing,
          rightLegAngle: -legSwing,
          scarfWavePhase: phase * 2,
          scarfLift: 4.0,
          angryEyes: true,
        );
      },
    );

    // 3. JUMP (4 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_jump.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.52, size.height - 14),
          torsoLean: 0.1,
          leftLegAngle: -0.45,
          rightLegAngle: 0.35,
          leftKneeOffset: -4,
          rightKneeOffset: -6,
          scarfWavePhase: phase,
          scarfLift: 18.0,
          angryEyes: true,
        );
      },
    );

    // 4. FALL (4 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_fall.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.52, size.height - 12),
          torsoLean: -0.1,
          leftLegAngle: 0.25,
          rightLegAngle: -0.2,
          scarfWavePhase: phase,
          scarfLift: -22.0,
        );
      },
    );

    // 5. DASH (4 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_dash.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.5, size.height - 14),
          torsoLean: 0.42,
          leftLegAngle: 0.6,
          rightLegAngle: -0.5,
          scarfWavePhase: phase * 2,
          scarfLift: 2.0,
          angryEyes: true,
          swordMode: 4,
          auraColor: GenUtils.cyan,
        );
      },
    );

    // 6. ATTACK 1 (5 frames, 144x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_attack1.png',
      frameWidth: 144,
      frameHeight: 128,
      frameCount: 5,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.44, size.height - 10),
          torsoLean: 0.18,
          leftLegAngle: 0.3,
          rightLegAngle: -0.35,
          scarfWavePhase: t * pi * 2,
          angryEyes: true,
          swordMode: 1,
          swordProgress: t,
          auraColor: GenUtils.yellow,
        );
      },
    );

    // 7. ATTACK 2 (5 frames, 144x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_attack2.png',
      frameWidth: 144,
      frameHeight: 128,
      frameCount: 5,
      drawFrame: (canvas, i, size) {
        final t = i / 4.0;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.44, size.height - 10),
          torsoLean: -0.1 + t * 0.25,
          leftLegAngle: -0.25,
          rightLegAngle: 0.3,
          scarfWavePhase: t * pi * 2,
          angryEyes: true,
          swordMode: 2,
          swordProgress: t,
          auraColor: GenUtils.cyan,
        );
      },
    );

    // 8. ATTACK 3 (6 frames, 144x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_attack3.png',
      frameWidth: 144,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final t = i / 5.0;
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.44, size.height - 12),
          bodyBob: -sin(t * pi) * 10,
          torsoLean: 0.3,
          leftLegAngle: 0.4,
          rightLegAngle: -0.45,
          scarfWavePhase: t * pi * 3,
          angryEyes: true,
          swordMode: 3,
          swordProgress: t,
          auraColor: GenUtils.red,
        );
      },
    );

    // 9. HURT (3 frames, 128x128)
    await GenUtils.saveSheet(
      relativePath: '$base/kaito_hurt.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 3,
      drawFrame: (canvas, i, size) {
        _drawKaitoPose(
          canvas,
          centerBottom: Offset(size.width * 0.52, size.height - 10),
          torsoLean: -0.28,
          leftLegAngle: -0.2,
          rightLegAngle: 0.3,
          scarfWavePhase: i.toDouble(),
          shockedEyes: true,
          auraColor: GenUtils.red,
        );
      },
    );
  }

  static double abs(double v) => v < 0 ? -v : v;

  // --- ENEMY GRUNT (Shadow Clan Cartoon Ninja) ---
  static void _drawGruntPose(
    Canvas canvas, {
    required Offset centerBottom,
    double legSwing = 0.0,
    double bob = 0.0,
    bool isAggro = false,
    double swordAngle = -0.3,
  }) {
    canvas.save();
    canvas.translate(centerBottom.dx, centerBottom.dy + bob);

    // Legs
    for (final side in [-1, 1]) {
      canvas.save();
      canvas.translate(side * 7.0, -28);
      canvas.rotate(side * legSwing);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-5, 0, 10, 26),
        4,
        GenUtils.darkPurple,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-5, 20, 13, 7),
        3,
        GenUtils.ink,
        outlineWidth: 2.5,
      );
      canvas.restore();
    }

    // Torso (Purple & Black Shadow Armor)
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-16, -62, 32, 36),
      7,
      GenUtils.ink,
      topHighlight: GenUtils.darkNavy,
      outlineWidth: 3.5,
    );
    // Purple chest X-harnesses & belt
    canvas.drawLine(
      const Offset(-12, -58),
      const Offset(12, -32),
      GenUtils.stroke(GenUtils.purple, 4.0),
    );
    canvas.drawLine(
      const Offset(12, -58),
      const Offset(-12, -32),
      GenUtils.stroke(GenUtils.purple, 4.0),
    );
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-17, -36, 34, 8),
      3,
      GenUtils.purple,
      topHighlight: const Color(0xFFBA68C8),
      outlineWidth: 3.0,
    );

    // Spiky Shoulder Pauldron
    final shoulderPath = Path()
      ..moveTo(-18, -58)
      ..lineTo(-4, -64)
      ..lineTo(0, -52)
      ..lineTo(-16, -48)
      ..close();
    GenUtils.drawCelPath(canvas, shoulderPath, GenUtils.purple, outlineWidth: 3.0);

    // Head (Horned Oni-Ninja Cartoon Hood)
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-19, -94, 38, 34),
      12,
      GenUtils.ink,
      topHighlight: GenUtils.darkPurple,
      outlineWidth: 3.5,
    );
    // Small purple demon horns on hood
    final hornLeft = Path()
      ..moveTo(-12, -92)
      ..lineTo(-18, -104)
      ..lineTo(-4, -93)
      ..close();
    final hornRight = Path()
      ..moveTo(12, -92)
      ..lineTo(18, -104)
      ..lineTo(4, -93)
      ..close();
    GenUtils.drawCelPath(canvas, hornLeft, GenUtils.purple, outlineWidth: 2.8);
    GenUtils.drawCelPath(canvas, hornRight, GenUtils.purple, outlineWidth: 2.8);

    // Glowing Red/Yellow Menacing Cartoon Eyes
    for (final ex in [-3.0, 9.0]) {
      final eyePath = Path()
        ..moveTo(ex - 4, -81)
        ..lineTo(ex + 4, -79)
        ..lineTo(ex + 3, -73)
        ..lineTo(ex - 4, -75)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        eyePath,
        isAggro ? GenUtils.yellow : GenUtils.red,
        outlineWidth: 2.0,
      );
    }

    // Katana Arm
    canvas.save();
    canvas.translate(8, -50);
    canvas.rotate(swordAngle);
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-4, -4, 14, 9),
      3,
      GenUtils.purple,
      outlineWidth: 2.8,
    );
    final blade = Path()
      ..moveTo(10, -4)
      ..lineTo(46, -2)
      ..lineTo(52, 1)
      ..lineTo(46, 4)
      ..lineTo(10, 4)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      blade,
      GenUtils.steel,
      highlightColor: Colors.white,
      outlineWidth: 2.8,
    );
    canvas.restore();

    canvas.restore();
  }

  static Future<void> _generateEnemyGrunt() async {
    const base = 'assets/images/enemies';

    await GenUtils.saveSheet(
      relativePath: '$base/grunt_walk.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        _drawGruntPose(
          canvas,
          centerBottom: Offset(size.width * 0.48, size.height - 10),
          legSwing: sin(phase) * 0.45,
          bob: -abs(cos(phase)) * 3.0,
          swordAngle: -0.2 + sin(phase) * 0.15,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/grunt_aggro.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        _drawGruntPose(
          canvas,
          centerBottom: Offset(size.width * 0.48, size.height - 10),
          legSwing: sin(phase) * 0.65,
          bob: -abs(cos(phase)) * 5.0,
          isAggro: true,
          swordAngle: -0.8 + sin(phase) * 0.25,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/grunt_attack.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final t = i / 3.0;
        _drawGruntPose(
          canvas,
          centerBottom: Offset(size.width * 0.48, size.height - 10),
          legSwing: 0.35,
          isAggro: true,
          swordAngle: -1.3 + t * 2.2,
        );
      },
    );
  }

  // --- ENEMY DRONE (Yokai Tengu Mask Flyer) ---
  static void _drawDronePose(
    Canvas canvas, {
    required Offset center,
    required double wingAngle,
    bool isAttacking = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Feathered Cartoon Wings (Left & Right)
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1.0);
      canvas.translate(18, -6);
      canvas.rotate(wingAngle);

      final wingPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(22, -22, 42, -10)
        ..lineTo(34, 4)
        ..lineTo(24, 2)
        ..lineTo(18, 12)
        ..lineTo(0, 8)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        wingPath,
        GenUtils.steel,
        highlightColor: Colors.white,
        outlineWidth: 3.2,
      );
      canvas.restore();
    }

    // Crimson Tengu Demon Mask Body
    final maskRect = Rect.fromCenter(center: Offset.zero, width: 52, height: 56);
    GenUtils.drawCelRRect(
      canvas,
      maskRect,
      20,
      GenUtils.darkRed,
      topHighlight: GenUtils.red,
      outlineWidth: 3.8,
    );

    // Forehead Golden Tokin Hat (Tengu Pillbox Cap)
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-12, -38, 24, 14),
      4,
      GenUtils.ink,
      topHighlight: GenUtils.gold,
      outlineWidth: 3.0,
    );

    // Bushy White Cartoon Eyebrows
    final leftBrow = Path()
      ..moveTo(-22, -16)
      ..lineTo(-4, -8)
      ..lineTo(-6, -18)
      ..close();
    final rightBrow = Path()
      ..moveTo(22, -16)
      ..lineTo(4, -8)
      ..lineTo(6, -18)
      ..close();
    GenUtils.drawCelPath(canvas, leftBrow, Colors.white, outlineWidth: 2.5);
    GenUtils.drawCelPath(canvas, rightBrow, Colors.white, outlineWidth: 2.5);

    // Big Expressive Yellow Cartoon Eyes
    for (final ex in [-11.0, 11.0]) {
      GenUtils.drawCelCircle(
        canvas,
        Offset(ex, -4),
        isAttacking ? 8.0 : 6.5,
        GenUtils.yellow,
        highlightColor: Colors.white,
        outlineWidth: 2.8,
      );
      canvas.drawCircle(Offset(ex, -4), 2.5, GenUtils.fill(GenUtils.ink));
    }

    // Iconic Long 2D Cartoon Tengu Nose
    final nosePath = Path()
      ..moveTo(-7, 0)
      ..lineTo(0, 22)
      ..lineTo(7, 0)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      nosePath,
      GenUtils.red,
      highlightColor: const Color(0xFFFF7588),
      outlineWidth: 3.0,
    );

    // Grinning teeth or shooting mouth at bottom
    if (isAttacking) {
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, 22),
        6,
        GenUtils.ink,
        outlineWidth: 2.5,
      );
    }

    canvas.restore();
  }

  static Future<void> _generateEnemyDrone() async {
    const base = 'assets/images/enemies';

    await GenUtils.saveSheet(
      relativePath: '$base/drone_fly.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        _drawDronePose(
          canvas,
          center: Offset(size.width / 2, size.height / 2 + sin(phase) * 4),
          wingAngle: sin(phase) * 0.55,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/drone_attack.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final phase = (i / 4.0) * 2 * pi;
        _drawDronePose(
          canvas,
          center: Offset(size.width / 2, size.height / 2),
          wingAngle: sin(phase * 2) * 0.7,
          isAttacking: true,
        );
      },
    );
  }
}
