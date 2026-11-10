import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class GameOverOverlay extends StatelessWidget {
  final MangaGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          body: Center(
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(24),
              decoration: ComicTheme.comicPanelDecoration(
                backgroundColor: ComicTheme.paperWhite,
                borderColor: ComicTheme.actionRed,
                borderWidth: 4,
                shadowOffset: 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.tr('gameover_title'),
                    style: ComicTheme.comicTitle(
                        fontSize: 32, color: ComicTheme.actionRed),
                  ),
                  Text(
                    AppLocalizations.tr('gameover_sub'),
                    style: ComicTheme.mangaHeader(
                        fontSize: 16, color: ComicTheme.inkBlack),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: ComicTheme.inkBlack, width: 3),
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
                            border: Border.all(
                                color: ComicTheme.inkBlack, width: 2),
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
                  const SizedBox(height: 12),
                  Text(
                    '${AppLocalizations.tr('score_label')}${game.score}',
                    style: ComicTheme.comicTitle(
                        fontSize: 20, color: ComicTheme.inkBlack),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => game.restartCurrentLevel(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: ComicTheme.comicButtonDecoration(
                        backgroundColor: ComicTheme.actionRed,
                      ),
                      child: Center(
                        child: Text(
                          '${AppLocalizations.tr('btn_retry')} ↺',
                          style: ComicTheme.comicTitle(
                              fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            game.overlays.remove('game_over');
                            game.overlays.add('chapter_select');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: ComicTheme.comicButtonDecoration(
                              backgroundColor: ComicTheme.paperWhite,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(CartoonAssets.uiBtnChapters,
                                    width: 22, height: 22),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppLocalizations.tr('select_chapter_title'),
                                    style: ComicTheme.comicTitle(
                                        fontSize: 14,
                                        color: ComicTheme.inkBlack),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => game.returnToMainMenu(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: ComicTheme.comicButtonDecoration(
                              backgroundColor: ComicTheme.paperWhite,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(CartoonAssets.uiBtnHome,
                                    width: 22, height: 22),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppLocalizations.tr('btn_main_menu'),
                                    style: ComicTheme.comicTitle(
                                        fontSize: 14,
                                        color: ComicTheme.inkBlack),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
