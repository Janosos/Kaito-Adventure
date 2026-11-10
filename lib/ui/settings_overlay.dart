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
        return ValueListenableBuilder<HudControlsConfig>(
          valueListenable: AppLocalizations.hudConfig,
          builder: (context, hudCfg, _) {
            final sizePct = (hudCfg.buttonScale * 100).round();
            final opacityPct = (hudCfg.buttonOpacity * 100).round();

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
                          fit: BoxFit.contain,
                          child: Container(
                            width: 820,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
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
                                      width: 44,
                                      height: 44,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: ComicTheme.mangaPanelBg,
                                        borderRadius:
                                            BorderRadius.circular(10),
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppLocalizations.tr(
                                              'settings_title',
                                            ),
                                            style: ComicTheme.titleText(
                                              size: 25,
                                              color: ComicTheme.actionRed,
                                            ),
                                          ),
                                          Text(
                                            AppLocalizations.tr(
                                              'settings_subtitle',
                                            ),
                                            style: ComicTheme.bodyText(
                                              size: 11.5,
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
                                const SizedBox(height: 12),

                                // Two-Column Settings Layout for Landscape Screens
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column: Language Selector (EN / ES / JA)
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: ComicTheme.mangaPanelBg,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: ComicTheme.inkBlack,
                                            width: 3.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.language,
                                                  color: ComicTheme.comicYellow,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    AppLocalizations.tr(
                                                      'language_label',
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: ComicTheme.titleText(
                                                      size: 16,
                                                      color: ComicTheme
                                                          .comicYellow,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            _buildLanguageOption(
                                              lang: AppLanguage.en,
                                              current: currentLang,
                                              flagBadge: 'EN',
                                              title: 'ENGLISH',
                                              subtitle: AppLocalizations.tr(
                                                'lang_en',
                                              ),
                                              activeColor:
                                                  ComicTheme.energyCyan,
                                            ),
                                            const SizedBox(height: 6),
                                            _buildLanguageOption(
                                              lang: AppLanguage.es,
                                              current: currentLang,
                                              flagBadge: 'ES',
                                              title: 'ESPAÑOL',
                                              subtitle: AppLocalizations.tr(
                                                'lang_es',
                                              ),
                                              activeColor:
                                                  ComicTheme.comicYellow,
                                            ),
                                            const SizedBox(height: 6),
                                            _buildLanguageOption(
                                              lang: AppLanguage.ja,
                                              current: currentLang,
                                              flagBadge: 'JP',
                                              title: '日本語',
                                              subtitle: AppLocalizations.tr(
                                                'lang_ja',
                                              ),
                                              activeColor: ComicTheme.actionRed,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Right Column: Touch Controls Toggle + Button Size, Opacity & Position Editor
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        children: [
                                          // Virtual Touch Controls Toggle
                                          ValueListenableBuilder<bool>(
                                            valueListenable: AppLocalizations
                                                .showVirtualControls,
                                            builder: (context, showTouch, _) {
                                              return GestureDetector(
                                                onTap: () {
                                                  game.setVirtualControlsEnabled(
                                                    !showTouch,
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                    vertical: 9,
                                                  ),
                                                  decoration: ComicTheme
                                                      .panelDecoration(
                                                    backgroundColor:
                                                        Colors.white,
                                                    borderWidth: 3.5,
                                                    shadowOffset: 4,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Image.asset(
                                                        CartoonAssets
                                                            .uiBtnControls,
                                                        width: 28,
                                                        height: 28,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          AppLocalizations.tr(
                                                            'virtual_controls_label',
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: ComicTheme
                                                              .titleText(
                                                            size: 15,
                                                            color: ComicTheme
                                                                .inkBlack,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 5,
                                                        ),
                                                        decoration: ComicTheme
                                                            .panelDecoration(
                                                          backgroundColor: showTouch
                                                              ? Colors
                                                                  .greenAccent
                                                                  .shade400
                                                              : Colors
                                                                  .grey
                                                                  .shade400,
                                                          borderWidth: 2.5,
                                                          shadowOffset: 2,
                                                        ),
                                                        child: Text(
                                                          showTouch
                                                              ? AppLocalizations
                                                                  .tr('enabled')
                                                              : AppLocalizations
                                                                  .tr(
                                                                  'disabled',
                                                                ),
                                                          style: ComicTheme
                                                              .titleText(
                                                            size: 14,
                                                            color: ComicTheme
                                                                .inkBlack,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 10),

                                          // Button Size, Transparency & Position Customization Panel
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: ComicTheme.mangaPanelBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: ComicTheme.inkBlack,
                                                width: 3.5,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.tr(
                                                    'hud_custom_title',
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: ComicTheme.titleText(
                                                    size: 15,
                                                    color:
                                                        ComicTheme.comicYellow,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),

                                                // Button Size Row
                                                _buildStepSliderRow(
                                                  title:
                                                      '${AppLocalizations.tr('btn_size_label')}: $sizePct%',
                                                  ratio: ((hudCfg.buttonScale -
                                                              0.60) /
                                                          1.20)
                                                      .clamp(0.0, 1.0),
                                                  barColor:
                                                      ComicTheme.energyCyan,
                                                  onMinus: () =>
                                                      AppLocalizations
                                                          .updateButtonScale(
                                                    hudCfg.buttonScale - 0.10,
                                                  ),
                                                  onPlus: () => AppLocalizations
                                                      .updateButtonScale(
                                                    hudCfg.buttonScale + 0.10,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),

                                                // Button Opacity / Transparency Row
                                                _buildStepSliderRow(
                                                  title:
                                                      '${AppLocalizations.tr('btn_opacity_label')}: $opacityPct%',
                                                  ratio:
                                                      ((hudCfg.buttonOpacity -
                                                                  0.25) /
                                                              0.75)
                                                          .clamp(0.0, 1.0),
                                                  barColor:
                                                      ComicTheme.comicYellow,
                                                  onMinus: () =>
                                                      AppLocalizations
                                                          .updateButtonOpacity(
                                                    hudCfg.buttonOpacity - 0.10,
                                                  ),
                                                  onPlus: () => AppLocalizations
                                                      .updateButtonOpacity(
                                                    hudCfg.buttonOpacity + 0.10,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),

                                                // Edit Button Positions + Reset Default Buttons
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: GestureDetector(
                                                        onTap: game
                                                            .openHudLayoutEditor,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 9,
                                                            horizontal: 8,
                                                          ),
                                                          decoration: ComicTheme
                                                              .comicButtonDecoration(
                                                            backgroundColor:
                                                                ComicTheme
                                                                    .comicYellow,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              AppLocalizations.tr(
                                                                'btn_edit_positions',
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: ComicTheme
                                                                  .titleText(
                                                                size: 14,
                                                                color: ComicTheme
                                                                    .inkBlack,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      flex: 2,
                                                      child: GestureDetector(
                                                        onTap: AppLocalizations
                                                            .resetHudLayout,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 9,
                                                            horizontal: 8,
                                                          ),
                                                          decoration: ComicTheme
                                                              .comicButtonDecoration(
                                                            backgroundColor:
                                                                ComicTheme
                                                                    .paperWhite,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              AppLocalizations.tr(
                                                                'btn_reset_layout',
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: ComicTheme
                                                                  .titleText(
                                                                size: 13,
                                                                color: ComicTheme
                                                                    .inkBlack,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepSliderRow({
    required String title,
    required double ratio,
    required Color barColor,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ComicTheme.titleText(size: 13, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            GestureDetector(
              onTap: onMinus,
              child: Container(
                width: 32,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ComicTheme.actionRed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '-',
                  style: ComicTheme.titleText(size: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPlus,
              child: Container(
                width: 32,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ComicTheme.inkBlack, width: 1.5),
                ),
                child: Text(
                  '+',
                  style: ComicTheme.titleText(
                    size: 18,
                    color: ComicTheme.inkBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ComicTheme.inkBlack : Colors.white38,
            width: isSelected ? 3.0 : 2.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: ComicTheme.inkBlack,
                    offset: Offset(3, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ComicTheme.inkBlack,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                flagBadge,
                style: ComicTheme.titleText(
                  size: 14,
                  color: ComicTheme.comicYellow,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ComicTheme.titleText(
                      size: 16,
                      color: isSelected
                          ? (lang == AppLanguage.ja
                              ? Colors.white
                              : ComicTheme.inkBlack)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ComicTheme.bodyText(
                      size: 10.5,
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ComicTheme.inkBlack,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
