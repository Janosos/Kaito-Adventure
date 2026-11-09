import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import 'manga_effects.dart';
import 'projectiles.dart';
import 'platform.dart';
import 'traps.dart';
import 'collectibles.dart';
import 'enemies/enemy_grunt.dart';
import 'enemies/enemy_drone.dart';

enum PlayerAction {
  idle,
  running,
  jumping,
  falling,
  dashing,
  attack1,
  attack2,
  attack3,
  hurt
}

class MangaPlayer extends PositionComponent
    with CollisionCallbacks, HasGameReference<MangaGame> {
  // Stats
  int maxHp = 5;
  late int hp;
  double spirit = 0.0; // 0 to 100
  int comboCount = 0;
  double comboTimer = 0.0;

  // Physics
  Vector2 velocity = Vector2.zero();
  final double moveSpeed = 230.0;
  final double jumpForce = -470.0;
  final double gravity = 1100.0;
  bool isOnGround = false;
  bool isTouchingWall = false;
  int wallDirection = 0; // -1 left, 1 right

  // Movement & State
  int facingDirection = 1; // 1 = right, -1 = left
  PlayerAction action = PlayerAction.idle;

  // Dash
  bool isDashing = false;
  double dashTimer = 0.0;
  double dashCooldown = 0.0;
  static const double dashDuration = 0.22;
  static const double dashSpeed = 560.0;

  // Attack combo
  int comboIndex = 0; // 0, 1, 2
  double attackCooldown = 0.0;
  double attackAnimTimer = 0.0;
  double kunaiCooldown = 0.0;

  // Invulnerability & Hurt
  double invulnerableTimer = 0.0;
  double hurtAnimTimer = 0.0;
  bool get isInvulnerable => invulnerableTimer > 0 || isDashing;

  double _animTime = 0.0;

  // 2D Cartoon Sprite Animation Tickers
  late final Map<PlayerAction, SpriteAnimationTicker> _tickers;

  MangaPlayer({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(34, 52),
          anchor: Anchor.bottomCenter,
        ) {
    hp = maxHp;
    priority = 800;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(24, 48), position: Vector2(5, 4)));

    final imgs = game.images;
    _tickers = {
      PlayerAction.idle: CartoonAssets.animation(
        imgs,
        'characters/kaito_idle.png',
        frames: 6,
        textureSize: Vector2(128, 128),
        stepTime: 0.11,
      ).createTicker(),
      PlayerAction.running: CartoonAssets.animation(
        imgs,
        'characters/kaito_run.png',
        frames: 8,
        textureSize: Vector2(128, 128),
        stepTime: 0.065,
      ).createTicker(),
      PlayerAction.jumping: CartoonAssets.animation(
        imgs,
        'characters/kaito_jump.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.09,
      ).createTicker(),
      PlayerAction.falling: CartoonAssets.animation(
        imgs,
        'characters/kaito_fall.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.09,
      ).createTicker(),
      PlayerAction.dashing: CartoonAssets.animation(
        imgs,
        'characters/kaito_dash.png',
        frames: 4,
        textureSize: Vector2(128, 128),
        stepTime: 0.05,
      ).createTicker(),
      PlayerAction.attack1: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack1.png',
        frames: 5,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.attack2: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack2.png',
        frames: 5,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.attack3: CartoonAssets.animation(
        imgs,
        'characters/kaito_attack3.png',
        frames: 6,
        textureSize: Vector2(144, 128),
        stepTime: 0.05,
        loop: false,
      ).createTicker(),
      PlayerAction.hurt: CartoonAssets.animation(
        imgs,
        'characters/kaito_hurt.png',
        frames: 3,
        textureSize: Vector2(128, 128),
        stepTime: 0.08,
      ).createTicker(),
    };
  }

  // Input Handling
  double moveInput = 0.0;
  bool jumpPressed = false;

  void handleInput({
    required double horizontal,
    required bool jump,
    required bool attack,
    required bool dash,
    required bool ranged,
    required bool ultimate,
  }) {
    moveInput = horizontal;

    if (jump && (isOnGround || isTouchingWall)) {
      performJump();
    }
    if (dash && dashCooldown <= 0 && !isDashing) {
      performDash();
    }
    if (attack && attackCooldown <= 0) {
      performAttack();
    }
    if (ranged && kunaiCooldown <= 0) {
      performThrowKunai();
    }
    if (ultimate && spirit >= 100.0) {
      performUltimate();
    }
  }

  void performJump() {
    if (isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
      game.add(MangaDustEffect(position: position.clone()));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - size.y - 10),
        text: 'HOP!',
        fillColor: ComicTheme.paperWhite,
        initialScale: 0.3,
        targetScale: 0.7,
      ));
    } else if (isTouchingWall) {
      velocity.y = jumpForce * 0.9;
      velocity.x = -wallDirection * moveSpeed * 1.3;
      facingDirection = -wallDirection;
      isTouchingWall = false;
      game.add(MangaDustEffect(position: position.clone()));
      game.add(MangaTextEffect(
        position: Vector2(position.x, position.y - 20),
        text: 'KICK!',
        fillColor: ComicTheme.energyCyan,
        initialScale: 0.4,
        targetScale: 0.8,
      ));
    }
  }

  void performDash() {
    isDashing = true;
    dashTimer = dashDuration;
    dashCooldown = 0.7;
    velocity.y = 0;
    velocity.x = facingDirection * dashSpeed;
    action = PlayerAction.dashing;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.5),
      text: 'DODODO!',
      fillColor: ComicTheme.energyCyan,
      targetScale: 1.3,
    ));

    game.add(SpeedLineStreakComponent(
      position: Vector2(position.x - 40, position.y - size.y),
      size: Vector2(80, size.y),
      direction: Vector2(facingDirection.toDouble(), 0),
    ));
  }

  void performAttack() {
    attackCooldown = 0.28;
    attackAnimTimer = 0.26;

    comboIndex = (comboIndex + 1) % 3;
    final attackActions = [
      PlayerAction.attack1,
      PlayerAction.attack2,
      PlayerAction.attack3
    ];
    action = attackActions[comboIndex];
    _tickers[action]?.reset();

    final texts = ['SLASH!', 'SHING!!', 'ZUBATTO!!!'];
    final colors = [
      ComicTheme.comicYellow,
      ComicTheme.energyCyan,
      ComicTheme.actionRed
    ];

    game.add(SlashArcEffect(
      position: Vector2(
          position.x + facingDirection * 26, position.y - size.y * 0.5),
      slashFlipped: facingDirection < 0,
      slashColor: colors[comboIndex],
      radius: 46.0 + comboIndex * 6,
    ));

    game.add(MangaTextEffect(
      position: Vector2(
          position.x + facingDirection * 35, position.y - size.y * 0.7),
      text: texts[comboIndex],
      fillColor: colors[comboIndex],
      targetScale: 1.1 + comboIndex * 0.3,
    ));

    _checkMeleeHit();
  }

  void performThrowKunai() {
    kunaiCooldown = 0.35;
    attackAnimTimer = 0.18;
    action = PlayerAction.attack1;
    _tickers[action]?.reset();

    game.add(InkKunai(
      position: Vector2(
          position.x + facingDirection * 15, position.y - size.y * 0.55),
      velocity: Vector2(facingDirection * 620.0, 0),
    ));
  }

  void performUltimate() {
    spirit = 0.0;
    invulnerableTimer = 2.0;
    attackAnimTimer = 0.5;
    action = PlayerAction.attack3;
    _tickers[action]?.reset();

    game.triggerBossCutIn(
      bossName: 'KAITO',
      quote: 'SECRET INK TECHNIQUE: 1000 CRANE HEAVEN SLASH!!',
      portraitColor: ComicTheme.energyCyan,
      portraitAsset: CartoonAssets.portraitKaito,
    );

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 20),
      text: 'OUGI: OMNI-SLASH!!',
      fillColor: ComicTheme.comicYellow,
      targetScale: 2.2,
      maxLifetime: 1.5,
    ));

    for (int i = 0; i < 4; i++) {
      game.add(SlashArcEffect(
        position: Vector2(position.x + (i - 1.5) * 60, position.y - 30),
        slashColor: ComicTheme.comicYellow,
        radius: 80,
      ));
    }

    for (final grunt in game.children.whereType<EnemyGrunt>()) {
      grunt.takeDamage(100);
    }
    for (final drone in game.children.whereType<EnemyDrone>()) {
      drone.takeDamage(100);
    }
    if (game.activeBoss != null && !game.activeBoss!.isDefeated) {
      game.activeBoss!.takeDamage(85);
      game.activeBoss!.breakGuard();
    }
  }

  void _checkMeleeHit() {
    const range = 65.0;
    final hitCenter = position.x + facingDirection * 30;

    for (final grunt in game.children.whereType<EnemyGrunt>()) {
      if ((grunt.position.x - hitCenter).abs() < range &&
          (grunt.position.y - position.y).abs() < 50) {
        final dmg = 20.0 + comboIndex * 12.0;
        grunt.takeDamage(dmg);
        _registerHit();
      }
    }

    for (final drone in game.children.whereType<EnemyDrone>()) {
      if ((drone.position.x - hitCenter).abs() < range &&
          (drone.position.y - position.y).abs() < 60) {
        final dmg = 25.0 + comboIndex * 10.0;
        drone.takeDamage(dmg);
        _registerHit();
      }
    }

    final boss = game.activeBoss;
    if (boss != null && !boss.isDefeated) {
      if ((boss.position.x - hitCenter).abs() < 75 &&
          (boss.position.y - position.y).abs() < 70) {
        final dmg = 18.0 + comboIndex * 14.0;
        boss.takeDamage(dmg);
        _registerHit();
      }
    }
  }

  void _registerHit() {
    comboCount++;
    comboTimer = 2.5;
    spirit = (spirit + 8.0).clamp(0.0, 100.0);
    game.addScore(50 * comboCount);
  }

  void takeDamage(int amount) {
    if (isInvulnerable) return;

    hp -= amount;
    invulnerableTimer = 1.3;
    hurtAnimTimer = 0.35;
    action = PlayerAction.hurt;
    velocity.y = -260;
    velocity.x = -facingDirection * 180;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: 'OUCH!!',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.4,
    ));

    if (hp <= 0) {
      hp = 0;
      game.onPlayerDied();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (invulnerableTimer > 0) invulnerableTimer -= dt;
    if (hurtAnimTimer > 0) hurtAnimTimer -= dt;
    if (attackCooldown > 0) attackCooldown -= dt;
    if (attackAnimTimer > 0) attackAnimTimer -= dt;
    if (kunaiCooldown > 0) kunaiCooldown -= dt;
    if (dashCooldown > 0) dashCooldown -= dt;

    if (comboCount > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        comboCount = 0;
      }
    }

    // Dash update
    if (isDashing) {
      dashTimer -= dt;
      position.x += velocity.x * dt;
      action = PlayerAction.dashing;
      _tickers[action]?.update(dt);
      if (dashTimer <= 0) {
        isDashing = false;
      }
      return;
    }

    // Horizontal Movement
    if (moveInput.abs() > 0.1) {
      velocity.x = moveInput * moveSpeed;
      facingDirection = moveInput > 0 ? 1 : -1;
    } else {
      velocity.x = 0;
    }

    // Determine active animation state
    if (hurtAnimTimer > 0) {
      action = PlayerAction.hurt;
    } else if (attackAnimTimer > 0) {
      // Keep current attack1/attack2/attack3 action
    } else if (!isOnGround) {
      action = velocity.y < 0 ? PlayerAction.jumping : PlayerAction.falling;
    } else if (moveInput.abs() > 0.1) {
      action = PlayerAction.running;
    } else {
      action = PlayerAction.idle;
    }

    _tickers[action]?.update(dt);

    // Gravity
    velocity.y += gravity * dt;
    if (isTouchingWall && velocity.y > 60) {
      velocity.y = 80;
    }

    position += velocity * dt;

    if (position.y > 1200) {
      takeDamage(1);
      position = Vector2(game.currentSpawnPoint.x, game.currentSpawnPoint.y);
      velocity = Vector2.zero();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is ComicPlatform) {
      final playerBottom = position.y;
      final platformTop = other.position.y;

      if (velocity.y > 0 && (playerBottom - platformTop).abs() < 18) {
        position.y = platformTop;
        velocity.y = 0;
        isOnGround = true;
        other.stepOn();
      } else if (position.y > other.position.y + 10) {
        isTouchingWall = true;
        wallDirection = (position.x < other.position.x) ? 1 : -1;
      }
    } else if (other is MangaSpringPad) {
      if (velocity.y > 0) {
        other.triggerSpring();
        velocity.y = -other.launchPower;
        isOnGround = false;
      }
    } else if (other is SpikeTrap || other is InkSawBlade) {
      takeDamage(1);
    } else if (other is InkScroll) {
      other.collect();
    } else if (other is RamenBowl) {
      other.collect();
    } else if (other is ToriiGateExit) {
      other.triggerEnter();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is ComicPlatform) {
      isOnGround = false;
      isTouchingWall = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (invulnerableTimer > 0 &&
        hurtAnimTimer <= 0 &&
        (_animTime * 20).toInt() % 2 == 0) {
      return;
    }

    final ticker = _tickers[action] ?? _tickers[PlayerAction.idle]!;
    final sprite = ticker.getSprite();

    final isAttackSheet = action == PlayerAction.attack1 ||
        action == PlayerAction.attack2 ||
        action == PlayerAction.attack3;
    final renderW = isAttackSheet ? 82.0 : 72.0;
    const renderH = 72.0;

    canvas.save();
    // Anchor.bottomCenter: origin in local render is (size.x/2, size.y)
    canvas.translate(size.x / 2, size.y + 5);
    if (facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    sprite.render(
      canvas,
      position: Vector2(-renderW / 2, -renderH),
      size: Vector2(renderW, renderH),
    );

    canvas.restore();
  }
}
