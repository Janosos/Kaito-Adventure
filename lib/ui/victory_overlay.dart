import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class VictoryOverlay extends StatelessWidget {
  final MangaGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isFinalChapter = game.currentLevelIndex >= MangaGame.totalLevels;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 490,
                    padding: const EdgeInsets.all(22),
                    decoration: ComicTheme.comicPanelDecoration(
                      backgroundColor: ComicTheme.paperWhite,
                      borderColor: ComicTheme.inkBlack,
                      borderWidth: 4,
                      shadowOffset: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          color: ComicTheme.comicYellow,
                          child: Text(
                            isFinalChapter
                                ? AppLocalizations.tr('victory_all')
                                : AppLocalizations.tr('victory_chapter'),
                            style: ComicTheme.mangaHeader(
                                fontSize: 16, color: ComicTheme.inkBlack),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isFinalChapter
                              ? AppLocalizations.tr('victory_sub_all')
                              : AppLocalizations.tr('victory_sub_next'),
                          textAlign: TextAlign.center,
                          style: ComicTheme.comicTitle(
                              fontSize: 20, color: ComicTheme.actionRed),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              CartoonAssets.uiBadgeSRank,
                              width: 72,
                              height: 72,
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
                                  '${AppLocalizations.tr('final_score_label')}${game.score}',
                                  style: ComicTheme.mangaHeader(
                                      fontSize: 18,
                                      color: ComicTheme.darkPurple),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(thickness: 3, color: ComicTheme.inkBlack),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            AudioService.buttonHaptic();
                            AudioService.playSfx(AudioService.sfxStart);
                            game.nextLevel();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: ComicTheme.comicButtonDecoration(
                              backgroundColor: ComicTheme.comicYellow,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(CartoonAssets.uiBtnPlay,
                                    width: 24, height: 24),
                                const SizedBox(width: 8),
                                Text(
                                  isFinalChapter
                                      ? '${AppLocalizations.tr('btn_play_again')} ↺'
                                      : '${AppLocalizations.tr('btn_next_chapter')} (${game.currentLevelIndex + 1}/${MangaGame.totalLevels}) ▶',
                                  style: ComicTheme.comicTitle(
                                      fontSize: 18, color: ComicTheme.inkBlack),
                                ),
                              ],
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
                                  game.overlays.remove('victory');
                                  game.overlays.add('chapter_select');
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: ComicTheme.comicButtonDecoration(
                                    backgroundColor: Colors.white,
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
        );
      },
    );
  }
}
