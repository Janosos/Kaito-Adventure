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

enum MuzanState {
  idle,
  teleportStrike,
  eclipseSlash,
  judgmentCutChain,
  astralPillars,
  voidNova,
  eclipseCounterMirror,
  recovering
}

class BossMuzanKai extends BossBase {
  MuzanState state = MuzanState.idle;
  double _stateTimer = 0.0;
  final Random _rnd = Random();
  double _actionInterval = 1.65;
  double _groundY = 0.0;
  int _chainBlinksRemaining = 0;
  bool _phase2Done = false;
  bool _phase3Done = false;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _slashTicker;
  late final SpriteAnimationTicker _castTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossMuzanKai({
    required super.position,
    super.arenaMinX = 2540.0,
    super.arenaMaxX = 3340.0,
  }) : super(
          name: 'MUZAN-KAI',
          title: 'THE ECLIPSE INK EMPEROR',
          maxHp: 800.0,
          size: Vector2(74, 98),
        ) {
    maxPhases = 3;
    _groundY = position.y;
  }

  @override
  Future<void> onLoad() async {
    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/muzan_idle.png',
      frames: 6,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _slashTicker = CartoonAssets.animation(
      imgs,
      'bosses/muzan_slash.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.07,
    ).createTicker();

    _castTicker = CartoonAssets.animation(
      imgs,
      'bosses/muzan_cast.png',
      frames: 5,
      textureSize: Vector2(240, 220),
      stepTime: 0.08,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/muzan_guard.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.09,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/muzan_stun.png',
      frames: 4,
      textureSize: Vector2(240, 220),
      stepTime: 0.1,
    ).createTicker();

    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onCounterTriggered() {
    super.onCounterTriggered();
    // Teleport behind Kaito on parry counter!
    final behind = game.player.facingDirection == 1 ? -68.0 : 68.0;
    position.x =
        (game.player.position.x + behind).clamp(arenaMinX, arenaMaxX);
    facing = game.player.position.x > position.x ? 1 : -1;
    state = MuzanState.eclipseSlash;
    _stateTimer = 0.0;
  }

  @override
  void checkPhaseTransition() {
    if (!_phase2Done && currentHp <= maxHp * 0.66) {
      _phase2Done = true;
      currentPhase = 2;
      _actionInterval = 1.30;
      game.triggerBossCutIn(
        bossName: 'MUZAN-KAI',
        quote: 'THE BLOOD ECLIPSE OBEYS MY BRUSH! KNEEL, MORTAL!!',
        portraitColor: ComicTheme.darkPurple,
        portraitAsset: CartoonAssets.portraitMuzanKai,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'PHASE 2: ECLIPSE AWAKENING!!',
        fillColor: ComicTheme.comicYellow,
        targetScale: 1.9,
      ));
    } else if (!_phase3Done && currentHp <= maxHp * 0.33) {
      _phase3Done = true;
      currentPhase = 3;
      _actionInterval = 0.95;
      game.triggerBossCutIn(
        bossName: 'MUZAN-KAI',
        quote: 'CELESTIAL INK APOCALYPSE!! BE ERASED FROM THIS MANGA!!',
        portraitColor: ComicTheme.actionRed,
        portraitAsset: CartoonAssets.portraitMuzanKai,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 25),
        text: 'FINAL PHASE: GOD OF INK!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 2.1,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = MuzanState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;
    if (state == MuzanState.idle || state == MuzanState.eclipseCounterMirror) {
      facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case MuzanState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideAction();
        }
        break;

      case MuzanState.eclipseCounterMirror:
        if (_stateTimer >= 0.95) {
          isCounterStance = false;
          isGuarding = false;
          state = MuzanState.voidNova;
          _stateTimer = 0.0;
        }
        break;

      case MuzanState.teleportStrike:
        if (_stateTimer >= 0.30) {
          final behind = player.facingDirection == 1 ? -70.0 : 70.0;
          position.x = (player.position.x + behind).clamp(arenaMinX, arenaMaxX);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          state = MuzanState.eclipseSlash;
          _stateTimer = 0.0;
        }
        break;

      case MuzanState.eclipseSlash:
        if (_stateTimer >= 0.28) {
          game.add(SlashArcEffect(
            position: Vector2(position.x + facing * 40, position.y - 48),
            slashFlipped: facing < 0,
            slashColor: ComicTheme.actionRed,
            radius: 74,
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + facing * 32, position.y - 30),
            velocity: Vector2(facing * 435.0, 0),
          ));
          if ((player.position.x - position.x).abs() < 92 &&
              (player.position.y - position.y).abs() < 65) {
            player.takeDamage(1);
          }
          // In Phase 2/3, chain multi-blink Judgment Cuts!
          if (_chainBlinksRemaining > 0) {
            _chainBlinksRemaining--;
            state = MuzanState.judgmentCutChain;
            _stateTimer = 0.0;
          } else {
            state = MuzanState.recovering;
            _stateTimer = 0.0;
          }
        }
        break;

      case MuzanState.judgmentCutChain:
        if (_stateTimer >= 0.26) {
          final side = (_chainBlinksRemaining % 2 == 0) ? 85.0 : -85.0;
          position.x = (player.position.x + side).clamp(arenaMinX, arenaMaxX);
          facing = player.position.x > position.x ? 1 : -1;
          game.add(MangaDustEffect(position: position.clone()));
          game.add(MangaTextEffect(
            position: Vector2(position.x, position.y - size.y),
            text: 'ECLIPSE FLASH!!',
            fillColor: ComicTheme.comicYellow,
          ));
          state = MuzanState.eclipseSlash;
          _stateTimer = 0.0;
        }
        break;

      case MuzanState.astralPillars:
        if (_stateTimer >= 0.36) {
          final offsets = currentPhase >= 2
              ? [-210.0, -70.0, 70.0, 210.0]
              : [-150.0, 0.0, 150.0];
          for (final offset in offsets) {
            game.add(BossFlamePillar(
              position: Vector2(
                (player.position.x + offset).clamp(arenaMinX, arenaMaxX),
                _groundY,
              ),
              eruptDelay: 0.56,
            ));
          }
          // Simultaneous twin shockwaves!
          game.add(BossDarkSlashWave(
            position: Vector2(position.x - 28, _groundY - 26),
            velocity: Vector2(-390.0, 0),
          ));
          game.add(BossDarkSlashWave(
            position: Vector2(position.x + 28, _groundY - 26),
            velocity: Vector2(390.0, 0),
          ));
          state = MuzanState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case MuzanState.voidNova:
        if (_stateTimer >= 0.38) {
          final angles = currentPhase >= 2
              ? [-0.52, -0.34, -0.17, 0.0, 0.17, 0.34, 0.52]
              : [-0.45, -0.22, 0.0, 0.22, 0.45];
          for (final a in angles) {
            game.add(BossEnergyOrb(
              position: Vector2(position.x + facing * 30, position.y - 54),
              velocity: Vector2(facing * cos(a) * 370, sin(a) * 370),
            ));
          }
          state = MuzanState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case MuzanState.recovering:
        if (_stateTimer >= (currentPhase == 3 ? 0.34 : 0.62)) {
          state = MuzanState.idle;
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
    if (r < 0.28) {
      _chainBlinksRemaining = currentPhase >= 2 ? 2 : 1;
      state = MuzanState.teleportStrike;
    } else if (r < 0.48) {
      _chainBlinksRemaining = 0;
      state = MuzanState.eclipseSlash;
    } else if (r < 0.68) {
      state = MuzanState.astralPillars;
    } else if (r < 0.85) {
      state = MuzanState.voidNova;
    } else {
      isGuarding = true;
      isCounterStance = true;
      state = MuzanState.eclipseCounterMirror;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 12),
        text: 'ECLIPSE MIRROR! (DASH BEHIND!)',
        fillColor: ComicTheme.actionRed,
      ));
    }
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding || isCounterStance) return _guardTicker;
    switch (state) {
      case MuzanState.eclipseSlash:
        return _slashTicker;
      case MuzanState.astralPillars:
      case MuzanState.voidNova:
      case MuzanState.teleportStrike:
      case MuzanState.judgmentCutChain:
        return _castTicker;
      default:
        return _idleTicker;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;
    final sprite = _activeTicker.getSprite();
    const renderW = 152.0;
    const renderH = 142.0;

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
