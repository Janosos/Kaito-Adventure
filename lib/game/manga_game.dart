import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cartoon_assets.dart';
import 'components/player.dart';
import 'components/bosses/boss_base.dart';
import 'levels/level_one.dart';
import 'levels/level_two.dart';

class MangaGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  late MangaPlayer player;
  BossBase? activeBoss;

  int currentLevelIndex = 1;
  int score = 0;
  Vector2 currentSpawnPoint = Vector2(80, 480);
  Component? _currentLevelComponent;

  // Cut-in data
  String cutInBossName = '';
  String cutInQuote = '';
  Color cutInColor = Colors.red;
  String cutInPortraitAsset = CartoonAssets.portraitKaito;

  // Key state tracking
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  Color backgroundColor() => const Color(0xFF141419);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all 2D Cartoon Sprite Sheets, Icons & Illustrations
    await CartoonAssets.preloadAll(images);

    // Setup Manga Camera with smooth tracking
    camera.viewport = FixedResolutionViewport(resolution: Vector2(960, 540));

    // Load initial level
    await loadLevel(currentLevelIndex);

    // Show initial HUD and controls
    overlays.add('hud');
    overlays.add('virtual_controls');
  }

  Future<void> loadLevel(int level) async {
    currentLevelIndex = level;
    activeBoss = null;

    if (_currentLevelComponent != null) {
      remove(_currentLevelComponent!);
    }

    if (children.whereType<MangaPlayer>().isNotEmpty) {
      remove(player);
    }

    if (level == 1) {
      currentSpawnPoint = LevelOne.spawnPosition;
      _currentLevelComponent = LevelOne();
    } else {
      currentSpawnPoint = LevelTwo.spawnPosition;
      _currentLevelComponent = LevelTwo();
    }

    await add(_currentLevelComponent!);

    // Instantiate Player
    player = MangaPlayer(position: currentSpawnPoint.clone());
    await add(player);

    // Set camera to follow player smoothly
    camera.follow(player, maxSpeed: 600, snap: true);
  }

  void addScore(int points) {
    score += points;
  }

  void addSpirit(double amount) {
    player.spirit = (player.spirit + amount).clamp(0.0, 100.0);
  }

  void healPlayer(int amount) {
    player.hp = (player.hp + amount).clamp(0, player.maxHp);
  }

  void triggerBossCutIn({
    required String bossName,
    required String quote,
    required Color portraitColor,
    String? portraitAsset,
  }) {
    cutInBossName = bossName;
    cutInQuote = quote;
    cutInColor = portraitColor;
    if (portraitAsset != null) {
      cutInPortraitAsset = portraitAsset;
    } else if (bossName.contains('KAITO')) {
      cutInPortraitAsset = CartoonAssets.portraitKaito;
    } else if (bossName.contains('KUROKAGE')) {
      cutInPortraitAsset = CartoonAssets.portraitKurokage;
    } else {
      cutInPortraitAsset = CartoonAssets.portraitRyuKotei;
    }

    overlays.add('manga_cutin');
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (overlays.isActive('manga_cutin')) {
        overlays.remove('manga_cutin');
      }
    });
  }

  void onPlayerDied() {
    pauseEngine();
    overlays.add('game_over');
  }

  void onBossDefeated(BossBase boss) {
    addScore(1000);
    Future.delayed(const Duration(milliseconds: 1400), () {
      pauseEngine();
      overlays.add('victory');
    });
  }

  void restartCurrentLevel() {
    overlays.remove('game_over');
    overlays.remove('victory');
    resumeEngine();
    loadLevel(currentLevelIndex);
  }

  void nextLevel() {
    overlays.remove('victory');
    resumeEngine();
    if (currentLevelIndex == 1) {
      loadLevel(2);
    } else {
      loadLevel(1);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        togglePause();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.handled;
  }

  void togglePause() {
    if (overlays.isActive('pause')) {
      overlays.remove('pause');
      resumeEngine();
    } else {
      pauseEngine();
      overlays.add('pause');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isLoaded && children.contains(player)) {
      double horizontal = 0.0;
      if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        horizontal -= 1.0;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        horizontal += 1.0;
      }

      final jump = _pressedKeys.contains(LogicalKeyboardKey.space) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyW) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowUp);

      final attack = _pressedKeys.contains(LogicalKeyboardKey.keyJ) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyX);

      final dash = _pressedKeys.contains(LogicalKeyboardKey.keyK) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyC) ||
          _pressedKeys.contains(LogicalKeyboardKey.shiftLeft);

      final ranged = _pressedKeys.contains(LogicalKeyboardKey.keyL) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyZ);

      final ultimate = _pressedKeys.contains(LogicalKeyboardKey.keyU) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyV);

      player.handleInput(
        horizontal: horizontal,
        jump: jump,
        attack: attack,
        dash: dash,
        ranged: ranged,
        ultimate: ultimate,
      );
    }
  }
}
