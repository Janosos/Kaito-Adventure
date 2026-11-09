import 'package:flutter/material.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class PauseOverlay extends StatelessWidget {
  final MangaGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: ComicTheme.comicPanelDecoration(
            backgroundColor: ComicTheme.paperWhite,
            borderWidth: 4,
            shadowOffset: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: ComicTheme.comicTitle(fontSize: 34, color: ComicTheme.inkBlack),
              ),
              Text(
                '一休み (TAKE A BREATHER)',
                style: ComicTheme.mangaHeader(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 3, color: ComicTheme.inkBlack),
              const SizedBox(height: 16),

              _buildMenuButton(
                label: 'RESUME [ESC]',
                color: ComicTheme.comicYellow,
                onTap: () => game.togglePause(),
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                label: 'RESTART CHAPTER',
                color: Colors.white,
                onTap: () {
                  game.overlays.remove('pause');
                  game.restartCurrentLevel();
                },
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                label: 'SELECT CHAPTER',
                color: ComicTheme.energyCyan,
                onTap: () {
                  game.overlays.remove('pause');
                  game.overlays.add('chapter_select');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor: color,
        ),
        child: Center(
          child: Text(
            label,
            style: ComicTheme.comicTitle(fontSize: 18, color: ComicTheme.inkBlack),
          ),
        ),
      ),
    );
  }
}
