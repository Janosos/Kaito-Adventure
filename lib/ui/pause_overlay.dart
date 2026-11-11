import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class PauseOverlay extends StatelessWidget {
  final MangaGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.72),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(20),
                    decoration: ComicTheme.comicPanelDecoration(
                      backgroundColor: ComicTheme.paperWhite,
                      borderWidth: 4,
                      shadowOffset: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.tr('pause_tag'),
                          style: ComicTheme.comicTitle(
                              fontSize: 28, color: ComicTheme.inkBlack),
                        ),
                        Text(
                          AppLocalizations.tr('pause_title'),
                          style: ComicTheme.mangaHeader(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        const Divider(thickness: 3, color: ComicTheme.inkBlack),
                        const SizedBox(height: 8),
                        _buildMenuButton(
                          iconAsset: CartoonAssets.uiBtnPlay,
                          label: AppLocalizations.tr('btn_resume'),
                          color: ComicTheme.comicYellow,
                          onTap: () => game.togglePause(),
                        ),
                        const SizedBox(height: 8),
                        _buildMenuButton(
                          iconAsset: CartoonAssets.uiSkillSlash,
                          label: AppLocalizations.tr('btn_restart_stage'),
                          color: Colors.white,
                          onTap: () {
                            game.overlays.remove('pause');
                            game.restartCurrentLevel();
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMenuButton(
                          iconAsset: CartoonAssets.uiBtnChapters,
                          label: AppLocalizations.tr('btn_select_chapter'),
                          color: ComicTheme.energyCyan,
                          onTap: () {
                            game.overlays.remove('pause');
                            game.overlays.add('chapter_select');
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMenuButton(
                          iconAsset: CartoonAssets.uiBtnSettings,
                          label: AppLocalizations.tr('btn_settings'),
                          color: const Color(0xFFE9D8FD),
                          onTap: () => game.openSettings(),
                        ),
                        const SizedBox(height: 8),
                        _buildMenuButton(
                          iconAsset: CartoonAssets.uiBtnHome,
                          label: AppLocalizations.tr('btn_main_menu'),
                          color: ComicTheme.paperWhite,
                          onTap: () => game.returnToMainMenu(),
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

  Widget _buildMenuButton({
    required String iconAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService.buttonHaptic();
        AudioService.playSfx(AudioService.sfxClick);
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor: color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 22, height: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: ComicTheme.comicTitle(
                    fontSize: 16, color: ComicTheme.inkBlack),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
