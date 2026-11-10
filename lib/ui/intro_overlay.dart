import 'dart:async';
import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

/// Startup Splash Screen showing the Game Title ("KAITO ADVENTURE") for a few seconds
/// and "DEVELOPED BY JANOSOS" with the attached Janosos developer avatar icon!
class SplashIntroOverlay extends StatefulWidget {
  final MangaGame game;

  const SplashIntroOverlay({super.key, required this.game});

  @override
  State<SplashIntroOverlay> createState() => _SplashIntroOverlayState();
}

class _SplashIntroOverlayState extends State<SplashIntroOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _splashTimer;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _splashTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        widget.game.finishIntroToMainMenu();
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, _, _) {
        return GestureDetector(
          onTap: () {
            _splashTimer?.cancel();
            widget.game.finishIntroToMainMenu();
          },
          child: Material(
            color: ComicTheme.inkBlack,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 2D Cartoon Illustrated Background
                Image.asset(
                  CartoonAssets.bgMainMenu,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        ComicTheme.mangaPanelBg.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),

                // Dynamic Manga Speedlines (Cached in RepaintBoundary)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MangaSpeedLinesPainter(
                        lineCount: 48,
                        color: ComicTheme.comicYellow.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),

                // Center Title & Developer Signature (Responsive Scaled for Mobile/Tablet/Desktop)
                SafeArea(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 880,
                        height: 490,
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: ScaleTransition(
                              scale: _scaleAnim,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Kaito App Icon Emblem + Crossed Katana Crest
                                    Image.asset(
                                      CartoonAssets.uiLogo,
                                      width: 360,
                                      height: 110,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 6),

                                    // Big 2D Cartoon Title Banner: KAITO ADVENTURE
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      decoration: ComicTheme.panelDecoration(
                                        backgroundColor:
                                            ComicTheme.mangaPanelBg,
                                        borderWidth: 5,
                                        shadowOffset: 10,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'KAITO ADVENTURE',
                                            textAlign: TextAlign.center,
                                            style: ComicTheme.titleText(
                                              size: 50,
                                              color: ComicTheme.comicYellow,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppLocalizations.tr(
                                              'game_subtitle',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: ComicTheme.titleText(
                                              size: 16,
                                              color: ComicTheme.energyCyan,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 22),

                                    // DEVELOPED BY JANOSOS with Creator's Photo Icon
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 12,
                                      ),
                                      decoration: ComicTheme.panelDecoration(
                                        backgroundColor: ComicTheme.paperWhite,
                                        borderWidth: 4.5,
                                        shadowOffset: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Creator Janosos Avatar Photo Icon
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              color: ComicTheme.mangaPanelBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: ComicTheme.inkBlack,
                                                width: 3.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: ComicTheme.inkBlack,
                                                  offset: Offset(3, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.asset(
                                                CartoonAssets.uiJanososAvatar,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: ComicTheme.actionRed,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: ComicTheme.inkBlack,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  'CREATOR & DEVELOPER',
                                                  style: ComicTheme.titleText(
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                AppLocalizations.tr(
                                                  'developed_by',
                                                ),
                                                style: ComicTheme.titleText(
                                                  size: 25,
                                                  color: ComicTheme.inkBlack,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Subtle Tap to Continue prompt
                                    Text(
                                      AppLocalizations.tr('tap_to_continue'),
                                      style: ComicTheme.titleText(
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Optional 3-Panel Story Intro accessible from the Main Menu ('story_intro')
class StoryIntroOverlay extends StatefulWidget {
  final MangaGame game;

  const StoryIntroOverlay({super.key, required this.game});

  @override
  State<StoryIntroOverlay> createState() => _StoryIntroOverlayState();
}

class _StoryIntroOverlayState extends State<StoryIntroOverlay> {
  int _currentPanel = 0;
  Timer? _autoTimer;

  static const List<String> _panelAssets = [
    CartoonAssets.introPanel1,
    CartoonAssets.introPanel2,
    CartoonAssets.introPanel3,
  ];

  static const List<Color> _panelColors = [
    ComicTheme.energyCyan,
    ComicTheme.actionRed,
    ComicTheme.comicYellow,
  ];

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (_currentPanel < _panelAssets.length - 1) {
        setState(() => _currentPanel++);
      } else {
        timer.cancel();
      }
    });
  }

  void _nextOrFinish() {
    if (_currentPanel < _panelAssets.length - 1) {
      setState(() => _currentPanel++);
      _startAutoAdvance();
    } else {
      _skipToMenu();
    }
  }

  void _skipToMenu() {
    _autoTimer?.cancel();
    widget.game.finishIntroToMainMenu();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, _, _) {
        final idx = _currentPanel + 1;
        final accentColor = _panelColors[_currentPanel];

        return Material(
          color: ComicTheme.inkBlack,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MangaSpeedLinesPainter(
                      lineCount: 44,
                      color: accentColor.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 880,
                      height: 500,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            // Top Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: ComicTheme.panelDecoration(
                                    backgroundColor: accentColor,
                                    borderWidth: 3.5,
                                    shadowOffset: 4,
                                  ),
                                  child: Text(
                                    AppLocalizations.tr(
                                      'story_p${idx}_chapter',
                                    ),
                                    style: ComicTheme.titleText(
                                      size: 18,
                                      color: ComicTheme.inkBlack,
                                    ),
                                  ),
                                ),
                                Row(
                                  children:
                                      List.generate(_panelAssets.length, (i) {
                                    final active = i == _currentPanel;
                                    return Container(
                                      width: active ? 32 : 14,
                                      height: 12,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? accentColor
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ComicTheme.inkBlack,
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                GestureDetector(
                                  onTap: _skipToMenu,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: ComicTheme.paperWhite,
                                      borderWidth: 3.5,
                                      shadowOffset: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          CartoonAssets.uiBtnSkip,
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.tr('story_skip'),
                                          style: ComicTheme.titleText(
                                            size: 16,
                                            color: ComicTheme.inkBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Main Story Panel
                            Expanded(
                              child: GestureDetector(
                                onTap: _nextOrFinish,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 380),
                                  child: Container(
                                    key: ValueKey<int>(_currentPanel),
                                    width: 760,
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: ComicTheme.mangaPanelBg,
                                      borderWidth: 5,
                                      shadowOffset: 10,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            _panelAssets[_currentPanel],
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    24,
                                                    14,
                                                    24,
                                                    14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: ComicTheme.inkBlack
                                                    .withValues(alpha: 0.88),
                                                border: Border(
                                                  top: BorderSide(
                                                    color: accentColor,
                                                    width: 4,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    AppLocalizations.tr(
                                                      'story_p${idx}_title',
                                                    ),
                                                    style: ComicTheme.titleText(
                                                      size: 26,
                                                      color: accentColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    AppLocalizations.tr(
                                                      'story_p${idx}_caption',
                                                    ),
                                                    style: ComicTheme.bodyText(
                                                      size: 14,
                                                      color:
                                                          ComicTheme.paperWhite,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Bottom Next / Back to Menu Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _nextOrFinish,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 9,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: _currentPanel ==
                                              _panelAssets.length - 1
                                          ? ComicTheme.actionRed
                                          : ComicTheme.comicYellow,
                                      borderWidth: 4,
                                      shadowOffset: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          CartoonAssets.uiBtnPlay,
                                          width: 26,
                                          height: 26,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _currentPanel ==
                                                  _panelAssets.length - 1
                                              ? AppLocalizations.tr(
                                                  'story_begin',
                                                )
                                              : AppLocalizations.tr(
                                                  'story_next',
                                                ),
                                          style: ComicTheme.titleText(
                                            size: 20,
                                            color: _currentPanel ==
                                                    _panelAssets.length - 1
                                                ? ComicTheme.paperWhite
                                                : ComicTheme.inkBlack,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
