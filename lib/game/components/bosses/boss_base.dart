import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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
      stunGauge += amount * 0.70;
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
      stunGauge += 48.0;
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

    stunGauge = (stunGauge + amount * 0.62).clamp(0.0, maxStun);
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

    AudioService.playSfx(AudioService.sfxOugiRelease);
    AudioService.heavyHaptic();

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y / 2),
      text: 'DEFEATED!!',
      fillColor: ComicTheme.comicYellow,
      targetScale: 2.2,
      maxLifetime: 1.8,
    ));

    game.onBossDefeated(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
    }

    if (isStunned) {
      stunDuration -= dt;
      if (stunDuration <= 0) {
        isStunned = false;
        stunGauge = 0.0;
      }
    }
  }
}
