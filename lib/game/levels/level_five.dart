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
import '../components/bosses/boss_muzan_kai.dart';
import 'level_one.dart';

class LevelFive extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 6420.0;
  static const double bossArenaTriggerX = 5450.0;
  static const double arenaCenterX = 5940.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Celestial Eclipse Sanctum Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level5_sanctum.png',
      tintColor: const Color(0x26120424),
    ));

    // =========================================================================
    // ZONE 1: Astral Torii Approach & Obsidian Courtyards (x: 0 .. 1100)
    // Raised starting platform (y: 390) so Kaito is clearly visible above mobile thumb/joystick!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(165, 390)));
    add(EnemyGrunt(
      position: Vector2(260, 390),
      minXBound: 180,
      maxXBound: 335,
      maxHp: 60,
    ));

    add(MangaSpringPad(position: Vector2(315, 390), launchPower: 610));

    add(ComicPlatform(
      position: Vector2(395, 290),
      size: Vector2(240, 26),
    ));
    add(EnemyOniArcher(position: Vector2(530, 290)));
    add(InkScroll(position: Vector2(455, 245)));

    add(TaikoBounceDrum(position: Vector2(695, 340)));
    add(ComicPlatform(
      position: Vector2(760, 250),
      size: Vector2(280, 24),
    ));
    add(BreakableCrate(position: Vector2(860, 250), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(960, 250)));

    // =========================================================================
    // ZONE 2: Dimensional Eclipse Warp Vaults (x: 1100 .. 2280) — LEVEL 5 EXCLUSIVE!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1100, 460),
      size: Vector2(1050, 65),
    ));
    add(EnemyGrunt(
      position: Vector2(1260, 460),
      minXBound: 1150,
      maxXBound: 1380,
      maxHp: 65,
    ));

    // Sealed High Sanctum Vault (unreachable without the Dimensional Warp Portal!)
    add(ComicPlatform(
      position: Vector2(1380, 195),
      size: Vector2(460, 24),
    ));
    add(EnemyOniArcher(position: Vector2(1580, 195)));
    add(InkScroll(position: Vector2(1490, 150)));
    add(RamenBowl(position: Vector2(1660, 150)));

    // Dimensional Warp Portal #1: Teleports Kaito from lower courtyard (x=1420, y=460)
    // up into the Sealed High Sanctum Vault (x=1430, y=190)!
    add(EclipseWarpPortal(
      position: Vector2(1420, 460),
      targetDestination: Vector2(1430, 190),
      portalColor: ComicTheme.actionRed,
    ));

    // Twin-Sealed Astral Gates blocking the lower floor!
    final gate5A = GateBarrier(position: Vector2(1980, 460));
    final gate5B = GateBarrier(position: Vector2(2035, 460));
    add(gate5A);
    add(gate5B);

    // Switch Orb #1 inside the High Sanctum Vault
    add(SwitchOrb(
      position: Vector2(1780, 195),
      targetGate: gate5A,
    ));

    // Switch Orb #2 on the Lower Sanctum Floor guarded by Saws &Magma
    add(InkSawBlade(
      position: Vector2(1680, 410),
      patrolOffset: Vector2(95, 0),
      patrolSpeed: 2.6,
    ));
    add(SwitchOrb(
      position: Vector2(1910, 460),
      targetGate: gate5B,
    ));
    add(CheckpointLantern(position: Vector2(2095, 460)));

    // =========================================================================
    // ZONE 3: Blood-Fire Crucible & Zipline Abyss (x: 2220 .. 3400)
    // =========================================================================
    // Overhead Sanctum Zipline Rail above Erupting Blood-Magma Geysers!
    add(ZipLineLanternRail(
      startX: 2150,
      endX: 2660,
      railY: 260,
      glideSpeed: 400,
    ));
    add(InkScroll(position: Vector2(2320, 295)));
    add(InkScroll(position: Vector2(2490, 295)));
    add(EnemyDrone(position: Vector2(2410, 190), flyRange: 85, flySpeed: 2.3));

    // Lower Crucible Floor with Magma Geysers
    add(ComicPlatform(
      position: Vector2(2220, 485),
      size: Vector2(460, 50),
    ));
    add(MagmaGeyserVent(
      position: Vector2(2340, 485),
      cyclePeriod: 2.6,
      activeDuration: 1.1,
      geyserHeight: 165,
      initialPhase: 0.0,
    ));
    add(MagmaGeyserVent(
      position: Vector2(2520, 485),
      cyclePeriod: 2.6,
      activeDuration: 1.1,
      geyserHeight: 165,
      initialPhase: 1.3,
    ));

    // Mid-Crucible Obsidian Bastion
    add(ComicPlatform(
      position: Vector2(2720, 390),
      size: Vector2(620, 65),
    ));
    add(CheckpointLantern(position: Vector2(2770, 390)));
    add(EnemyGrunt(
      position: Vector2(2920, 390),
      minXBound: 2820,
      maxXBound: 3040,
      maxHp: 65,
    ));
    add(PoisonSporeGeyser(
      position: Vector2(3090, 390),
      cyclePeriod: 2.7,
      activeDuration: 1.1,
    ));
    add(EnemyOniArcher(position: Vector2(3230, 390)));
    add(BreakableCrate(position: Vector2(3295, 390), dropsRamen: true));

    // =========================================================================
    // ZONE 4: Celestial Spire Ascent & Warp Rift II (x: 3400 .. 4450)
    // =========================================================================
    add(WindUpdraftVent(
      position: Vector2(3410, 450),
      liftHeight: 230,
      liftSpeed: -420,
    ));
    add(ComicPlatform(
      position: Vector2(3360, 450),
      size: Vector2(110, 30),
    ));

    add(ComicPlatform(
      position: Vector2(3530, 260),
      size: Vector2(240, 24),
    ));
    add(EnemyDrone(position: Vector2(3650, 180), flyRange: 85, flySpeed: 2.4));

    // Dimensional Warp Portal #2: Warps across the Spiked Void from (3730, 260) to (4040, 370)!
    add(EclipseWarpPortal(
      position: Vector2(3730, 260),
      targetDestination: Vector2(4040, 360),
      portalColor: ComicTheme.energyCyan,
    ));

    // Alternate lower path with Taiko Bounce Drums over Spikes
    add(TaikoBounceDrum(position: Vector2(3830, 370)));
    add(TaikoBounceDrum(position: Vector2(3950, 350)));
    add(ComicPlatform(
      position: Vector2(3770, 515),
      size: Vector2(250, 30),
    ));
    add(SpikeTrap(position: Vector2(3785, 515), spikeCount: 14));

    add(ComicPlatform(
      position: Vector2(4000, 370),
      size: Vector2(410, 60),
    ));
    add(CheckpointLantern(position: Vector2(4090, 370)));
    add(EnemyGrunt(
      position: Vector2(4240, 370),
      minXBound: 4140,
      maxXBound: 4360,
      maxHp: 65,
    ));
    add(InkScroll(position: Vector2(4340, 320)));

    // =========================================================================
    // ZONE 5: Emperor's Royal Guard Gauntlet (x: 4450 .. 5460)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4450, 420),
      size: Vector2(105, 24),
      isCrumbling: true,
    ));
    add(TaikoBounceDrum(position: Vector2(4620, 360)));
    add(ComicPlatform(
      position: Vector2(4690, 400),
      size: Vector2(105, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(4430, 515),
      size: Vector2(390, 30),
    ));
    add(SpikeTrap(position: Vector2(4445, 515), spikeCount: 22));

    // Grand Sanctum Hallway before Muzan-Kai's Throne
    add(ComicPlatform(
      position: Vector2(4840, 455),
      size: Vector2(640, 65),
    ));
    add(InkSawBlade(
      position: Vector2(4950, 405),
      patrolOffset: Vector2(85, 0),
      patrolSpeed: 2.8,
    ));
    add(EnemyOniArcher(position: Vector2(5130, 455)));
    add(EnemyGrunt(
      position: Vector2(5260, 455),
      minXBound: 5180,
      maxXBound: 5340,
      maxHp: 70,
    ));
    add(RamenBowl(position: Vector2(5350, 410)));
    add(CheckpointLantern(position: Vector2(5395, 455)));

    add(ToriiGateExit(
      position: Vector2(5445, 455),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Imperial Throne Boss Arena (x: 5500 .. 6400)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5500, 485),
      size: Vector2(900, 60),
    ));
    add(ComicPlatform(
      position: Vector2(5620, 355),
      size: Vector2(140, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6110, 355),
      size: Vector2(140, 22),
    ));
    add(ComicPlatform(
      position: Vector2(5865, 245),
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

    if (game.player.position.x < 5560) {
      game.player.position = Vector2(5580, 460);
    }
    game.currentSpawnPoint = Vector2(5580, 460);
    game.lockToBossArena(minX: 5530, maxX: 6360);

    add(BossMuzanKai(
      position: Vector2(6150, 485),
      arenaMinX: 5540,
      arenaMaxX: 6340,
    ));

    game.triggerBossCutIn(
      bossName: 'MUZAN-KAI',
      quote:
          'SO YOU HAVE REACHED MY CELESTIAL SANCTUM, KAITO... PREPARE TO BE ERASED!!',
      portraitColor: ComicTheme.actionRed,
      portraitAsset: CartoonAssets.portraitMuzanKai,
    );
  }
}
