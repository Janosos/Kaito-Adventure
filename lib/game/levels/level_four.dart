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
import '../components/enemies/enemy_oni_archer.dart';
import '../components/bosses/boss_yuki_oni.dart';
import 'level_one.dart';

class LevelFour extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 5820.0;
  static const double bossArenaTriggerX = 4850.0;
  static const double arenaCenterX = 5340.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Frozen Oni Peaks Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level4_peaks.png',
      tintColor: const Color(0x2204162C),
    ));

    // =========================================================================
    // ZONE 1: Frozen Foothills & Slippery Ice Ledges (x: 0 .. 1140)
    // Raised starting platform (y: 390) so Kaito is clearly visible above mobile thumb/joystick!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
      isSlipperyIce: true,
    ));
    add(EnemyGrunt(
      position: Vector2(215, 390),
      minXBound: 130,
      maxXBound: 330,
      maxHp: 55,
    ));
    add(BreakableCrate(position: Vector2(310, 390)));

    add(ComicPlatform(
      position: Vector2(400, 410),
      size: Vector2(180, 26),
      isSlipperyIce: true,
    ));
    add(FallingIcicleTrap(position: Vector2(490, 140), maxFallY: 410));

    add(TaikoBounceDrum(position: Vector2(640, 360)));

    add(ComicPlatform(
      position: Vector2(710, 270),
      size: Vector2(350, 26),
      isSlipperyIce: true,
    ));
    add(EnemyOniArcher(position: Vector2(860, 270)));
    add(InkScroll(position: Vector2(770, 225)));
    add(BreakableCrate(position: Vector2(960, 270), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(1015, 270)));

    // =========================================================================
    // ZONE 2: Glacial Icicle Cavern Tunnel (x: 1120 .. 2400) — LEVEL 4 EXCLUSIVE!
    // =========================================================================
    // Overhanging Ice Cavern Ceiling studded with Falling Icicle Traps!
    add(ComicPlatform(
      position: Vector2(1140, 95),
      size: Vector2(1180, 32),
      isSlipperyIce: true,
    ));
    add(FallingIcicleTrap(position: Vector2(1240, 127), maxFallY: 460));
    add(FallingIcicleTrap(position: Vector2(1410, 127), maxFallY: 460));
    add(FallingIcicleTrap(position: Vector2(1610, 127), maxFallY: 420));
    add(FallingIcicleTrap(position: Vector2(1820, 127), maxFallY: 420));
    add(FallingIcicleTrap(position: Vector2(2040, 127), maxFallY: 460));
    add(FallingIcicleTrap(position: Vector2(2210, 127), maxFallY: 460));

    // Slippery Ice Cavern Floor & Crumbling Ice Bridges
    add(ComicPlatform(
      position: Vector2(1120, 460),
      size: Vector2(380, 65),
      isSlipperyIce: true,
    ));
    add(EnemyGrunt(
      position: Vector2(1320, 460),
      minXBound: 1160,
      maxXBound: 1460,
      maxHp: 60,
    ));

    add(ComicPlatform(
      position: Vector2(1550, 420),
      size: Vector2(125, 24),
      isCrumbling: true,
    ));
    add(InkScroll(position: Vector2(1610, 370)));
    add(ComicPlatform(
      position: Vector2(1740, 420),
      size: Vector2(125, 24),
      isCrumbling: true,
    ));
    add(InkScroll(position: Vector2(1800, 370)));

    // Spiked Ice Trench below the Crumbling Bridges
    add(ComicPlatform(
      position: Vector2(1520, 515),
      size: Vector2(380, 30),
    ));
    add(SpikeTrap(position: Vector2(1540, 515), spikeCount: 21));

    add(ComicPlatform(
      position: Vector2(1920, 460),
      size: Vector2(440, 65),
      isSlipperyIce: true,
    ));
    add(EnemyOniArcher(position: Vector2(2140, 460)));
    add(RamenBowl(position: Vector2(2260, 415)));
    add(CheckpointLantern(position: Vector2(2315, 460)));

    // =========================================================================
    // ZONE 3: Howling Blizzard Ridge & Ice Fortress Gate (x: 2400 .. 3660) — LEVEL 4 EXCLUSIVE!
    // =========================================================================
    // Howling Blizzard Crosswind pushing Kaito back (-95 px/s headwind)!
    add(BlizzardWindZone(
      position: Vector2(2420, 140),
      size: Vector2(1180, 350),
      windSpeedX: -95.0,
    ));

    add(ComicPlatform(
      position: Vector2(2420, 380),
      size: Vector2(140, 24),
      isMoving: true,
      moveRange: Vector2(150, 0),
      moveSpeed: 2.1,
    ));
    add(EnemyDrone(position: Vector2(2560, 210), flyRange: 90, flySpeed: 2.2));

    add(ComicPlatform(
      position: Vector2(2760, 460),
      size: Vector2(820, 65),
      isSlipperyIce: true,
    ));
    add(InkSawBlade(
      position: Vector2(2920, 410),
      patrolOffset: Vector2(100, 0),
      patrolSpeed: 2.5,
    ));
    add(EnemyGrunt(
      position: Vector2(3180, 460),
      minXBound: 3060,
      maxXBound: 3320,
      maxHp: 60,
    ));

    final gate4 = GateBarrier(position: Vector2(3490, 460));
    add(gate4);

    add(WindUpdraftVent(
      position: Vector2(2840, 460),
      liftHeight: 215,
    ));
    add(ComicPlatform(
      position: Vector2(2920, 250),
      size: Vector2(340, 24),
      isSlipperyIce: true,
    ));
    add(EnemyOniArcher(position: Vector2(3090, 250)));
    add(SwitchOrb(
      position: Vector2(3210, 250),
      targetGate: gate4,
    ));
    add(InkScroll(position: Vector2(2980, 205)));

    // =========================================================================
    // ZONE 4: Shattered Peak Ascent & Saw Gauntlet (x: 3640 .. 4860)
    // =========================================================================
    add(CheckpointLantern(position: Vector2(3545, 460)));

    // Tailwind Blizzard Gust (+105 px/s) helping Kaito leap across wide glacial chasms!
    add(BlizzardWindZone(
      position: Vector2(3640, 160),
      size: Vector2(620, 330),
      windSpeedX: 105.0,
    ));

    add(ComicPlatform(
      position: Vector2(3650, 415),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(TaikoBounceDrum(position: Vector2(3860, 355)));
    add(ComicPlatform(
      position: Vector2(3960, 385),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(TaikoBounceDrum(position: Vector2(4170, 345)));

    // Spiked Ice Floor under the Tailwind Chasm
    add(ComicPlatform(
      position: Vector2(3630, 515),
      size: Vector2(620, 30),
    ));
    add(SpikeTrap(position: Vector2(3645, 515), spikeCount: 36));

    // Final Pre-Boss Glacial Approach
    add(ComicPlatform(
      position: Vector2(4270, 455),
      size: Vector2(610, 65),
      isSlipperyIce: true,
    ));
    add(EnemyOniArcher(position: Vector2(4410, 455)));
    add(InkSawBlade(
      position: Vector2(4540, 395),
      patrolOffset: Vector2(0, -65),
      patrolSpeed: 2.7,
    ));
    add(EnemyGrunt(
      position: Vector2(4660, 455),
      minXBound: 4590,
      maxXBound: 4740,
      maxHp: 60,
    ));
    add(RamenBowl(position: Vector2(4745, 410)));
    add(CheckpointLantern(position: Vector2(4795, 455)));

    add(ToriiGateExit(
      position: Vector2(4845, 455),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 5: Frost Titan Boss Arena (x: 4900 .. 5800)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4900, 485),
      size: Vector2(900, 60),
      isSlipperyIce: true,
    ));
    add(ComicPlatform(
      position: Vector2(5020, 355),
      size: Vector2(140, 22),
      isSlipperyIce: true,
    ));
    add(ComicPlatform(
      position: Vector2(5510, 355),
      size: Vector2(140, 22),
      isSlipperyIce: true,
    ));
    add(ComicPlatform(
      position: Vector2(5265, 250),
      size: Vector2(130, 22),
      isSlipperyIce: true,
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

    if (game.player.position.x < 4960) {
      game.player.position = Vector2(4980, 460);
    }
    game.currentSpawnPoint = Vector2(4980, 460);
    game.lockToBossArena(minX: 4930, maxX: 5760);

    add(BossYukiOni(
      position: Vector2(5550, 485),
      arenaMinX: 4940,
      arenaMaxX: 5740,
    ));

    game.triggerBossCutIn(
      bossName: 'YUKI-ONI',
      quote: 'NONE SHALL SURVIVE THE FROZEN WRATH OF THE ONI PEAKS!!',
      portraitColor: ComicTheme.energyCyan,
      portraitAsset: CartoonAssets.portraitYukiOni,
    );
  }
}
