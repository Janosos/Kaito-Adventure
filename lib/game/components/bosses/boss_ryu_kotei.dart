import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';
import '../projectiles.dart';
import 'boss_base.dart';

enum RyuState {
  idle,
  chargingDash,
  dashing,
  reboundDash,
  leaping,
  stomping,
  firingPillars,
  laserOverdrive,
  dragonGuard,
  recovering
}

class BossRyuKotei extends BossBase {
  RyuState state = RyuState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();

  double _actionInterval = 2.0;
  double _stompY = 0.0;
  double _dashTrailTimer = 0.0;
  bool _phase2Triggered = false;
  bool _phase3Triggered = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _dashTicker;
  late final SpriteAnimationTicker _stompTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossRyuKotei({
    required Vector2 position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'RYU-KOTEI',
          title: 'THE DRAGON SHOGUN',
          maxHp: 520.0,
          position: position,
          size: Vector2(74, 96),
        ) {
    maxPhases = 3;
    _stompY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/ryu_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.1,
    ).createTicker();

    _dashTicker = CartoonAssets.animation(
      imgs,
      'bosses/ryu_dash.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _stompTicker = CartoonAssets.animation(
      imgs,
      'bosses/ryu_stomp.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/ryu_cast.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/ryu_stun.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.11,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (!_phase2Triggered && currentHp <= maxHp * 0.66) {
      _phase2Triggered = true;
      currentPhase = 2;
      _actionInterval = 1.55;
      game.triggerBossCutIn(
        bossName: 'RYU-KOTEI',
        quote: 'IGNITE THE CRUCIBLE! NONE ESCAPE MY DRAGON FORGE!!',
        portraitColor: ComicTheme.actionRed,
        portraitAsset: CartoonAssets.portraitRyuKotei,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: FLAME SURGE!',
        fillColor: ComicTheme.comicYellow,
        targetScale: 1.8,
      ));
    } else if (!_phase3Triggered && currentHp <= maxHp * 0.33) {
      _phase3Triggered = true;
      currentPhase = 3;
      _actionInterval = 1.15;
      game.triggerBossCutIn(
        bossName: 'RYU-KOTEI',
        quote: 'DRAGON OVERDRIVE!! ASHES TO ASHES!!',
        portraitColor: ComicTheme.comicYellow,
        portraitAsset: CartoonAssets.portraitRyuKotei,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'FINAL PHASE: OVERDRIVE!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 2.0,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      position.y = _stompY;
      state = RyuState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;

    if (state == RyuState.idle || state == RyuState.dragonGuard) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case RyuState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideNextAction();
        }
        break;

      case RyuState.dragonGuard:
        if (_stateTimer >= 1.0) {
          isGuarding = false;
          isCounterStance = false;
          state = RyuState.firingPillars;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.chargingDash:
        if (_stateTimer >= 0.42) {
          state = RyuState.dashing;
          _stateTimer = 0.0;
          _dashTrailTimer = 0.0;
          game.add(MangaTextEffect(
            position: position.clone(),
            text: 'DRAGON CHARGE!!',
            fillColor: ComicTheme.actionRed,
          ));
        }
        break;

      case RyuState.dashing:
        position.x += facing * 550.0 * dt;
        _dashTrailTimer += dt;
        // Leave erupting magma pillars in his wake during Phase 2 & 3!
        if (currentPhase >= 2 && _dashTrailTimer >= 0.18) {
          _dashTrailTimer = 0.0;
          game.add(BossFlamePillar(
            position: Vector2(position.x, _stompY),
            eruptDelay: 0.55,
          ));
        }
        final dist = (player.position.x - position.x).abs();
        if (dist < 52 && (player.position.y - position.y).abs() < 52) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.44 ||
            position.x <= arenaMinX ||
            position.x >= arenaMaxX) {
          position.x = position.x.clamp(arenaMinX, arenaMaxX);
          if (currentPhase >= 2 && _rnd.nextDouble() < 0.65) {
            // Rebound off the arena edge for a second reverse dash!
            facing = player.position.x > position.x ? 1 : -1;
            state = RyuState.reboundDash;
            _stateTimer = 0.0;
            game.add(MangaTextEffect(
              position: Vector2(position.x, position.y - size.y),
              text: 'REBOUND RUSH!!',
              fillColor: ComicTheme.comicYellow,
            ));
          } else {
            state = RyuState.recovering;
            _stateTimer = 0.0;
          }
        }
        break;

      case RyuState.reboundDash:
        position.x = (position.x + facing * 580.0 * dt)
            .clamp(arenaMinX, arenaMaxX);
        if ((player.position.x - position.x).abs() < 52 &&
            (player.position.y - position.y).abs() < 52) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.36) {
          state = RyuState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.leaping:
        position.y -= 340.0 * dt;
        position.x +=
            ((player.position.x - position.x).clamp(-200.0, 200.0)) * dt * 2.0;
        position.x = position.x.clamp(arenaMinX, arenaMaxX);
        if (_stateTimer >= 0.40) {
          state = RyuState.stomping;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.stomping:
        position.y += 690.0 * dt;
        if (position.y >= _stompY) {
          position.y = _stompY;
          _triggerGroundTremor();
          state = RyuState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.firingPillars:
        if (_stateTimer >= 0.36) {
          _spawnFlameVents();
          state = RyuState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.laserOverdrive:
        if (_stateTimer >= 0.52) {
          _fireEnergySpread();
          state = RyuState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case RyuState.recovering:
        if (_stateTimer >= (currentPhase == 3 ? 0.36 : 0.68)) {
          state = RyuState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    switch (state) {
      case RyuState.chargingDash:
      case RyuState.dashing:
      case RyuState.reboundDash:
        return _dashTicker;
      case RyuState.leaping:
      case RyuState.stomping:
        return _stompTicker;
      case RyuState.firingPillars:
      case RyuState.laserOverdrive:
      case RyuState.dragonGuard:
        return _castTicker;
      default:
        return _idleTicker;
    }
  }

  void _decideNextAction() {
    _stateTimer = 0.0;
    isGuarding = false;
    isCounterStance = false;
    final r = _rnd.nextDouble();

    if (currentPhase == 1) {
      if (r < 0.38) {
        state = RyuState.chargingDash;
      } else if (r < 0.72) {
        state = RyuState.leaping;
      } else {
        state = RyuState.firingPillars;
      }
    } else if (currentPhase == 2) {
      if (r < 0.22) {
        isGuarding = true;
        isCounterStance = true;
        state = RyuState.dragonGuard;
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y - 10),
          text: 'DRAGON AEGIS! (BACKSTAB!)',
          fillColor: ComicTheme.comicYellow,
        ));
      } else if (r < 0.48) {
        state = RyuState.firingPillars;
      } else if (r < 0.76) {
        state = RyuState.chargingDash;
      } else {
        state = RyuState.leaping;
      }
    } else {
      if (r < 0.36) {
        state = RyuState.laserOverdrive;
      } else if (r < 0.65) {
        state = RyuState.firingPillars;
      } else if (r < 0.85) {
        state = RyuState.chargingDash;
      } else {
        state = RyuState.leaping;
      }
    }
  }

  void _triggerGroundTremor() {
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - 10),
      text: 'BOOM!!',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.8,
    ));
    game.add(MangaDustEffect(position: position.clone()));

    game.add(BossDarkSlashWave(
      position: Vector2(position.x - 30, position.y - 20),
      velocity: Vector2(-410, 0),
    ));
    game.add(BossDarkSlashWave(
      position: Vector2(position.x + 30, position.y - 20),
      velocity: Vector2(410, 0),
    ));
    // Also erupt a flame pillar at Kaito's position on stomp!
    game.add(BossFlamePillar(
      position: Vector2(
        game.player.position.x.clamp(arenaMinX, arenaMaxX),
        _stompY,
      ),
      eruptDelay: 0.60,
    ));
  }

  void _spawnFlameVents() {
    final player = game.player;
    final offsets = currentPhase >= 2
        ? [-180.0, -60.0, 60.0, 180.0]
        : [-130.0, 0.0, 130.0];
    for (final off in offsets) {
      game.add(BossFlamePillar(
        position: Vector2(
          (player.position.x + off).clamp(arenaMinX, arenaMaxX),
          _stompY,
        ),
        eruptDelay: 0.62,
      ));
    }
  }

  void _fireEnergySpread() {
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: 'DRAGON BLAST!!',
      fillColor: ComicTheme.energyCyan,
    ));

    final angles = [-0.42, -0.20, 0.0, 0.20, 0.42];
    for (final a in angles) {
      final vx = facing * cos(a) * 350.0;
      final vy = sin(a) * 350.0;
      game.add(BossEnergyOrb(
        position:
            Vector2(position.x + facing * 35, position.y - size.y * 0.5),
        velocity: Vector2(vx, vy),
      ));
    }
    // Simultaneous ground wave!
    game.add(BossDarkSlashWave(
      position: Vector2(position.x + facing * 30, _stompY - 24),
      velocity: Vector2(facing * 390.0, 0),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;

    final sprite = _activeTicker.getSprite();
    const renderW = 148.0;
    const renderH = 136.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (facing < 0) {
      canvas.scale(-1, 1);
    }

    Paint? overridePaint;
    if (hitFlashTimer > 0) {
      overridePaint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        );
    } else if (currentPhase == 3) {
      overridePaint = Paint()
        ..colorFilter = ColorFilter.mode(
          ComicTheme.actionRed.withValues(alpha: 0.22),
          BlendMode.srcATop,
        );
    }

    sprite.render(
      canvas,
      position: Vector2(-renderW * 0.45, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );

    canvas.restore();
  }
}
