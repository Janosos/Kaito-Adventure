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

  void takeDamage(double amount) {
    if (isDefeated || isInvulnerable) return;

    if (isGuarding) {
      // Guard blocks frontal damage and gives "GUARD!!" popup
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
    hitFlashTimer = 0.15;

    stunGauge = (stunGauge + amount * 0.8).clamp(0.0, maxStun);
    if (!isStunned && stunGauge >= maxStun) {
      breakGuard();
    }

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: isStunned ? 'CRITICAL!!' : 'BAM!',
      fillColor: isStunned ? ComicTheme.comicYellow : ComicTheme.actionRed,
      targetScale: isStunned ? 1.6 : 1.2,
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
