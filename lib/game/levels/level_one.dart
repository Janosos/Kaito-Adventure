import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import '../components/platform.dart';
import '../components/traps.dart';
import '../components/collectibles.dart';
import '../components/enemies/enemy_grunt.dart';
import '../components/enemies/enemy_drone.dart';
import '../components/bosses/boss_kurokage.dart';

class LevelOne extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 470);
  static const double levelWidth = 4620.0;
  static const double bossArenaTriggerX = 3650.0;
  static const double arenaCenterX = 4140.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Rooftop Backdrop (GPU-Culled Tiling)
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level1_rooftops.jpg',
      tintColor: const Color(0x280D1322),
    ));

    // =========================================================================
    // ZONE 1: Opening Neo-Tokyo Pagoda Eaves (x: 0 .. 900)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 480),
      size: Vector2(390, 60),
    ));
    add(BreakableCrate(position: Vector2(180, 480)));
    add(EnemyGrunt(
      position: Vector2(275, 480),
      minXBound: 195,
      maxXBound: 360,
    ));
    add(InkScroll(position: Vector2(340, 430)));

    add(ComicPlatform(
      position: Vector2(430, 410),
      size: Vector2(200, 28),
    ));
    add(InkScroll(position: Vector2(490, 365)));
    add(MangaSpringPad(
      position: Vector2(585, 410),
      launchPower: 570,
    ));

    add(ComicPlatform(
      position: Vector2(650, 285),
      size: Vector2(230, 28),
    ));
    add(EnemyDrone(
      position: Vector2(755, 205),
      flyRange: 75,
    ));
    add(BreakableCrate(position: Vector2(820, 285), dropsRamen: true));

    // =========================================================================
    // ZONE 2: Vertical Wall-Jump Pagoda Chimney & Locked Gate (x: 920 .. 1760)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(930, 460),
      size: Vector2(560, 65),
    ));
    add(CheckpointLantern(position: Vector2(980, 460)));
    add(EnemyGrunt(
      position: Vector2(1150, 460),
      minXBound: 1030,
      maxXBound: 1320,
    ));

    // Twin Vertical Chimney Walls for Shinobi Wall-Kick Ascent!
    add(ComicPlatform(
      position: Vector2(1180, 220),
      size: Vector2(36, 175),
    ));
    add(ComicPlatform(
      position: Vector2(1310, 190),
      size: Vector2(36, 205),
    ));
    // Upper Pagoda Roof at top of the Chimney
    add(ComicPlatform(
      position: Vector2(1310, 190),
      size: Vector2(210, 24),
    ));

    final gate1 = GateBarrier(position: Vector2(1445, 460));
    add(gate1);
    add(SwitchOrb(
      position: Vector2(1450, 190),
      targetGate: gate1,
    ));
    add(InkScroll(position: Vector2(1380, 145)));

    add(ComicPlatform(
      position: Vector2(1540, 410),
      size: Vector2(180, 26),
    ));
    add(EnemyGrunt(
      position: Vector2(1630, 410),
      minXBound: 1555,
      maxXBound: 1700,
    ));

    // =========================================================================
    // ZONE 3: Neon Rooftop Zipline Chasm (x: 1760 .. 2720) — LEVEL 1 EXCLUSIVE!
    // =========================================================================
    // First Neon Zipline Rail across the wide Neo-Tokyo street abyss
    add(ZipLineLanternRail(
      startX: 1730,
      endX: 2160,
      railY: 280,
      glideSpeed: 390,
    ));
    add(InkScroll(position: Vector2(1880, 315)));
    add(InkScroll(position: Vector2(2020, 315)));
    add(EnemyDrone(position: Vector2(1960, 210), flyRange: 80));

    // Mid-Chasm Pagoda Tower
    add(ComicPlatform(
      position: Vector2(2140, 370),
      size: Vector2(190, 30),
    ));
    add(CheckpointLantern(position: Vector2(2210, 370)));
    add(BreakableCrate(position: Vector2(2285, 370), dropsRamen: true));

    // Second Neon Zipline Rail climbing higher
    add(ZipLineLanternRail(
      startX: 2330,
      endX: 2730,
      railY: 250,
      glideSpeed: 400,
    ));
    add(InkScroll(position: Vector2(2480, 285)));
    add(InkScroll(position: Vector2(2610, 285)));

    // =========================================================================
    // ZONE 4: Taiko Bounce Drum Sky-Chain & Pre-Boss Roof (x: 2730 .. 3660)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(2720, 380),
      size: Vector2(210, 30),
    ));
    add(EnemyGrunt(
      position: Vector2(2820, 380),
      minXBound: 2740,
      maxXBound: 2905,
    ));

    // Rhythm Chain of 3 Mid-Air Taiko Bounce Drums over Spiked Lower Roof!
    add(TaikoBounceDrum(position: Vector2(3000, 350), bounceForce: 540));
    add(InkScroll(position: Vector2(3065, 240)));
    add(TaikoBounceDrum(position: Vector2(3130, 320), bounceForce: 540));
    add(InkScroll(position: Vector2(3195, 210)));
    add(TaikoBounceDrum(position: Vector2(3260, 350), bounceForce: 560));

    // Spiked Safety Floor underneath the Taiko Drum Chain
    add(ComicPlatform(
      position: Vector2(2950, 515),
      size: Vector2(370, 30),
    ));
    add(SpikeTrap(position: Vector2(2970, 515), spikeCount: 20));

    // Final Pre-Boss Rooftop Approach
    add(ComicPlatform(
      position: Vector2(3340, 450),
      size: Vector2(340, 70),
    ));
    add(EnemyGrunt(
      position: Vector2(3450, 450),
      minXBound: 3365,
      maxXBound: 3540,
    ));
    add(RamenBowl(position: Vector2(3545, 405)));
    add(CheckpointLantern(position: Vector2(3590, 450)));

    add(ToriiGateExit(
      position: Vector2(3645, 450),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 5: Kurokage Boss Arena (x: 3700 .. 4600)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(3700, 480),
      size: Vector2(900, 60),
    ));
    add(ComicPlatform(
      position: Vector2(3840, 355),
      size: Vector2(140, 22),
    ));
    add(ComicPlatform(
      position: Vector2(4300, 355),
      size: Vector2(140, 22),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_bossSpawned && game.player.position.x >= bossArenaTriggerX) {
      _enterBossArena();
    }
  }

  void _enterBossArena() {
    if (_bossSpawned) return;
    _bossSpawned = true;

    if (game.player.position.x < 3760) {
      game.player.position = Vector2(3780, 460);
    }
    game.currentSpawnPoint = Vector2(3780, 460);
    game.lockToBossArena(minX: 3730, maxX: 4560);

    add(BossKurokage(
      position: Vector2(4320, 480),
      arenaMinX: 3740,
      arenaMaxX: 4540,
    ));

    game.triggerBossCutIn(
      bossName: 'KUROKAGE',
      quote: 'THE MOON SHALL WEEP INK TONIGHT...',
      portraitColor: ComicTheme.darkPurple,
      portraitAsset: CartoonAssets.portraitKurokage,
    );
  }
}

/// GPU-Culled 2D Cartoon Panoramic Tiled Backdrop Component
/// Only draws the 2 visible panels inside the camera frustum for 60/120 FPS on Mali/Adreno/Web!
class MangaTiledBackdrop extends Component with HasGameReference<MangaGame> {
  final String assetPath;
  final Color tintColor;
  late final Sprite _bgSprite;
  late final Paint _tintPaint;

  MangaTiledBackdrop({
    required this.assetPath,
    required this.tintColor,
  }) {
    priority = 100;
  }

  @override
  Future<void> onLoad() async {
    _bgSprite = CartoonAssets.sprite(game.images, assetPath);
    _tintPaint = Paint()..color = tintColor;
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    const panelW = 1120.0;
    const panelH = 680.0;
    final camX = game.camera.viewfinder.position.x;
    final firstTile = ((camX - 620.0) / panelW).floor();
    final lastTile = ((camX + 620.0) / panelW).floor();

    for (int i = firstTile; i <= lastTile; i++) {
      canvas.save();
      if (i.isOdd) {
        canvas.translate((i + 1) * panelW, -40);
        canvas.scale(-1, 1);
        _bgSprite.render(
          canvas,
          position: Vector2.zero(),
          size: Vector2(panelW, panelH),
        );
      } else {
        _bgSprite.render(
          canvas,
          position: Vector2(i * panelW, -40),
          size: Vector2(panelW, panelH),
        );
      }
      canvas.restore();
    }

    canvas.drawRect(
      Rect.fromLTWH(camX - 560.0, -60, 1120.0, 660.0),
      _tintPaint,
    );
  }
}
