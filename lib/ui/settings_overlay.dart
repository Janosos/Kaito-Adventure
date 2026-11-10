import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class SettingsOverlay extends StatelessWidget {
  final MangaGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, currentLang, _) {
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
                      fit: BoxFit.scaleDown,
                      child: Container(
                        width: 580,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: ComicTheme.paperWhite,
                          borderWidth: 5,
                          shadowOffset: 10,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: ComicTheme.mangaPanelBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: ComicTheme.inkBlack,
                                      width: 3,
                                    ),
                                  ),
                                  child: Image.asset(
                                    CartoonAssets.uiBtnSettings,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.tr('settings_title'),
                                        style: ComicTheme.titleText(
                                          size: 26,
                                          color: ComicTheme.actionRed,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.tr(
                                          'settings_subtitle',
                                        ),
                                        style: ComicTheme.bodyText(
                                          size: 12,
                                          color: ComicTheme.inkBlack,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: game.closeSettings,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: ComicTheme.actionRed,
                                      borderWidth: 3,
                                      shadowOffset: 3,
                                    ),
                                    child: Text(
                                      AppLocalizations.tr('btn_close'),
                                      style: ComicTheme.titleText(
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Language Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ComicTheme.mangaPanelBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ComicTheme.inkBlack,
                                  width: 3.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.language,
                                        color: ComicTheme.comicYellow,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.tr('language_label'),
                                        style: ComicTheme.titleText(
                                          size: 17,
                                          color: ComicTheme.comicYellow,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildLanguageOption(
                                    lang: AppLanguage.en,
                                    current: currentLang,
                                    flagBadge: 'EN',
                                    title: 'ENGLISH',
                                    subtitle: AppLocalizations.tr('lang_en'),
                                    activeColor: ComicTheme.energyCyan,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLanguageOption(
                                    lang: AppLanguage.es,
                                    current: currentLang,
                                    flagBadge: 'ES',
                                    title: 'ESPAÑOL',
                                    subtitle: AppLocalizations.tr('lang_es'),
                                    activeColor: ComicTheme.comicYellow,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLanguageOption(
                                    lang: AppLanguage.ja,
                                    current: currentLang,
                                    flagBadge: 'JP',
                                    title: '日本語',
                                    subtitle: AppLocalizations.tr('lang_ja'),
                                    activeColor: ComicTheme.actionRed,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Virtual Touch Controls Toggle
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  AppLocalizations.showVirtualControls,
                              builder: (context, showTouch, _) {
                                return GestureDetector(
                                  onTap: () {
                                    game.setVirtualControlsEnabled(!showTouch);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: ComicTheme.panelDecoration(
                                      backgroundColor: Colors.white,
                                      borderWidth: 3.5,
                                      shadowOffset: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          CartoonAssets.uiBtnControls,
                                          width: 32,
                                          height: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.tr(
                                              'virtual_controls_label',
                                            ),
                                            style: ComicTheme.titleText(
                                              size: 17,
                                              color: ComicTheme.inkBlack,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration:
                                              ComicTheme.panelDecoration(
                                                backgroundColor: showTouch
                                                    ? Colors
                                                          .greenAccent
                                                          .shade400
                                                    : Colors.grey.shade400,
                                                borderWidth: 2.5,
                                                shadowOffset: 2,
                                              ),
                                          child: Text(
                                            showTouch
                                                ? AppLocalizations.tr('enabled')
                                                : AppLocalizations.tr(
                                                    'disabled',
                                                  ),
                                            style: ComicTheme.titleText(
                                              size: 15,
                                              color: ComicTheme.inkBlack,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildLanguageOption({
    required AppLanguage lang,
    required AppLanguage current,
    required String flagBadge,
    required String title,
    required String subtitle,
    required Color activeColor,
  }) {
    final isSelected = lang == current;
    return GestureDetector(
      onTap: () => AppLocalizations.setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ComicTheme.inkBlack : Colors.white38,
            width: isSelected ? 3.5 : 2.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: ComicTheme.inkBlack,
                    offset: Offset(4, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ComicTheme.inkBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                flagBadge,
                style: ComicTheme.titleText(
                  size: 15,
                  color: ComicTheme.comicYellow,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ComicTheme.titleText(
                      size: 18,
                      color: isSelected
                          ? (lang == AppLanguage.ja
                              ? Colors.white
                              : ComicTheme.inkBlack)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: ComicTheme.bodyText(
                      size: 11,
                      color: isSelected
                          ? (lang == AppLanguage.ja
                              ? Colors.white70
                              : ComicTheme.inkBlack)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ComicTheme.inkBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
