import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:manga_platformer/game/cartoon_assets.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/game/services/audio_service.dart';
import 'package:manga_platformer/game/services/lan_multiplayer_service.dart';
import 'package:manga_platformer/ui/comic_theme.dart';
import 'manga_effects.dart';
import 'projectiles.dart';
import 'platform.dart';
import 'traps.dart';
import 'collectibles.dart';
import 'enemies/enemy_grunt.dart';
import 'enemies/enemy_drone.dart';
import 'enemies/enemy_oni_archer.dart';

enum PlayerAction {
  idle,
  running,
  jumping,
  falling,
  dashing,
  attack1,
  attack2,
  attack3,
  hurt,
  death,
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
  final double moveSpeed = 240.0;
  final double jumpForce = -485.0;
  final double gravity = 1100.0;
  bool isOnGround = false;
  bool isTouchingWall = false;
  int wallDirection = 0; // -1 left, 1 right
  ComicPlatform? _standingPlatform;

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
  static const double maxKunaiCooldown = 5.0;
  double kunaiCooldown = 0.0;
  double externalWindX = 0.0;

  // Invulnerability, Hurt & Death Animation State
  double invulnerableTimer = 0.0;
  double hurtAnimTimer = 0.0;
  bool isDying = false;
  double deathAnimTimer = 0.0;
  bool _spawnedDeathCollapseFx = false;
  bool get isInvulnerable => invulnerableTimer > 0 || isDashing || isDying;

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
      PlayerAction.death: CartoonAssets.animation(
        imgs,
        'characters/kaito_death.png',
        frames: 7,
        textureSize: Vector2(144, 128),
        stepTime: 0.17,
        loop: false,
      ).createTicker(),
    };
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(24, 48), position: Vector2(5, 4)));
  }

  // Input Handling (Separated so keyboard polling never overwrites touch joystick state!)
  double keyboardMoveInput = 0.0;
  double touchMoveInput = 0.0;
  double get moveInput =>
      touchMoveInput.abs() > 0.01 ? touchMoveInput : keyboardMoveInput;
  set moveInput(double value) {
    touchMoveInput = value;
  }

  bool jumpPressed = false;

  void handleInput({
    required double horizontal,
    required bool jump,
    required bool attack,
    required bool dash,
    required bool ranged,
    required bool ultimate,
  }) {
    if (isDying) {
      keyboardMoveInput = 0.0;
      touchMoveInput = 0.0;
      return;
    }
    keyboardMoveInput = horizontal;

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
    if (isDying) return;
    if (isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
      _standingPlatform = null;
      AudioService.playSfx(AudioService.sfxJump);
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
      AudioService.playSfx(AudioService.sfxJump);
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
    if (isDying) return;
    isDashing = true;
    dashTimer = dashDuration;
    dashCooldown = 0.65;
    velocity.y = 0;
    velocity.x = facingDirection * dashSpeed;
    action = PlayerAction.dashing;
    AudioService.playSfx(AudioService.sfxDash);

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
    if (isDying) return;
    attackCooldown = 0.25;
    attackAnimTimer = 0.26;

    comboIndex = (comboIndex + 1) % 3;
    final attackActions = [
      PlayerAction.attack1,
      PlayerAction.attack2,
      PlayerAction.attack3
    ];
    action = attackActions[comboIndex];
    _tickers[action]?.reset();

    AudioService.playSfx(
      comboIndex == 2 ? AudioService.sfxSlashHeavy : AudioService.sfxSlash,
    );

    // Subtle forward lunge on slash
    position.x = (position.x + facingDirection * 4.0)
        .clamp(game.minPlayerX, game.maxPlayerX);

    final texts = ['SLASH!', 'SHING!!', 'ZUBATTO!!!'];
    final colors = [
      ComicTheme.comicYellow,
      ComicTheme.energyCyan,
      ComicTheme.actionRed
    ];

    game.add(SlashArcEffect(
      position: Vector2(
          position.x + facingDirection * 28, position.y - size.y * 0.5),
      slashFlipped: facingDirection < 0,
      slashColor: colors[comboIndex],
      radius: 48.0 + comboIndex * 6,
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
    if (isDying || kunaiCooldown > 0) return;
    kunaiCooldown = maxKunaiCooldown;
    attackAnimTimer = 0.18;
    action = PlayerAction.attack1;
    _tickers[action]?.reset();

    AudioService.playSfx(AudioService.sfxKunaiThrow);

    game.add(MangaTextEffect(
      position: Vector2(
          position.x + facingDirection * 24, position.y - size.y * 0.75),
      text: 'KUNAI!!',
      fillColor: ComicTheme.energyCyan,
      initialScale: 0.4,
      targetScale: 0.95,
    ));

    game.add(InkKunai(
      position: Vector2(
          position.x + facingDirection * 15, position.y - size.y * 0.55),
      velocity: Vector2(facingDirection * 640.0, 0),
      damage: 32.0,
    ));
  }

  void performUltimate() {
    if (isDying) return;
    spirit = 0.0;
    invulnerableTimer = 2.0;
    attackAnimTimer = 0.5;
    action = PlayerAction.attack3;
    _tickers[action]?.reset();

    AudioService.playSfx(AudioService.sfxOugiRelease);
    AudioService.heavyHaptic();

    // In-game dynamic Ougi sequence: No full-screen modal blocking the view!
    // Spawns radiating anime celestial slash arcs, shockwave dust, and stylish manga onomatopoeia
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 32),
      text: 'OUGI: CELESTIAL BLADE FLURRY!!',
      fillColor: ComicTheme.comicYellow,
      initialScale: 0.55,
      targetScale: 1.55,
      maxLifetime: 1.15,
    ));

    // Dual ground dust bursts radiating from Kaito's stance
    game.add(MangaDustEffect(position: Vector2(position.x - 38, position.y)));
    game.add(MangaDustEffect(position: Vector2(position.x + 38, position.y)));

    // Multi-angle vibrant slash arcs radiating around Kaito
    final arcColors = [
      ComicTheme.energyCyan,
      ComicTheme.comicYellow,
      ComicTheme.actionRed,
      ComicTheme.energyCyan,
      ComicTheme.comicYellow,
      ComicTheme.actionRed,
    ];
    for (int i = 0; i < 6; i++) {
      final xOffset = (i - 2.5) * 48.0;
      final yOffset = ((i % 2 == 0) ? -22.0 : 8.0);
      game.add(SlashArcEffect(
        position: Vector2(position.x + xOffset, position.y - size.y * 0.5 + yOffset),
        slashColor: arcColors[i],
        slashFlipped: i.isOdd,
        radius: 64,
      ));
    }

    for (final grunt in game.queryWorld<EnemyGrunt>().toList()) {
      if ((grunt.position.x - position.x).abs() < 420) {
        grunt.takeDamage(100, knockbackDir: facingDirection, knockbackForce: 20);
      }
    }
    for (final drone in game.queryWorld<EnemyDrone>().toList()) {
      if ((drone.position.x - position.x).abs() < 420) {
        drone.takeDamage(100, knockbackDir: facingDirection, knockbackForce: 20);
      }
    }
    for (final archer in game.queryWorld<EnemyOniArcher>().toList()) {
      if ((archer.position.x - position.x).abs() < 420) {
        archer.takeDamage(100, knockbackDir: facingDirection, knockbackForce: 20);
      }
    }
    if (game.activeBoss != null && !game.activeBoss!.isDefeated) {
      game.activeBoss!.takeDamage(
        90,
        knockbackDir: facingDirection,
        knockbackForce: 14,
      );
      game.activeBoss!.breakGuard();
    }
    if (game.isMultiplayer && game.pvpRemotePlayer != null) {
      final remote = game.pvpRemotePlayer!;
      if ((remote.position.x - position.x).abs() < 420) {
        final dmg = 45.0;
        final kb = Vector2(facingDirection * 24.0, -8.0);
        remote.takeDamage(dmg, knockback: kb);
        LanMultiplayerService.instance.sendHitDamage(
          damage: dmg,
          knockbackX: kb.x,
          knockbackY: kb.y,
          targetRemainingHp: remote.hp,
        );
      }
    }
  }

  bool _isInSlashArc(Vector2 targetCenter, {double extraReach = 0.0}) {
    final playerCenterY = position.y - size.y * 0.5;
    final dx = (targetCenter.x - position.x) * facingDirection;
    final dy = (targetCenter.y - playerCenterY).abs();
    return dx >= -22.0 && dx <= (92.0 + extraReach) && dy <= (68.0 + extraReach);
  }

  void _checkMeleeHit() {
    final kbForce = 11.0 + comboIndex * 3.0;

    // 1. Hit Enemy Grunts (Shadow Ninjas)
    for (final grunt in game.queryWorld<EnemyGrunt>().toList()) {
      final center = Vector2(grunt.position.x, grunt.position.y - grunt.size.y * 0.5);
      if (_isInSlashArc(center)) {
        final dmg = 22.0 + comboIndex * 10.0;
        grunt.takeDamage(
          dmg,
          knockbackDir: facingDirection,
          knockbackForce: kbForce,
        );
        _registerHit();
      }
    }

    // 2. Hit Enemy Drones (Tengu Flyers - Anchor.center)
    for (final drone in game.queryWorld<EnemyDrone>().toList()) {
      if (_isInSlashArc(drone.position, extraReach: 12.0)) {
        final dmg = 25.0 + comboIndex * 10.0;
        drone.takeDamage(
          dmg,
          knockbackDir: facingDirection,
          knockbackForce: kbForce,
        );
        _registerHit();
      }
    }

    // 3. Hit Enemy Oni Archers
    for (final archer in game.queryWorld<EnemyOniArcher>().toList()) {
      final center =
          Vector2(archer.position.x, archer.position.y - archer.size.y * 0.5);
      if (_isInSlashArc(center)) {
        final dmg = 24.0 + comboIndex * 10.0;
        archer.takeDamage(
          dmg,
          knockbackDir: facingDirection,
          knockbackForce: kbForce,
        );
        _registerHit();
      }
    }

    // 4. Hit Active Boss
    final boss = game.activeBoss;
    if (boss != null && !boss.isDefeated) {
      final bossCenter =
          Vector2(boss.position.x, boss.position.y - boss.size.y * 0.5);
      if (_isInSlashArc(bossCenter, extraReach: 22.0)) {
        final dmg = 20.0 + comboIndex * 12.0;
        boss.takeDamage(
          dmg,
          knockbackDir: facingDirection,
          knockbackForce: 7.0 + comboIndex * 2.0,
        );
        _registerHit();
      }
    }

    // 5. Smash Breakable Supply Crates
    for (final crate in game.queryWorld<BreakableCrate>().toList()) {
      final center =
          Vector2(crate.position.x, crate.position.y - crate.size.y * 0.5);
      if (_isInSlashArc(center)) {
        crate.hit();
      }
    }

    // 6. Activate Switch Orbs & Taiko Bounce Drums with Slash!
    for (final sw in game.queryWorld<SwitchOrb>().toList()) {
      final center = Vector2(sw.position.x, sw.position.y - sw.size.y * 0.5);
      if (_isInSlashArc(center)) {
        sw.triggerSwitch();
      }
    }
    for (final drum in game.queryWorld<TaikoBounceDrum>().toList()) {
      if (_isInSlashArc(drum.position, extraReach: 10.0)) {
        drum.triggerBounce();
      }
    }

    // 7. PvP Duel: Hit Remote Opponent
    if (game.isMultiplayer && game.pvpRemotePlayer != null) {
      final remote = game.pvpRemotePlayer!;
      if (!remote.isDying) {
        final remoteCenter = Vector2(remote.position.x, remote.position.y - remote.size.y * 0.5);
        if (_isInSlashArc(remoteCenter, extraReach: 15.0)) {
          final dmg = 15.0 + comboIndex * 8.0;
          final kbDir = facingDirection;
          final kbForce = 12.0 + comboIndex * 4.0;
          remote.takeDamage(dmg, knockback: Vector2(kbDir * kbForce, -4.0));
          _registerHit();
          LanMultiplayerService.instance.sendHitDamage(
            damage: dmg,
            knockbackX: kbDir * kbForce,
            knockbackY: -4.0,
            targetRemainingHp: remote.hp,
          );
        }
      }
    }
  }

  void _registerHit() {
    comboCount++;
    comboTimer = 2.5;
    final spiritGain = game.isMultiplayer ? 3.0 : 9.0;
    spirit = (spirit + spiritGain).clamp(0.0, 100.0);
    game.addScore(50 * comboCount);
  }

  void takeMultiplayerDamage(double amount, {double knockbackX = 0, double knockbackY = 0}) {
    if (isInvulnerable || isDying) return;

    hp -= amount.toInt();
    if (hp <= 0) {
      hp = 0;
      _startDeathSequence();
      LanMultiplayerService.instance.sendRingOut(
        defeatedNickname: LanMultiplayerService.instance.myNickname,
      );
      game.onMultiplayerMatchOver(
        winnerName: LanMultiplayerService.instance.opponentNickname,
        didLocalWin: false,
      );
      return;
    }

    AudioService.playSfx(AudioService.sfxPlayerHurt);
    AudioService.heavyHaptic();

    invulnerableTimer = 0.8;
    hurtAnimTimer = 0.30;
    action = PlayerAction.hurt;
    if (knockbackX != 0 || knockbackY != 0) {
      velocity.x = knockbackX * 25.0;
      velocity.y = knockbackY * 25.0;
    } else {
      velocity.y = -220;
      velocity.x = -facingDirection * 120;
    }

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: '-${amount.toInt()}',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.4,
    ));
  }

  void takeDamage(int amount) {
    if (isInvulnerable || isDying) return;

    hp -= amount;
    if (hp <= 0) {
      hp = 0;
      _startDeathSequence();
      return;
    }

    AudioService.playSfx(AudioService.sfxPlayerHurt);
    AudioService.heavyHaptic();

    invulnerableTimer = 1.3;
    hurtAnimTimer = 0.35;
    action = PlayerAction.hurt;
    velocity.y = -250;
    velocity.x = -facingDirection * 150;

    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y * 0.7),
      text: 'OUCH!!',
      fillColor: ComicTheme.actionRed,
      targetScale: 1.4,
    ));
  }

  void _startDeathSequence() {
    if (isDying) return;
    isDying = true;
    isDashing = false;
    touchMoveInput = 0.0;
    keyboardMoveInput = 0.0;
    deathAnimTimer = 1.65;
    _spawnedDeathCollapseFx = false;
    action = PlayerAction.death;
    _tickers[PlayerAction.death]?.reset();

    AudioService.playSfx(AudioService.sfxPlayerDeath);
    AudioService.heavyHaptic();

    // Ensure Kaito is visible on screen if he died near/in a pit
    if (position.y > 520) {
      position.y = 505;
    }
    isOnGround = false;
    velocity.y = -275;
    velocity.x = -facingDirection * 105;

    game.add(MangaDustEffect(position: position.clone()));
    game.add(MangaTextEffect(
      position: Vector2(position.x, position.y - size.y - 16),
      text: 'DEFEATED!!',
      fillColor: ComicTheme.actionRed,
      initialScale: 0.55,
      targetScale: 1.85,
      maxLifetime: 1.45,
    ));

    game.onPlayerDied();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    // Dramatic Death Animation Sequence before showing Game Over screen
    if (isDying) {
      action = PlayerAction.death;
      _tickers[PlayerAction.death]?.update(dt);
      deathAnimTimer -= dt;

      if (!isOnGround && position.y < 515) {
        velocity.y += gravity * 0.85 * dt;
        position += velocity * dt;
        position.x = position.x.clamp(game.minPlayerX, game.maxPlayerX);
        if (position.y >= 515) {
          position.y = 515;
          velocity = Vector2.zero();
          isOnGround = true;
        }
      } else {
        velocity.x *= (1.0 - dt * 6.5).clamp(0.0, 1.0);
        velocity.y = 0;
        position.x = (position.x + velocity.x * dt)
            .clamp(game.minPlayerX, game.maxPlayerX);
      }

      if (!_spawnedDeathCollapseFx && deathAnimTimer <= 1.15) {
        _spawnedDeathCollapseFx = true;
        game.add(MangaDustEffect(position: position.clone()));
        game.add(MangaTextEffect(
          position: Vector2(position.x + 10, position.y - size.y * 0.65),
          text: 'THUD...',
          fillColor: ComicTheme.comicYellow,
          initialScale: 0.4,
          targetScale: 1.1,
          maxLifetime: 0.9,
        ));
      }

      if (deathAnimTimer <= 0) {
        game.finalizePlayerDeath();
      }
      return;
    }

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

    // Follow moving platform if standing on one
    if (isOnGround && _standingPlatform != null) {
      position += _standingPlatform!.frameDelta;
    }

    // Dash update
    if (isDashing) {
      dashTimer -= dt;
      position.x = (position.x + velocity.x * dt)
          .clamp(game.minPlayerX, game.maxPlayerX);
      action = PlayerAction.dashing;
      _tickers[action]?.update(dt);
      if (dashTimer <= 0) {
        isDashing = false;
      }
      return;
    }

    // Horizontal Movement (with Slippery Ice Physics on Frostfang Ice Platforms!)
    final bool onSlipperyIce =
        isOnGround && (_standingPlatform?.isSlipperyIce ?? false);
    if (onSlipperyIce) {
      if (moveInput.abs() > 0.1) {
        final targetVx = moveInput * moveSpeed * 1.15;
        velocity.x += (targetVx - velocity.x) * (dt * 4.5).clamp(0.0, 1.0);
        facingDirection = moveInput > 0 ? 1 : -1;
      } else if (hurtAnimTimer <= 0) {
        velocity.x *= (1.0 - dt * 1.85).clamp(0.0, 1.0);
        if (velocity.x.abs() < 6.0) velocity.x = 0.0;
      }
    } else {
      if (moveInput.abs() > 0.1) {
        velocity.x = moveInput * moveSpeed;
        facingDirection = moveInput > 0 ? 1 : -1;
      } else if (hurtAnimTimer <= 0) {
        velocity.x = 0;
      }
    }

    // Apply Environmental Crosswind (e.g. Level 4 Blizzard Gusts)
    if (externalWindX.abs() > 0.1 && !isDashing) {
      position.x += externalWindX * dt;
      externalWindX = 0.0;
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
    position.x = position.x.clamp(game.minPlayerX, game.maxPlayerX);

    // Pit fall respawn
    if (position.y > 590) {
      takeDamage(1);
      if (hp > 0) {
        position = game.currentSpawnPoint.clone();
        velocity = Vector2.zero();
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is ComicPlatform) {
      final playerBottom = position.y;
      final platformTop = other.position.y;

      if (velocity.y >= 0 && (playerBottom - platformTop).abs() < 22) {
        position.y = platformTop;
        velocity.y = 0;
        isOnGround = true;
        _standingPlatform = other;
        other.stepOn();
      } else if (position.y > other.position.y + 12) {
        isTouchingWall = true;
        wallDirection = (position.x < other.position.x) ? 1 : -1;
      }
    } else if (other is MangaSpringPad) {
      if (velocity.y >= 0) {
        other.triggerSpring();
        velocity.y = -other.launchPower;
        isOnGround = false;
        _standingPlatform = null;
      }
    } else if (other is TaikoBounceDrum) {
      other.triggerBounce();
      _standingPlatform = null;
    } else if (other is CheckpointLantern) {
      other.activate();
    } else if (other is SwitchOrb) {
      other.triggerSwitch();
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
      if (_standingPlatform == other) {
        _standingPlatform = null;
      }
      isOnGround = false;
      isTouchingWall = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isDying &&
        invulnerableTimer > 0 &&
        hurtAnimTimer <= 0 &&
        (_animTime * 20).toInt() % 2 == 0) {
      return;
    }

    final ticker = _tickers[action] ?? _tickers[PlayerAction.idle]!;
    final sprite = ticker.getSprite();

    final isWideSheet = action == PlayerAction.attack1 ||
        action == PlayerAction.attack2 ||
        action == PlayerAction.attack3 ||
        action == PlayerAction.death;
    final renderW = isWideSheet ? 82.0 : 72.0;
    const renderH = 72.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y + 5);

    if (isDying) {
      // Subtle dramatic crimson spotlight ring under Kaito during death collapse
      final ringPaint = Paint()
        ..color = ComicTheme.actionRed.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -4), width: 68, height: 14),
        ringPaint,
      );
    }

    if (facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    Paint? overridePaint;
    if (game.isMultiplayer) {
      final myColor = LanMultiplayerService.instance.myColor;
      overridePaint = Paint()
        ..colorFilter = ColorFilter.mode(myColor, BlendMode.hue);
    }

    sprite.render(
      canvas,
      position: Vector2(-renderW / 2, -renderH),
      size: Vector2(renderW, renderH),
      overridePaint: overridePaint,
    );

    canvas.restore();
  }
}
