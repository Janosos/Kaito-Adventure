import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
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
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.90 + 0.10 * t,
                child: child,
              ),
            );
          },
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.85),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                    width: 460,
                    padding: const EdgeInsets.all(22),
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
                              fontSize: 30, color: ComicTheme.actionRed),
                        ),
                        Text(
                          AppLocalizations.tr('gameover_sub'),
                          style: ComicTheme.mangaHeader(
                              fontSize: 15, color: ComicTheme.inkBlack),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: ComicTheme.inkBlack, width: 3),
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
                                      fontSize: 12.5,
                                      color: ComicTheme.inkBlack),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${AppLocalizations.tr('score_label')}${game.score}',
                          style: ComicTheme.comicTitle(
                              fontSize: 19, color: ComicTheme.inkBlack),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            AudioService.buttonHaptic();
                            AudioService.playSfx(AudioService.sfxStart);
                            game.restartCurrentLevel();
                          },
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
                                    fontSize: 19, color: Colors.white),
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
                                  AudioService.buttonHaptic();
                                  AudioService.playSfx(AudioService.sfxClick);
                                  game.overlays.remove('game_over');
                                  game.overlays.add('chapter_select');
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
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
                                          AppLocalizations.tr(
                                              'select_chapter_title'),
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
                                onTap: () {
                                  AudioService.buttonHaptic();
                                  AudioService.playSfx(AudioService.sfxClick);
                                  game.returnToMainMenu();
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
