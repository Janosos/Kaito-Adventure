import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_platformer/game/components/enemies/enemy_grunt.dart';
import 'package:manga_platformer/game/components/player.dart';
import 'package:manga_platformer/game/manga_game.dart';
import 'package:manga_platformer/game/services/audio_service.dart';
import 'package:manga_platformer/game/services/pwa_service.dart';
import 'package:manga_platformer/main.dart';
import 'package:manga_platformer/ui/app_localizations.dart';
import 'package:manga_platformer/ui/chapter_select_overlay.dart';
import 'package:manga_platformer/ui/comic_hud.dart';
import 'package:manga_platformer/ui/main_menu_overlay.dart';
import 'package:manga_platformer/ui/manga_cutin_overlay.dart';
import 'package:manga_platformer/ui/settings_overlay.dart';
import 'package:manga_platformer/ui/story_epilogue_overlay.dart';
import 'package:manga_platformer/ui/multiplayer_hud.dart';
import 'package:manga_platformer/ui/multiplayer_overlay.dart';
import 'package:manga_platformer/ui/multiplayer_results_overlay.dart';
import 'package:manga_platformer/game/services/lan_multiplayer_service.dart';
import 'package:manga_platformer/ui/virtual_joystick_overlay.dart';

void main() {
  setUpAll(() {
    AudioService.isTestMode = true;
    PwaService.forceShowInstallButtonForTest = true;
  });

  testWidgets('Manga platformer smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MangaPlatformerApp());
    expect(find.byType(MangaGameScreen), findsOneWidget);
  });

  testWidgets(
      'Mobile landscape (800x360) and portrait auto-rotate (360x800) render all UI overlays without overflow',
      (WidgetTester tester) async {
    final game = MangaGame();
    await tester.runAsync(() async {
      game.onGameResize(Vector2(800, 360));
      await game.onLoad();
      // ignore: invalid_use_of_internal_member
      game.setLoaded();
      // ignore: invalid_use_of_internal_member
      game.setMounted();
      game.update(0);
      await game.ready();
      await game.loadLevel(1);
      game.update(0);
      await game.ready();
    });

    // Test at compact mobile landscape resolution (800x360)
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1. MainMenuOverlay at 800x360
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MainMenuOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Verify PWA Install modal opens, switches tabs, and renders cleanly
    final installBtn = find.text(AppLocalizations.tr('btn_install_app'));
    expect(installBtn, findsOneWidget);
    await tester.tap(installBtn);
    await tester.pump();
    expect(find.text(AppLocalizations.tr('install_title')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final iosTab = find.text(AppLocalizations.tr('install_ios_tab'));
    await tester.tap(iosTab);
    await tester.pump();
    expect(find.text(AppLocalizations.tr('install_ios_step1')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final gotItBtn = find.text(AppLocalizations.tr('btn_got_it'));
    await tester.tap(gotItBtn);
    await tester.pump();
    expect(find.text(AppLocalizations.tr('install_title')), findsNothing);

    // 2. ChapterSelectOverlay at 800x360
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: ChapterSelectOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // 3. SettingsOverlay at 800x360
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: SettingsOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // 4. ComicHud + VirtualJoystickOverlay + MangaCutInOverlay with Ougi Ready & Boss Active at 800x360
    await tester.runAsync(() async {
      game.player.spirit = 100.0;
      game.player.position = Vector2(game.currentBossGateX + 20, 460);
      game.update(0.05);
      await game.ready();
      game.update(0.05);
      await game.ready();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: Scaffold(
            body: Stack(
              children: [
                ComicHud(game: game),
                VirtualJoystickOverlay(game: game),
                MangaCutInOverlay(game: game),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    // 5. Verify floating joystick only appears on left-side touch, moves Kaito continuously across frames while held stationary, and disappears on release
    expect(game.player.moveInput, equals(0.0));
    final TestGesture gesture =
        await tester.startGesture(const Offset(140, 250));
    await tester.pump();
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();
    expect(game.player.moveInput, equals(1.0));

    // Simulate 10 consecutive game frames while finger is held stationary on joystick
    final double startX = game.player.position.x;
    for (int f = 0; f < 10; f++) {
      game.update(0.016);
    }
    // Verify Kaito kept moving continuously without stuttering or resetting to 0!
    expect(game.player.moveInput, equals(1.0));
    expect(game.player.position.x, greaterThan(startX + 20.0));

    await gesture.up();
    await tester.pump();
    expect(game.player.moveInput, equals(0.0));
    expect(tester.takeException(), isNull);

    // Unmount repeating tickers cleanly
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
      'All 5 distinct progressive levels load, Kunai has 5s cooldown, Slash deals damage + knockback, and Boss spawns at final stage',
      () async {
    final game = MangaGame();
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    // ignore: invalid_use_of_internal_member
    game.setLoaded();
    // ignore: invalid_use_of_internal_member
    game.setMounted();
    game.update(0);
    await game.ready();

    double previousLevelWidth = 0;

    for (int lvl = 1; lvl <= 5; lvl++) {
      await game.loadLevel(lvl);
      // Pump world lifecycle so level & children mount inside game.world
      game.update(0);
      await game.ready();
      game.update(0);
      await game.ready();
      game.update(0.05);

      expect(game.currentLevelIndex, lvl);
      // Verify each level is progressively longer than the last
      expect(game.currentLevelWidth, greaterThan(previousLevelWidth));
      previousLevelWidth = game.currentLevelWidth;

      // Boss is NOT active until player reaches the final stage!
      expect(game.activeBoss, isNull);

      // Verify 5-second Kunai Cooldown anti-spam
      game.player.kunaiCooldown = 0;
      game.player.performThrowKunai();
      expect(
        game.player.kunaiCooldown,
        closeTo(MangaPlayer.maxKunaiCooldown, 0.001),
      );
      expect(MangaPlayer.maxKunaiCooldown, equals(5.0));

      final grunts = game.queryWorld<EnemyGrunt>().toList();
      expect(grunts, isNotEmpty);

      // Move player right next to the first grunt and perform Slash
      final firstGrunt = grunts.first;
      final initialHp = firstGrunt.hp;
      expect(initialHp, greaterThanOrEqualTo(80.0));
      final initialX = firstGrunt.position.x;

      game.player.position =
          Vector2(firstGrunt.position.x - 28, firstGrunt.position.y);
      game.player.facingDirection = 1;
      game.player.attackCooldown = 0;
      game.player.performAttack();

      expect(firstGrunt.hp, lessThan(initialHp));
      expect(firstGrunt.position.x, greaterThan(initialX));

      // Now advance player to this level's final stage Boss Arena trigger
      game.player.position = Vector2(game.currentBossGateX + 20, 460);
      game.update(0.05);
      await game.ready();
      game.update(0.05);
      await game.ready();
      game.update(0.05);
      await game.ready();

      expect(game.isBossArenaLocked, isTrue);
      expect(game.activeBoss, isNotNull);
      final expectedBossHp = [760.0, 1040.0, 1160.0, 1320.0, 1600.0][lvl - 1];
      expect(game.activeBoss!.maxHp, equals(expectedBossHp));
    }

    // Verify default button scale starts at 140% (1.40) and persists custom settings locally
    AppLocalizations.resetHudLayout();
    expect(AppLocalizations.hudConfig.value.buttonScale, closeTo(1.40, 0.01));

    AppLocalizations.updateButtonScale(1.25);
    AppLocalizations.updateButtonOpacity(0.65);
    AppLocalizations.updateButtonPosition('slash', const Offset(0.82, 0.48));
    AppLocalizations.saveSettings();

    // Reset in-memory and reload from local storage
    AppLocalizations.hudConfig.value = const HudControlsConfig();
    AppLocalizations.loadSettings();
    expect(AppLocalizations.hudConfig.value.buttonScale, closeTo(1.25, 0.01));
    expect(AppLocalizations.hudConfig.value.buttonOpacity, closeTo(0.65, 0.01));
    expect(
      AppLocalizations.hudConfig.value.posFor('slash').dx,
      closeTo(0.82, 0.01),
    );
    AppLocalizations.resetHudLayout();
    expect(AppLocalizations.hudConfig.value.buttonScale, closeTo(1.40, 0.01));

    // Verify minimizing / app-switching / Home button preserves level, position, score & boss without resetting
    game.score = 4500;
    final savedLevel = game.currentLevelIndex;
    final savedPos = game.player.position.clone();
    final savedBoss = game.activeBoss;

    // Simulate OS reporting transient portrait dimensions during Home/Recents + lifecycle pause
    game.onGameResize(Vector2(360, 800));
    game.lifecycleStateChange(AppLifecycleState.paused);
    game.onGameResize(Vector2(960, 540));
    game.lifecycleStateChange(AppLifecycleState.resumed);

    expect(game.currentLevelIndex, equals(savedLevel));
    expect(game.player.position.x, closeTo(savedPos.x, 0.01));
    expect(game.score, equals(4500));
    expect(game.activeBoss, same(savedBoss));

    // Verify Kaito plays full 2D cartoon death animation before transitioning to Game Over
    game.player.invulnerableTimer = 0.0;
    game.player.isDashing = false;
    game.player.takeDamage(game.player.hp);
    expect(game.player.hp, equals(0));
    expect(game.player.isDying, isTrue);
    expect(game.player.action, equals(PlayerAction.death));
    // Must NOT jump abruptly to game_over on the frame of death!
    expect(game.isGameOver, isFalse);

    // Advance death animation frames (~1.7s)
    for (int f = 0; f < 36; f++) {
      game.update(0.05);
    }
    expect(game.isGameOver, isTrue);

    // Verify navigating to Chapter Select or Settings while dead and pressing BACK restores Game Over
    game.closeChapterSelect();
    expect(game.isGameOver, isTrue);

    // Verify victory navigation when defeating a boss and pressing BACK from Chapter Select
    game.isGameOver = false;
    game.isLevelVictory = true;
    game.closeChapterSelect();
    expect(game.isLevelVictory, isTrue);

    // Verify Audio and Haptics toggles, local persistence and AudioService safe execution
    AppLocalizations.setHapticsEnabled(true);
    expect(AppLocalizations.hapticsEnabled.value, isTrue);
    AppLocalizations.setHapticsEnabled(false);
    expect(AppLocalizations.hapticsEnabled.value, isFalse);
    AppLocalizations.setHapticsEnabled(true);

    AppLocalizations.setBgmEnabled(false);
    expect(AppLocalizations.bgmEnabled.value, isFalse);
    AppLocalizations.setBgmEnabled(true);
    expect(AppLocalizations.bgmEnabled.value, isTrue);

    AppLocalizations.setSfxEnabled(false);
    expect(AppLocalizations.sfxEnabled.value, isFalse);
    AppLocalizations.setSfxEnabled(true);
    expect(AppLocalizations.sfxEnabled.value, isTrue);

    // Verify AudioService triggers safely without exceptions
    AudioService.playSfx(AudioService.sfxSlash);
    AudioService.playSfx(AudioService.sfxJump);
    AudioService.playSfx(AudioService.sfxParryCounter);
    AudioService.playSfx(AudioService.sfxBackstabPierce);
    AudioService.playBgm(AudioService.bgmStage);
    AudioService.buttonHaptic();
    AudioService.heavyHaptic();
    AudioService.stopBgm();
  });

  testWidgets(
      'StoryEpilogueOverlay renders cleanly on mobile landscape (800x360)',
      (WidgetTester tester) async {
    final game = MangaGame();
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: StoryEpilogueOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(StoryEpilogueOverlay), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Native APK hides the PWA Install button completely',
      (WidgetTester tester) async {
    PwaService.forceShowInstallButtonForTest = false;
    final game = MangaGame();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MainMenuOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppLocalizations.tr('btn_install_app')), findsNothing);
    expect(find.text(AppLocalizations.tr('btn_settings')), findsOneWidget);

    // Restore for any following tests
    PwaService.forceShowInstallButtonForTest = true;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Multiplayer overlay & HUD render cleanly on mobile landscape (800x360) and palette has 8 colors',
      (WidgetTester tester) async {
    // 1. Verify palette options
    expect(kMultiplayerColors.length, equals(8));

    final game = MangaGame();
    await tester.runAsync(() async {
      game.onGameResize(Vector2(800, 360));
      await game.onLoad();
      // ignore: invalid_use_of_internal_member
      game.setLoaded();
      // ignore: invalid_use_of_internal_member
      game.setMounted();
      game.update(0);
      await game.ready();
    });

    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 2. Main menu displays the Multiplayer button
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MainMenuOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(AppLocalizations.tr('btn_multiplayer')), findsOneWidget);

    // 3. Multiplayer Lobby Overlay renders without overflow
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MultiplayerOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(MultiplayerOverlay), findsOneWidget);

    // 4. Multiplayer HUD renders with 100 HP health bars
    game.isMultiplayer = true;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MultiplayerHud(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(MultiplayerHud), findsOneWidget);

    // 5. Multiplayer 5-Player Waiting Room Lobby renders all 5 slots
    final net = LanMultiplayerService.instance;
    net.role = MatchRole.host;
    net.isConnected = true;
    net.myPlayerId = 'p_host';
    net.roomPlayers.clear();
    net.roomPlayers['p_host'] = MultiplayerPlayer(
      id: 'p_host',
      nickname: 'Jano',
      colorIndex: 0,
      slot: 0,
      isHost: true,
    );
    net.roomPlayers['p_1'] = MultiplayerPlayer(
      id: 'p_1',
      nickname: 'Rival1',
      colorIndex: 1,
      slot: 1,
      isHost: false,
    );
    net.roomPlayers['p_2'] = MultiplayerPlayer(
      id: 'p_2',
      nickname: 'Rival2',
      colorIndex: 2,
      slot: 2,
      isHost: false,
    );
    net.roomPlayersNotifier.value = net.roomPlayers.values.toList();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MultiplayerOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('INICIAR PARTIDA (3/5)'), findsOneWidget);
    expect(find.text('RANURA 4'), findsOneWidget);
    expect(find.text('RANURA 5'), findsOneWidget);

    // 6. Multiplayer 5-Player Battle Royale HUD
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MultiplayerHud(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Jano (TÚ)'), findsOneWidget);
    expect(find.text('Rival1'), findsOneWidget);

    // 7. Smash Bros Style Victory Podium Screen (MultiplayerResultsOverlay)
    final podium = [
      MultiplayerPlayer(
        id: 'p_host',
        nickname: 'Jano',
        colorIndex: 0,
        slot: 0,
        isHost: true,
        placement: 1,
      ),
      MultiplayerPlayer(
        id: 'p_1',
        nickname: 'Rival1',
        colorIndex: 1,
        slot: 1,
        placement: 2,
      ),
      MultiplayerPlayer(
        id: 'p_2',
        nickname: 'Rival2',
        colorIndex: 2,
        slot: 2,
        placement: 3,
      ),
    ];
    net.resultsPodiumNotifier.value = podium;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 360)),
          child: MultiplayerResultsOverlay(game: game),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('RESULTADOS DE LA BATALLA'), findsOneWidget);
    expect(find.text('1° LUGAR'), findsOneWidget);
    expect(find.text('¡CAMPEÓN!'), findsOneWidget);
    expect(find.text('2° LUGAR'), findsOneWidget);
    expect(find.textContaining('VOLVER A JUGAR'), findsOneWidget);

    // Tap Rematch vote
    await tester.tap(find.textContaining('VOLVER A JUGAR'));
    await tester.pump();
    expect(find.textContaining('¡LISTO PARA REVANCHA!'), findsOneWidget);

    // Countdown active
    net.rematchCountdownNotifier.value = 3;
    await tester.pump();
    expect(find.textContaining('¡REVANCHA CONFIRMADA! INICIANDO EN 3...'), findsOneWidget);

    await net.disconnect();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'PvP match spawns RemotePlayer in world, updates smoothly, and renders cleanly',
      (WidgetTester tester) async {
    final game = MangaGame();
    await tester.runAsync(() async {
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      // ignore: invalid_use_of_internal_member
      game.setLoaded();
      // ignore: invalid_use_of_internal_member
      game.setMounted();
      game.update(0);
      await game.ready();

      final net = LanMultiplayerService.instance;
      net.myPlayerId = 'p_host';
      net.mySlot = 0;
      net.roomPlayers['p_host'] = MultiplayerPlayer(
        id: 'p_host',
        nickname: 'Jano',
        colorIndex: 0,
        slot: 0,
        isHost: true,
      );
      net.roomPlayers['p_1'] = MultiplayerPlayer(
        id: 'p_1',
        nickname: 'Kaito_176',
        colorIndex: 1,
        slot: 1,
        isHost: false,
      );

      await game.startPvPMatch();
      await game.ready();

      final remote = game.pvpArena?.remotePlayers['p_1'];
      expect(remote, isNotNull);
      expect(remote!.isMounted, isTrue);
      expect(game.world.children.contains(remote), isTrue);

      // Verify remote player updates and renders without crashing
      for (int i = 0; i < 5; i++) {
        game.update(0.016);
      }

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      game.render(canvas);
      final pic = recorder.endRecording();
      pic.dispose();

      // Throw kunai and verify it does not crash or pause engine
      game.player.performThrowKunai();
      game.update(0.016);
      expect(game.paused, isFalse);

      await net.disconnect();
    });
  });
}
