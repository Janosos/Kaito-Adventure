import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/manga_game.dart';
import 'ui/app_localizations.dart';
import 'ui/comic_theme.dart';
import 'ui/comic_hud.dart';
import 'ui/manga_cutin_overlay.dart';
import 'ui/virtual_joystick_overlay.dart';
import 'ui/chapter_select_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/victory_overlay.dart';
import 'ui/intro_overlay.dart';
import 'ui/main_menu_overlay.dart';
import 'ui/settings_overlay.dart';
import 'ui/story_epilogue_overlay.dart';
import 'ui/multiplayer_hud.dart';
import 'ui/multiplayer_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted language, virtual controls toggle, button positions, size & transparency
  AppLocalizations.loadSettings();

  // Keep decoded 2D illustrations and sprite sheets resident in GPU/RAM cache
  // to avoid texture re-decoding stutter on Snapdragon (Adreno) & MediaTek (Mali)
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150 MB

  // Lock orientation to horizontal landscape on Android & iOS
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MangaPlatformerApp());
}

class MangaPlatformerApp extends StatelessWidget {
  const MangaPlatformerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaito Adventure: Ink Shinobi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Bangers',
        scaffoldBackgroundColor: ComicTheme.inkBlack,
      ),
      home: const MangaGameScreen(),
    );
  }
}

class MangaGameScreen extends StatefulWidget {
  const MangaGameScreen({super.key});

  @override
  State<MangaGameScreen> createState() => _MangaGameScreenState();
}

class _MangaGameScreenState extends State<MangaGameScreen>
    with WidgetsBindingObserver {
  late final MangaGame _game;
  final GlobalKey _gameWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = MangaGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restore sticky fullscreen landscape mode when returning from Home / App Switcher
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortraitViewport =
        media.size.width > 0 && media.size.width < media.size.height;
    final effectiveSize = isPortraitViewport
        ? Size(media.size.height, media.size.width)
        : media.size;
    final effectivePadding = isPortraitViewport
        ? EdgeInsets.only(
            left: media.padding.top,
            right: media.padding.bottom,
            top: media.padding.right,
            bottom: media.padding.left,
          )
        : media.padding;
    final isCompactMobile = effectiveSize.height < 460;

    // IMPORTANT: Keep the exact same widget tree depth (RotatedBox -> MediaQuery -> Scaffold -> GameWidget)
    // regardless of whether `isPortraitViewport` is true or false!
    // Changing tree depth when Android transitions to the Portrait Home/Recents screen
    // would unmount GameWidget and reset the game!
    return RotatedBox(
      quarterTurns: isPortraitViewport ? 1 : 0,
      child: MediaQuery(
        data: media.copyWith(
          size: effectiveSize,
          padding: effectivePadding,
        ),
        child: Scaffold(
          backgroundColor: ComicTheme.inkBlack,
          body: Container(
            padding: EdgeInsets.all(isCompactMobile ? 2.0 : 6.0),
            color: ComicTheme.inkBlack,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: isCompactMobile ? 1.5 : 2.5,
                ),
              ),
              child: RepaintBoundary(
                child: GameWidget<MangaGame>(
                  key: _gameWidgetKey,
                  game: _game,
                  overlayBuilderMap: {
                    'intro': (context, game) => SplashIntroOverlay(game: game),
                    'story_intro': (context, game) =>
                        StoryIntroOverlay(game: game),
                    'settings': (context, game) => SettingsOverlay(game: game),
                    'main_menu': (context, game) =>
                        MainMenuOverlay(game: game),
                    'hud': (context, game) => ComicHud(game: game),
                    'virtual_controls': (context, game) =>
                        VirtualJoystickOverlay(game: game),
                    'manga_cutin': (context, game) =>
                        MangaCutInOverlay(game: game),
                    'pause': (context, game) => PauseOverlay(game: game),
                    'game_over': (context, game) => GameOverOverlay(game: game),
                    'victory': (context, game) => VictoryOverlay(game: game),
                    'chapter_select': (context, game) =>
                        ChapterSelectOverlay(game: game),
                    'story_epilogue': (context, game) =>
                        StoryEpilogueOverlay(game: game),
                    'multiplayer_lobby': (context, game) =>
                        MultiplayerOverlay(game: game),
                    'multiplayer_hud': (context, game) =>
                        MultiplayerHud(game: game),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
