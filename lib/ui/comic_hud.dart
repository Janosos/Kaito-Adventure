import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class ComicHud extends StatefulWidget {
  final MangaGame game;
  const ComicHud({super.key, required this.game});

  @override
  State<ComicHud> createState() => _ComicHudState();
}

class _ComicHudState extends State<ComicHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _ticker.addListener(() {
      // Throttle HUD widget rebuilds to ~20 FPS for smooth Mali/Adreno/Web performance
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTickMs >= 50) {
        _lastTickMs = now;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final player = game.player;
    final boss = game.activeBoss;
    final screenSize = MediaQuery.of(context).size;
    final double uiScale = (screenSize.height / 540.0).clamp(0.58, 0.94);
    final bool isCompact = screenSize.height < 440;
    final double edgePad = isCompact ? 6.0 : 12.0;
    final double topPad = isCompact ? 4.0 : 10.0;

    return SafeArea(
      child: Stack(
        children: [
          // Top Left: 2D Cartoon Player Status Card (Responsive Scaled)
          Positioned(
            top: topPad,
            left: edgePad,
            child: Transform.scale(
              scale: uiScale,
              alignment: Alignment.topLeft,
              child: _buildPlayerStatusCard(player),
            ),
          ),

          // Top Center: Stage Progression Bar OR Boss Health & Stun Bar
          // Placing the Boss Bar in the Top-Center slot keeps the bottom D-Pad,
          // Action Buttons, and ground combat arena 100% unobstructed on mobile!
          Positioned(
            top: topPad,
            left: 275 * uiScale,
            right: 235 * uiScale,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: (boss != null && !boss.isDefeated)
                    ? _buildBossHud(boss)
                    : _buildStageProgressBar(game),
              ),
            ),
          ),

          // Top Right: Chapter & Score Card + Pause Button (Responsive Scaled)
          Positioned(
            top: topPad,
            right: edgePad,
            child: Transform.scale(
              scale: uiScale,
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildScoreCard(game),
                  const SizedBox(width: 8),
                  _buildPauseButton(game),
                ],
              ),
            ),
          ),

          // Right: Dynamic Manga Combo Banner (Below Score Card, Above Action Buttons)
          if (player.comboCount >= 2)
            Positioned(
              right: edgePad + 4,
              top: topPad + (68 * uiScale),
              child: Transform.scale(
                scale: uiScale,
                alignment: Alignment.topRight,
                child: _buildComboBanner(player),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatusCard(dynamic player) {
    final hp = player.hp as int;
    final maxHp = player.maxHp as int;
    final spirit = (player.spirit as double).clamp(0.0, 100.0);
    final isUltReady = spirit >= 100.0;
    final kunaiCd = (player.kunaiCooldown as double).clamp(0.0, 5.0);
    final kunaiReady = kunaiCd <= 0.01;
    final kunaiRatio = ((5.0 - kunaiCd) / 5.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite.withValues(alpha: 0.86),
        borderWidth: 2.5,
        shadowOffset: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2D Cartoon Kaito Avatar Portrait
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                CartoonAssets.portraitKaito,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name tag & Shinobi badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: ComicTheme.inkBlack,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '忍 KAITO',
                      style: ComicTheme.mangaHeader(
                          fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SHINOBI',
                    style: ComicTheme.comicBody(
                        fontSize: 10.5, color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // 2D Cartoon Health Hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxHp, (index) {
                  final isFull = index < hp;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Image.asset(
                      isFull
                          ? CartoonAssets.uiHeartFull
                          : CartoonAssets.uiHeartEmpty,
                      width: 20,
                      height: 20,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 3),

              // Ougi / Spirit Gauge Bar with 2D Cartoon Spirit Orb Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    CartoonAssets.uiSpiritOrb,
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.tr('hud_spirit'),
                    style: ComicTheme.mangaHeader(
                        fontSize: 11, color: ComicTheme.inkBlack),
                  ),
                  Container(
                    width: 84,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ComicTheme.halftoneGray,
                      borderRadius: BorderRadius.circular(3),
                      border:
                          Border.all(color: ComicTheme.inkBlack, width: 1.8),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: spirit / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUltReady
                              ? ComicTheme.comicYellow
                              : ComicTheme.energyCyan,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                  if (isUltReady) ...[
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.tr('hud_ougi_ready'),
                      style: ComicTheme.comicTitle(
                        fontSize: 11,
                        color: ComicTheme.actionRed,
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 2),

              // Kunai 5-Second Cooldown Gauge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    CartoonAssets.uiSkillKunai,
                    width: 15,
                    height: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.tr('hud_kunai'),
                    style: ComicTheme.mangaHeader(
                      fontSize: 10.5,
                      color: ComicTheme.inkBlack,
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ComicTheme.halftoneGray,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: ComicTheme.inkBlack,
                        width: 1.5,
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: kunaiRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kunaiReady
                              ? Colors.greenAccent.shade400
                              : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    kunaiReady
                        ? AppLocalizations.tr('hud_kunai_ready')
                        : '${kunaiCd.toStringAsFixed(1)}s',
                    style: ComicTheme.mangaHeader(
                      fontSize: 10.5,
                      color: kunaiReady
                          ? Colors.green.shade800
                          : ComicTheme.actionRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(MangaGame game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite.withValues(alpha: 0.86),
        borderWidth: 2.5,
        shadowOffset: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            CartoonAssets.uiScoreScroll,
            width: 26,
            height: 26,
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.tr('hud_stage_progress')}${game.currentLevelIndex}/${MangaGame.totalLevels}',
                style: ComicTheme.mangaHeader(
                    fontSize: 12, color: ComicTheme.actionRed),
              ),
              Text(
                '${AppLocalizations.tr('score_label')}${game.score.toString().padLeft(6, '0')}',
                style: ComicTheme.comicTitle(
                    fontSize: 16, color: ComicTheme.inkBlack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(MangaGame game) {
    return GestureDetector(
      onTap: () {
        AudioService.buttonHaptic();
        AudioService.playSfx(AudioService.sfxClick);
        game.togglePause();
      },
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor: ComicTheme.comicYellow,
        ),
        child: Image.asset(
          CartoonAssets.uiPause,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildComboBanner(dynamic player) {
    final count = player.comboCount as int;
    String grade = 'GOOD!';
    Color gradeColor = ComicTheme.comicYellow;
    if (count >= 10) {
      grade = 'INSANE!!';
      gradeColor = ComicTheme.actionRed;
    } else if (count >= 5) {
      grade = 'SUGOI!!';
      gradeColor = ComicTheme.energyCyan;
    }

    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: ComicTheme.comicPanelDecoration(
          backgroundColor: gradeColor,
          borderColor: ComicTheme.inkBlack,
          borderWidth: 3,
          shadowOffset: 4,
        ),
        child: Column(
          children: [
            Text(
              'COMBO x$count',
              style: ComicTheme.comicTitle(
                  fontSize: 20, color: ComicTheme.inkBlack),
            ),
            Text(
              grade,
              style: ComicTheme.mangaHeader(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageProgressBar(MangaGame game) {
    final progress = game.stageProgress;
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite,
        borderWidth: 2.5,
        shadowOffset: 3,
      ),
      child: Row(
        children: [
          Image.asset(CartoonAssets.uiKaitoHead, width: 20, height: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: ComicTheme.halftoneGray,
                border: Border.all(color: ComicTheme.inkBlack, width: 2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  color: ComicTheme.actionRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Image.asset(CartoonAssets.uiBossSkull, width: 20, height: 20),
        ],
      ),
    );
  }

  String _bossPortraitFor(String bossName) {
    if (bossName.contains('KUROKAGE')) return CartoonAssets.portraitKurokage;
    if (bossName.contains('RYU')) return CartoonAssets.portraitRyuKotei;
    if (bossName.contains('HEBI')) return CartoonAssets.portraitHebiHime;
    if (bossName.contains('YUKI')) return CartoonAssets.portraitYukiOni;
    return CartoonAssets.portraitMuzanKai;
  }

  Widget _buildBossHud(dynamic boss) {
    final double hpRatio = (boss.currentHp / boss.maxHp).clamp(0.0, 1.0);
    final double stunRatio = (boss.stunGauge / 100.0).clamp(0.0, 1.0);
    final isStunned = boss.isStunned as bool;
    final bossName = boss.name as String;
    final bossPortrait = _bossPortraitFor(bossName);

    return Container(
      width: 390,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite.withValues(alpha: 0.86),
        borderColor: ComicTheme.inkBlack,
        borderWidth: 2.5,
        shadowOffset: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2D Cartoon Boss Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                bossPortrait,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            color: ComicTheme.actionRed,
                            child: Text(
                              'BOSS',
                              style: ComicTheme.mangaHeader(
                                  fontSize: 11, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${boss.name}: ${boss.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ComicTheme.comicTitle(
                                fontSize: 14,
                                color: ComicTheme.inkBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'P${boss.currentPhase}/${boss.maxPhases}',
                      style: ComicTheme.mangaHeader(
                          fontSize: 12, color: ComicTheme.inkBlack),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Boss Main Health Bar
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: ComicTheme.halftoneGray,
                    border: Border.all(color: ComicTheme.inkBlack, width: 2),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: hpRatio,
                        child: Container(
                          color: isStunned
                              ? ComicTheme.comicYellow
                              : ComicTheme.actionRed,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(hpRatio * 100).toInt()}%',
                          style: ComicTheme.comicTitle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Stun / Break Gauge Bar
                Row(
                  children: [
                    Text(
                      'BREAK: ',
                      style: ComicTheme.mangaHeader(
                          fontSize: 10, color: Colors.grey.shade800),
                    ),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: ComicTheme.halftoneGray,
                          border: Border.all(
                              color: ComicTheme.inkBlack, width: 1.5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: stunRatio,
                          child: Container(
                            color: isStunned
                                ? Colors.redAccent
                                : ComicTheme.energyCyan,
                          ),
                        ),
                      ),
                    ),
                    if (isStunned) ...[
                      const SizedBox(width: 4),
                      Text(
                        '2x DMG!',
                        style: ComicTheme.comicTitle(
                          fontSize: 10,
                          color: ComicTheme.actionRed,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
