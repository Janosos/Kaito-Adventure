import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class ChapterSelectOverlay extends StatefulWidget {
  final MangaGame game;

  const ChapterSelectOverlay({super.key, required this.game});

  @override
  State<ChapterSelectOverlay> createState() => _ChapterSelectOverlayState();
}

class _ChapterSelectOverlayState extends State<ChapterSelectOverlay> {
  late int _selectedLevel;

  static const List<_ChapterInfo> _chapters = [
    _ChapterInfo(
      level: 1,
      difficulty: '★☆☆☆☆',
      accentColor: ComicTheme.energyCyan,
      bgAsset: CartoonAssets.bgLevel1,
      bossPortrait: CartoonAssets.portraitKurokage,
      hazards: ['Ziplines', 'Wall Jumps', 'Taiko Drums'],
    ),
    _ChapterInfo(
      level: 2,
      difficulty: '★★☆☆☆',
      accentColor: ComicTheme.actionRed,
      bgAsset: CartoonAssets.bgLevel2,
      bossPortrait: CartoonAssets.portraitRyuKotei,
      hazards: ['Magma Forges', 'Elevators', 'Oni Archers'],
    ),
    _ChapterInfo(
      level: 3,
      difficulty: '★★★☆☆',
      accentColor: Color(0xFF00E676),
      bgAsset: CartoonAssets.bgLevel3,
      bossPortrait: CartoonAssets.portraitHebiHime,
      hazards: ['Poison Vents', 'Canopy Glides', 'River Rafts'],
    ),
    _ChapterInfo(
      level: 4,
      difficulty: '★★★★☆',
      accentColor: Color(0xFF40C4FF),
      bgAsset: CartoonAssets.bgLevel4,
      bossPortrait: CartoonAssets.portraitYukiOni,
      hazards: ['Slippery Ice', 'Icicle Falls', 'Blizzard Gale'],
    ),
    _ChapterInfo(
      level: 5,
      difficulty: '★★★★★',
      accentColor: ComicTheme.comicYellow,
      bgAsset: CartoonAssets.bgLevel5,
      bossPortrait: CartoonAssets.portraitMuzanKai,
      hazards: ['Void Portals', 'Astral Waves', 'Final Trial'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.game.currentLevelIndex.clamp(1, 5);
  }

  void _selectPrev() {
    setState(() {
      _selectedLevel = _selectedLevel > 1 ? _selectedLevel - 1 : 5;
    });
  }

  void _selectNext() {
    setState(() {
      _selectedLevel = _selectedLevel < 5 ? _selectedLevel + 1 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final curChapter = _chapters.firstWhere(
      (c) => c.level == _selectedLevel,
      orElse: () => _chapters.first,
    );

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, _, _) {
        return Material(
          color: Colors.black.withValues(alpha: 0.88),
          child: Stack(
            children: [
              // Background dynamic speedlines
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

              // Responsive Chapter Showcase Layout
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        width: 900,
                        height: 500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: ComicTheme.paperWhite,
                          borderWidth: 4.5,
                          shadowOffset: 8,
                        ),
                        child: Column(
                          children: [
                            // 1. Header Bar: Title + Subtitle + Back Button
                            Row(
                              children: [
                                Image.asset(
                                  CartoonAssets.uiBtnChapters,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(width: 10),
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
                                          size: 26,
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
                                          size: 11,
                                          color: ComicTheme.inkBlack,
                                        ).copyWith(height: 1.1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Safe BACK button: returns to Game Over (retry), Victory, or Menu without freezing!
                                GestureDetector(
                                  onTap: () =>
                                      widget.game.closeChapterSelect(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 7,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: ComicTheme.inkBlack,
                                      borderWidth: 3,
                                      shadowOffset: 3,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.tr('btn_back'),
                                          style: ComicTheme.titleText(
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 2. Interactive Chapter Selection Tabs (CH 1 .. CH 5)
                            _buildChapterTabBar(),
                            const SizedBox(height: 10),

                            // 3. Main Stage Showcase: Left (Stage Art & Info) | Right (Boss Intel & Play)
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Half: Stage Illustrated Panorama & Environment Briefing
                                  Expanded(
                                    flex: 5,
                                    child: _buildStageLandscapeCard(curChapter),
                                  ),
                                  const SizedBox(width: 12),

                                  // Right Half: Boss Wanted Poster & Big Play Button
                                  Expanded(
                                    flex: 5,
                                    child: _buildBossIntelCard(curChapter),
                                  ),
                                ],
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

  Widget _buildChapterTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ComicTheme.mangaPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ComicTheme.inkBlack, width: 3),
      ),
      child: Row(
        children: [
          // Previous button
          GestureDetector(
            onTap: _selectPrev,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ComicTheme.panelDecoration(
                backgroundColor: ComicTheme.paperWhite,
                borderWidth: 2,
                shadowOffset: 2,
              ),
              child: const Text('◀', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6),

          // 5 Stage Tabs
          Expanded(
            child: Row(
              children: _chapters.map((ch) {
                final isSelected = ch.level == _selectedLevel;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLevel = ch.level;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: isSelected
                              ? ch.accentColor
                              : ComicTheme.paperWhite.withValues(alpha: 0.85),
                          borderWidth: isSelected ? 3.0 : 2.0,
                          shadowOffset: isSelected ? 3 : 1,
                        ),
                        child: Center(
                          child: Text(
                            'STAGE ${ch.level}',
                            style: ComicTheme.titleText(
                              size: 14,
                              color: ComicTheme.inkBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 6),

          // Next button
          GestureDetector(
            onTap: _selectNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ComicTheme.panelDecoration(
                backgroundColor: ComicTheme.paperWhite,
                borderWidth: 2,
                shadowOffset: 2,
              ),
              child: const Text('▶', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageLandscapeCard(_ChapterInfo ch) {
    return Container(
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Stage Illustrated Background
            Image.asset(
              ch.bgAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
            // Manga Gradient Shading
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ComicTheme.inkBlack.withValues(alpha: 0.35),
                    ComicTheme.inkBlack.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),

            // Content Overlays
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Chapter Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: ch.accentColor,
                          borderWidth: 2.5,
                          shadowOffset: 2,
                        ),
                        child: Text(
                          'STAGE ${ch.level} / 5',
                          style: ComicTheme.titleText(
                            size: 13,
                            color: ComicTheme.inkBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Stage Title
                  Text(
                    AppLocalizations.chapterTitle(ch.level),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ComicTheme.titleText(
                      size: 22,
                      color: Colors.white,
                    ).copyWith(height: 1.15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossIntelCard(_ChapterInfo ch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        children: [
          // Boss Header with Skull Icon
          Row(
            children: [
              Image.asset(
                CartoonAssets.uiBossSkull,
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppLocalizations.tr('boss_prefix')}${AppLocalizations.chapterBoss(ch.level)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ComicTheme.titleText(
                    size: 16,
                    color: ch.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Center Boss Portrait with Frame
          Expanded(
            child: Row(
              children: [
                // Boss Illustrated Portrait
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ch.accentColor, width: 3.5),
                    boxShadow: const [
                      BoxShadow(
                        color: ComicTheme.inkBlack,
                        offset: Offset(3, 3),
                      ),
                    ],
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
                const SizedBox(width: 12),

                // Boss Intel & Mechanics Notes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ComicTheme.actionRed,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ComicTheme.inkBlack,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.tr('arena_gate_badge'),
                          style: ComicTheme.titleText(
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.tr('arena_gate_desc'),
                        style: ComicTheme.bodyText(
                          size: 11.5,
                          color: Colors.white70,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 ${AppLocalizations.tr('tip_label')}: ${AppLocalizations.chapterTip(ch.level)}',
                        style: ComicTheme.bodyText(
                          size: 11,
                          color: ComicTheme.comicYellow,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Big 2D Cartoon PLAY Button
          GestureDetector(
            onTap: () {
              widget.game.startFromMainMenu(level: ch.level);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: ComicTheme.comicButtonDecoration(
                backgroundColor: ch.accentColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    CartoonAssets.uiBtnPlay,
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${AppLocalizations.tr('btn_play_chapter')} STAGE ${ch.level} ▶',
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
    );
  }
}

class _ChapterInfo {
  final int level;
  final String difficulty;
  final Color accentColor;
  final String bgAsset;
  final String bossPortrait;
  final List<String> hazards;

  const _ChapterInfo({
    required this.level,
    required this.difficulty,
    required this.accentColor,
    required this.bgAsset,
    required this.bossPortrait,
    required this.hazards,
  });
}
