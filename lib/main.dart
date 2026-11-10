import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/manga_game.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class _MangaGameScreenState extends State<MangaGameScreen> {
  late final MangaGame _game;

  @override
  void initState() {
    super.initState();
    _game = MangaGame();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isPortraitViewport =
        media.size.width > 0 && media.size.width < media.size.height;
    final effectiveSize = isPortraitViewport
        ? Size(media.size.height, media.size.width)
        : media.size;
    final isCompactMobile = effectiveSize.height < 460;

    Widget content = Scaffold(
      backgroundColor: ComicTheme.inkBlack,
      body: Container(
        // Adaptive Tankobon Page Framing (compact on mobile, classic on desktop/tablet)
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
              game: _game,
              overlayBuilderMap: {
                'intro': (context, game) => SplashIntroOverlay(game: game),
                'story_intro': (context, game) => StoryIntroOverlay(game: game),
                'settings': (context, game) => SettingsOverlay(game: game),
                'main_menu': (context, game) => MainMenuOverlay(game: game),
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
              },
              initialActiveOverlays: const ['intro'],
            ),
          ),
        ),
      ),
    );

    // Guarantee horizontal landscape presentation even if a mobile browser opens in portrait!
    if (isPortraitViewport) {
      content = RotatedBox(
        quarterTurns: 1,
        child: MediaQuery(
          data: media.copyWith(
            size: effectiveSize,
            padding: EdgeInsets.only(
              left: media.padding.top,
              right: media.padding.bottom,
              top: media.padding.right,
              bottom: media.padding.left,
            ),
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}
