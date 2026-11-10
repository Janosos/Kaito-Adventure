import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import '../manga_effects.dart';

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

  double stunGauge = 0.0;
  static const double maxStun = 100.0;
  bool isStunned = false;
  double stunDuration = 0.0;

  bool isGuarding = false;
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

  void takeDamage(
    double amount, {
    int knockbackDir = 0,
    double knockbackForce = 6.0,
  }) {
    if (isDefeated || isInvulnerable) return;

    final pushDir =
        knockbackDir != 0 ? knockbackDir : (game.player.position.x < position.x ? 1 : -1);

    if (isGuarding) {
      // Guard blocks frontal damage and gives "BLOCKED!" popup + slight push
      position.x =
          (position.x + pushDir * (knockbackForce * 0.5)).clamp(arenaMinX, arenaMaxX);
      stunGauge += amount * 1.5;
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'BLOCKED!',
        fillColor: ComicTheme.halftoneGray,
      ));
      if (stunGauge >= maxStun) {
        breakGuard();
      }
      return;
    }

    final finalDamage = isStunned ? amount * 1.8 : amount;
    currentHp = (currentHp - finalDamage).clamp(0.0, maxHp);
    hitFlashTimer = 0.16;

    // Slight knockback push when slashed
    position.x =
        (position.x + pushDir * knockbackForce).clamp(arenaMinX, arenaMaxX);

    stunGauge = (stunGauge + amount * 0.85).clamp(0.0, maxStun);
    if (!isStunned && stunGauge >= maxStun) {
      breakGuard();
    }

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: isStunned ? 'CRITICAL!! -${finalDamage.toInt()}' : 'BAM! -${finalDamage.toInt()}',
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
    stunDuration = 3.5;
    isGuarding = false;
    stunGauge = 0.0;

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
