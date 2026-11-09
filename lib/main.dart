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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred landscape orientation for platformer experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MangaPlatformerApp());
}

class MangaPlatformerApp extends StatelessWidget {
  const MangaPlatformerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Blade: Ink Shinobi',
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
    return Scaffold(
      backgroundColor: ComicTheme.inkBlack,
      body: Container(
        // Outer Manga Tankobon Page Framing
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: ComicTheme.inkBlack,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: GameWidget<MangaGame>(
            game: _game,
            overlayBuilderMap: {
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
            initialActiveOverlays: const ['hud', 'virtual_controls'],
          ),
        ),
      ),
    );
  }
}
