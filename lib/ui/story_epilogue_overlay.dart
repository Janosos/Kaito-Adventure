import 'dart:async';
import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

/// 3-Panel Story Epilogue (Outro) triggered upon completing Chapter 5 (Muzan-Kai defeated!)
class StoryEpilogueOverlay extends StatefulWidget {
  final MangaGame game;

  const StoryEpilogueOverlay({super.key, required this.game});

  @override
  State<StoryEpilogueOverlay> createState() => _StoryEpilogueOverlayState();
}

class _StoryEpilogueOverlayState extends State<StoryEpilogueOverlay> {
  int _currentPanel = 0;
  Timer? _autoTimer;

  static const List<String> _panelAssets = [
    CartoonAssets.epiloguePanel1,
    CartoonAssets.epiloguePanel2,
    CartoonAssets.epiloguePanel3,
  ];

  static const List<Color> _panelColors = [
    ComicTheme.actionRed,
    ComicTheme.energyCyan,
    ComicTheme.comicYellow,
  ];

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 5500), (timer) {
      if (!mounted) return;
      if (_currentPanel < _panelAssets.length - 1) {
        setState(() => _currentPanel++);
      } else {
        timer.cancel();
      }
    });
  }

  void _nextOrFinish() {
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxClick);
    if (_currentPanel < _panelAssets.length - 1) {
      setState(() => _currentPanel++);
      _startAutoAdvance();
    } else {
      _finishToVictory();
    }
  }

  void _finishToVictory() {
    _autoTimer?.cancel();
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    widget.game.finishEpilogueToVictory();
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
                            // Top Header: Epilogue Stage & Progress Dots & Skip
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
                                      'epilogue_p${idx}_chapter',
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
                                  onTap: _finishToVictory,
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

                            // Main Illustrated Story Epilogue Panel
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
                                                      'epilogue_p${idx}_title',
                                                    ),
                                                    style: ComicTheme.titleText(
                                                      size: 26,
                                                      color: accentColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    AppLocalizations.tr(
                                                      'epilogue_p${idx}_caption',
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

                            // Bottom Next / Claim Victory Button
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
                                          ? ComicTheme.comicYellow
                                          : accentColor,
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
                                                  'epilogue_finish',
                                                )
                                              : AppLocalizations.tr(
                                                  'story_next',
                                                ),
                                          style: ComicTheme.titleText(
                                            size: 20,
                                            color: ComicTheme.inkBlack,
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
