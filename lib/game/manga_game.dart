import 'dart:async';
import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/app_localizations.dart';
import '../ui/comic_theme.dart';
import 'cartoon_assets.dart';
import 'components/player.dart';
import 'components/projectiles.dart';
import 'components/manga_effects.dart';
import 'components/bosses/boss_base.dart';
import 'services/audio_service.dart';
import 'services/lan_multiplayer_service.dart';
import 'components/remote_player.dart';
import 'levels/pvp_arena.dart';
import 'levels/level_one.dart';
import 'levels/level_two.dart';
import 'levels/level_three.dart';
import 'levels/level_four.dart';
import 'levels/level_five.dart';

class MangaGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  static const int totalLevels = 5;

  late MangaPlayer player;
  BossBase? activeBoss;

  int currentLevelIndex = 1;
  int unlockedLevel = 5;
  int score = 0;
  bool isGameOver = false;
  bool isLevelVictory = false;
  Vector2 currentSpawnPoint = Vector2(80, 380);
  Component? _currentLevelComponent;
  bool _hasShownInitialSplash = false;

  // World & Arena Bounds (Dynamic per Level!)
  double minPlayerX = 24.0;
  double maxPlayerX = 4580.0;
  bool isBossArenaLocked = false;
  double currentBossGateX = 3650.0;
  double currentArenaCamX = 4140.0;

  // Local WiFi PvP Multiplayer State
  bool isMultiplayer = false;
  PvPArenaLevel? pvpArena;
  RemotePlayer? get pvpRemotePlayer => pvpArena?.remotePlayers.values.firstOrNull;
  StreamSubscription? _multiplayerSub;
  VoidCallback? onRequestGameFocus;
  bool _multiplayerNotifiersBound = false;
  bool _startingPvPMatch = false;
  int _startedMatchSessionId = 0;
  int? _lastSentHp;
  int? _lastSentFacing;
  String? _lastSentAction;
  double _lastSentX = double.nan;
  double _lastSentY = double.nan;
  double _stateSyncAccumulator = 0.0;
  double currentLevelWidth = 4620.0;
  double viewportWidth = 960.0;

  /// Fast horizontal camera frustum check for Mali/Adreno/Web GPU culling
  bool isInView(double worldX, [double margin = 740.0]) {
    if (!isLoaded) return true;
    final halfView = viewportWidth * 0.5;
    return (worldX - camera.viewfinder.position.x).abs() <=
        (halfView + margin - 480.0);
  }

  @override
  void onGameResize(Vector2 size) {
    if (size.y > 0 && size.x > 0) {
      // Always compute landscape aspect using max/min so transient portrait sizes
      // during Android Home/Recents transitions never distort or reset the camera!
      final w = math.max(size.x, size.y);
      final h = math.min(size.x, size.y);
      final aspect = (w / h).clamp(1.33, 2.40);
      final nextWidth = (540.0 * aspect).roundToDouble();
      if (!isLoaded || (nextWidth - viewportWidth).abs() > 2.0) {
        viewportWidth = nextWidth;
        camera.viewport = FixedResolutionViewport(
          resolution: Vector2(viewportWidth, 540.0),
        );
      }
    }
    super.onGameResize(size);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    // In active multiplayer matches (especially on Web when clicking/focusing),
    // keep the simulation running so remote packets and fighters never freeze.
    final inMultiplayerMatch = isMultiplayer &&
        overlays.isActive('multiplayer_hud') &&
        !overlays.isActive('multiplayer_results') &&
        !overlays.isActive('pause') &&
        !overlays.isActive('settings') &&
        !overlays.isActive('main_menu');

    // Prevent Flame's default lifecycle handler from resetting or unpausing menus!
    if (state != AppLifecycleState.resumed) {
      _pressedKeys.clear();
      if (isLoaded && world.children.contains(player)) {
        player.touchMoveInput = 0.0;
        player.keyboardMoveInput = 0.0;
      }
      if (inMultiplayerMatch) {
        resumeEngine();
        return;
      }
      // If the player was in active solo gameplay, pause safely without losing progress!
      final inActiveGameplay = overlays.isActive('hud') &&
          !overlays.isActive('pause') &&
          !overlays.isActive('settings') &&
          !overlays.isActive('game_over') &&
          !overlays.isActive('victory') &&
          !overlays.isActive('main_menu') &&
          !overlays.isActive('intro') &&
          !overlays.isActive('story_intro') &&
          !overlays.isActive('chapter_select');
      if (inActiveGameplay) {
        pauseEngine();
        _addOverlay('pause');
      } else {
        pauseEngine();
      }
    } else {
      // Only resume engine if we are in active gameplay (solo or multiplayer) with no modal/menu open
      final shouldResume = (overlays.isActive('hud') || inMultiplayerMatch) &&
          !overlays.isActive('pause') &&
          !overlays.isActive('settings') &&
          !overlays.isActive('game_over') &&
          !overlays.isActive('victory') &&
          !overlays.isActive('main_menu') &&
          !overlays.isActive('intro') &&
          !overlays.isActive('story_intro') &&
          !overlays.isActive('chapter_select') &&
          !AppLocalizations.isEditingHudLayout.value;
      if (shouldResume) {
        resumeEngine();
      } else {
        pauseEngine();
      }
    }
  }

  // Cut-in data
  String cutInBossName = '';
  String cutInQuote = '';
  Color cutInColor = Colors.red;
  String cutInPortraitAsset = CartoonAssets.portraitKaito;

  // Key state tracking
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  Color backgroundColor() => const Color(0xFF141419);

  /// Route all game entities/effects into `world` so `camera` scrolls them properly!
  /// Includes active effect throttling for smooth 60/120 FPS on Snapdragon Adreno & MediaTek Mali GPUs.
  @override
  FutureOr<void> add(Component component) {
    if (component == world || component == camera) {
      return super.add(component);
    }
    if (component is MangaTextEffect) {
      final activeTexts = world.children.whereType<MangaTextEffect>().length;
      if (activeTexts >= 6) return null;
    } else if (component is MangaDustEffect) {
      final activeDust = world.children.whereType<MangaDustEffect>().length;
      if (activeDust >= 5) return null;
    }
    return world.add(component);
  }

  /// Query all active components of type [T] inside the game world
  Iterable<T> queryWorld<T extends Component>() {
    return world.descendants().whereType<T>();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all 2D Cartoon Sprite Sheets, Icons & Illustrations
    await CartoonAssets.preloadAll(images);

    // Setup Adaptive Landscape Camera looking at `world`
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(viewportWidth, 540),
    );
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(viewportWidth * 0.5, 270);

    await AudioService.init();

    // Load Level 1 in the background and pause while Intro / Main Menu is shown
    await loadLevel(1, pauseForMenu: true);

    if (!_hasShownInitialSplash) {
      _hasShownInitialSplash = true;
      _addOverlay('intro');
    }
  }

  void _addOverlay(String name) {
    if (overlays.registeredOverlays.contains(name) &&
        !overlays.isActive(name)) {
      overlays.add(name);
    }
  }

  Future<void> loadLevel(int level, {bool pauseForMenu = false}) async {
    isGameOver = false;
    isLevelVictory = false;
    currentLevelIndex = level.clamp(1, totalLevels);
    activeBoss = null;
    isBossArenaLocked = false;
    minPlayerX = 24.0;
    maxPlayerX = 3380.0;
    overlays.remove('manga_cutin');

    // Fully tear down previous level component, hitboxes and world children
    if (_currentLevelComponent != null) {
      _currentLevelComponent!.removeAll(_currentLevelComponent!.children.toList());
      _currentLevelComponent!.removeFromParent();
      _currentLevelComponent = null;
    }
    final existing = world.children.toList();
    for (final c in existing) {
      c.removeAll(c.children.toList());
      c.removeFromParent();
    }

    switch (currentLevelIndex) {
      case 1:
        currentSpawnPoint = LevelOne.spawnPosition.clone();
        currentLevelWidth = LevelOne.levelWidth;
        currentBossGateX = LevelOne.bossArenaTriggerX;
        currentArenaCamX = LevelOne.arenaCenterX;
        _currentLevelComponent = LevelOne();
        break;
      case 2:
        currentSpawnPoint = LevelTwo.spawnPosition.clone();
        currentLevelWidth = LevelTwo.levelWidth;
        currentBossGateX = LevelTwo.bossArenaTriggerX;
        currentArenaCamX = LevelTwo.arenaCenterX;
        _currentLevelComponent = LevelTwo();
        break;
      case 3:
        currentSpawnPoint = LevelThree.spawnPosition.clone();
        currentLevelWidth = LevelThree.levelWidth;
        currentBossGateX = LevelThree.bossArenaTriggerX;
        currentArenaCamX = LevelThree.arenaCenterX;
        _currentLevelComponent = LevelThree();
        break;
      case 4:
        currentSpawnPoint = LevelFour.spawnPosition.clone();
        currentLevelWidth = LevelFour.levelWidth;
        currentBossGateX = LevelFour.bossArenaTriggerX;
        currentArenaCamX = LevelFour.arenaCenterX;
        _currentLevelComponent = LevelFour();
        break;
      case 5:
      default:
        currentSpawnPoint = LevelFive.spawnPosition.clone();
        currentLevelWidth = LevelFive.levelWidth;
        currentBossGateX = LevelFive.bossArenaTriggerX;
        currentArenaCamX = LevelFive.arenaCenterX;
        _currentLevelComponent = LevelFive();
        break;
    }
    maxPlayerX = currentLevelWidth - 40.0;

    await world.add(_currentLevelComponent!);

    // Instantiate Player inside `world`
    player = MangaPlayer(position: currentSpawnPoint.clone());
    await world.add(player);

    // Snap camera to start of level
    camera.viewfinder.position = Vector2(480, 270);

    if (pauseForMenu) {
      pauseEngine();
      AudioService.playBgm(AudioService.bgmMenu);
    } else {
      overlays.remove('intro');
      overlays.remove('story_intro');
      overlays.remove('settings');
      overlays.remove('main_menu');
      overlays.remove('chapter_select');
      overlays.remove('pause');
      overlays.remove('game_over');
      overlays.remove('victory');
      _addOverlay('hud');
      if (AppLocalizations.showVirtualControls.value) {
        _addOverlay('virtual_controls');
      } else {
        overlays.remove('virtual_controls');
      }
      resumeEngine();
      AudioService.playBgm(AudioService.bgmStage);
    }
  }

  void lockToBossArena({required double minX, required double maxX}) {
    isBossArenaLocked = true;
    minPlayerX = minX;
    maxPlayerX = maxX;
    AudioService.playSfx(AudioService.sfxBossRoar);
    AudioService.heavyHaptic();
    AudioService.playBgm(AudioService.bgmBoss);
  }

  void startFromMainMenu({int level = 1}) {
    score = 0;
    isGameOver = false;
    isLevelVictory = false;
    loadLevel(level, pauseForMenu: false);
  }

  void returnToMainMenu() {
    isMultiplayer = false;
    _startedMatchSessionId = 0;
    _multiplayerSub?.cancel();
    _multiplayerSub = null;
    _unbindMultiplayerNotifiers();
    LanMultiplayerService.instance.disconnect();
    pvpArena = null;

    AppLocalizations.isEditingHudLayout.value = false;
    isGameOver = false;
    isLevelVictory = false;
    if (isLoaded && world.children.contains(player)) {
      player.resetForMatch(maxHealth: player.maxHp);
    }
    overlays.remove('manga_cutin');
    overlays.remove('pause');
    overlays.remove('settings');
    overlays.remove('story_intro');
    overlays.remove('story_epilogue');
    overlays.remove('game_over');
    overlays.remove('victory');
    overlays.remove('chapter_select');
    overlays.remove('hud');
    overlays.remove('virtual_controls');
    overlays.remove('multiplayer_lobby');
    overlays.remove('multiplayer_hud');
    overlays.remove('multiplayer_results');
    AudioService.stopBgm();
    pauseEngine();
    _addOverlay('main_menu');
    AudioService.playBgm(AudioService.bgmMenu);
  }

  void _bindMultiplayerNotifiers() {
    if (_multiplayerNotifiersBound) return;
    _multiplayerNotifiersBound = true;
    final net = LanMultiplayerService.instance;
    net.matchSessionIdNotifier.addListener(_onMatchSessionChanged);
    net.victoryCelebrationNotifier.addListener(_onVictoryCelebrationChanged);
    net.resultsPodiumNotifier.addListener(_onResultsPodiumChanged);
  }

  void _unbindMultiplayerNotifiers() {
    if (!_multiplayerNotifiersBound) return;
    _multiplayerNotifiersBound = false;
    final net = LanMultiplayerService.instance;
    net.matchSessionIdNotifier.removeListener(_onMatchSessionChanged);
    net.victoryCelebrationNotifier.removeListener(_onVictoryCelebrationChanged);
    net.resultsPodiumNotifier.removeListener(_onResultsPodiumChanged);
  }

  void _onMatchSessionChanged() {
    final net = LanMultiplayerService.instance;
    final sessionId = net.matchSessionIdNotifier.value;
    if (sessionId > 0 &&
        sessionId != _startedMatchSessionId &&
        (net.isConnected || net.role != MatchRole.none)) {
      startPvPMatch();
    }
  }

  void _onVictoryCelebrationChanged() {
    final winner =
        LanMultiplayerService.instance.victoryCelebrationNotifier.value;
    if (winner == null || !isMultiplayer) return;
    AudioService.playSfx(AudioService.sfxVictory);
    overlays.remove('virtual_controls');
    if (winner.id == LanMultiplayerService.instance.myPlayerId) {
      player.performVictoryCelebration();
    } else {
      pvpArena?.remotePlayers[winner.id]?.triggerVictoryCelebration();
    }
  }

  void _onResultsPodiumChanged() {
    final podium = LanMultiplayerService.instance.resultsPodiumNotifier.value;
    if (podium != null && isMultiplayer) {
      overlays.remove('multiplayer_hud');
      overlays.remove('virtual_controls');
      _addOverlay('multiplayer_results');
    }
  }

  void openMultiplayerLobby() {
    isMultiplayer = false;
    _startedMatchSessionId = 0;
    _bindMultiplayerNotifiers();
    overlays.remove('main_menu');
    overlays.remove('hud');
    overlays.remove('virtual_controls');
    overlays.remove('multiplayer_results');
    pauseEngine();
    _addOverlay('multiplayer_lobby');
  }

  void closeMultiplayerLobby() {
    _startedMatchSessionId = 0;
    _unbindMultiplayerNotifiers();
    LanMultiplayerService.instance.disconnect();
    overlays.remove('multiplayer_lobby');
    _addOverlay('main_menu');
  }

  Future<void> startPvPMatch() async {
    if (_startingPvPMatch) return;
    _startingPvPMatch = true;
    try {
      final net = LanMultiplayerService.instance;
      _startedMatchSessionId = net.matchSessionIdNotifier.value;
      _bindMultiplayerNotifiers();
      isMultiplayer = true;
      _pressedKeys.clear();
      _lastSentHp = null;
      _lastSentFacing = null;
      _lastSentAction = null;
      _lastSentX = double.nan;
      _lastSentY = double.nan;
      _stateSyncAccumulator = 0.0;

      overlays.remove('multiplayer_lobby');
      overlays.remove('multiplayer_results');
      overlays.remove('main_menu');
      overlays.remove('game_over');
      overlays.remove('victory');
      overlays.remove('hud');

      // Remove existing story level components, preserving local player!
      final toRemove = world.children.where((c) => c != player).toList();
      for (final child in toRemove) {
        world.remove(child);
      }
      _currentLevelComponent = null;

      if (!world.children.contains(player)) {
        await world.add(player);
      }

      // Reset local player state for PvP match
      player.resetForMatch(maxHealth: LanMultiplayerService.kPvpMaxHpInt);

      // Create and add PvP Arena (Supports up to 5 players)
      final arena = PvPArenaLevel();
      pvpArena = arena;
      await world.add(arena);
      _currentLevelComponent = arena;

      // PvP Arena Bounds and camera
      minPlayerX = 0.0;
      maxPlayerX = PvPArenaLevel.arenaWidth;
      camera.viewfinder.position = Vector2(600, 270);

      // Listen to LAN network packets safely
      _multiplayerSub?.cancel();
      _multiplayerSub = net.onMatchData.listen((data) {
        try {
          final type = data['type'] as String?;
          if (type == 'state') {
            final pid = data['id'] as String?;
            if (pid != null) {
              pvpArena?.remotePlayers[pid]?.updateFromNetwork(
                x: (data['x'] as num).toDouble(),
                y: (data['y'] as num).toDouble(),
                vx: (data['vx'] as num).toDouble(),
                vy: (data['vy'] as num).toDouble(),
                facing: (data['f'] as num?)?.toInt() ?? 1,
                actionName: (data['act'] as String?) ?? PlayerAction.idle.name,
                remoteHp: (data['hp'] as num?)?.toDouble() ??
                    LanMultiplayerService.kPvpMaxHp,
                remoteOugi: (data['ougi'] as num?)?.toDouble() ?? 0.0,
              );
            }
          } else if (type == 'spawn_kunai') {
            final throwerId = data['throwerId'] as String?;
            if (throwerId != net.myPlayerId) {
              world.add(InkKunai(
                position: Vector2(
                  (data['x'] as num).toDouble(),
                  (data['y'] as num).toDouble(),
                ),
                velocity: Vector2(
                  (data['vx'] as num).toDouble(),
                  (data['vy'] as num).toDouble(),
                ),
                damage: 32.0,
                throwerId: throwerId ?? '',
                isFromRemote: true,
              ));
            }
          } else if (type == 'hit') {
            final targetId = data['targetId'] as String?;
            if (targetId == net.myPlayerId) {
              final dmg = (data['dmg'] as num).toDouble();
              final kbX = (data['kbX'] as num?)?.toDouble() ?? 0.0;
              final kbY = (data['kbY'] as num?)?.toDouble() ?? 0.0;
              player.takeMultiplayerDamage(dmg, knockbackX: kbX, knockbackY: kbY);
            }
          } else if (type == 'player_eliminated') {
            final pid = data['id'] as String?;
            if (pid != null) {
              pvpArena?.remotePlayers[pid]?.markEliminated();
            }
          }
        } catch (e) {
          debugPrint('[PvP Packet Error] $e');
        }
      });

      _addOverlay('multiplayer_hud');
      _addOverlay('virtual_controls');
      onRequestGameFocus?.call();

      AudioService.playBgm(AudioService.bgmBoss);
    } catch (e, stack) {
      debugPrint('[PvP Match Error] $e\n$stack');
    } finally {
      _startingPvPMatch = false;
      resumeEngine();
    }
  }

  void onLocalPlayerEliminated() {
    if (!isMultiplayer) return;
    overlays.remove('virtual_controls');
    add(MangaTextEffect(
      position: Vector2(600, 240),
      text: '¡K.O. - HAS CAÍDO!',
      fillColor: ComicTheme.actionRed,
      targetScale: 2.2,
      maxLifetime: 2.5,
    ));
    AudioService.playSfx(AudioService.sfxPlayerDeath);
  }

  void onMultiplayerMatchOver({
    required String winnerName,
    required bool didLocalWin,
  }) {
    if (!isMultiplayer) return;
    _multiplayerSub?.cancel();
    _multiplayerSub = null;

    add(MangaTextEffect(
      position: Vector2(600, 240),
      text: didLocalWin ? '¡VICTORIA SHINOBI!' : '¡DERROTA!',
      fillColor: didLocalWin ? ComicTheme.comicYellow : ComicTheme.actionRed,
      targetScale: 2.5,
      maxLifetime: 3.0,
    ));

    if (didLocalWin) {
      AudioService.playSfx(AudioService.sfxVictory);
    } else {
      AudioService.playSfx(AudioService.sfxPlayerDeath);
    }
  }

  void openIntroStory() {
    overlays.remove('main_menu');
    pauseEngine();
    _addOverlay('story_intro');
  }

  void finishIntroToMainMenu() {
    overlays.remove('intro');
    overlays.remove('story_intro');
    overlays.remove('story_epilogue');
    pauseEngine();
    _addOverlay('main_menu');
  }

  void finishEpilogueToVictory() {
    overlays.remove('story_epilogue');
    _addOverlay('victory');
  }

  void openSettings() {
    _addOverlay('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    // If user accessed settings from Main Menu or outside active gameplay, always return to Main Menu
    if (overlays.isActive('main_menu') || !overlays.isActive('hud')) {
      pauseEngine();
      _addOverlay('main_menu');
      return;
    }

    final isDead = isGameOver ||
        (isLoaded &&
            world.children.contains(player) &&
            (player.hp <= 0 || player.isDying));
    final isWon =
        isLevelVictory || (activeBoss != null && activeBoss!.isDefeated);

    if (isDead) {
      pauseEngine();
      _addOverlay('game_over');
    } else if (isWon) {
      pauseEngine();
      _addOverlay('victory');
    } else if (overlays.isActive('hud')) {
      if (!overlays.isActive('pause')) {
        resumeEngine();
      }
    } else {
      pauseEngine();
      _addOverlay('main_menu');
    }
  }

  void closeChapterSelect() {
    overlays.remove('chapter_select');
    // If user opened chapter select from Main Menu or outside active gameplay, always return to Main Menu
    if (overlays.isActive('main_menu') || !overlays.isActive('hud')) {
      pauseEngine();
      _addOverlay('main_menu');
      return;
    }

    final isDead = isGameOver ||
        (isLoaded &&
            world.children.contains(player) &&
            (player.hp <= 0 || player.isDying));
    final isWon =
        isLevelVictory || (activeBoss != null && activeBoss!.isDefeated);

    if (isDead) {
      pauseEngine();
      _addOverlay('game_over');
    } else if (isWon) {
      pauseEngine();
      _addOverlay('victory');
    } else if (overlays.isActive('hud')) {
      pauseEngine();
      _addOverlay('pause');
    } else {
      pauseEngine();
      _addOverlay('main_menu');
    }
  }

  void openHudLayoutEditor() {
    overlays.remove('settings');
    pauseEngine();
    AppLocalizations.showVirtualControls.value = true;
    AppLocalizations.isEditingHudLayout.value = true;
    _addOverlay('virtual_controls');
  }

  void closeHudLayoutEditor() {
    AppLocalizations.isEditingHudLayout.value = false;
    AppLocalizations.saveSettings();
    if (overlays.isActive('main_menu') || overlays.isActive('pause')) {
      if (!overlays.isActive('hud')) {
        overlays.remove('virtual_controls');
      }
      _addOverlay('settings');
    } else if (overlays.isActive('hud')) {
      resumeEngine();
    }
  }

  void setVirtualControlsEnabled(bool enabled) {
    AppLocalizations.showVirtualControls.value = enabled;
    AppLocalizations.saveSettings();
    if (overlays.isActive('hud')) {
      if (enabled) {
        _addOverlay('virtual_controls');
      } else {
        overlays.remove('virtual_controls');
      }
    }
  }

  void addScore(int points) {
    score += points;
  }

  void addSpirit(double amount) {
    player.spirit = (player.spirit + amount).clamp(0.0, 100.0);
  }

  void healPlayer(int amount) {
    if (isMultiplayer) return;
    player.hp = (player.hp + amount).clamp(0, player.maxHp);
  }

  double get stageProgress {
    if (isBossArenaLocked) return 1.0;
    if (!isLoaded || !world.children.contains(player)) return 0.0;
    return ((player.position.x - 80.0) / (currentBossGateX - 80.0))
        .clamp(0.0, 1.0);
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
    } else if (bossName.contains('RYU')) {
      cutInPortraitAsset = CartoonAssets.portraitRyuKotei;
    } else if (bossName.contains('HEBI')) {
      cutInPortraitAsset = CartoonAssets.portraitHebiHime;
    } else if (bossName.contains('YUKI')) {
      cutInPortraitAsset = CartoonAssets.portraitYukiOni;
    } else {
      cutInPortraitAsset = CartoonAssets.portraitMuzanKai;
    }

    _addOverlay('manga_cutin');
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (overlays.isActive('manga_cutin')) {
        overlays.remove('manga_cutin');
      }
    });
  }

  void onPlayerDied() {
    _pressedKeys.clear();
    if (isLoaded && world.children.contains(player)) {
      player.touchMoveInput = 0.0;
      player.keyboardMoveInput = 0.0;
    }
  }

  void finalizePlayerDeath() {
    if (isMultiplayer) return; // In multiplayer, match results podium handles match end!
    isGameOver = true;
    AudioService.stopBgm();
    AudioService.playSfx(AudioService.sfxGameOver);
    pauseEngine();
    _addOverlay('game_over');
  }

  void onBossDefeated(BossBase boss) {
    isLevelVictory = true;
    AudioService.stopBgm();
    AudioService.playSfx(AudioService.sfxVictory);
    addScore(1000 * currentLevelIndex);
    Future.delayed(const Duration(milliseconds: 1400), () {
      pauseEngine();
      if (currentLevelIndex >= totalLevels) {
        _addOverlay('story_epilogue');
      } else {
        _addOverlay('victory');
      }
    });
  }

  void restartCurrentLevel() {
    isGameOver = false;
    isLevelVictory = false;
    overlays.remove('game_over');
    overlays.remove('victory');
    overlays.remove('story_epilogue');
    overlays.remove('manga_cutin');
    AudioService.stopBgm();
    loadLevel(currentLevelIndex, pauseForMenu: false);
  }

  void nextLevel() {
    isGameOver = false;
    isLevelVictory = false;
    overlays.remove('victory');
    overlays.remove('story_epilogue');
    overlays.remove('manga_cutin');
    AudioService.stopBgm();
    final nextIdx = currentLevelIndex < totalLevels ? currentLevelIndex + 1 : 1;
    loadLevel(nextIdx, pauseForMenu: false);
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
        if (!overlays.isActive('main_menu') &&
            !overlays.isActive('intro') &&
            !overlays.isActive('story_intro') &&
            !overlays.isActive('settings')) {
          togglePause();
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.handled;
  }

  void togglePause() {
    if (overlays.isActive('pause')) {
      overlays.remove('pause');
      resumeEngine();
      AudioService.resumeBgm();
    } else {
      pauseEngine();
      AudioService.pauseBgm();
      _addOverlay('pause');
    }
  }

  @override
  void update(double dt) {
    // Clamping dt guarantees stable physics integration and prevents tunneling/overshoot
    // across all refresh rates: 60 Hz (~16.6ms), 90 Hz (~11.1ms), 120 Hz (~8.33ms), 144 Hz (~6.94ms)
    final clampedDt = dt.clamp(0.0005, 0.1);
    super.update(clampedDt);

    if (isLoaded && world.children.contains(player) && player.isLoaded) {
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

      if (isMultiplayer) {
        _stateSyncAccumulator += clampedDt;
        final currentAction = player.action.name;
        final movedSignificantly = _lastSentX.isNaN ||
            (player.position.x - _lastSentX).abs() > 0.5 ||
            (player.position.y - _lastSentY).abs() > 0.5;
        final localDead = player.isDying || player.hp <= 0;
        final reportedHp = localDead ? 0 : player.hp;
        final urgentChange = currentAction != _lastSentAction ||
            player.facingDirection != _lastSentFacing ||
            reportedHp != _lastSentHp;
        final syncInterval = movedSignificantly ? 0.033 : 0.20;
        if (urgentChange || _stateSyncAccumulator >= syncInterval) {
          _stateSyncAccumulator = 0.0;
          _lastSentX = player.position.x;
          _lastSentY = player.position.y;
          _lastSentFacing = player.facingDirection;
          _lastSentAction = currentAction;
          _lastSentHp = reportedHp;
          LanMultiplayerService.instance.sendPlayerState(
            x: player.position.x,
            y: player.position.y,
            vx: player.velocity.x,
            vy: player.velocity.y,
            facing: player.facingDirection,
            action: currentAction,
            hp: reportedHp.toDouble(),
            ougi: localDead ? 0.0 : player.spirit,
          );
        }

        const double targetCamX = 600.0;
        const double targetCamY = 270.0;
        final currentCam = camera.viewfinder.position;
        final lerpFactor = 1.0 - math.exp(-8.5 * clampedDt);
        camera.viewfinder.position = Vector2(
          currentCam.x + (targetCamX - currentCam.x) * lerpFactor,
          currentCam.y + (targetCamY - currentCam.y) * lerpFactor,
        );
        return;
      }

      // Smoothly scroll camera horizontally along the level or lock into the Boss Arena.
      // Exponential decay smoothing (1.0 - exp(-k * dt)) provides mathematically identical
      // buttery-smooth tracking at 60 Hz, 90 Hz, 120 Hz, and 144 Hz.
      final minCamX = viewportWidth * 0.5;
      final double targetCamX = isBossArenaLocked
          ? currentArenaCamX
          : (player.position.x + 110.0).clamp(minCamX, currentArenaCamX);
      const double targetCamY = 270.0;

      final currentCam = camera.viewfinder.position;
      final lerpFactor = 1.0 - math.exp(-8.5 * clampedDt);
      camera.viewfinder.position = Vector2(
        currentCam.x + (targetCamX - currentCam.x) * lerpFactor,
        currentCam.y + (targetCamY - currentCam.y) * lerpFactor,
      );
    }
  }
}
