import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class ChapterSelectOverlay extends StatelessWidget {
  final MangaGame game;

  const ChapterSelectOverlay({super.key, required this.game});

  static const List<_ChapterVisual> _visuals = [
    _ChapterVisual(
      level: 1,
      accentColor: ComicTheme.energyCyan,
      bgAsset: CartoonAssets.bgLevel1,
      bossPortrait: CartoonAssets.portraitKurokage,
    ),
    _ChapterVisual(
      level: 2,
      accentColor: ComicTheme.actionRed,
      bgAsset: CartoonAssets.bgLevel2,
      bossPortrait: CartoonAssets.portraitRyuKotei,
    ),
    _ChapterVisual(
      level: 3,
      accentColor: Color(0xFF00E676),
      bgAsset: CartoonAssets.bgLevel3,
      bossPortrait: CartoonAssets.portraitHebiHime,
    ),
    _ChapterVisual(
      level: 4,
      accentColor: Color(0xFF40C4FF),
      bgAsset: CartoonAssets.bgLevel4,
      bossPortrait: CartoonAssets.portraitYukiOni,
    ),
    _ChapterVisual(
      level: 5,
      accentColor: ComicTheme.comicYellow,
      bgAsset: CartoonAssets.bgLevel5,
      bossPortrait: CartoonAssets.portraitMuzanKai,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, _, _) {
        return Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MangaSpeedLinesPainter(
                      lineCount: 36,
                      color: Colors.white10,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        width: 820,
                        height: 490,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: ComicTheme.paperWhite,
                          borderWidth: 4.5,
                          shadowOffset: 8,
                        ),
                        child: Column(
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Image.asset(
                                  CartoonAssets.uiBtnChapters,
                                  width: 38,
                                  height: 38,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.tr(
                                          'select_chapter_title',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: ComicTheme.titleText(
                                          size: 28,
                                          color: ComicTheme.actionRed,
                                        ).copyWith(height: 1.05),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppLocalizations.tr(
                                          'select_chapter_sub',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: ComicTheme.bodyText(
                                          size: 11.5,
                                          color: ComicTheme.inkBlack,
                                        ).copyWith(height: 1.1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () =>
                                      game.overlays.remove('chapter_select'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: ComicTheme.inkBlack,
                                      borderWidth: 3,
                                      shadowOffset: 3,
                                    ),
                                    child: Text(
                                      AppLocalizations.tr('btn_back'),
                                      style: ComicTheme.titleText(
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Scrollable 5-Chapter List (Overflow-Free!)
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _visuals.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return _buildChapterCard(_visuals[index]);
                                },
                              ),
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

  Widget _buildChapterCard(_ChapterVisual ch) {
    final isCurrent = game.currentLevelIndex == ch.level;

    return GestureDetector(
      onTap: () {
        game.overlays.remove('chapter_select');
        game.startFromMainMenu(level: ch.level);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        decoration: ComicTheme.panelDecoration(
          backgroundColor: ComicTheme.mangaPanelBg,
          borderWidth: 3.5,
          shadowOffset: 4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.48,
                  child: Image.asset(
                    ch.bgAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ComicTheme.inkBlack.withValues(alpha: 0.92),
                        ComicTheme.inkBlack.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Boss Portrait Thumbnail
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: ch.accentColor, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.asset(
                          ch.bossPortrait,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.chapterTitle(ch.level),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ComicTheme.titleText(
                              size: 18,
                              color: ch.accentColor,
                            ).copyWith(height: 1.08),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.chapterSubtitle(ch.level),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ComicTheme.bodyText(
                              size: 11.5,
                              color: Colors.white70,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppLocalizations.tr('boss_prefix')}${AppLocalizations.chapterBoss(ch.level)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ComicTheme.titleText(
                              size: 12.5,
                              color: ComicTheme.comicYellow,
                            ).copyWith(height: 1.08),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: ComicTheme.panelDecoration(
                        backgroundColor:
                            isCurrent ? ComicTheme.comicYellow : ch.accentColor,
                        borderWidth: 3,
                        shadowOffset: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            CartoonAssets.uiBtnPlay,
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.tr('btn_play_chapter'),
                            style: ComicTheme.titleText(
                              size: 17,
                              color: ComicTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterVisual {
  final int level;
  final Color accentColor;
  final String bgAsset;
  final String bossPortrait;

  const _ChapterVisual({
    required this.level,
    required this.accentColor,
    required this.bgAsset,
    required this.bossPortrait,
  });
}
