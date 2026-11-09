import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class VictoryOverlay extends StatelessWidget {
  final MangaGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isFinalChapter = game.currentLevelIndex >= 2;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: ComicTheme.comicPanelDecoration(
            backgroundColor: ComicTheme.paperWhite,
            borderColor: ComicTheme.inkBlack,
            borderWidth: 4,
            shadowOffset: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Japanese victory title
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                color: ComicTheme.comicYellow,
                child: Text(
                  '完全勝利 (TOTAL VICTORY)',
                  style: ComicTheme.mangaHeader(
                      fontSize: 16, color: ComicTheme.inkBlack),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'CHAPTER COMPLETE!!',
                style: ComicTheme.comicTitle(
                    fontSize: 32, color: ComicTheme.actionRed),
              ),
              const SizedBox(height: 14),

              // 2D Cartoon S-RANK Badge & Kaito Portrait
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    CartoonAssets.uiBadgeSRank,
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHINOBI RANK: S-CLASS',
                        style: ComicTheme.comicTitle(
                            fontSize: 18, color: ComicTheme.inkBlack),
                      ),
                      Text(
                        'FINAL SCORE: ${game.score}',
                        style: ComicTheme.mangaHeader(
                            fontSize: 18, color: ComicTheme.darkPurple),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(thickness: 3, color: ComicTheme.inkBlack),
              const SizedBox(height: 16),

              // Action Buttons
              GestureDetector(
                onTap: () => game.nextLevel(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: ComicTheme.comicYellow,
                  ),
                  child: Center(
                    child: Text(
                      isFinalChapter ? 'PLAY AGAIN ↺' : 'NEXT CHAPTER ▶',
                      style: ComicTheme.comicTitle(
                          fontSize: 20, color: ComicTheme.inkBlack),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  game.overlays.remove('victory');
                  game.overlays.add('chapter_select');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'CHAPTER SELECT',
                      style: ComicTheme.comicTitle(
                          fontSize: 16, color: ComicTheme.inkBlack),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
