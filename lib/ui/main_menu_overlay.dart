import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class MainMenuOverlay extends StatefulWidget {
  final MangaGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  bool _showControlsModal = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, _, _) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 2D Cartoon Illustrated Panoramic Main Menu Background
              Image.asset(
                CartoonAssets.bgMainMenu,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      ComicTheme.inkBlack.withValues(alpha: 0.78),
                      ComicTheme.inkBlack.withValues(alpha: 0.30),
                      ComicTheme.inkBlack.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),

              // 2. Manga Halftone & Speedline Accents (Cached in RepaintBoundary)
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MangaSpeedLinesPainter(
                      lineCount: 36,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),

              // 3. Responsive Main Menu Layout (Scales cleanly on Mobile, Tablet & Desktop)
              SafeArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 920,
                      height: 500,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            const Spacer(),

                            // Center Row: Left Hero Showcase Card + Right Action Buttons
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: Kaito Hero Portrait Card
                                Expanded(
                                  flex: 5,
                                  child: Center(
                                    child: Container(
                                      width: 310,
                                      padding: const EdgeInsets.all(12),
                                      decoration: ComicTheme.panelDecoration(
                                        backgroundColor: ComicTheme.paperWhite,
                                        borderWidth: 5,
                                        shadowOffset: 8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 150,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: ComicTheme.inkBlack,
                                                width: 3.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              child: Image.asset(
                                                CartoonAssets.portraitKaito,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'KAITO • THE INK SHINOBI',
                                            style: ComicTheme.titleText(
                                              size: 20,
                                              color: ComicTheme.actionRed,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppLocalizations.tr('hero_card_sub'),
                                            textAlign: TextAlign.center,
                                            style: ComicTheme.bodyText(
                                              size: 11,
                                              color: ComicTheme.inkBlack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Right: 2D Cartoon Action Buttons
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildCartoonMenuButton(
                                        iconAsset: CartoonAssets.uiBtnPlay,
                                        label: AppLocalizations.tr(
                                          'btn_start_adventure',
                                        ),
                                        bgColor: ComicTheme.actionRed,
                                        textColor: ComicTheme.paperWhite,
                                        isPrimary: true,
                                        onTap: () {
                                          widget.game.startFromMainMenu(
                                            level: 1,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      _buildCartoonMenuButton(
                                        iconAsset: CartoonAssets.uiBtnChapters,
                                        label: AppLocalizations.tr(
                                          'btn_select_chapter',
                                        ),
                                        bgColor: ComicTheme.comicYellow,
                                        textColor: ComicTheme.inkBlack,
                                        onTap: () {
                                          widget.game.overlays
                                              .add('chapter_select');
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildCartoonMenuButton(
                                              iconAsset:
                                                  CartoonAssets.uiBtnIntro,
                                              label: AppLocalizations.tr(
                                                'btn_story_intro',
                                              ),
                                              bgColor: ComicTheme.paperWhite,
                                              textColor: ComicTheme.inkBlack,
                                              compact: true,
                                              onTap: () {
                                                widget.game.openIntroStory();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildCartoonMenuButton(
                                              iconAsset:
                                                  CartoonAssets.uiBtnControls,
                                              label: AppLocalizations.tr(
                                                'btn_how_to_play',
                                              ),
                                              bgColor: ComicTheme.energyCyan,
                                              textColor: ComicTheme.inkBlack,
                                              compact: true,
                                              onTap: () {
                                                setState(
                                                  () =>
                                                      _showControlsModal = true,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildCartoonMenuButton(
                                        iconAsset: CartoonAssets.uiBtnSettings,
                                        label: AppLocalizations.tr(
                                          'btn_settings',
                                        ),
                                        bgColor: ComicTheme.mangaPanelBg,
                                        textColor: ComicTheme.comicYellow,
                                        compact: true,
                                        onTap: () {
                                          widget.game.openSettings();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Controls / How To Play Modal (Responsive FittedBox)
              if (_showControlsModal) _buildControlsModal(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartoonMenuButton({
    required String iconAsset,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService.buttonHaptic();
        AudioService.playSfx(
          isPrimary ? AudioService.sfxStart : AudioService.sfxClick,
        );
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: isPrimary ? 11 : (compact ? 8 : 9),
        ),
        decoration: ComicTheme.panelDecoration(
          backgroundColor: bgColor,
          borderWidth: isPrimary ? 4.5 : 3.5,
          shadowOffset: isPrimary ? 7 : 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: isPrimary ? 32 : (compact ? 24 : 28),
              height: isPrimary ? 32 : (compact ? 24 : 28),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: ComicTheme.titleText(
                  size: isPrimary ? 23 : (compact ? 16 : 19),
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(22),
                decoration: ComicTheme.panelDecoration(
                  backgroundColor: ComicTheme.paperWhite,
                  borderWidth: 5,
                  shadowOffset: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.tr('controls_title'),
                      style: ComicTheme.titleText(
                        size: 28,
                        color: ComicTheme.actionRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _controlRow(
                      'A / D  |  ◀ / ▶',
                      AppLocalizations.tr('ctrl_move'),
                    ),
                    _controlRow(
                      'SPACE / W / ▲',
                      AppLocalizations.tr('ctrl_jump'),
                    ),
                    _controlRow(
                      'J / X',
                      AppLocalizations.tr('ctrl_slash'),
                    ),
                    _controlRow(
                      'K / C / SHIFT',
                      AppLocalizations.tr('ctrl_dash'),
                    ),
                    _controlRow(
                      'L / Z',
                      AppLocalizations.tr('ctrl_kunai'),
                    ),
                    _controlRow(
                      'U / V',
                      AppLocalizations.tr('ctrl_ougi'),
                    ),
                    _controlRow(
                      'P / ESC',
                      AppLocalizations.tr('ctrl_pause'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.tr('ctrl_tip'),
                      textAlign: TextAlign.center,
                      style: ComicTheme.bodyText(
                        size: 13,
                        color: ComicTheme.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ComicButton(
                      label: AppLocalizations.tr('btn_got_it'),
                      color: ComicTheme.comicYellow,
                      onPressed: () =>
                          setState(() => _showControlsModal = false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlRow(String keys, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ComicTheme.mangaPanelBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
            ),
            child: Text(
              keys,
              textAlign: TextAlign.center,
              style: ComicTheme.titleText(
                size: 15,
                color: ComicTheme.comicYellow,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              desc,
              style: ComicTheme.bodyText(
                size: 14,
                color: ComicTheme.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
