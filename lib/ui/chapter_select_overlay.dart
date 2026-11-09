import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class ChapterSelectOverlay extends StatelessWidget {
  final MangaGame game;
  const ChapterSelectOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.78),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 840),
            decoration: ComicTheme.comicPanelDecoration(
              backgroundColor: ComicTheme.paperWhite,
              borderWidth: 4,
              shadowOffset: 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MANGA VOLUME SELECT',
                      style: ComicTheme.comicTitle(
                          fontSize: 28, color: ComicTheme.inkBlack),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () {
                        game.overlays.remove('chapter_select');
                        game.resumeEngine();
                      },
                    ),
                  ],
                ),
                const Divider(thickness: 3, color: ComicTheme.inkBlack),
                const SizedBox(height: 16),

                // Chapter Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildChapterCard(
                        context,
                        chapterNumber: 1,
                        title: 'THE INKED ROOFTOPS',
                        japaneseTitle: '墨の屋根',
                        bossName: 'KUROKAGE (黒影)',
                        bgAsset: CartoonAssets.bgLevel1,
                        bossAsset: CartoonAssets.portraitKurokage,
                        description:
                            'Leap across Neo-Tokyo pagoda rooftops, evade saw hazards, and confront the Shadow Executioner under the crescent moon.',
                        accentColor: ComicTheme.darkPurple,
                        onSelect: () {
                          game.overlays.remove('chapter_select');
                          game.resumeEngine();
                          game.loadLevel(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildChapterCard(
                        context,
                        chapterNumber: 2,
                        title: 'THE CRIMSON CITADEL',
                        japaneseTitle: '紅蓮の城塞',
                        bossName: 'RYU-KOTEI (竜皇帝)',
                        bgAsset: CartoonAssets.bgLevel2,
                        bossAsset: CartoonAssets.portraitRyuKotei,
                        description:
                            'Ascend the molten fortress, avoid erupted flame geysers, and face the 3-phase Dragon Shogun Mech.',
                        accentColor: ComicTheme.actionRed,
                        onSelect: () {
                          game.overlays.remove('chapter_select');
                          game.resumeEngine();
                          game.loadLevel(2);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context, {
    required int chapterNumber,
    required String title,
    required String japaneseTitle,
    required String bossName,
    required String bgAsset,
    required String bossAsset,
    required String description,
    required Color accentColor,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: Colors.white,
        borderColor: ComicTheme.inkBlack,
        borderWidth: 3,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2D Cartoon Chapter Artwork Preview Banner with Boss Portrait Badge
          SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
                  ),
                  child: Image.asset(
                    bgAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      'ISSUE #$chapterNumber • $japaneseTitle',
                      style: ComicTheme.mangaHeader(
                          fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: Image.asset(
                      bossAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style:
                ComicTheme.comicTitle(fontSize: 20, color: ComicTheme.inkBlack),
          ),
          const SizedBox(height: 4),
          Text(
            'BOSS: $bossName',
            style: ComicTheme.mangaHeader(
                fontSize: 14, color: ComicTheme.actionRed),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: ComicTheme.comicBody(
                fontSize: 12.5, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: ComicTheme.comicButtonDecoration(
                  backgroundColor: ComicTheme.comicYellow,
                ),
                child: Center(
                  child: Text(
                    'PLAY CHAPTER ▶',
                    style: ComicTheme.comicTitle(
                        fontSize: 16, color: ComicTheme.inkBlack),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
