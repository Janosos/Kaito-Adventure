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
import '../components/bosses/boss_ryu_kotei.dart';
import '../components/projectiles.dart';

class LevelTwo extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 500);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Crimson Citadel Backdrop
    add(MangaCitadelBackdrop());

    // --- SECTION 1: Fortress Ramparts ---
    add(ComicPlatform(
      position: Vector2(20, 520),
      size: Vector2(300, 60),
      fillColor: const Color(0xFFFBE9E7),
    ));

    add(EnemyGrunt(position: Vector2(200, 520), patrolDistance: 70));
    add(InkScroll(position: Vector2(130, 460)));

    add(ComicPlatform(
      position: Vector2(360, 440),
      size: Vector2(110, 24),
    ));
    add(ComicPlatform(
      position: Vector2(260, 360),
      size: Vector2(110, 24),
    ));
    add(RamenBowl(position: Vector2(310, 320)));

    add(MangaSpringPad(
      position: Vector2(310, 360),
      launchPower: 620,
    ));

    add(ComicPlatform(
      position: Vector2(480, 250),
      size: Vector2(240, 26),
    ));
    add(EnemyGrunt(position: Vector2(600, 250), patrolDistance: 80));
    add(InkScroll(position: Vector2(520, 200)));

    add(EnemyDrone(position: Vector2(820, 220), flyRange: 80));

    add(ComicPlatform(
      position: Vector2(760, 340),
      size: Vector2(120, 24),
      isMoving: true,
      moveRange: Vector2(150, 0),
      moveSpeed: 1.8,
    ));

    add(InkSawBlade(
      position: Vector2(850, 430),
      radius: 28,
      patrolOffset: Vector2(60, 0),
    ));

    // --- SECTION 2: The Fiery Gauntlet ---
    add(ComicPlatform(
      position: Vector2(1060, 480),
      size: Vector2(360, 50),
      fillColor: const Color(0xFFFBE9E7),
    ));

    add(BossFlamePillar(
      position: Vector2(1160, 480),
      eruptDelay: 1.0,
      activeDuration: 1.2,
    ));
    add(BossFlamePillar(
      position: Vector2(1320, 480),
      eruptDelay: 2.2,
      activeDuration: 1.2,
    ));

    add(EnemyGrunt(position: Vector2(1240, 480), patrolDistance: 40));
    add(InkScroll(position: Vector2(1380, 430)));

    add(ComicPlatform(
      position: Vector2(1460, 440),
      size: Vector2(90, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(1580, 410),
      size: Vector2(90, 24),
      isCrumbling: true,
    ));

    add(SpikeTrap(
      position: Vector2(1440, 580),
      spikeCount: 18,
    ));

    add(ComicPlatform(
      position: Vector2(1700, 450),
      size: Vector2(180, 40),
    ));
    add(ToriiGateExit(
      position: Vector2(1790, 450),
      onEnter: () {
        _enterDragonCrucible();
      },
    ));

    // --- SECTION 3: Dragon Shogun Boss Arena (The Dragon Crucible) ---
    add(ComicPlatform(
      position: Vector2(2000, 520),
      size: Vector2(920, 80),
      fillColor: const Color(0xFFFBE9E7),
    ));

    add(ComicPlatform(
      position: Vector2(1970, 100),
      size: Vector2(30, 500),
    ));
    add(ComicPlatform(
      position: Vector2(2920, 100),
      size: Vector2(30, 500),
    ));

    add(ComicPlatform(
      position: Vector2(2120, 360),
      size: Vector2(130, 24),
    ));
    add(ComicPlatform(
      position: Vector2(2670, 360),
      size: Vector2(130, 24),
    ));

    add(ComicPlatform(
      position: Vector2(2400, 250),
      size: Vector2(120, 22),
    ));

    add(BossRyuKotei(
      position: Vector2(2620, 520),
    ));
  }

  void _enterDragonCrucible() {
    game.player.position = Vector2(2080, 480);
    game.currentSpawnPoint = Vector2(2080, 480);
    game.triggerBossCutIn(
      bossName: 'RYU-KOTEI',
      quote: 'WHO DARES TREAD UPON THE DRAGON THRONE?!',
      portraitColor: ComicTheme.actionRed,
      portraitAsset: CartoonAssets.portraitRyuKotei,
    );
  }
}

/// 2D Cartoon Citadel Backdrop Component
class MangaCitadelBackdrop extends Component with HasGameReference<MangaGame> {
  late final Sprite _bgSprite;

  MangaCitadelBackdrop() {
    priority = 100;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bgSprite = CartoonAssets.sprite(
      game.images,
      'illustrations/bg_level2_citadel.jpg',
    );
  }

  @override
  void render(Canvas canvas) {
    const panelW = 1120.0;
    const panelH = 680.0;
    for (int i = -1; i < 4; i++) {
      canvas.save();
      if (i % 2 != 0) {
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
      const Rect.fromLTWH(-500, -100, 4500, 900),
      Paint()..color = const Color(0x241B0808),
    );
  }
}
