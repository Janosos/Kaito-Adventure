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

enum KurokageState {
  idle,
  charging,
  cleaving,
  shockwave,
  teleporting,
  recovering
}

class BossKurokage extends BossBase {
  KurokageState state = KurokageState.idle;
  double _stateTimer = 0.0;
  int _facing = -1; // -1 = facing left, 1 = facing right
  final Random _rnd = Random();

  double _actionInterval = 2.4;

  late final SpriteAnimationTicker _idleTicker;
  late final SpriteAnimationTicker _chargeTicker;
  late final SpriteAnimationTicker _cleaveTicker;
  late final SpriteAnimationTicker _guardTicker;
  late final SpriteAnimationTicker _stunTicker;

  BossKurokage({
    required super.position,
  }) : super(
          name: 'KUROKAGE',
          title: 'THE SHADOW EXECUTIONER',
          maxHp: 240.0,
          size: Vector2(58, 76),
        ) {
    maxPhases = 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    final imgs = game.images;
    _idleTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_idle.png',
      frames: 6,
      textureSize: Vector2(200, 180),
      stepTime: 0.1,
    ).createTicker();

    _chargeTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_charge.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.08,
    ).createTicker();

    _cleaveTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_cleave.png',
      frames: 5,
      textureSize: Vector2(200, 180),
      stepTime: 0.07,
      loop: false,
    ).createTicker();

    _guardTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_guard.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.09,
    ).createTicker();

    _stunTicker = CartoonAssets.animation(
      imgs,
      'bosses/kurokage_stun.png',
      frames: 4,
      textureSize: Vector2(200, 180),
      stepTime: 0.11,
    ).createTicker();
  }

  @override
  void checkPhaseTransition() {
    if (currentPhase == 1 && currentHp <= maxHp * 0.5) {
      currentPhase = 2;
      _actionInterval = 1.7;
      game.triggerBossCutIn(
        bossName: 'KUROKAGE',
        quote: 'FOOL! THE TRUE SHADOW CONSUMES ALL!!',
        portraitColor: ComicTheme.darkPurple,
        portraitAsset: CartoonAssets.portraitKurokage,
      );
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 30),
        text: 'PHASE 2: ENRAGED!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 1.8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    if (isStunned) {
      state = KurokageState.recovering;
      _stunTicker.update(dt);
      return;
    }

    _stateTimer += dt;
    final player = game.player;

    if (state == KurokageState.idle) {
      _facing = player.position.x > position.x ? 1 : -1;
    }

    switch (state) {
      case KurokageState.idle:
        if (_stateTimer >= _actionInterval) {
          _decideNextAction();
        }
        break;

      case KurokageState.teleporting:
        if (_stateTimer >= 0.4) {
          final behindOffset = player.facingDirection == 1 ? -65.0 : 65.0;
          position.x = (player.position.x + behindOffset).clamp(2020.0, 2760.0);
          _facing = player.position.x > position.x ? 1 : -1;

          game.add(MangaTextEffect(
            position: position.clone(),
            text: 'SHING!',
            fillColor: ComicTheme.energyCyan,
          ));
          game.add(MangaDustEffect(position: position.clone()));

          state = KurokageState.charging;
          _chargeTicker.reset();
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.charging:
        if (_stateTimer >= (currentPhase == 2 ? 0.35 : 0.6)) {
          _executeCleave();
        }
        break;

      case KurokageState.cleaving:
        if (_stateTimer >= 0.45) {
          state = KurokageState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.shockwave:
        if (_stateTimer >= 0.35) {
          _fireShockwave();
          state = KurokageState.recovering;
          _stateTimer = 0.0;
        }
        break;

      case KurokageState.recovering:
        if (_stateTimer >= (currentPhase == 2 ? 0.4 : 0.8)) {
          state = KurokageState.idle;
          _stateTimer = 0.0;
        }
        break;
    }

    _activeTicker.update(dt);
  }

  SpriteAnimationTicker get _activeTicker {
    if (isStunned) return _stunTicker;
    if (isGuarding) return _guardTicker;
    switch (state) {
      case KurokageState.charging:
      case KurokageState.shockwave:
        return _chargeTicker;
      case KurokageState.cleaving:
        return _cleaveTicker;
      default:
        return _idleTicker;
    }
  }

  void _decideNextAction() {
    _stateTimer = 0.0;

    final player = game.player;
    final dist = (player.position.x - position.x).abs();

    if (dist > 180 || _rnd.nextDouble() < 0.4) {
      if (_rnd.nextBool()) {
        state = KurokageState.teleporting;
        game.add(MangaDustEffect(position: position.clone()));
      } else {
        state = KurokageState.shockwave;
        _chargeTicker.reset();
      }
    } else {
      if (_rnd.nextDouble() < 0.35 && currentPhase == 1) {
        isGuarding = true;
        state = KurokageState.idle;
        _actionInterval = 1.2;
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y - 10),
          text: 'DEFENSE STANCE!',
          fillColor: ComicTheme.comicYellow,
          initialScale: 0.6,
        ));
      } else {
        isGuarding = false;
        state = KurokageState.charging;
        _chargeTicker.reset();
      }
    }
  }

  void _executeCleave() {
    state = KurokageState.cleaving;
    _cleaveTicker.reset();
    _stateTimer = 0.0;

    game.add(SlashArcEffect(
      position: Vector2(position.x + _facing * 35, position.y - size.y * 0.5),
      slashFlipped: _facing < 0,
      radius: 65,
      slashColor: ComicTheme.darkPurple,
    ));

    game.add(MangaTextEffect(
      position: Vector2(position.x + _facing * 40, position.y - size.y * 0.7),
      text: 'ZUBATTO!!',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.5,
    ));

    final player = game.player;
    final dx = player.position.x - position.x;
    final inFront = (_facing > 0 && dx > 0) || (_facing < 0 && dx < 0);
    if (inFront &&
        dx.abs() < 90 &&
        (player.position.y - position.y).abs() < 60) {
      player.takeDamage(1);
    }
  }

  void _fireShockwave() {
    game.add(BossDarkSlashWave(
      position: Vector2(position.x + _facing * 25, position.y - 26),
      velocity: Vector2(_facing * 360.0, 0),
    ));

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.8),
      text: 'DODODO!',
      fillColor: ComicTheme.actionRed,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) return;

    final sprite = _activeTicker.getSprite();
    const renderW = 120.0;
    const renderH = 108.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (_facing < 0) {
      canvas.scale(-1, 1);
    }

    final overridePaint = hitFlashTimer > 0
        ? (Paint()
          ..colorFilter = const ColorFilter.mode(
            Colors.white,
            BlendMode.srcATop,
          ))
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
