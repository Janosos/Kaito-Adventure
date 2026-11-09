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
  static final Vector2 spawnPosition = Vector2(80, 480);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Rooftop Backdrop
    add(MangaRooftopBackdrop());

    // --- SECTION 1: Starting Rooftops ---
    add(ComicPlatform(
      position: Vector2(20, 500),
      size: Vector2(340, 60),
    ));

    add(EnemyGrunt(position: Vector2(220, 500), patrolDistance: 80));
    add(InkScroll(position: Vector2(160, 440)));

    add(ComicPlatform(
      position: Vector2(400, 420),
      size: Vector2(180, 30),
    ));
    add(InkScroll(position: Vector2(490, 380)));

    add(MangaSpringPad(
      position: Vector2(530, 420),
      launchPower: 580,
    ));

    add(EnemyDrone(
      position: Vector2(650, 260),
      flyRange: 90,
    ));

    add(ComicPlatform(
      position: Vector2(640, 330),
      size: Vector2(160, 30),
    ));
    add(RamenBowl(position: Vector2(720, 290)));

    add(ComicPlatform(
      position: Vector2(840, 400),
      size: Vector2(130, 26),
      isMoving: true,
      moveRange: Vector2(120, -50),
      moveSpeed: 1.6,
    ));

    // --- SECTION 2: Crumbling Rooftops & Traps ---
    add(ComicPlatform(
      position: Vector2(1100, 460),
      size: Vector2(100, 26),
      isCrumbling: true,
    ));

    add(ComicPlatform(
      position: Vector2(1240, 430),
      size: Vector2(100, 26),
      isCrumbling: true,
    ));

    add(SpikeTrap(
      position: Vector2(1100, 580),
      spikeCount: 16,
    ));

    add(ComicPlatform(
      position: Vector2(1380, 460),
      size: Vector2(300, 50),
    ));
    add(EnemyGrunt(position: Vector2(1460, 460), patrolDistance: 60));
    add(EnemyGrunt(position: Vector2(1600, 460), patrolDistance: 50));
    add(InkScroll(position: Vector2(1520, 410)));

    add(InkSawBlade(
      position: Vector2(1740, 380),
      patrolOffset: Vector2(0, 70),
      patrolSpeed: 2.5,
    ));

    add(ToriiGateExit(
      position: Vector2(1820, 460),
      onEnter: () {
        _enterBossArena();
      },
    ));

    // --- SECTION 3: Boss Arena (Moonlit Shrine Rooftop) ---
    add(ComicPlatform(
      position: Vector2(2000, 520),
      size: Vector2(800, 80),
    ));

    add(ComicPlatform(
      position: Vector2(1970, 150),
      size: Vector2(30, 450),
    ));
    add(ComicPlatform(
      position: Vector2(2800, 150),
      size: Vector2(30, 450),
    ));

    add(ComicPlatform(
      position: Vector2(2120, 380),
      size: Vector2(110, 22),
    ));
    add(ComicPlatform(
      position: Vector2(2570, 380),
      size: Vector2(110, 22),
    ));

    add(BossKurokage(
      position: Vector2(2500, 520),
    ));
  }

  void _enterBossArena() {
    game.player.position = Vector2(2080, 480);
    game.currentSpawnPoint = Vector2(2080, 480);
    game.triggerBossCutIn(
      bossName: 'KUROKAGE',
      quote: 'THE MOON SHALL WEEP INK TONIGHT...',
      portraitColor: ComicTheme.darkPurple,
      portraitAsset: CartoonAssets.portraitKurokage,
    );
  }
}

/// 2D Cartoon Rooftops Backdrop Component
class MangaRooftopBackdrop extends Component with HasGameReference<MangaGame> {
  late final Sprite _bgSprite;

  MangaRooftopBackdrop() {
    priority = 100;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bgSprite = CartoonAssets.sprite(
      game.images,
      'illustrations/bg_level1_rooftops.jpg',
    );
  }

  @override
  void render(Canvas canvas) {
    // Render tiled 2D cartoon rooftop panoramic panels across the level
    const panelW = 1120.0;
    const panelH = 680.0;
    for (int i = -1; i < 4; i++) {
      canvas.save();
      if (i % 2 != 0) {
        // Mirror alternating panels for seamless panoramic horizon
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

    // Subtle atmospheric contrast wash so foreground cartoon characters pop
    canvas.drawRect(
      const Rect.fromLTWH(-500, -100, 4500, 900),
      Paint()..color = const Color(0x280D1322),
    );
  }
}
