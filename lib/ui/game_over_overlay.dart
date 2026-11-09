import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class GameOverOverlay extends StatelessWidget {
  final MangaGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: ComicTheme.comicPanelDecoration(
            backgroundColor: ComicTheme.paperWhite,
            borderColor: ComicTheme.actionRed,
            borderWidth: 4,
            shadowOffset: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Manga defeat title
              Text(
                'TO BE CONTINUED...?',
                style: ComicTheme.comicTitle(
                    fontSize: 34, color: ComicTheme.actionRed),
              ),
              Text(
                '敗北 (DEFEAT)',
                style: ComicTheme.mangaHeader(
                    fontSize: 16, color: ComicTheme.inkBlack),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      border: Border.all(color: ComicTheme.inkBlack, width: 3),
                    ),
                    child: Image.asset(
                      CartoonAssets.portraitKaito,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ComicTheme.halftoneGray,
                        border:
                            Border.all(color: ComicTheme.inkBlack, width: 2),
                      ),
                      child: Text(
                        '"A shinobi rises from every fall. Sharpen your ink blade and strike again!"',
                        style: ComicTheme.comicBody(
                            fontSize: 13, color: ComicTheme.inkBlack),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'FINAL SCORE: ${game.score}',
                style: ComicTheme.comicTitle(
                    fontSize: 20, color: ComicTheme.inkBlack),
              ),
              const SizedBox(height: 18),

              // Buttons
              GestureDetector(
                onTap: () => game.restartCurrentLevel(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: ComicTheme.actionRed,
                  ),
                  child: Center(
                    child: Text(
                      'TRY AGAIN ↺',
                      style:
                          ComicTheme.comicTitle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  game.overlays.remove('game_over');
                  game.overlays.add('chapter_select');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: ComicTheme.paperWhite,
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
