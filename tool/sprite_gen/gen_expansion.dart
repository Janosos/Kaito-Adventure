import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'gen_utils.dart';

class GenExpansion {
  static const Color emerald = Color(0xFF00C853);
  static const Color darkEmerald = Color(0xFF1B5E20);
  static const Color iceBlue = Color(0xFF40C4FF);
  static const Color darkIce = Color(0xFF01579B);
  static const Color magenta = Color(0xFFE040FB);

  static Future<void> generateAll() async {
    await _generateAppIconsAndMenuUi();
    await _generateIntroAndMenuIllustrations();
    await _generateInteractivePropsAndPlatforms();
    await _generateOniArcherEnemy();
    await generateBosses3To5();
  }

  static Future<void> generateBosses3To5() async {
    await _generateBoss3HebiHime();
    await _generateBoss4YukiOni();
    await _generateBoss5MuzanKai();
  }

  /// Draws Kaito's heroic 2D cartoon bust for the App Icon & UI emblems
  static void drawKaitoHeroHead(
    Canvas canvas,
    Offset center,
    double scale, {
    bool withKatana = true,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    if (withKatana) {
      // Diagonal gleaming katana behind Kaito
      canvas.save();
      canvas.rotate(-0.65);
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-75, -6, 150, 12),
        4,
        GenUtils.steel,
        topHighlight: Colors.white,
        outlineWidth: 4.0,
      );
      canvas.drawLine(
        const Offset(-68, 0),
        const Offset(68, 0),
        GenUtils.stroke(GenUtils.cyan, 3.5),
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-42, -14, 8, 28),
        2,
        GenUtils.gold,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-72, -5, 30, 10),
        2,
        GenUtils.red,
        outlineWidth: 3.0,
      );
      canvas.restore();
    }

    // Flowing red scarf tails
    final scarfBack = Path()
      ..moveTo(-22, 16)
      ..quadraticBezierTo(-55, 10, -64, 34)
      ..lineTo(-42, 42)
      ..quadraticBezierTo(-28, 26, -12, 28)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      scarfBack,
      GenUtils.darkRed,
      highlightColor: GenUtils.red,
      outlineWidth: 4.0,
    );

    // Shoulders / Navy Shinobi Gi
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-34, 18, 68, 36),
      12,
      GenUtils.darkNavy,
      topHighlight: GenUtils.navy,
      outlineWidth: 4.0,
    );

    // Red Scarf Collar
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-30, 10, 60, 18),
      8,
      GenUtils.red,
      topHighlight: const Color(0xFFFF6B7A),
      outlineWidth: 4.0,
    );

    // Head Base (Navy Shinobi Hood)
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-36, -42, 72, 58),
      20,
      GenUtils.darkNavy,
      topHighlight: GenUtils.navy,
      outlineWidth: 4.5,
    );

    // Spiky Anime Hair Bangs
    final hair = Path()
      ..moveTo(-28, -36)
      ..lineTo(-38, -56)
      ..lineTo(-14, -44)
      ..lineTo(0, -64)
      ..lineTo(14, -44)
      ..lineTo(36, -56)
      ..lineTo(28, -36)
      ..close();
    GenUtils.drawCelPath(
      canvas,
      hair,
      GenUtils.ink,
      highlightColor: GenUtils.navy,
      outlineWidth: 3.8,
    );

    // Face Opening
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-26, -22, 52, 24),
      9,
      GenUtils.skin,
      topHighlight: const Color(0xFFFFF0DB),
      outlineWidth: 3.5,
    );

    // Expressive Cyan Shinobi Eyes
    for (final ex in [-11.0, 11.0]) {
      final eyeRect =
          Rect.fromCenter(center: Offset(ex, -10), width: 12, height: 14);
      canvas.drawOval(eyeRect, GenUtils.fill(Colors.white));
      canvas.drawOval(eyeRect, GenUtils.stroke(GenUtils.ink, 2.8));
      canvas.drawCircle(
          Offset(ex + 1.0, -10), 4.8, GenUtils.fill(GenUtils.cyan));
      canvas.drawCircle(Offset(ex + 1.2, -10), 2.5, GenUtils.fill(GenUtils.ink));
      canvas.drawCircle(
          Offset(ex - 1.5, -13), 2.0, GenUtils.fill(Colors.white));
    }

    // Determined Eyebrows
    canvas.drawLine(
      const Offset(-20, -19),
      const Offset(-3, -15),
      GenUtils.stroke(GenUtils.ink, 3.8),
    );
    canvas.drawLine(
      const Offset(20, -19),
      const Offset(3, -15),
      GenUtils.stroke(GenUtils.ink, 3.8),
    );

    // Red Headband & Steel Plate
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-38, -35, 76, 14),
      5,
      GenUtils.red,
      topHighlight: const Color(0xFFFF6B7A),
      outlineWidth: 3.8,
    );
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(-16, -33, 32, 10),
      3,
      GenUtils.steel,
      topHighlight: Colors.white,
      outlineWidth: 3.0,
    );

    canvas.restore();
  }

  static Future<Uint8List> _renderAppIconBytes(int pixelSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelSize.toDouble(), pixelSize.toDouble()),
    );
    final s = pixelSize / 256.0;
    canvas.save();
    canvas.scale(s, s);

    // Rounded App Icon Background (Vibrant Crimson-Gold-Midnight Cel-Shaded Frame)
    GenUtils.drawCelRRect(
      canvas,
      const Rect.fromLTWH(8, 8, 240, 240),
      48,
      GenUtils.darkNavy,
      topHighlight: const Color(0xFF311B92),
      outlineWidth: 8.0,
    );

    // Glowing Golden Moon / Sunburst behind Kaito
    GenUtils.drawCartoonStar(
      canvas,
      const Offset(128, 128),
      104,
      74,
      12,
      GenUtils.red.withValues(alpha: 0.85),
      outlineWidth: 4.0,
    );
    GenUtils.drawCelCircle(
      canvas,
      const Offset(128, 124),
      76,
      GenUtils.goldDark,
      highlightColor: GenUtils.yellow,
      outlineWidth: 5.0,
    );

    // Main Character Kaito Hero Bust
    drawKaitoHeroHead(
      canvas,
      const Offset(128, 136),
      1.35,
      withKatana: true,
    );

    // Corner Shuriken Star Sparkle
    GenUtils.drawCartoonStar(
      canvas,
      const Offset(204, 52),
      18,
      7,
      4,
      GenUtils.cyan,
      outlineWidth: 3.0,
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(pixelSize, pixelSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Writes a valid Windows .ico file containing a 256x256 PNG icon
  static Future<void> _writeWindowsIco(String path, Uint8List pngBytes) async {
    final header = ByteData(22);
    header.setUint16(0, 0, Endian.little); // Reserved
    header.setUint16(2, 1, Endian.little); // Type 1 = ICO
    header.setUint16(4, 1, Endian.little); // 1 image
    header.setUint8(6, 0); // width 256 (0 means 256)
    header.setUint8(7, 0); // height 256 (0 means 256)
    header.setUint8(8, 0); // color palette
    header.setUint8(9, 0); // reserved
    header.setUint16(10, 1, Endian.little); // color planes
    header.setUint16(12, 32, Endian.little); // bits per pixel
    header.setUint32(14, pngBytes.length, Endian.little); // data size
    header.setUint32(18, 22, Endian.little); // data offset

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pngBytes);

    final file = File(path);
    if (await file.parent.exists()) {
      await file.writeAsBytes(builder.toBytes());
    }
  }

  static Future<void> _generateAppIconsAndMenuUi() async {
    const uiBase = 'assets/images/ui';

    // 1. Generate Kaito App Icon for Flutter UI and all platform launchers!
    final icon256 = await _renderAppIconBytes(256);
    final uiIconFile = File('$uiBase/app_icon.png');
    await uiIconFile.parent.create(recursive: true);
    await uiIconFile.writeAsBytes(icon256);

    // Update Android mipmap launcher icons
    final androidSizes = <String, int>{
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'web/favicon.png': 64,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-512.png': 512,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
    };

    for (final entry in androidSizes.entries) {
      final f = File(entry.key);
      if (await f.parent.exists()) {
        final bytes = await _renderAppIconBytes(entry.value);
        await f.writeAsBytes(bytes);
      }
    }

    await _writeWindowsIco('windows/runner/resources/app_icon.ico', icon256);

    // 2. GAME LOGO EMBLEM CREST (480x160 - Pure Vector Cartoon Crest, No TextPainter Ahem blocks!)
    await GenUtils.saveSingle(
      relativePath: '$uiBase/logo_kaito_adventure.png',
      width: 480,
      height: 160,
      draw: (canvas, size) {
        final cx = size.width / 2;
        final cy = size.height / 2;

        // Crossed Gleaming Katanas behind Logo Shield
        for (final angle in [-0.24, 0.24]) {
          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(angle);
          GenUtils.drawCelRRect(
            canvas,
            const Rect.fromLTWH(-220, -7, 440, 14),
            5,
            GenUtils.steel,
            topHighlight: Colors.white,
            outlineWidth: 3.8,
          );
          canvas.drawLine(
            const Offset(-200, 0),
            const Offset(200, 0),
            GenUtils.stroke(GenUtils.cyan, 3.0),
          );
          GenUtils.drawCelRRect(
            canvas,
            const Rect.fromLTWH(-162, -16, 12, 32),
            3,
            GenUtils.gold,
            topHighlight: GenUtils.yellow,
            outlineWidth: 3.2,
          );
          GenUtils.drawCelRRect(
            canvas,
            const Rect.fromLTWH(-222, -7, 62, 14),
            4,
            GenUtils.red,
            topHighlight: GenUtils.orange,
            outlineWidth: 3.2,
          );
          canvas.restore();
        }

        // Outer Ornate Shogun Banner Plaque
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromCenter(center: Offset(cx, cy), width: 392, height: 112),
          22,
          GenUtils.darkNavy,
          topHighlight: const Color(0xFF311B92),
          outlineWidth: 5.5,
        );
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromCenter(center: Offset(cx, cy), width: 372, height: 92),
          16,
          GenUtils.darkRed,
          topHighlight: GenUtils.red,
          outlineWidth: 4.0,
        );

        // Inner Gold Trim Bar & Speed Streaks
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromCenter(center: Offset(cx, cy), width: 344, height: 70),
          12,
          const Color(0xFF1A103C),
          topHighlight: GenUtils.darkPurple,
          outlineWidth: 3.5,
        );

        // Left & Right Spinning Cyan Shuriken Medallions
        for (final sx in [cx - 152, cx + 152]) {
          GenUtils.drawCartoonStar(
            canvas,
            Offset(sx, cy),
            26,
            11,
            4,
            GenUtils.cyan,
            outlineWidth: 3.2,
          );
          GenUtils.drawCelCircle(
            canvas,
            Offset(sx, cy),
            7,
            GenUtils.yellow,
            highlightColor: Colors.white,
            outlineWidth: 2.5,
          );
        }

        // Center Golden Sunburst & Hero Kaito Medallion Crest
        GenUtils.drawCartoonStar(
          canvas,
          Offset(cx, cy),
          46,
          30,
          10,
          GenUtils.gold,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset(cx, cy),
          32,
          GenUtils.darkNavy,
          highlightColor: GenUtils.purple,
          outlineWidth: 3.5,
        );
        drawKaitoHeroHead(
          canvas,
          Offset(cx, cy + 8),
          0.52,
          withKatana: false,
        );
      },
    );

    // 3. MENU BUTTON ICONS (80x80)
    // PLAY ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_play.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        final playPath = Path()
          ..moveTo(22, 14)
          ..lineTo(66, 40)
          ..lineTo(22, 66)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          playPath,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 4.0,
        );
      },
    );

    // CHAPTERS MAP SCROLL ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_chapters.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(10, 22, 60, 36),
          6,
          const Color(0xFFFFF8E1),
          topHighlight: Colors.white,
          outlineWidth: 3.8,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(8, 16, 12, 48),
          4,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(60, 16, 12, 48),
          4,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(40, 40),
          12,
          5,
          5,
          GenUtils.red,
          outlineWidth: 2.5,
        );
      },
    );

    // INTRO STORY ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_intro.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(12, 16, 56, 48),
          8,
          GenUtils.purple,
          topHighlight: magenta,
          outlineWidth: 3.8,
        );
        // Manga panel dividers
        canvas.drawLine(
          const Offset(40, 16),
          const Offset(34, 64),
          GenUtils.stroke(GenUtils.ink, 3.5),
        );
        canvas.drawLine(
          const Offset(12, 40),
          const Offset(68, 36),
          GenUtils.stroke(GenUtils.ink, 3.5),
        );
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(52, 50),
          10,
          4,
          4,
          GenUtils.yellow,
          outlineWidth: 2.2,
        );
      },
    );

    // CONTROLS ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_controls.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(10, 22, 60, 38),
          14,
          GenUtils.darkCyan,
          topHighlight: GenUtils.cyan,
          outlineWidth: 3.8,
        );
        // D-pad cross
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(20, 37, 16, 6),
          2,
          GenUtils.white,
          outlineWidth: 2.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(25, 32, 6, 16),
          2,
          GenUtils.white,
          outlineWidth: 2.0,
        );
        // Action buttons
        GenUtils.drawCelCircle(
          canvas,
          const Offset(50, 44),
          5,
          GenUtils.red,
          outlineWidth: 2.2,
        );
        GenUtils.drawCelCircle(
          canvas,
          const Offset(58, 36),
          5,
          GenUtils.yellow,
          outlineWidth: 2.2,
        );
      },
    );

    // SKIP ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_skip.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        for (final dx in [14.0, 38.0]) {
          final p = Path()
            ..moveTo(dx, 20)
            ..lineTo(dx + 24, 40)
            ..lineTo(dx, 60)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            p,
            GenUtils.goldDark,
            highlightColor: GenUtils.yellow,
            outlineWidth: 3.5,
          );
        }
      },
    );

    // HOME TORII ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_home.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(20, 26, 8, 42),
          2,
          GenUtils.red,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(52, 26, 8, 42),
          2,
          GenUtils.red,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(12, 28, 56, 8),
          2,
          GenUtils.red,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(8, 16, 64, 10),
          4,
          GenUtils.ink,
          topHighlight: GenUtils.darkNavy,
          outlineWidth: 3.2,
        );
      },
    );

    // SETTINGS SHURIKEN-GEAR ICON
    await GenUtils.saveSingle(
      relativePath: '$uiBase/btn_settings.png',
      width: 80,
      height: 80,
      draw: (canvas, size) {
        final c = Offset(size.width / 2, size.height / 2);
        // 8-tooth cartoon gear star
        GenUtils.drawCartoonStar(
          canvas,
          c,
          30,
          21,
          8,
          GenUtils.goldDark,
          outlineWidth: 3.8,
        );
        GenUtils.drawCelCircle(
          canvas,
          c,
          19,
          GenUtils.gold,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.2,
        );
        GenUtils.drawCelCircle(
          canvas,
          c,
          8,
          GenUtils.darkNavy,
          highlightColor: GenUtils.cyan,
          outlineWidth: 2.8,
        );
      },
    );

    // MINI KAITO HEAD & BOSS SKULL FOR PROGRESS BAR (64x64)
    await GenUtils.saveSingle(
      relativePath: '$uiBase/icon_kaito_head.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        drawKaitoHeroHead(
          canvas,
          const Offset(32, 38),
          0.62,
          withKatana: false,
        );
      },
    );

    await GenUtils.saveSingle(
      relativePath: '$uiBase/icon_boss_skull.png',
      width: 64,
      height: 64,
      draw: (canvas, size) {
        final cx = size.width / 2;
        final cy = size.height / 2 + 4;
        // Oni Horns
        final hornL = Path()
          ..moveTo(cx - 14, cy - 12)
          ..lineTo(cx - 26, cy - 28)
          ..lineTo(cx - 6, cy - 16)
          ..close();
        final hornR = Path()
          ..moveTo(cx + 14, cy - 12)
          ..lineTo(cx + 26, cy - 28)
          ..lineTo(cx + 6, cy - 16)
          ..close();
        GenUtils.drawCelPath(canvas, hornL, GenUtils.gold, outlineWidth: 3.0);
        GenUtils.drawCelPath(canvas, hornR, GenUtils.gold, outlineWidth: 3.0);

        GenUtils.drawCelCircle(
          canvas,
          Offset(cx, cy),
          18,
          GenUtils.darkRed,
          highlightColor: GenUtils.red,
          outlineWidth: 3.5,
        );
        for (final ex in [cx - 7, cx + 7]) {
          GenUtils.drawCelCircle(
            canvas,
            Offset(ex, cy - 2),
            4.5,
            GenUtils.yellow,
            outlineWidth: 2.0,
          );
        }
      },
    );
  }

  static Future<void> _generateIntroAndMenuIllustrations() async {
    const base = 'assets/images/illustrations';

    // INTRO PANEL 1: THE SACRED INK SCROLL (640x360)
    await GenUtils.saveSingle(
      relativePath: '$base/intro_panel1_shrine.png',
      width: 640,
      height: 360,
      draw: (canvas, size) {
        final bg = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            [const Color(0xFF0D253F), const Color(0xFF1D4E89)],
          );
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

        // Glowing Shrine Altar & Floating Sacred Scroll
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(220, 250, 200, 90),
          10,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 4.0,
        );

        // Radiant Golden Aura around the Sacred Scroll
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(320, 145),
          95,
          55,
          12,
          GenUtils.yellow.withValues(alpha: 0.45),
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(255, 120, 130, 50),
          10,
          const Color(0xFFFFF8E1),
          topHighlight: Colors.white,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(306, 116, 28, 58),
          4,
          GenUtils.red,
          outlineWidth: 3.5,
        );

        // Kaito guarding on the left
        drawKaitoHeroHead(canvas, const Offset(130, 220), 1.25);
      },
    );

    // 3. INTRO PANEL 2: THE 5 SHADOW WARLORDS & BLOOD ECLIPSE (640x360)
    await GenUtils.saveSingle(
      relativePath: '$base/intro_panel2_warlords.png',
      width: 640,
      height: 360,
      draw: (canvas, size) {
        final bg = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            [const Color(0xFF1A001A), const Color(0xFF7F0000)],
          );
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

        // Blood Eclipse Sun in center sky
        GenUtils.drawCelCircle(
          canvas,
          const Offset(320, 130),
          88,
          GenUtils.red,
          highlightColor: GenUtils.orange,
          outlineWidth: 5.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          const Offset(320, 130),
          70,
          GenUtils.ink,
          outlineWidth: 3.5,
        );

        // 5 Menacing Warlord Silhouettes with glowing eyes across the horizon
        final colors = [
          GenUtils.purple,
          GenUtils.orange,
          emerald,
          iceBlue,
          GenUtils.red,
        ];
        for (int i = 0; i < 5; i++) {
          final wx = 100.0 + i * 110.0;
          final wy = i == 2 ? 230.0 : 255.0;
          GenUtils.drawCelRRect(
            canvas,
            Rect.fromCenter(center: Offset(wx, wy + 40), width: 76, height: 110),
            16,
            GenUtils.ink,
            topHighlight: colors[i].withValues(alpha: 0.45),
            outlineWidth: 3.5,
          );
          // Glowing Warlord Eyes
          GenUtils.drawCelCircle(
            canvas,
            Offset(wx - 12, wy + 10),
            5,
            colors[i],
            outlineWidth: 2.0,
          );
          GenUtils.drawCelCircle(
            canvas,
            Offset(wx + 12, wy + 10),
            5,
            colors[i],
            outlineWidth: 2.0,
          );
        }
      },
    );

    // 4. INTRO PANEL 3: KAITO'S CELESTIAL OATH (640x360)
    await GenUtils.saveSingle(
      relativePath: '$base/intro_panel3_oath.png',
      width: 640,
      height: 360,
      draw: (canvas, size) {
        final bg = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(640, 360),
            [const Color(0xFF002B49), const Color(0xFF00838F)],
          );
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

        // Action Speed bursts
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(320, 180),
          220,
          90,
          16,
          GenUtils.cyan.withValues(alpha: 0.35),
          outlineWidth: 3.0,
        );

        drawKaitoHeroHead(
          canvas,
          const Offset(320, 195),
          1.65,
          withKatana: true,
        );
      },
    );
  }

  static Future<void> _generateInteractivePropsAndPlatforms() async {
    const base = 'assets/images/environment';

    // 1. NEW PLATFORM SPRITES (Bamboo, Ice, Sanctum - 256x80)
    await GenUtils.saveSingle(
      relativePath: '$base/platform_bamboo.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 16, size.width - 8, size.height - 20),
          8,
          GenUtils.woodDark,
          topHighlight: GenUtils.wood,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(2, 4, size.width - 4, 24),
          8,
          darkEmerald,
          topHighlight: emerald,
          outlineWidth: 4.0,
        );
        for (double x = 40; x < size.width - 20; x += 48) {
          canvas.drawLine(
            Offset(x, 6),
            Offset(x, 26),
            GenUtils.stroke(GenUtils.ink, 3.5),
          );
        }
      },
    );

    await GenUtils.saveSingle(
      relativePath: '$base/platform_ice.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 8, size.width - 8, size.height - 12),
          8,
          darkIce,
          topHighlight: iceBlue,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 6, size.width - 8, 18),
          6,
          Colors.white,
          topHighlight: const Color(0xFFE1F5FE),
          outlineWidth: 3.5,
        );
      },
    );

    await GenUtils.saveSingle(
      relativePath: '$base/platform_sanctum.png',
      width: 256,
      height: 80,
      draw: (canvas, size) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 8, size.width - 8, size.height - 12),
          8,
          GenUtils.ink,
          topHighlight: GenUtils.darkPurple,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(4, 6, size.width - 8, 16),
          6,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.5,
        );
      },
    );

    // 2. CHECKPOINT LANTERN (4 frames, 80x110)
    await GenUtils.saveSheet(
      relativePath: '$base/prop_checkpoint.png',
      frameWidth: 80,
      frameHeight: 110,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final cx = size.width / 2;
        final bottom = size.height - 4.0;
        final isLit = i > 0;

        // Stone Lantern Pedestal & Pillar
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 22, bottom - 16, 44, 16),
          4,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 10, bottom - 56, 20, 42),
          3,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 3.5,
        );

        // Lantern Chamber
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 18, bottom - 84, 36, 30),
          5,
          isLit ? GenUtils.cyan : GenUtils.darkNavy,
          topHighlight: isLit ? GenUtils.yellow : GenUtils.navy,
          outlineWidth: 3.5,
        );

        if (isLit) {
          GenUtils.drawCartoonStar(
            canvas,
            Offset(cx, bottom - 69),
            14 + (i % 2) * 4.0,
            6,
            4,
            Colors.white,
            outlineWidth: 2.0,
          );
        }

        // Pagoda Lantern Roof
        final roof = Path()
          ..moveTo(cx - 28, bottom - 82)
          ..lineTo(cx, bottom - 104)
          ..lineTo(cx + 28, bottom - 82)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          roof,
          GenUtils.ink,
          highlightColor: GenUtils.steelDark,
          outlineWidth: 3.5,
        );
      },
    );

    // 3. BREAKABLE SHINOBI CRATE (3 frames, 72x72)
    await GenUtils.saveSheet(
      relativePath: '$base/prop_crate.png',
      frameWidth: 72,
      frameHeight: 72,
      frameCount: 3,
      drawFrame: (canvas, i, size) {
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(6, 6, 60, 60),
          8,
          GenUtils.woodDark,
          topHighlight: GenUtils.wood,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(14, 14, 44, 44),
          4,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.0,
        );
        // Diagonal wood braces
        canvas.drawLine(
          const Offset(14, 14),
          const Offset(58, 58),
          GenUtils.stroke(GenUtils.woodDark, 5.0),
        );
        canvas.drawLine(
          const Offset(58, 14),
          const Offset(14, 58),
          GenUtils.stroke(GenUtils.woodDark, 5.0),
        );
        if (i >= 1) {
          // Cracks
          canvas.drawLine(
            const Offset(20, 10),
            const Offset(42, 48),
            GenUtils.stroke(GenUtils.ink, 4.0),
          );
        }
      },
    );

    // 4. TAIKO SPIRIT BOUNCE DRUM (4 frames, 88x88)
    await GenUtils.saveSheet(
      relativePath: '$base/prop_bounce_drum.png',
      frameWidth: 88,
      frameHeight: 88,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final scale = i == 1 ? 1.12 : (i == 2 ? 0.92 : 1.0);
        final c = Offset(size.width / 2, size.height / 2);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(scale, scale);

        GenUtils.drawCelCircle(
          canvas,
          Offset.zero,
          34,
          GenUtils.red,
          highlightColor: GenUtils.orange,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset.zero,
          24,
          const Color(0xFFFFF8E1),
          highlightColor: Colors.white,
          outlineWidth: 3.5,
        );
        GenUtils.drawCartoonStar(
          canvas,
          Offset.zero,
          14,
          6,
          3,
          GenUtils.ink,
          rotation: i * 0.5,
        );
        canvas.restore();
      },
    );

    // 5. WIND UPDRAFT VENT (4 frames, 96x128)
    await GenUtils.saveSheet(
      relativePath: '$base/prop_wind_vent.png',
      frameWidth: 96,
      frameHeight: 128,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final cx = size.width / 2;
        final bottom = size.height - 4.0;
        final phase = (i / 4.0) * 2 * pi;

        // Rising cyan wind swirls
        for (int w = 0; w < 3; w++) {
          final wy = bottom - 28 - ((w * 32 + i * 8) % 90);
          final wx = cx + (w - 1) * 18.0 + sin(phase + w) * 6;
          canvas.drawLine(
            Offset(wx, wy + 18),
            Offset(wx, wy),
            GenUtils.stroke(GenUtils.cyan.withValues(alpha: 0.8), 4.0),
          );
        }

        // Base metallic fan vent
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(10, bottom - 20, size.width - 20, 20),
          6,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 3.8,
        );
      },
    );

    // 6. SWITCH ORB & GATE BARRIER
    await GenUtils.saveSheet(
      relativePath: '$base/prop_switch_orb.png',
      frameWidth: 64,
      frameHeight: 80,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final cx = size.width / 2;
        final bottom = size.height - 4.0;
        final active = i >= 2;

        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 18, bottom - 24, 36, 24),
          4,
          GenUtils.steelDark,
          topHighlight: GenUtils.steel,
          outlineWidth: 3.5,
        );
        GenUtils.drawCelCircle(
          canvas,
          Offset(cx, bottom - 44),
          18,
          active ? emerald : GenUtils.red,
          highlightColor: active ? GenUtils.cyan : GenUtils.yellow,
          outlineWidth: 3.8,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/prop_gate_barrier.png',
      frameWidth: 64,
      frameHeight: 160,
      frameCount: 4,
      drawFrame: (canvas, i, size) {
        final cx = size.width / 2;
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(cx - 16, 4, 32, size.height - 8),
          6,
          GenUtils.darkNavy,
          topHighlight: GenUtils.red,
          outlineWidth: 4.0,
        );
        for (double y = 24; y < size.height - 20; y += 32) {
          GenUtils.drawCelCircle(
            canvas,
            Offset(cx, y),
            8,
            GenUtils.yellow,
            outlineWidth: 2.5,
          );
        }
      },
    );
  }

  static Future<void> _generateOniArcherEnemy() async {
    const base = 'assets/images/enemies';

    void drawOni(Canvas canvas, Offset centerBottom,
        {double bob = 0.0, bool shooting = false}) {
      canvas.save();
      canvas.translate(centerBottom.dx, centerBottom.dy + bob);

      // Armored Legs
      for (final s in [-1.0, 1.0]) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(s * 8 - 5, -26, 10, 24),
          4,
          GenUtils.darkRed,
          outlineWidth: 3.0,
        );
      }

      // Samurai Shooter Cuirass
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-17, -62, 34, 38),
        8,
        GenUtils.darkRed,
        topHighlight: GenUtils.red,
        outlineWidth: 3.5,
      );

      // Horned Oni Mask Head
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-18, -94, 36, 34),
        10,
        GenUtils.goldDark,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.5,
      );
      for (final ex in [-3.0, 9.0]) {
        GenUtils.drawCelCircle(
          canvas,
          Offset(ex, -78),
          4.5,
          GenUtils.cyan,
          outlineWidth: 2.0,
        );
      }

      // Great Bow (Yumi) in front
      final bow = Path()
        ..moveTo(12, -88)
        ..quadraticBezierTo(34, -52, 12, -16);
      canvas.drawPath(bow, GenUtils.stroke(GenUtils.ink, 6.0));
      canvas.drawPath(
        bow,
        GenUtils.stroke(shooting ? GenUtils.cyan : GenUtils.gold, 3.0),
      );

      canvas.restore();
    }

    await GenUtils.saveSheet(
      relativePath: '$base/oni_idle.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 6,
      drawFrame: (canvas, i, size) {
        final phase = (i / 6.0) * 2 * pi;
        drawOni(
          canvas,
          Offset(size.width * 0.48, size.height - 10),
          bob: sin(phase) * 2.5,
        );
      },
    );

    await GenUtils.saveSheet(
      relativePath: '$base/oni_shoot.png',
      frameWidth: 128,
      frameHeight: 128,
      frameCount: 5,
      drawFrame: (canvas, i, size) {
        drawOni(
          canvas,
          Offset(size.width * 0.48, size.height - 10),
          shooting: true,
        );
      },
    );
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
    double bodyCenterY = -92,
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

  // =========================================================================
  // BOSS 3: HEBI-HIME (THE OROCHI VENOM EMPRESS) — High-Detail 2D Cartoon
  // =========================================================================
  static Future<void> _generateBoss3HebiHime() async {
    const base = 'assets/images/bosses';

    void drawHebi(
      Canvas canvas,
      Offset centerBottom, {
      double sway = 0.0,
      double animProgress = 0.0,
      int mode = 0, // 0=idle, 1=dash, 2=cast, 3=stun
    }) {
      final bool isDash = mode == 1;
      final bool isCast = mode == 2;
      final bool isStun = mode == 3;

      double bodyDx = 0.0;
      double bodyDy = 0.0;
      double torsoTilt = 0.0;
      double scaleY = 1.0;

      if (isDash) {
        bodyDx = sin(animProgress * pi) * 16.0;
        bodyDy = 4.0 * sin(animProgress * pi);
        torsoTilt = 0.24;
      } else if (isCast) {
        bodyDy = -8.0 - sin(animProgress * pi) * 6.0;
        torsoTilt = -0.06 * sin(animProgress * pi);
      } else if (isStun) {
        bodyDx = sin(animProgress * 2 * pi) * 5.5;
        bodyDy = 2.0 + cos(animProgress * 4 * pi) * 1.5;
        torsoTilt = sin(animProgress * 2 * pi) * 0.11;
        scaleY = 1.0;
      }

      canvas.save();
      canvas.translate(centerBottom.dx + bodyDx, centerBottom.dy + bodyDy);
      canvas.scale(1.0, scaleY);

      if (isDash) {
        for (int l = 0; l < 4; l++) {
          final ly = -28.0 - l * 28.0;
          canvas.drawLine(
            Offset(-82 - (l % 2) * 14.0, ly),
            Offset(-32, ly),
            GenUtils.stroke(emerald.withValues(alpha: 0.78), 3.2),
          );
        }
      }

      // 1. Toxic Emerald Venom Aura & Floating Miasma Orbs
      final auraPaint = Paint()
        ..color = emerald.withValues(alpha: (isDash || isCast) ? 0.45 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -82), width: 130, height: 150),
        auraPaint,
      );

      // 2. Twin Rearing Spectral Orochi Cobras behind Empress Shoulders
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        final cobraBob = sin(animProgress * 2 * pi + side) * (isCast ? 9.0 : 4.5);
        final cobraDrop = isStun ? 16.0 : 0.0;
        canvas.translate(
          side * (isCast ? 44.0 : 38.0) + sway * 0.4,
          -95.0 + cobraBob + cobraDrop,
        );
        canvas.scale(side, 1.0);
        if (isDash) canvas.rotate(0.18);
        if (isStun) canvas.rotate(0.32);

        // Flared King Cobra Hood
        final hoodPath = Path()
          ..moveTo(-10, 18)
          ..quadraticBezierTo(-24, -10, -8, -32)
          ..quadraticBezierTo(8, -42, 22, -26)
          ..quadraticBezierTo(28, -4, 10, 18)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          hoodPath,
          GenUtils.darkPurple,
          highlightColor: emerald,
          outlineWidth: 3.4,
        );

        // Crimson Cobra Hood Eye-Marking
        GenUtils.drawCelCircle(
          canvas,
          const Offset(2, -12),
          6.5,
          GenUtils.gold,
          highlightColor: GenUtils.red,
          outlineWidth: 2.2,
        );

        // Snarling Cobra Head & Open Fangs
        final headPath = Path()
          ..moveTo(-6, -26)
          ..lineTo(18, -34)
          ..lineTo(26, -22)
          ..lineTo(6, -16)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          headPath,
          darkEmerald,
          highlightColor: emerald,
          outlineWidth: 3.2,
        );
        GenUtils.drawCelCircle(
          canvas,
          const Offset(12, -26),
          3.5,
          GenUtils.yellow,
          outlineWidth: 1.8,
        );
        canvas.drawLine(
          const Offset(18, -20),
          const Offset(20, -12),
          GenUtils.stroke(Colors.white, 3.0),
        );
        canvas.drawLine(
          const Offset(23, -21),
          const Offset(25, -14),
          GenUtils.stroke(Colors.white, 2.8),
        );
        canvas.drawLine(
          const Offset(24, -22),
          const Offset(34, -24),
          GenUtils.stroke(GenUtils.red, 2.2),
        );
        canvas.restore();
      }

      // 3. Coiled Armored Naga-Serpent Lower Body & Whipping Rattle Tail
      final coilSway = isDash ? sin(animProgress * 2 * pi) * 14.0 : sway;
      final backTail = Path()
        ..moveTo(-28 + coilSway, -18)
        ..quadraticBezierTo(-68 + coilSway, -28, -62 + coilSway * 1.2, -62)
        ..quadraticBezierTo(-56 + coilSway, -42, -20 + coilSway, -32)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        backTail,
        darkEmerald,
        highlightColor: emerald,
        outlineWidth: 3.8,
      );
      GenUtils.drawCartoonStar(
        canvas,
        Offset(-62 + coilSway * 1.2, -66),
        14,
        6,
        4,
        GenUtils.gold,
        rotation: animProgress * 2 * pi,
        outlineWidth: 2.8,
      );

      // Primary Heavy Serpent Coils (2 tiered loops)
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(-48 + coilSway * 0.7, -26, 96, 24),
        12,
        darkEmerald,
        topHighlight: emerald,
        outlineWidth: 4.0,
      );
      GenUtils.drawCelRRect(
        canvas,
        Rect.fromLTWH(-38 - coilSway * 0.5, -46, 76, 24),
        12,
        darkEmerald,
        topHighlight: emerald,
        outlineWidth: 4.0,
      );

      for (double sx = -26; sx <= 26; sx += 13) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(sx - 5 + coilSway * 0.4, -22, 10, 14),
          3,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 2.2,
        );
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -48);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 48);

      // 4. Scale-Armored Kunoichi Empress Torso & Obi Sash
      final torsoPath = Path()
        ..moveTo(-22, -44)
        ..lineTo(-28, -104)
        ..lineTo(28, -104)
        ..lineTo(22, -44)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        torsoPath,
        GenUtils.darkPurple,
        highlightColor: GenUtils.purple,
        outlineWidth: 4.0,
      );

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-18, -98, 36, 36),
        8,
        darkEmerald,
        topHighlight: emerald,
        outlineWidth: 3.2,
      );
      for (double y = -88; y <= -70; y += 9) {
        canvas.drawLine(
          Offset(-14, y),
          Offset(14, y),
          GenUtils.stroke(GenUtils.gold, 2.5),
        );
      }

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-25, -58, 50, 14),
        5,
        GenUtils.darkRed,
        topHighlight: GenUtils.red,
        outlineWidth: 3.5,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -51),
        8,
        GenUtils.gold,
        highlightColor: emerald,
        outlineWidth: 2.8,
      );

      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.scale(side, 1.0);
        final pauldron = Path()
          ..moveTo(18, -106)
          ..lineTo(44, -118)
          ..lineTo(38, -92)
          ..lineTo(20, -88)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          pauldron,
          GenUtils.goldDark,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.4,
        );
        canvas.restore();
      }

      // 5. Kunoichi Empress Face, Glowing Emerald Viper Eyes & Horned Kasa Hat
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-19, -138, 38, 34),
        12,
        GenUtils.skin,
        topHighlight: const Color(0xFFFFF0DB),
        outlineWidth: 3.6,
      );

      for (final ex in [-7.0, 8.0]) {
        final eyePath = Path()
          ..moveTo(ex - 6, -123)
          ..lineTo(ex + 6, -120)
          ..lineTo(ex + 5, -114)
          ..lineTo(ex - 5, -116)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          eyePath,
          emerald,
          highlightColor: GenUtils.yellow,
          outlineWidth: 2.2,
        );
        canvas.drawLine(
          Offset(ex + 0.5, -122),
          Offset(ex + 0.5, -115),
          GenUtils.stroke(GenUtils.ink, 2.2),
        );
      }

      final kasaPath = Path()
        ..moveTo(-54, -128)
        ..quadraticBezierTo(0, -164, 54, -128)
        ..quadraticBezierTo(0, -136, -54, -128)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        kasaPath,
        GenUtils.woodDark,
        highlightColor: GenUtils.wood,
        outlineWidth: 4.0,
      );
      final crownPath = Path()
        ..moveTo(-16, -136)
        ..quadraticBezierTo(-28, -158, -18, -172)
        ..quadraticBezierTo(-10, -154, 0, -146)
        ..quadraticBezierTo(10, -154, 18, -172)
        ..quadraticBezierTo(28, -158, 16, -136)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        crownPath,
        GenUtils.gold,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.4,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -142),
        5.5,
        emerald,
        highlightColor: Colors.white,
        outlineWidth: 2.2,
      );

      // 6. Dual Curved Viper Kusarigama Sickles Dripping Venom (dynamic swing!)
      double rightBladeAngle = -0.35 + sin(animProgress * 2 * pi) * 0.08;
      double leftBladeAngle = -2.4 - sin(animProgress * 2 * pi) * 0.08;
      if (isDash) {
        // Slashing dash sweep!
        rightBladeAngle = -1.45 + animProgress * 2.35;
        leftBladeAngle = -2.35 + animProgress * 1.85;
      } else if (isCast) {
        rightBladeAngle = -1.25 + sin(animProgress * 2 * pi) * 0.30;
        leftBladeAngle = -1.90 - sin(animProgress * 2 * pi) * 0.30;
      } else if (isStun) {
        rightBladeAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
        leftBladeAngle = 2.08 - sin(animProgress * 2 * pi) * 0.14;
      }

      for (final isRight in [false, true]) {
        canvas.save();
        canvas.translate(isRight ? 24 : -24, -84);
        canvas.rotate(isRight ? rightBladeAngle : leftBladeAngle);

        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-6, -6, 20, 12),
          5,
          GenUtils.purple,
          topHighlight: magenta,
          outlineWidth: 3.0,
        );

        final sickle = Path()
          ..moveTo(12, -5)
          ..quadraticBezierTo(52, -26, 74, 6)
          ..quadraticBezierTo(58, 18, 46, 22)
          ..quadraticBezierTo(48, 2, 12, 5)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          sickle,
          emerald,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.5,
        );
        canvas.drawCircle(
          const Offset(68, 8),
          4.5,
          GenUtils.fill(GenUtils.yellow),
        );
        canvas.restore();
      }

      if (isDash && animProgress >= 0.20) {
        _drawSlashArc(
          canvas,
          center: const Offset(20, -76),
          radius: 62,
          startAngle: -1.1 + animProgress * 1.2,
          sweepAngle: 1.45,
          color: emerald,
        );
      }

      // Cast Mode: Spinning Venom Mandala Sigil
      if (isCast) {
        GenUtils.drawCartoonStar(
          canvas,
          const Offset(0, -90),
          42,
          20,
          8,
          emerald.withValues(alpha: 0.62),
          rotation: animProgress * 2 * pi,
          outlineWidth: 2.8,
        );
      }

      canvas.restore(); // end torso tilt

      // Stun Mode: Circling Cartoon Stars & Guard-Break Sparks
      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -172,
          starRadiusX: 36,
          bodyCenterY: -82,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'hebi_idle.png': [6, 0],
      'hebi_dash.png': [4, 1],
      'hebi_cast.png': [5, 2],
      'hebi_stun.png': [4, 3],
    }.entries) {
      await GenUtils.saveSheet(
        relativePath: '$base/${entry.key}',
        frameWidth: 200,
        frameHeight: 180,
        frameCount: entry.value[0],
        drawFrame: (canvas, i, size) {
          final count = entry.value[0];
          final mode = entry.value[1];
          final t = mode == 1 || mode == 2
              ? (i / (count - 1))
              : (i / count);
          final phase = (i / count) * 2 * pi;
          drawHebi(
            canvas,
            Offset(size.width * 0.46, size.height - 8),
            sway: sin(phase) * 6.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // =========================================================================
  // BOSS 4: YUKI-ONI (THE GLACIAL TITAN WARLORD) — High-Detail 2D Cartoon
  // =========================================================================
  static Future<void> _generateBoss4YukiOni() async {
    const base = 'assets/images/bosses';

    void drawYuki(
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
          final ly = -36.0 - l * 32.0;
          canvas.drawLine(
            Offset(-92 - (l % 2) * 16.0, ly),
            Offset(-40, ly),
            GenUtils.stroke(iceBlue.withValues(alpha: 0.78), 3.4),
          );
        }
      }

      // 1. Swirling Cryo Blizzard Aura
      final auraPaint = Paint()
        ..color = iceBlue.withValues(alpha: (isCharge || isSlam) ? 0.46 : 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -96), width: 150, height: 175),
        auraPaint,
      );

      // 2. Colossal Frost-Armored Samurai Greaves & Spiked Sabatons (animated stride / lunge / kneel)
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
          const Rect.fromLTWH(-15, 0, 30, 46),
          8,
          GenUtils.darkNavy,
          topHighlight: darkIce,
          outlineWidth: 4.0,
        );
        GenUtils.drawCelCircle(
          canvas,
          const Offset(0, 16),
          9,
          iceBlue,
          highlightColor: Colors.white,
          outlineWidth: 3.0,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-17, 40, 34, 12),
          4,
          iceBlue,
          topHighlight: Colors.white,
          outlineWidth: 3.5,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 3. Jagged Crystalline Back-Glacier Spires jutting behind shoulders
      for (int sp = -2; sp <= 2; sp++) {
        final angle = sp * 0.28;
        canvas.save();
        canvas.translate(sp * 16.0, -126);
        canvas.rotate(angle);
        final spire = Path()
          ..moveTo(-10, 10)
          ..lineTo(0, -48 - (2 - sp.abs()) * 10.0)
          ..lineTo(10, 10)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          spire,
          darkIce,
          highlightColor: Colors.white,
          outlineWidth: 3.4,
        );
        canvas.restore();
      }

      // 4. Wild Flowing White Kabuki / Yeti Mane behind Helmet
      final manePath = Path()
        ..moveTo(-48, -148)
        ..lineTo(-68, -110)
        ..lineTo(-52, -88)
        ..lineTo(52, -88)
        ..lineTo(68, -110)
        ..lineTo(48, -148)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        manePath,
        const Color(0xFFE1F5FE),
        highlightColor: Colors.white,
        outlineWidth: 3.8,
      );

      // 5. Hulking Glacial Ō-Yoroi Samurai Cuirass & Kusazuri Tasset Skirt
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-44, -132, 88, 84),
        16,
        GenUtils.darkNavy,
        topHighlight: darkIce,
        outlineWidth: 4.5,
      );

      for (double y = -118; y <= -78; y += 18) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(-36, y, 72, 13),
          4,
          darkIce,
          topHighlight: iceBlue,
          outlineWidth: 3.0,
        );
      }

      for (int k = -1; k <= 1; k++) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(k * 26.0 - 11, -58, 22, 20),
          4,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.2,
        );
      }

      // Blazing Cryo-Furnace Core in Center of Chest
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -96),
        24,
        12,
        6,
        Colors.white,
        rotation: animProgress * pi,
        outlineWidth: 3.0,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -96),
        11,
        GenUtils.cyan,
        highlightColor: Colors.white,
        outlineWidth: 2.8,
      );

      // 6. Mammoth Ice-Horned Shoulder Pauldrons (Sode)
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.scale(side, 1.0);
        final pauldron = Path()
          ..moveTo(30, -130)
          ..lineTo(72, -148)
          ..lineTo(66, -110)
          ..lineTo(70, -94)
          ..lineTo(34, -90)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          pauldron,
          iceBlue,
          highlightColor: Colors.white,
          outlineWidth: 4.0,
        );
        canvas.restore();
      }

      // 7. Oni Warlord Dark-Iron Kabuto Helmet, Menpo Tusk Mask & Giant Glowing Cyan Ice Horns
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-28, -174, 56, 46),
        14,
        GenUtils.darkNavy,
        topHighlight: GenUtils.steelDark,
        outlineWidth: 4.2,
      );

      for (final side in [-1.0, 1.0]) {
        final horn = Path()
          ..moveTo(side * 18, -164)
          ..lineTo(side * 46, -182)
          ..lineTo(side * 52, -210)
          ..lineTo(side * 28, -192)
          ..lineTo(side * 10, -170)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          horn,
          iceBlue,
          highlightColor: Colors.white,
          outlineWidth: 3.8,
        );
      }

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-24, -148, 48, 20),
        6,
        GenUtils.ink,
        topHighlight: GenUtils.steelDark,
        outlineWidth: 3.5,
      );
      for (final side in [-1.0, 1.0]) {
        final tusk = Path()
          ..moveTo(side * 14, -134)
          ..lineTo(side * 23, -152)
          ..lineTo(side * 9, -136)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          tusk,
          Colors.white,
          outlineWidth: 2.5,
        );
      }

      for (final ex in [-10.0, 10.0]) {
        final eye = Path()
          ..moveTo(ex - 6, -158)
          ..lineTo(ex + 6, -155)
          ..lineTo(ex + 5, -149)
          ..lineTo(ex - 5, -152)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          eye,
          GenUtils.cyan,
          highlightColor: Colors.white,
          outlineWidth: 2.2,
        );
      }

      // 8. Colossal Spiked Frost-Iron Kanabo War Club (dynamic 150° smash arc!)
      double clubAngle = -0.55 + sin(animProgress * 2 * pi) * 0.06;
      if (isCharge) {
        clubAngle = -1.35 - sin(animProgress * pi) * 0.35;
      } else if (isSlam) {
        // Overhead windup (-1.75) -> full downward glacier smash (+0.85)!
        clubAngle = -1.75 + animProgress * 2.60;
      } else if (isStun) {
        clubAngle = 1.05 + sin(animProgress * 2 * pi) * 0.14;
      }

      canvas.save();
      canvas.translate(38, -98);
      canvas.rotate(clubAngle);

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-10, -10, 26, 20),
        6,
        GenUtils.goldDark,
        topHighlight: GenUtils.yellow,
        outlineWidth: 3.6,
      );

      final clubBody = Path()
        ..moveTo(14, -9)
        ..lineTo(96, -18)
        ..lineTo(108, 0)
        ..lineTo(96, 18)
        ..lineTo(14, 9)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        clubBody,
        darkIce,
        highlightColor: iceBlue,
        outlineWidth: 4.0,
      );

      for (double cx = 32; cx <= 88; cx += 18) {
        for (final side in [-1.0, 1.0]) {
          final stud = Path()
            ..moveTo(cx - 5, side * 12)
            ..lineTo(cx, side * 24)
            ..lineTo(cx + 5, side * 12)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            stud,
            Colors.white,
            outlineWidth: 2.5,
          );
        }
      }
      canvas.restore();

      // Slam Slash Arc & Ice Spikes
      if (isSlam && animProgress >= 0.30 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(28, -88),
          radius: 82,
          startAngle: -1.40 + (animProgress - 0.30) * 1.5,
          sweepAngle: 1.60,
          color: iceBlue,
        );
        if (animProgress >= 0.50) {
          for (int sp = 0; sp < 3; sp++) {
            final sx = 46.0 + sp * 16.0;
            final spike = Path()
              ..moveTo(sx - 8, 0)
              ..lineTo(sx, -26 - (2 - sp) * 6.0)
              ..lineTo(sx + 8, 0)
              ..close();
            GenUtils.drawCelPath(
              canvas,
              spike,
              iceBlue,
              highlightColor: Colors.white,
              outlineWidth: 2.8,
            );
          }
        }
      }

      canvas.restore(); // end torso tilt

      // Stun Mode Stars & Guard-Break Sparks
      if (isStun) {
        _drawStunSparksAndStars(
          canvas,
          animProgress: animProgress,
          starY: -196,
          starRadiusX: 44,
          bodyCenterY: -96,
        );
      }

      canvas.restore();
    }

    for (final entry in {
      'yuki_idle.png': [6, 0],
      'yuki_charge.png': [4, 1],
      'yuki_slam.png': [6, 2],
      'yuki_stun.png': [4, 3],
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
          drawYuki(
            canvas,
            Offset(size.width * 0.44, size.height - 8),
            bob: mode == 0 ? sin(phase) * 4.0 : 0.0,
            animProgress: t,
            mode: mode,
          );
        },
      );
    }
  }

  // =========================================================================
  // BOSS 5: MUZAN-KAI (LORD OF THE BLOOD ECLIPSE) — High-Detail 2D Cartoon
  // =========================================================================
  static Future<void> _generateBoss5MuzanKai() async {
    const base = 'assets/images/bosses';

    void drawMuzan(
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
          bodyDy = -6.0 * wt;
          torsoTilt = -0.18 * wt;
        } else {
          final st = ((animProgress - 0.30) / 0.70).clamp(0.0, 1.0);
          bodyDx = -10.0 + 26.0 * sin(st * pi * 0.65);
          bodyDy = 6.0 * sin(st * pi);
          torsoTilt = -0.18 + 0.42 * sin(st * pi * 0.75);
        }
      } else if (isCast) {
        bodyDy = -10.0 - sin(animProgress * pi) * 8.0;
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
          final ly = -35.0 - l * 32.0;
          canvas.drawLine(
            Offset(-90 - (l % 2) * 16.0, ly),
            Offset(-38, ly),
            GenUtils.stroke(GenUtils.red.withValues(alpha: 0.78), 3.4),
          );
        }
      }

      // 1. Rotating Celestial Blood-Eclipse Halo & Golden Sunburst behind Overlord
      GenUtils.drawCartoonStar(
        canvas,
        const Offset(0, -118),
        84 + (isCast ? sin(animProgress * pi) * 10.0 : 0.0),
        52,
        12,
        GenUtils.gold.withValues(alpha: 0.8),
        rotation: animProgress * pi,
        outlineWidth: 3.4,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -118),
        46,
        GenUtils.ink,
        highlightColor: GenUtils.darkRed,
        outlineWidth: 4.0,
      );

      // 2. Flowing Tattered Blood-Emperor Cape & Armored Hakama Greaves
      final cape = Path()
        ..moveTo(-34, -126)
        ..lineTo(34, -126)
        ..lineTo(52, -10)
        ..lineTo(24, -24)
        ..lineTo(0, -8)
        ..lineTo(-24, -24)
        ..lineTo(-52, -10)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        cape,
        GenUtils.darkRed,
        highlightColor: GenUtils.red,
        outlineWidth: 4.0,
      );

      // Imperial Obsidian & Gold Samurai Hakama Legs (animated lunge / kneel)
      for (final side in [-1.0, 1.0]) {
        double lx = side * 18.0;
        double ly = 0.0;
        double legRot = 0.0;
        if (isSlash && animProgress >= 0.30) {
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
          const Rect.fromLTWH(-13, 0, 26, 48),
          6,
          GenUtils.ink,
          topHighlight: GenUtils.darkPurple,
          outlineWidth: 3.8,
        );
        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-14, 42, 28, 10),
          4,
          GenUtils.gold,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.2,
        );
        canvas.restore();
      }

      // Upper body pivot
      canvas.save();
      canvas.translate(0, -56);
      canvas.rotate(torsoTilt);
      canvas.translate(0, 56);

      // 3. Six Articulated Obsidian & Crimson Archfiend Dragon Wings (3 pairs)
      for (final side in [-1.0, 1.0]) {
        for (int w = 0; w < 3; w++) {
          canvas.save();
          canvas.translate(side * 22.0, -124.0 + w * 20.0);
          canvas.scale(side, 1.0);
          final wingFlap = isCast
              ? sin(animProgress * 2 * pi + w) * 0.25
              : (isStun ? 0.32 : sin(animProgress * 2 * pi + w) * 0.10);
          canvas.rotate((w - 1) * 0.25 + wingFlap);

          final wing = Path()
            ..moveTo(0, 0)
            ..lineTo(68 - w * 8.0, -34 + w * 10.0)
            ..lineTo(56 - w * 6.0, -4 + w * 8.0)
            ..lineTo(36, 12)
            ..close();
          GenUtils.drawCelPath(
            canvas,
            wing,
            GenUtils.ink,
            highlightColor: GenUtils.red,
            outlineWidth: 3.5,
          );
          canvas.restore();
        }
      }

      // 4. Ornate Black-and-Gold Shogun Overlord Cuirass & Eclipse Chest Eye
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-32, -128, 64, 78),
        12,
        GenUtils.ink,
        topHighlight: GenUtils.darkPurple,
        outlineWidth: 4.2,
      );
      for (double y = -116; y <= -76; y += 13) {
        canvas.drawLine(
          Offset(-24, y),
          Offset(24, y),
          GenUtils.stroke(GenUtils.gold, 3.0),
        );
      }
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -94),
        14,
        GenUtils.gold,
        outlineWidth: 3.2,
      );
      GenUtils.drawCelCircle(
        canvas,
        const Offset(0, -94),
        9,
        GenUtils.red,
        highlightColor: GenUtils.yellow,
        outlineWidth: 2.5,
      );

      // 5. Spiked Golden Archfiend Shoulder Pauldrons
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.scale(side, 1.0);
        final sode = Path()
          ..moveTo(22, -128)
          ..lineTo(62, -146)
          ..lineTo(54, -106)
          ..lineTo(26, -96)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          sode,
          GenUtils.goldDark,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.8,
        );
        canvas.restore();
      }

      // 6. Obsidian Samurai Kabuto Mask, Menpo Tusks & Blazing Eclipse V-Horns
      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-26, -172, 52, 46),
        14,
        GenUtils.ink,
        topHighlight: GenUtils.steelDark,
        outlineWidth: 4.0,
      );

      for (final side in [-1.0, 1.0]) {
        GenUtils.drawCelRRect(
          canvas,
          Rect.fromLTWH(side * 24 - 6, -162, 12, 26),
          3,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.0,
        );
      }

      GenUtils.drawCelRRect(
        canvas,
        const Rect.fromLTWH(-20, -146, 40, 18),
        5,
        GenUtils.darkRed,
        topHighlight: GenUtils.red,
        outlineWidth: 3.2,
      );
      for (final side in [-1.0, 1.0]) {
        final fang = Path()
          ..moveTo(side * 11, -132)
          ..lineTo(side * 17, -146)
          ..lineTo(side * 7, -134)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          fang,
          GenUtils.gold,
          highlightColor: Colors.white,
          outlineWidth: 2.2,
        );
      }

      for (final ex in [-9.0, 9.0]) {
        final eye = Path()
          ..moveTo(ex - 6, -156)
          ..lineTo(ex + 6, -153)
          ..lineTo(ex + 5, -147)
          ..lineTo(ex - 5, -150)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          eye,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 2.0,
        );
      }

      final crown = Path()
        ..moveTo(0, -164)
        ..lineTo(-42, -206)
        ..lineTo(-24, -168)
        ..lineTo(0, -182)
        ..lineTo(24, -168)
        ..lineTo(42, -206)
        ..close();
      GenUtils.drawCelPath(
        canvas,
        crown,
        GenUtils.orange,
        highlightColor: GenUtils.yellow,
        outlineWidth: 3.8,
      );

      // 7. Dual Cursed Blood-Moon Odachi Katanas (dynamic sweep across frames!)
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
        canvas.translate(isRight ? 30 : -30, -96);
        canvas.rotate(isRight ? rAngle : lAngle);

        GenUtils.drawCelRRect(
          canvas,
          const Rect.fromLTWH(-4, -5, 24, 10),
          3,
          GenUtils.goldDark,
          topHighlight: GenUtils.yellow,
          outlineWidth: 3.0,
        );

        final odachi = Path()
          ..moveTo(18, -7)
          ..lineTo(96, -5)
          ..lineTo(112, 0)
          ..lineTo(96, 7)
          ..lineTo(18, 7)
          ..close();
        GenUtils.drawCelPath(
          canvas,
          odachi,
          GenUtils.red,
          highlightColor: GenUtils.yellow,
          outlineWidth: 3.8,
        );
        canvas.drawLine(
          const Offset(22, 0),
          const Offset(98, 0),
          GenUtils.stroke(GenUtils.ink, 3.2),
        );
        canvas.restore();
      }

      if (isSlash && animProgress >= 0.25 && animProgress <= 0.88) {
        _drawSlashArc(
          canvas,
          center: const Offset(24, -84),
          radius: 78,
          startAngle: -1.35 + (animProgress - 0.25) * 1.5,
          sweepAngle: 1.60,
          color: GenUtils.red,
        );
      }

      // Guard Mode: Blood-Eclipse Hex Barrier Shield
      if (isGuard) {
        final shieldRect =
            Rect.fromCenter(center: const Offset(0, -96), width: 110, height: 140);
        canvas.drawOval(
          shieldRect,
          GenUtils.fill(GenUtils.red.withValues(alpha: 0.28)),
        );
        canvas.drawOval(shieldRect, GenUtils.stroke(GenUtils.gold, 3.8));
      }

      canvas.restore(); // end torso tilt

      // Stun Mode: Circling Stars & Guard-Break Sparks
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
      'muzan_idle.png': [6, 0],
      'muzan_slash.png': [5, 1],
      'muzan_cast.png': [5, 2],
      'muzan_guard.png': [4, 3],
      'muzan_stun.png': [4, 4],
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
          drawMuzan(
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
}
