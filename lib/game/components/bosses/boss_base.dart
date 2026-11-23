import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/game/services/audio_service.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';
import '../projectiles.dart';

abstract class BossBase extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  final String name;
  final String title;
  final double maxHp;
  final double arenaMinX;
  final double arenaMaxX;
  late double currentHp;

  int currentPhase = 1;
  int maxPhases = 2;
  int facing = -1; // -1 = facing left, 1 = facing right

  double stunGauge = 0.0;
  static const double maxStun = 100.0;
  bool isStunned = false;
  double stunDuration = 0.0;

  bool isGuarding = false;
  bool isCounterStance = false;
  bool isInvulnerable = false;
  double hitFlashTimer = 0.0;
  bool isDefeated = false;
  double _defeatAnimTimer = 0.0;
  int _defeatBurstStage = 0;
  static const double defeatAnimDuration = 1.45;

  // Dynamic animation state tracking across all 10 Bosses
  double animTime = 0.0;
  double _attackHoldTimer = 0.0;
  double _activeActionElapsed = 0.0;
  SpriteAnimationTicker? _lastActiveTicker;
  SpriteAnimationTicker? _heldCombatTicker;

  BossBase({
    required this.name,
    required this.title,
    required this.maxHp,
    required Vector2 position,
    required Vector2 size,
    this.arenaMinX = 2540.0,
    this.arenaMaxX = 3340.0,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.bottomCenter,
        ) {
      currentHp = maxHp;
      priority = 750;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Notify HUD about Boss entry
    game.activeBoss = this;
  }

  @override
  void onRemove() {
    if (game.activeBoss == this) {
      game.activeBoss = null;
    }
    super.onRemove();
  }

  void onCounterTriggered() {
    isCounterStance = false;
    isGuarding = false;
    game.add(SlashArcEffect(
      position: Vector2(position.x + facing * 36, position.y - size.y * 0.5),
      slashFlipped: facing < 0,
      slashColor: ComicTheme.actionRed,
      radius: 70,
    ));
    game.add(BossDarkSlashWave(
      position: Vector2(position.x + facing * 28, position.y - 26),
      velocity: Vector2(facing * 430.0, 0),
    ));
  }

  void takeDamage(
    double amount, {
    int knockbackDir = 0,
    double knockbackForce = 6.0,
    double stunMultiplier = 1.0,
  }) {
    if (isDefeated || isInvulnerable) return;

    final playerX = game.player.position.x;
    final pushDir =
        knockbackDir != 0 ? knockbackDir : (playerX < position.x ? 1 : -1);
    final isBackstab =
        (facing > 0 && playerX < position.x - 6) ||
        (facing < 0 && playerX > position.x + 6);

    if (isCounterStance && !isBackstab) {
      AudioService.playSfx(AudioService.sfxParryCounter);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 14),
        text: 'PARRY COUNTER!!',
        fillColor: ComicTheme.actionRed,
        targetScale: 1.5,
      ));
      onCounterTriggered();
      return;
    }

    if (isGuarding && !isBackstab) {
      // Guard blocks frontal damage; player must dash behind for a Backstab or break guard!
      AudioService.playSfx(AudioService.sfxKunaiHit);
      position.x = (position.x + pushDir * (knockbackForce * 0.35))
          .clamp(arenaMinX, arenaMaxX);
      stunGauge += amount * 0.70 * stunMultiplier;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'BLOCKED! DASH BEHIND!',
        fillColor: ComicTheme.halftoneGray,
      ));
      if (stunGauge >= maxStun) {
        breakGuard();
      }
      return;
    }

    double finalDamage = isStunned ? amount * 1.75 : amount;
    if ((isGuarding || isCounterStance) && isBackstab) {
      isGuarding = false;
      isCounterStance = false;
      finalDamage = amount * 1.45;
      stunGauge += 48.0 * stunMultiplier;
      AudioService.playSfx(AudioService.sfxBackstabPierce);
      AudioService.heavyHaptic();
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 22),
        text: 'BACKSTAB PIERCE!!',
        fillColor: ComicTheme.energyCyan,
        targetScale: 1.6,
      ));
    } else {
      AudioService.playSfx(AudioService.sfxEnemyHit);
    }

    currentHp = (currentHp - finalDamage).clamp(0.0, maxHp);
    hitFlashTimer = 0.16;

    // Slight knockback push when slashed
    position.x =
        (position.x + pushDir * knockbackForce).clamp(arenaMinX, arenaMaxX);

    stunGauge = (stunGauge + amount * 0.62 * stunMultiplier).clamp(0.0, maxStun);
    if (!isStunned && stunGauge >= maxStun) {
      breakGuard();
    }

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: isStunned
          ? 'CRITICAL!! -${finalDamage.toInt()}'
          : 'BAM! -${finalDamage.toInt()}',
      fillColor: isStunned ? ComicTheme.comicYellow : ComicTheme.actionRed,
      targetScale: isStunned ? 1.5 : 1.15,
    ));

    checkPhaseTransition();

    if (currentHp <= 0) {
      defeat();
    }
  }

  void breakGuard() {
    isStunned = true;
    stunDuration = 2.8;
    isGuarding = false;
    isCounterStance = false;
    stunGauge = 0.0;

    AudioService.playSfx(AudioService.sfxParryCounter);
    AudioService.heavyHaptic();

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 20),
      text: 'GUARD BREAK!!',
      fillColor: ComicTheme.energyCyan,
      targetScale: 1.8,
    ));
  }

  void checkPhaseTransition();

  void defeat() {
    if (isDefeated) return;
    isDefeated = true;
    isStunned = true;
    isGuarding = false;
    isCounterStance = false;
    _defeatAnimTimer = 0.0;
    _defeatBurstStage = 0;
    hitFlashTimer = 0.25;

    AudioService.playSfx(AudioService.sfxOugiRelease);
    AudioService.heavyHaptic();

    game.add(SubtleKoExplosionEffect(
      position: Vector2(position.x, position.y - size.y * 0.55),
      playerColor: ComicTheme.actionRed,
      maxRadius: 92.0,
    ));
    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 18),
      text: 'DEFEATED!!',
      fillColor: ComicTheme.comicYellow,
      targetScale: 2.2,
      maxLifetime: 1.6,
    ));

    game.onBossDefeated(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTime += dt;
    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }
    if (_attackHoldTimer > 0) {
      _attackHoldTimer -= dt;
    }

    if (isDefeated) {
      _defeatAnimTimer += dt;
      if (_defeatBurstStage == 0 && _defeatAnimTimer >= 0.28) {
        _defeatBurstStage = 1;
        hitFlashTimer = 0.18;
        AudioService.playSfx(AudioService.sfxEnemyHit);
        game.add(SubtleKoExplosionEffect(
          position: Vector2(position.x - 24, position.y - size.y * 0.65),
          playerColor: ComicTheme.comicYellow,
          maxRadius: 72.0,
        ));
        game.add(SlashArcEffect(
          position: Vector2(position.x - 18, position.y - size.y * 0.6),
          slashColor: ComicTheme.energyCyan,
          radius: 58,
        ));
      } else if (_defeatBurstStage == 1 && _defeatAnimTimer >= 0.60) {
        _defeatBurstStage = 2;
        hitFlashTimer = 0.18;
        AudioService.playSfx(AudioService.sfxEnemyHit);
        game.add(SubtleKoExplosionEffect(
          position: Vector2(position.x + 26, position.y - size.y * 0.45),
          playerColor: ComicTheme.energyCyan,
          maxRadius: 78.0,
        ));
        game.add(MangaDustEffect(position: position.clone()));
      } else if (_defeatBurstStage == 2 && _defeatAnimTimer >= 0.96) {
        _defeatBurstStage = 3;
        hitFlashTimer = 0.24;
        AudioService.playSfx(AudioService.sfxEnemyDefeat);
        game.add(SubtleKoExplosionEffect(
          position: Vector2(position.x, position.y - size.y * 0.5),
          playerColor: ComicTheme.actionRed,
          maxRadius: 118.0,
        ));
        game.add(MangaDustEffect(
          position: Vector2(position.x - 28, position.y),
        ));
        game.add(MangaDustEffect(
          position: Vector2(position.x + 28, position.y),
        ));
        game.add(MangaTextEffect(
          position: Vector2(position.x, position.y - size.y * 0.8),
          text: 'K.O.!!',
          fillColor: ComicTheme.actionRed,
          targetScale: 2.0,
          maxLifetime: 0.9,
        ));
      }
      return;
    }

    if (isStunned) {
      stunDuration -= dt;
      if (stunDuration <= 0) {
        isStunned = false;
        stunGauge = 0.0;
      }
    }
  }

  /// Resolves and updates the active boss animation ticker, automatically resetting
  /// on transition and holding attack/cast animations through follow-through frames!
  SpriteAnimationTicker resolveAndUpdateBossTicker(
    double dt, {
    required SpriteAnimationTicker desiredTicker,
    required SpriteAnimationTicker idleTicker,
    required SpriteAnimationTicker stunTicker,
  }) {
    SpriteAnimationTicker chosen = desiredTicker;
    if (isStunned) {
      chosen = stunTicker;
      _heldCombatTicker = null;
      _attackHoldTimer = 0.0;
    } else if (desiredTicker != idleTicker) {
      if (_heldCombatTicker != desiredTicker) {
        _heldCombatTicker = desiredTicker;
        _activeActionElapsed = 0.0;
      }
      _attackHoldTimer = 0.34;
    } else if (_attackHoldTimer > 0 && _heldCombatTicker != null) {
      chosen = _heldCombatTicker!;
    } else {
      _heldCombatTicker = null;
    }

    if (chosen != _lastActiveTicker) {
      _lastActiveTicker = chosen;
      _activeActionElapsed = 0.0;
      chosen.reset();
    } else {
      _activeActionElapsed += dt;
    }

    chosen.update(dt);
    return chosen;
  }

  /// Renders the boss sprite with dynamic 60/120 FPS procedural animation:
  /// breathing, attack lunge & tilt, hit recoil jolt, guard barrier, and stun collapse!
  void renderBossAnimated(
    Canvas canvas, {
    required SpriteAnimationTicker desiredTicker,
    required SpriteAnimationTicker idleTicker,
    required double renderW,
    required double renderH,
    Paint? extraOverridePaint,
  }) {
    if (isDefeated && _defeatAnimTimer >= defeatAnimDuration) return;
    final activeTicker = _lastActiveTicker ?? desiredTicker;
    final sprite = activeTicker.getSprite();
    final isCombatAction = !isStunned && !isDefeated && activeTicker != idleTicker;

    // 1. Compute dynamic procedural offsets & transforms
    double offsetX = 0.0;
    double offsetY = 0.0;
    double tilt = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double defeatAlpha = 1.0;

    if (isDefeated) {
      final p = (_defeatAnimTimer / defeatAnimDuration).clamp(0.0, 1.0);
      final collapse = Curves.easeInCubic.transform(p);
      // Violent death shudder + kneeling collapse + ink dissolve fade
      offsetX = sin(_defeatAnimTimer * 52.0) * 10.0 * (1.0 - p * 0.45);
      offsetY = collapse * 28.0;
      tilt = -0.42 * Curves.easeInQuad.transform(p);
      scaleX = 1.0 + collapse * 0.14;
      scaleY = (1.0 - collapse * 0.35).clamp(0.35, 1.0);
      defeatAlpha = (1.0 - collapse).clamp(0.0, 1.0);
    } else if (isStunned) {
      // Natural dizzy side-to-side stagger without squishing proportions
      offsetX = sin(animTime * 7.5) * 3.0;
      offsetY = sin(animTime * 6.0).abs() * 1.5;
      tilt = sin(animTime * 7.5) * 0.04;
      scaleX = 1.0;
      scaleY = 1.0;
    } else if (isGuarding || isCounterStance) {
      // Defensive brace
      offsetY = 2.0;
      tilt = -0.04 + sin(animTime * 10.0) * 0.02;
      scaleX = 1.0;
      scaleY = 1.0;
    } else if (isCombatAction) {
      // Dynamic wind-up -> explosive forward lunge & slash lean!
      final p = (_activeActionElapsed / 0.42).clamp(0.0, 1.0);
      final lungeCurve = sin(p * pi);
      offsetX = lungeCurve * 15.0;
      offsetY = -sin(p * pi * 2) * 5.0;
      tilt = (p < 0.25 ? -0.14 : 0.18 * lungeCurve);
      scaleX = 1.0 + lungeCurve * 0.07;
      scaleY = 1.0 - lungeCurve * 0.05;
    } else {
      // Menacing idle breathing & subtle float
      final breathe = sin(animTime * 4.2);
      offsetY = breathe * 3.0;
      scaleX = 1.0 - breathe * 0.025;
      scaleY = 1.0 + breathe * 0.032;
    }

    // Hit recoil jolt whenever Kaito lands a slash/kunai/ougi!
    if (hitFlashTimer > 0) {
      final jolt = (hitFlashTimer / 0.16).clamp(0.0, 1.0);
      offsetX -= 9.0 * jolt;
      tilt -= 0.12 * jolt;
      scaleX *= (1.0 - 0.06 * jolt);
      scaleY *= (1.0 + 0.06 * jolt);
    }

    canvas.save();
    canvas.translate(size.x / 2, size.y + 6);
    if (facing < 0) {
      canvas.scale(-1, 1);
    }

    // 2. Dynamic ground shadow / combat aura ring under boss's feet
    final ringColor = isStunned
        ? ComicTheme.energyCyan.withValues(alpha: 0.36)
        : (isCombatAction
            ? ComicTheme.actionRed.withValues(alpha: 0.34)
            : Colors.black.withValues(alpha: 0.38));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offsetX * 0.5, -3),
        width: isCombatAction ? 96 : 82,
        height: 16,
      ),
      Paint()..color = ringColor,
    );

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.rotate(tilt);
    canvas.scale(scaleX, scaleY);

    Paint? overridePaint = extraOverridePaint;
    if (isDefeated) {
      final flashWhite = ((_defeatAnimTimer * 18).toInt() % 2 == 0);
      overridePaint = Paint()
        ..color = Colors.white.withValues(alpha: defeatAlpha)
        ..colorFilter = flashWhite
            ? ColorFilter.mode(
                ComicTheme.actionRed.withValues(alpha: 0.55 * defeatAlpha),
                BlendMode.srcATop,
              )
            : null;
    } else if (hitFlashTimer > 0) {
      overridePaint = Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
    }

    sprite.render(
      canvas,
      position: Vector2(-renderW * 0.45, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );
    canvas.restore();

    canvas.restore();
  }
}
