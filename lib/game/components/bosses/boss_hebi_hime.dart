import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../enemies/enemy_drone.dart';
import '../manga_effects.dart';
import '../projectiles.dart';
import 'boss_base.dart';

enum HebiState {
  idle,
  slitherDash,
  viperRecoilDash,
  coilingAmbush,
  venomBarrage,
  fangEruption,
  recovering
}

class BossHebiHime extends BossBase {
  HebiState state = HebiState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.85;
  double _groundY = 0.0;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _dashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossHebiHime({
    required super.position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'HEBI-HIME',
          title: 'THE VENOM VIPER EMPRESS',
          maxHp: 580.0,
          size: Vector2(62, 84),
        ) {
    maxPhases = 2;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_idle.png',
      frames: 6,
      textureSize: Vector2(200, 180),
      stepTime: 0.09,
    ).createTicker();

    _dashTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_dash.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.07,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_cast.png',
      frames: 5,
      textureSize: Vector2(200, 180),
      stepTime: 0.08,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/hebi_stun.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.1,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void checkPhaseTransition() {
    if (currentPhase == 1 && currentHp <= maxHp * 0.5) {
      currentPhase = 2;
      _actionInterval = 1.25;
      game.triggerBossCutIn(
        bossName: 'HEBI-HIME',
        quote: 'DROWN IN A THOUSAND FANGS OF EMERALD VENOM!!',
        portraitColor: const Color(0xFF00C853),
        portraitAsset: CartoonAssets.portraitHebiHime,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: SERPENT FRENZY!!',
        fillColor: Colors.greenAccent,
        targetScale: 1.8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      isInvulnerable = false;
      state = HebiState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;
    if (state == HebiState.idle) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case HebiState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case HebiState.slitherDash:
        position.x += facing * (currentPhase == 2 ? 590.0 : 480.0) * dt;
        if ((player.position.x - position.x).abs() < 48 &&
            (player.position.y - position.y).abs() < 54) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.42 ||
            position.x <= arenaMinX ||
            position.x >= arenaMaxX) {
          position.x = position.x.clamp(arenaMinX, arenaMaxX);
          // Fire a venom wave behind and recoil dash in Phase 2!
          game.add(BossDarkSlashWave(
            position: Vector2(position.x, _groundY - 24),
            velocity: Vector2(-facing * 380.0, 0),
          ));
          if (currentPhase == 2 && _rnd.nextDouble() < 0.7) {
            facing = player.position.x > position.x ? 1 : -1;
            state = HebiState.viperRecoilDash;
            _stateTimer = 0.0;
            game.add(MangaTextEffect(
              position: Vector2(position.x, position.y - size.y),
              text: 'VIPER RECOIL!!',
              fillColor: Colors.greenAccent,
            ));
          } else {
            state = HebiState.recovering;
            _stateTimer = 0.0;
          }
        }
        break;

      case HebiState.viperRecoilDash:
        position.x = (position.x + facing * 610.0 * dt)
            .clamp(arenaMinX, arenaMaxX);
        if ((player.position.x - position.x).abs() < 48 &&
            (player.position.y - position.y).abs() < 54) {
          player.takeDamage(1);
        }
        if (_stateTimer >= 0.34) {
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.coilingAmbush:
        // Shadowy burrow ambush under Kaito's position, then erupt with twin waves & overhead venom rain!
        if (_stateTimer >= 0.38) {
          position.x = (player.position.x + (player.facingDirection * -55.0))
              .clamp(arenaMinX, arenaMaxX);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(SlashArcEffect(
            position: Vector2(position.x + facing * 34, position.y - 44),
            slashFlipped: facing < 0,
            slashColor: Colors.greenAccent,
            radius: 66,
          ));
          // Drop venom needles from canopy above Kaito!
          for (final off in [-90.0, 0.0, 90.0]) {
            game.add(DroneInkNeedle(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                _groundY - 260.0,
              ),
              speed: 280.0,
            ));
          }
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.venomBarrage:
        if (_stateTimer >= 0.34) {
          final spread = currentPhase == 2
              ? [-0.36, -0.18, 0.0, 0.18, 0.36]
              : [-0.25, -0.08, 0.08, 0.25];
          for (final a in spread) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 30, position.y - 44),
              velocity: Vector2(facing * cos(a) * 355, sin(a) * 355),
            ));
          }
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'VENOM FANGS!!',
            fillColor: Colors.greenAccent,
          ));
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.fangEruption:
        if (_stateTimer >= 0.36) {
          final offsets = currentPhase == 2
              ? [-140.0, 0.0, 140.0]
              : [-80.0, 80.0];
          for (final off in offsets) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + off).clamp(arenaMinX, arenaMaxX),
                _groundY,
              ),
              eruptDelay: 0.58,
            ));
          }
          // Plus a low slithering wave
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 28, _groundY - 24),
            velocity: Vector2(facing * 390.0, 0),
          ));
          state = HebiState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case HebiState.recovering:
        if (_stateTimer >= (currentPhase == 2 ? 0.38 : 0.65)) {
          state = HebiState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  void _decideAction() {
    _stateTimer = 0.0;
    isGuarding = false;
    isCounterStance = false;
    final r = _rnd.nextDouble();
    if (r < 0.22) {
      state = HebiState.slitherDash;
      game.add(MangaTextEffect(
        position: position.clone(),
        text: 'SHAA!!',
        fillColor: Colors.greenAccent,
      ));
    } else if (r < 0.44) {
      state = HebiState.coilingAmbush;
      game.add(MangaDustEffect(position: position.clone()));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y),
        text: 'COILING AMBUSH!!',
        fillColor: ComicTheme.comicYellow,
      ));
    } else if (r < 0.68) {
      state = HebiState.venomBarrage;
    } else if (r < 0.85) {
      state = HebiState.fangEruption;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = HebiState.recovering;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'VIPER COIL! (BACKSTAB!)',
        fillColor: Colors.greenAccent,
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _castTicker;
    switch (state) {
      case HebiState.slitherDash:
      case HebiState.viperRecoilDash:
        return _dashTicker;
      case HebiState.venomBarrage:
      case HebiState.fangEruption:
      case HebiState.coilingAmbush:
        return _castTicker;
      default:
        return _idleTicker;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;
    final sprite = _activeTicker.getSprite();
    const renderW = 128.0;
    const renderH = 116.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = hitFlashTimer > 0
        ? (Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.white, BlendMode.srcATop))
        : null;

    sprite.render(
      canvas,
      position: Vector2(-renderW * 0.45, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );
    canvas.restore();
  }
}
